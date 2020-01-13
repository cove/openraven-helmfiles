#! /usr/bin/env bash
set -euo pipefail
TRACE="${TRACE:-}"
[[ -n "$TRACE" ]] && set -x
tgz_dir="$PWD/charts"
for i in charts/*/Chart.yaml; do
  cd "$(dirname "$i")"
  helm ${TRACE:+--debug} package .
  mv -iv *.tgz "$tgz_dir/"
  cd ../..
done
