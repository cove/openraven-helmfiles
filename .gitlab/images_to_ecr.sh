#! /usr/bin/env bash

set -euo pipefail
export AWS_REGION=us-west-2
export AWS_PAGER="/bin/cat"

AWS_ACCOUNT=184855680035
ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT:role/prod_push_ecr"
REPOSITORY="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"

# shellcheck disable=SC2207
session_token=($(aws sts assume-role --role-arn $ROLE_ARN --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --role-session-name "helmfiles" --output text))
export AWS_ACCESS_KEY_ID="${session_token[0]}" AWS_SECRET_ACCESS_KEY="${session_token[1]}" AWS_SESSION_TOKEN="${session_token[2]}"

aws ecr get-login-password | docker login --username AWS --password-stdin "$REPOSITORY"

for image in $(jq -r '.images | .[] ' manifest.json); do
  docker pull "$image" --quiet

  # Split the image at the / and grab the last element in the array. This will give us the image name.
  # The problem with this is that when we use it later, we may end up in a bad spot since it is possible, but unlikely
  # that we will see a duplicate image name. Think registry.docker.tld/foo/bar and registry.docker.tld/joe/bar. If we
  # hit this case, we probably want to blow up anyway.
  readarray -d '/' -t fullname_parts <<< "$image"
  image_base_with_tag=$(echo "${fullname_parts[${#fullname_parts[@]} - 1]}" | tr -d '\n')

  # take the image and grab the tag. if there is no tag... we should probably actually blow up... but not going there
  # yet.
  readarray -d ':' -t base_parts <<< "$image_base_with_tag"
  image_basename="$(echo "${base_parts[0]}" | tr -d '\n')"

  # Check to see if we already have a registry for this image and create it if we don't
  if ! aws ecr describe-repositories | jq -r '.repositories | .[].repositoryName' | sort | grep "^${image_basename}$"; then
    aws ecr create-repository \
      --repository-name "$image_basename" \
      --image-scanning-configuration scanOnPush=true \
      --encryption-configuration encryptionType=KMS \
      --image-tag-mutability IMMUTABLE
  fi

  ecr_push_image="$REPOSITORY/$image_base_with_tag"

  docker tag "$image" "$ecr_push_image"
  docker push "$ecr_push_image"
done
