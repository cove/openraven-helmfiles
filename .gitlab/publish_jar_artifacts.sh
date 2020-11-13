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

HELM_S3_PATH_BASE="s3://${HELM_S3_BUCKET}/dmap"

#Extract the version from ./values/aws-s3-scanner-version.yaml and ./values/dmap-lambda-version.yaml

DMAP_LAMBDA_VERSION="$(awk '{print $2}' ./helmfile.d/values/dmap-lambda-version.yaml)"
AWS_S3_SCANNER_VERSION="$(awk  '{print $2}' ./helmfile.d/values/aws-s3-scanner-version.yaml)"
DMAP_LAMBDA_FN=dmap-lambda-${DMAP_LAMBDA_VERSION}.jar
AWS_S3_SCANNER_FN=aws-s3-scanner-${AWS_S3_SCANNER_VERSION}.jar

mvn -U dependency:copy -DoutputDirectory=. -Dartifact=io.openraven:aws-s3-scanner:${AWS_S3_SCANNER_VERSION}
mvn -U dependency:copy -DoutputDirectory=. -Dartifact=io.openraven:dmap-lambda:${DMAP_LAMBDA_VERSION}

all_regions=(us-west-2 us-west-1 us-east-2 us-east-1 ca-central-1 sa-east-1 eu-west-3 eu-west-2 eu-west-1 eu-north-1 eu-central-1 ap-southeast-2 ap-southeast-1 ap-south-1 ap-northeast-2 ap-northeast-1)

for region in "${all_regions[@]}";do
  aws s3 cp $AWS_S3_SCANNER_FN s3://$HELM_S3_BUCKET-$region/dmap/dataclassification/$AWS_S3_SCANNER_FN;
done;

# Fetch the artifacts from mvn

# Iterate all the regions, uploading to s3 the artifacts
