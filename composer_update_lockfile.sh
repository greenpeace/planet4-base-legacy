#!/usr/bin/env bash
set -e

if [[ -z "${GITHUB_OAUTH_TOKEN}" ]]
then
  >&2 echo "ERROR: \$GITHUB_OAUTH_TOKEN is not set"
  >&2 echo "       Please ensure a valid github token is available"
  >&2 echo "       Attempting to continue ..."
fi

if [[ "${COMPOSER}" ]]
then
  echo "Using COMPOSER=${COMPOSER}"
fi

composer --profile -vvv update
