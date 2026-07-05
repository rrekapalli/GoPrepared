# shellcheck shell=bash
# Pin JAVA_HOME to JDK 21 for GoPrepared Maven builds (Lombok requires a supported JDK).

JAVA21_HOME_CANDIDATES=(
    "/usr/lib/jvm/java-21-openjdk-amd64"
    "/usr/lib/jvm/java-21-openjdk-arm64"
)

probe_java21_home() {
    local dir
    for dir in "${JAVA21_HOME_CANDIDATES[@]}"; do
        if [[ -d "$dir" && -x "$dir/bin/javac" ]]; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

ensure_java21_env() {
    local jdk_home
    if jdk_home="$(probe_java21_home)"; then
        export JAVA_HOME="$jdk_home"
        export PATH="$JAVA_HOME/bin:$PATH"
        return 0
    fi

    echo "[ERROR] Java 21 JDK required for API builds (found: $(java -version 2>&1 | head -1))." >&2
    echo "[ERROR] Run: ./deployment/prepare-dev-machine.sh" >&2
    return 1
}
