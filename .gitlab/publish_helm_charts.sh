#! /usr/bin/env bash
set -euo pipefail
TRACE="${TRACE:-}"
[[ -n "$TRACE" ]] && set -x
HELM_S3_BUCKET="${HELM_S3_BUCKET:-}"
if [[ -z "$HELM_S3_BUCKET" ]]; then
    echo 'Not without $HELM_S3_BUCKET' >&2
    exit 1
fi
HELM_S3_BUCKET_HOST="${HELM_S3_BUCKET_HOST:-s3.amazonaws.com}"

HELM_S3_PATH="s3://${HELM_S3_BUCKET}/charts"
# this represents the way that the charts are consumed by the public
HELM_PUBLIC_REPO_URL="https://${HELM_S3_BUCKET}.${HELM_S3_BUCKET_HOST}/charts"

cd charts
helm_index_args="${helm_index_args:-}"
if [[ -n "$TRACE" ]]; then
    helm_index_args="${helm_index_args} --debug"
fi
existing_index_fn=upstream-index.yaml
# guard this, because the upstream bucket may be fresh, and thus there is nothing to merge
if curl -fsSLo "$existing_index_fn" ${HELM_PUBLIC_REPO_URL}/index.yaml; then
  helm_index_args="${helm_index_args} --merge=$existing_index_fn"
fi
helm repo index ${helm_index_args} --url=${HELM_PUBLIC_REPO_URL} .
for ch in *.tgz; do
  aws s3 cp "$ch" ${HELM_S3_PATH}/
done
aws s3 cp index.yaml ${HELM_S3_PATH}/
