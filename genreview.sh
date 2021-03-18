#!/bin/bash

cat<<EOM > SECURITY_REVIEW.md
# Security Review
Last Update: $(date +%D)

EOM

grep -h -A1 -R '^####' * | egrep -v '(^--|SECURITY_REVIEW.md)' |sed -e 's/^# / /g' >> SECURITY_REVIEW.md

