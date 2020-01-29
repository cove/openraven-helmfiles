#! /usr/bin/env bash
set -euo pipefail
CI="${CI:-}"
TRACE="${TRACE:-}"
trace_on() {
    [[ -n "$TRACE" ]] && set -x
}
trace_on
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 the-helmfile-filename the-charts-dirname the-new-version" >&2
    exit 1
fi
# we could also take advantage of the fact that currently
# the helmfile.d and chart names basically match
helmfile_name="$1"
shift
chart_name="$1"
shift
chart_ver="$1"
shift
chart_yaml_fn=charts/${chart_name}/Chart.yaml
helmfile_fn=helmfile.d/$helmfile_name

if [[ -z "$CI" ]]; then
    chat_start() {
        :
    }
    chat_stop() {
        :
    }
fi

if [[ ! -e "$chart_yaml_fn" ]]; then
    chat_start; echo "Sorry, your chart file \"$chart_yaml_fn\" is 404" >&2; chat_stop
    exit 1
fi
if [[ ! -e "$helmfile_fn" ]]; then
    chat_start; echo "Sorry, your helmfile.d file \"$helmfile_fn\" is 404" >&2; chat_stop
    exit 1
fi

# watch out, this won't work for more complex setups like 13-aws-discovery-svc.yaml
sed -i.bak -e "s/^  version: .*/  version: $chart_ver/" "$helmfile_fn"
sed -i.bak -e "s/^version: .*/version: $chart_ver/" "$chart_yaml_fn"

git add "$helmfile_fn" "$chart_yaml_fn"

if [[ -n "$CI" ]]; then
    set +x
    push_url="${CI_REPOSITORY_URL//${CI_REGISTRY_USER}[^@]*@/oauth2:${GLR_PAT}@/}"
    git config --local user.name  "$GITLAB_USER_NAME"
    git config --local user.email "$GITLAB_USER_EMAIL"
    git remote set-url --push origin "$push_url"
    trace_on
    git commit -m"Bump $chart_name to $chart_ver

    By request of @${GITLAB_USER_LOGIN}
    "
    # skip CI jobs to (a) avoid any CI cycles (b) avoid any accidental rollouts
    # maybe make this a job parameter?
    git push -o ci.skip=true origin "$CI_COMMIT_REF_NAME"
fi
