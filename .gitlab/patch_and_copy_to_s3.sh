#! /usr/bin/env bash
set -euo pipefail
TRACE="${TRACE:-}"
[[ -n "$TRACE" ]] && set -x

CI_COMMIT_SHA="${CI_COMMIT_SHA:-}"
if [[ -z "$CI_COMMIT_SHA" ]]; then
    echo 'Not without $CI_COMMIT_SHA' >&2
    exit 1
fi

HELM_S3_BUCKET="${HELM_S3_BUCKET:-}"
if [[ -z "$HELM_S3_BUCKET" ]]; then
    echo 'Not without $HELM_S3_BUCKET' >&2
    exit 1
fi
HELM_S3_PATH="s3://${HELM_S3_BUCKET}/charts"

CI_COMMIT_REF_NAME="${CI_COMMIT_REF_NAME:-}"
if [ "$CI_COMMIT_REF_NAME" = "master" ]; then
  .gitlab/bump_release_version.sh "${CI_PIPELINE_ID}"
fi

git_sha=$(git rev-parse HEAD)

# we could also update HELMFILE_GIT_URL here if necessary, too
sed -i.bak -e '/"HELMFILE_GIT_REF"/s@default "[^"]*"@default "'${git_sha}'"@' helmfile.yaml
cat helmfile.yaml
aws s3 cp helmfile.yaml ${HELM_S3_PATH}/
aws s3 cp manifest.json ${HELM_S3_PATH}/
