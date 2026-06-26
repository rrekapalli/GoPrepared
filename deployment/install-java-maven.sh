#!/usr/bin/env bash
# Java 21 + Maven for GoPrepared API builds in WSL (Ubuntu 24.04).
set -euo pipefail

log() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*" >&2; }

JAVA_PKG="${JAVA_PKG:-openjdk-21-jdk}"
JAVA_HOME_CANDIDATES=(
  "/usr/lib/jvm/java-21-openjdk-amd64"
  "/usr/lib/jvm/java-21-openjdk-arm64"
)

detect_java_home() {
    local dir
    for dir in "${JAVA_HOME_CANDIDATES[@]}"; do
        if [[ -d "$dir" && -x "$dir/bin/javac" ]]; then
            echo "$dir"
            return 0
        fi
    done
    if command -v java >/dev/null 2>&1; then
        local java_bin jdk_dir
        java_bin="$(readlink -f "$(command -v java)" 2>/dev/null || command -v java)"
        jdk_dir="$(dirname "$(dirname "$java_bin")")"
        if [[ -x "$jdk_dir/bin/javac" ]]; then
            echo "$jdk_dir"
            return 0
        fi
    fi
    return 1
}

ensure_java_home_in_profile() {
    local jdk_home="$1"
    if grep -qF 'JAVA_HOME=' "$HOME/.bashrc" 2>/dev/null; then
        log "JAVA_HOME already in ~/.bashrc"
        return 0
    fi
    cat >> "$HOME/.bashrc" <<EOF

# GoPrepared Java 21 (deployment/install-java-maven.sh)
export JAVA_HOME="$jdk_home"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
    log "Added JAVA_HOME to ~/.bashrc"
}

if jdk_home="$(detect_java_home)"; then
    log "Java already installed at $jdk_home"
else
    log "Installing $JAVA_PKG and Maven (sudo required)..."
    sudo apt-get update -qq
    sudo apt-get install -y "$JAVA_PKG" maven
    jdk_home="$(detect_java_home)" || {
        err "Java install finished but JDK home not found under /usr/lib/jvm"
        exit 1
    }
fi

if ! command -v mvn >/dev/null 2>&1; then
    log "Installing Maven..."
    sudo apt-get install -y maven
fi

ensure_java_home_in_profile "$jdk_home"
export JAVA_HOME="$jdk_home"
export PATH="$JAVA_HOME/bin:$PATH"

log "JAVA_HOME=$JAVA_HOME"
log "Java: $(java -version 2>&1 | head -1)"
log "Maven: $(mvn -version 2>&1 | head -1)"
