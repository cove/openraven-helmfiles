#! /usr/bin/env bash
set -euo pipefail
CHATOPS="${CHAT_CHANNEL:-}"
TRACE="${TRACE:-}"
trace_on() {
    if [[ -n "$TRACE" ]]; then
      set -x
    fi
}
trace_on
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 source-bucket dest-bucket" >&2
    exit 1
fi

src_bucket="$1"
shift
dest_bucket="$1"
shift

if [[ -z "$CHATOPS" ]]; then
    chat_start() {
        :
    }
    chat_stop() {
        :
    }
fi

# Check for existence of the buckets
if ! aws s3 ls "s3://$src_bucket"; then
  chat_start; echo "$src_bucket does not exist."; chat_stop
  exit 1
fi

if ! aws s3 ls "s3://$dest_bucket"; then
  chat_start; echo "$dest_bucket does not exist."; chat_stop
  exit 1
fi

mkdir workingdir
cd workingdir
aws s3 cp "s3://$src_bucket/charts/manifest.json" .

mkdir charts
for x in $(jq -r '.charts[] | select(.external == false) | {name, version} | "\(.name)-\(.version).tgz"' < manifest.json); do
  aws s3 cp "s3://$src_bucket/charts/$x" charts/
done

export HELM_S3_BUCKET=$dest_bucket
../.gitlab/publish_helm_charts.sh

aws s3 cp "s3://${src_bucket}/charts/helmfile.yaml" "s3://${dest_bucket}/charts/helmfile.yaml"
aws s3 cp manifest.json "s3://${dest_bucket}/charts/manifest.json"

chat_start; echo "Promoted $src_bucket to $dest_bucket"; chat_stop
