#! /usr/bin/env bash
set -euo pipefail
CI="${CI:-}"
CHATOPS="${CHAT_CHANNEL:-}"
TRACE="${TRACE:-}"
trace_on() {
    if [[ -n "$TRACE" ]]; then
      set -x
    fi
}
trace_on
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 patch-version [major_minor_pair]" >&2
    exit 1
fi
patch_version=${1:-}
major_minor_pair=${2:-}

values_fn=helmfile.d/values/releaseVersion.yaml

if [[ -z "$CHATOPS" ]]; then
    chat_start() {
        :
    }
    chat_stop() {
        :
    }
fi

if [[ ! -e "$values_fn" ]]; then
    chat_start; echo "Sorry, your helmfile.d file \"$values_fn\" is 404" >&2; chat_stop
    exit 1
fi

if [[ -n "$CI" ]]; then
  echo "Putting the working copy back onto $CI_COMMIT_REF_NAME (was in detached head)" >&2
  git checkout --force "$CI_COMMIT_REF_NAME"
  git reset --hard "$CI_COMMIT_SHA"
fi

exit_if_not_dirty() {
  local fn="$1"
  if ! git status --porc "$fn" | grep -- "$fn"; then
    echo "Expected the change to dirty \"$fn\" but nope" >&2
    exit 1
  fi
}
if [[ -n "$major_minor_pair" ]]; then
  sed -i.bak -E -e 's/^(releaseVersion: ).*/\1'"${major_minor_pair}[.]${patch_version}/" "$values_fn"
else
  sed -i.bak -E -e 's/^(releaseVersion: [[:digit:]]+[.][[:digit:]]+[.]).*/\1'"${patch_version}/" "$values_fn"
fi
exit_if_not_dirty "$values_fn"

git add "$values_fn"
new_version=$(sed -nEe 's/^releaseVersion: //p' "$values_fn")

if [[ -n "$CI" ]]; then
    # shellcheck disable=SC2001
    push_url="$(echo "$CI_REPOSITORY_URL" | sed -e "s/${CI_REGISTRY_USER}[^@]*@/oauth2:${GLR_PAT}@/")"
    git config --local user.name  "$GITLAB_USER_NAME"
    git config --local user.email "$GITLAB_USER_EMAIL"
    git remote set-url --push origin "$push_url"
    git commit -m"Bump Release to $new_version

    By request of @${GITLAB_USER_LOGIN}
    "
    git push origin "$CI_COMMIT_REF_NAME" -o ci.skip
fi
