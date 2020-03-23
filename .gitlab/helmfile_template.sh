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


export ADMIN_CLIENT_ID=AdMiNCliE-nt-id
export ADMIN_CLIENT_SECRET='ZeAdmen/Sekrit-123'
export COOKIE_SECRET=c00kieS3krit
export CLUSTER_NAME='Spaces Are Awesome!'
export FRONTEND_CLIENT_ID=feCID
export GROUP_ID=ThEgRoUpId
export OPENRAVEN_INGRESS_HOSTNAME=www.example.com
export SERVICE_CLIENT_ID=seCLID
export SERVICE_CLIENT_SECRET=scSec

# test all of them, and don't go through the git ref
rm -v helmfile.yaml

{ helmfile --log-level "${HELMFILE_LOG_LEVEL}" template | tee k8s.yml; } || {
    echo 'the rendered values files: ' >&2
    cat /tmp/values*
    exit 1
}

echo '<editor-fold desc="k8s.yml">'
cat k8s.yml
echo '</editor-fold>'

python3 -c '
import json
import sys
import yaml
all_docs = list(yaml.safe_load_all(sys.stdin))
json.dump(all_docs, sys.stdout)
' < k8s.yml | jq .

# This is ugly but keeps from needing to do a bunch of complicated bits in python
grep 'helm.sh/chart' k8s.yml | sed -e 's@^.*helm\.sh/chart: @@' | sort | uniq | .gitlab/generate_manifest.py > manifest.json

echo '<editor-fold desc="manifest.json">'
jq . < manifest.json
echo '</editor-fold>'

git checkout helmfile.yaml
