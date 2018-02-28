#!/usr/bin/env bash
set -eo pipefail

# Description: FROM_TAG is the version of p4-onbuild from which to build this application
#              This script attempts to determine the correct version to use




# If the environment isn't already configured, source env.sh
if [[ -z "${BUILD_NAMESPACE}" ]] || [[ -z "${GOOGLE_PROJECT_ID}" ]]
then
  # Find real file path of current script
  # https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
  source="${BASH_SOURCE[0]}"
  while [[ -h "$source" ]]
  do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    # if $source was a relative symlink, we need to resolve it relative to the
    # path where the symlink file was located
    [[ $source != /* ]] && source="$dir/$source"
  done
  current_dir="$( cd -P "$( dirname "$source" )" && pwd )"

  # shellcheck disable=SC1090
  . "$current_dir/env.sh"
fi

# Determine gcloud binary
if [[ ! -z "${CIRCLECI}" ]]
then
  # Expect gcloud to be configured under the home directory
  gcloud_binary="${HOME}/google-cloud-sdk/bin/gcloud"
else
  # Hope for the best
  gcloud_binary=$(type -P gcloud)
fi

# If it's set, use that
if [[ "${FROM_TAG}" ]]
then
  echo "${FROM_TAG}"
  exit 0
fi

# Search gcloud container registry for p4-onbuild images with the current branch
if [[ "$(${gcloud_binary} container images list-tags "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/p4-onbuild" --filter="tags=${BRANCH_NAME:-$(git rev-parse --abbrev-ref HEAD)}" --format="table[no-heading](tags, timestamp)" 2>/dev/null)" != "" ]]
then
  >&2 echo "Found image with current branch: ${BRANCH_NAME}"
  echo "${BRANCH_NAME}"
  exit 0
fi

exit 1
