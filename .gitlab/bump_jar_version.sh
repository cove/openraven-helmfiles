#! /usr/bin/env bash
set -euo pipefail
CI="${CI:-}"
if [[ -n "$CI" ]]; then
  # purposefully dereference this when in CI to die early if not set
  GLR_PAT="${GLR_PAT}"
fi
CHATOPS="${CHAT_CHANNEL:-}"
TRACE="${TRACE:-}"
trace_on() {
    if [[ -n "$TRACE" ]]; then
      set -x
    fi
}
trace_on
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 the-jar-name the-new-version" >&2
    exit 1
fi

# The jar name currently either aws-s3-scanner or dmap-lambda
jar_name="$1"
shift
# The jar version of the form 0.0.PIPELINEID
jar_ver="$1"
shift
# The location of the version file for the current jar
jar_version_fn=helmfile.d/values/${jar_name}-version.yaml

if [[ -z "$CHATOPS" ]]; then
    chat_start() {
        :
    }
    chat_stop() {
        :
    }
fi

if [[ ! -e "$jar_version_fn" ]]; then
    chat_start; echo "Sorry, your jar file \"$jar_version_fn\" is 404" >&2; chat_stop
    exit 1
fi

if [[ -n "$CI" ]]; then
  echo "Putting the working copy back onto $CI_COMMIT_REF_NAME (was in detached head)" >&2
  git checkout --force "$CI_COMMIT_REF_NAME"
  git reset --hard "$CI_COMMIT_SHA"
fi

exit_if_not_dirty() {
  local fn="$1"
  if ! git status --porc "$fn" | grep -q -- "$fn"; then
    echo "Expected the change to dirty \"$fn\" but nope" >&2
    exit 1
  fi
}

sed -i.bak -e "s/^version: .*/version: $jar_ver/" "$jar_version_fn"
exit_if_not_dirty "$jar_version_fn"

git add "$jar_version_fn"

git diff --cached || true

if [[ -n "$CI" ]]; then
    set +x
    # shellcheck disable=SC2001
    push_url="$(echo "$CI_REPOSITORY_URL" | sed -e "s/${CI_REGISTRY_USER}[^@]*@/oauth2:${GLR_PAT}@/")"
    git config --local user.name  "$GITLAB_USER_NAME"
    git config --local user.email "$GITLAB_USER_EMAIL"
    git remote set-url --push origin "$push_url"
    trace_on
    git commit -m"Bump $jar_name to $jar_ver

    By request of @${GITLAB_USER_LOGIN}
    "
    git push origin "$CI_COMMIT_REF_NAME"
fi
