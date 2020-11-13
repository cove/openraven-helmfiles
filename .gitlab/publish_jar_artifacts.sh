#! /usr/bin/env bash
set -euo pipefail
TRACE="${TRACE:-}"
[[ -n "$TRACE" ]] && set -x
HELM_S3_BUCKET="${HELM_S3_BUCKET:-}"
if [[ -z "$HELM_S3_BUCKET" ]]; then
    echo 'Not without $HELM_S3_BUCKET' >&2
    exit 1
fi

DMAP_ART_ID=dmap-lambda
AWS_S3_ART_ID=aws-s3-scanner

if [[ -z "${all_regions:-}" ]]; then
  all_regions=(us-west-2 us-west-1 us-east-2 us-east-1 ca-central-1 sa-east-1 eu-west-3 eu-west-2 eu-west-1 eu-north-1 eu-central-1 ap-southeast-2 ap-southeast-1 ap-south-1 ap-northeast-2 ap-northeast-1)
fi

copy_to_all_regions() {
  local fn="$1"
  for region in "${all_regions[@]}"; do
    aws s3 cp $fn s3://${HELM_S3_BUCKET}-${region}/dmap/dataclassification/$fn
  done
}

copy_mvn_jar() {
  local art_id="$1"
  local v
  v="$(awk '{print $2}' ./helmfile.d/values/${art_id}-version.yaml)"
  mvn -U --batch-mode --settings ${GITLAB_MAVEN_SETTINGS_XML} dependency:copy -DoutputDirectory=. -Dartifact=io.openraven:${art_id}:${v}
  copy_to_all_regions ${art_id}-${v}.jar
}

copy_mvn_jar ${DMAP_ART_ID}
copy_mvn_jar ${AWS_S3_ART_ID}
