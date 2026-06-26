# shellcheck shell=bash
# Resolve Flutter on Linux, macOS, and WSL (including Windows Flutter on /mnt/c/).

is_wsl() {
    grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

resolve_flutter() {
    if [[ -n "${FLUTTER:-}" ]] && [[ -x "${FLUTTER}" ]]; then
        echo "${FLUTTER}"
        return 0
    fi
    if command -v flutter >/dev/null 2>&1; then
        command -v flutter
        return 0
    fi
    return 1
}

fix_flutter_crlf_if_needed() {
    local flutter_bin="$1"
    is_wsl || return 0
    [[ "$flutter_bin" == /mnt/c/* ]] || return 0

    local flutter_root internal f patched=0
    flutter_root="$(cd "$(dirname "$flutter_bin")/.." && pwd)"
    internal="${flutter_root}/bin/internal"

    for f in "$flutter_bin" "${internal}"/*.sh; do
        [[ -f "$f" ]] || continue
        if grep -q $'\r' "$f" 2>/dev/null; then
            sed -i 's/\r$//' "$f"
            patched=1
        fi
    done

    if [[ "$patched" -eq 1 ]]; then
        log_warn "Fixed CRLF in Windows Flutter SDK scripts (required when building from WSL)."
    fi
}

run_flutter() {
    local app_dir="$1"
    local flutter_bin="$2"
    shift 2
    fix_flutter_crlf_if_needed "$flutter_bin"
    (cd "$app_dir" && "$flutter_bin" "$@")
}

ensure_wsl_build_path() {
    if command -v git >/dev/null 2>&1 && git --version >/dev/null 2>&1; then
        return 0
    fi

    if is_wsl; then
        local win_git dir
        for win_git in \
            "/mnt/c/Program Files/Git/cmd/git.exe" \
            "/mnt/c/Program Files/Git/bin/git.exe"; do
            if [[ -x "$win_git" ]] && "$win_git" --version >/dev/null 2>&1; then
                dir="$(dirname "$win_git")"
                export PATH="${dir}:${PATH}"
                log_info "Using Windows Git from WSL: ${win_git}"
                return 0
            fi
        done
    fi

    log_error "git not found or not runnable from this shell."
    exit 1
}

flutter_is_windows_sdk_in_wsl() {
    local flutter_bin="$1"
    is_wsl || return 1
    [[ "$flutter_bin" == /mnt/c/* ]] || return 1
    local flutter_root dart_linux
    flutter_root="$(cd "$(dirname "$flutter_bin")/.." && pwd)"
    dart_linux="${flutter_root}/bin/cache/dart-sdk/bin/dart"
    [[ -x "$dart_linux" ]] && return 1
    return 0
}

find_linux_flutter() {
    local candidate
    for candidate in \
        "${FLUTTER:-}" \
        "${HOME}/flutter/bin/flutter" \
        "${HOME}/development/flutter/bin/flutter" \
        "/opt/flutter/bin/flutter"; do
        [[ -n "$candidate" && -x "$candidate" ]] || continue
        [[ "$candidate" == /mnt/c/* ]] && continue
        echo "$candidate"
        return 0
    done
    return 1
}

build_pwa_artifact_powershell() {
    local root_dir="$1"
    local ps_script="${root_dir}/scripts/build_pwa_artifact.ps1"
    [[ -f "$ps_script" ]] || {
        log_error "Missing Windows build script: ${ps_script}"
        exit 1
    }

    local ps_exe ps_path
    for ps_exe in powershell.exe pwsh.exe; do
        if command -v "$ps_exe" >/dev/null 2>&1; then
            ps_path="$(wslpath -w "$ps_script")"
            log_info "Building PWA via Windows ${ps_exe}..."
            if "$ps_exe" -NoProfile -ExecutionPolicy Bypass -File "$ps_path"; then
                [[ -f "${root_dir}/deployment/artifacts/pwa-dist.zip" ]] || {
                    log_error "PowerShell build finished but pwa-dist.zip is missing"
                    exit 1
                }
                log_success "PWA zip: ${root_dir}/deployment/artifacts/pwa-dist.zip"
                return 0
            fi
        fi
    done

    log_error "Cannot build with Windows Flutter from WSL."
    log_error "From Windows: powershell -File scripts/build_pwa_artifact.ps1"
    log_error "Then from WSL: ./deploy.sh --skip-build"
    exit 1
}

build_pwa_artifact_native() {
    local root_dir="$1"
    local api_base_url="${2:-http://localhost:8080/api/v1}"
    local app_dir="${root_dir}/go-prepared-app"
    local artifacts_dir="${root_dir}/deployment/artifacts"
    local build_dir="${app_dir}/build/web"
    local flutter_bin

    ensure_wsl_build_path
    command -v zip >/dev/null 2>&1 || {
        log_error "zip not found. Install zip and retry."
        exit 1
    }

    flutter_bin="$(resolve_flutter)" || {
        log_error "Flutter not found. Install Flutter or set FLUTTER=/path/to/flutter"
        exit 1
    }

    if flutter_is_windows_sdk_in_wsl "$flutter_bin"; then
        local linux_flutter
        linux_flutter="$(find_linux_flutter || true)"
        if [[ -n "$linux_flutter" ]]; then
            flutter_bin="$linux_flutter"
        else
            build_pwa_artifact_powershell "$root_dir"
            return 0
        fi
    fi

    log_info "Flutter API_BASE_URL=${api_base_url}"
    run_flutter "$app_dir" "$flutter_bin" pub get
    run_flutter "$app_dir" "$flutter_bin" build web --release --pwa-strategy offline-first \
        --dart-define="API_BASE_URL=${api_base_url}"

    [[ -d "$build_dir" ]] || { log_error "Build dir missing: $build_dir"; exit 1; }
    [[ -f "${build_dir}/index.html" ]] || { log_error "index.html missing in build output"; exit 1; }

    rm -f "${artifacts_dir}/pwa-dist.zip"
    (cd "$build_dir" && zip -qr "${artifacts_dir}/pwa-dist.zip" .)
    log_success "PWA zip: ${artifacts_dir}/pwa-dist.zip"
}

build_api_artifact() {
    local root_dir="$1"
    local api_dir="${root_dir}/go-prepared-api"
    local artifacts_dir="${root_dir}/deployment/artifacts"
    local mvnw="${api_dir}/mvnw"

    [[ -x "$mvnw" ]] || chmod +x "$mvnw" 2>/dev/null || true

    log_info "Building Spring Boot API (Maven)..."
    (cd "$api_dir" && ./mvnw -q -DskipTests package) || {
        log_error "Maven package failed"
        exit 1
    }

    local jar
    jar=$(find "${api_dir}/target" -maxdepth 1 -name 'go-prepared-api-*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' | head -n1)
    [[ -n "$jar" ]] || { log_error "API jar not found under ${api_dir}/target"; exit 1; }
    cp "$jar" "${artifacts_dir}/go-prepared-api.jar"
    log_success "API jar: ${artifacts_dir}/go-prepared-api.jar"
}
