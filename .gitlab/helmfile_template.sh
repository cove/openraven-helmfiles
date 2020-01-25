#! /usr/bin/env bash
set -euo pipefail
CI="${CI:-}"
HELMFILE_LOG_LEVEL="${HELMFILE_LOG_LEVEL:-debug}"
TRACE="${TRACE:-}"

[[ -n "$TRACE" ]] && set -x

if [[ "$CI" == "true" ]]; then
    CI_PROJECT_DIR="${CI_PROJECT_DIR}"
    if ! type python3 >/dev/null 2>&1; then
        apk add python3
    fi
    cd "$CI_PROJECT_DIR"
    python3 -m http.server 9090 &
    python_pid=$!
    sleep 1
    cleanup_python() {
        kill -9 ${python_pid}
    }
    trap cleanup_python EXIT
    export HELM_S3_URL=http://127.0.0.1:9090/charts
    curl -fI ${HELM_S3_URL}/index.yaml
    cd -
fi


export COOKIE_SECRET=c00kieS3krit
export FRONTEND_CLIENT_ID=feCID
export GROUP_ID=ThEgRoUpId
export OPENRAVEN_INGRESS_HOSTNAME=www.example.com
export SERVICE_CLIENT_ID=seCLID
export SERVICE_CLIENT_SECRET=scSec

# test all of them, and don't go through the git ref
rm -v helmfile.yaml

helmfile --log-level ${HELMFILE_LOG_LEVEL} template || {
    echo 'the rendered values files: ' >&2
    cat /tmp/values*
    exit 1
}
git checkout helmfile.yaml
