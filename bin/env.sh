#!/usr/bin/env bash
# shellcheck disable=SC2034
set -ao pipefail

# CONFIG FILE
# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

DEFAULT_CONFIG_FILE="${BUILD_DIR}/config.default"
if [[ ! -f "${DEFAULT_CONFIG_FILE}" ]]
then
  fatal "Default configuration file not found: ${DEFAULT_CONFIG_FILE}"
fi
# shellcheck source=/dev/null
. ${DEFAULT_CONFIG_FILE}

# Read from custom config file from command line parameter
if [[ "${CONFIG_FILE}" ]]
then
  if [[ ! -f "${CONFIG_FILE}" ]]
  then
    fatal "Custom config file not found: ${CONFIG_FILE}"
  fi

  echo "Reading config from: ${CONFIG_FILE}"

  # https://github.com/koalaman/shellcheck/wiki/SC1090
  # shellcheck source=/dev/null
  . ${CONFIG_FILE}
fi

if [[ -z "${GITHUB_OAUTH_TOKEN}" ]]
then
  fatal "GITHUB_OAUTH_TOKEN environment variable not set"
fi

# Envsubst and cloudbuild.yaml variable consolidation
APPLICATION_NAME=${APPLICATION_NAME:-${DEFAULT_APPLICATION_NAME}}
FROM_IMAGE="${FROM_IMAGE:-${DEFAULT_FROM_IMAGE}}"
FROM_NAMESPACE="${FROM_NAMESPACE:-${DEFAULT_FROM_NAMESPACE}}"
FROM_TAG="${FROM_TAG:-${DEFAULT_FROM_TAG}}"
BRANCH_NAME="${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
BUILD_ENVIRONMENT="${BUILD_ENVIRONMENT:-${DEFAULT_BUILD_ENVIRONMENT}}"
BUILD_NAMESPACE="${BUILD_NAMESPACE:-${DEFAULT_BUILD_NAMESPACE}}"
BUILD_NUM="${BUILD_NUM:-${CIRCLE_BUILD_NUM:-"local"}}"
GIT_REF="${GIT_REF:-${DEFAULT_GIT_REF}}"
GOOGLE_PROJECT_ID="${GOOGLE_PROJECT_ID:-${DEFAULT_GOOGLE_PROJECT_ID}}"
IMAGE_MAINTAINER="${MAINTAINER:-${DEFAULT_MAINTAINER}}"
