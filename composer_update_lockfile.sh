#!/usr/bin/env bash
set -e

if [[ -z "${GITHUB_OAUTH_TOKEN}" ]]
then
  echo "GITHUB_OAUTH_TOKEN not found in environment."
  printf "%s " "Please enter token now:"
  read GITHUB_OAUTH_TOKEN
fi

if [[ -z "${GITHUB_OAUTH_TOKEN}" ]]
then
  >&2 echo "ERROR: \$GITHUB_OAUTH_TOKEN is not set"
  >&2 echo "       Please ensure a valid github token is available"
  exit 1
fi

if [[ $1 = 'dev' ]]
then
  COMPOSER="composer-dev.json"
fi

if [[ "${COMPOSER}" ]]
then
  echo "Using COMPOSER=${COMPOSER}"
fi

composer --profile -vv update
