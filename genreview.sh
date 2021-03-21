#!/bin/bash

cat<<EOM > SECURITY_REVIEW.md
# Security Review
Last Update: $(date +%D)

EOM

grep -h -A1 -R '^####' * | egrep -v '(^--|SECURITY_REVIEW.md)' |sed -e 's/^# / /g' >> SECURITY_REVIEW.md

# ref: https://bridgecrew.io/blog/scan-helm-charts-for-kubernetes-misconfigurations-with-checkov/
bash -c 'find -iname chart.yaml' | xargs -n1 -I% bash -c " dirname %" | xargs -n1 -I% bash -c "helm template % > %.yaml \
  && checkov -f %.yaml --framework kubernetes || true" -- > SECURITY_REVIEW_CHECKOV.txt
