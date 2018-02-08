#!/usr/bin/env bash
#shellcheck disable=2034,2016,1090

set -eo pipefail

# Description:  Configures and submits container builds on Google Container Registry
# Author:       Raymond Walker <raymond.walker@greenpeace.org>

function usage() {
  echo "Usage: $0 [-l|r|v] [-c <configfile>] ...

Build and test artifacts in this repository. By default this script will only
recreate a new Dockerfile from the Dockerfile.in template.  To initiate a build

Options:
  -c    Config file for environment variables, eg:
          \$ $(basename "$0") -c config
  -e    Environment to build
  -l    Perform the CircleCI task locally (requires circlecli)
  -p    Pull images after build
  -r    Submits a build request to Google Container Builder
  -v    Verbose
"
}

bash_version=$(bash --version | head -n 1| cut -d' ' -f4 | cut -d '.' -f 1)
config_pass=0
env_parameters=()

# Clean up on exit
function finish() {
  rm -fr "$TMPDIR"
}
trap finish EXIT

TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

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
BUILD_DIR="$( cd -P "$( dirname "$source" )/.." && pwd )"

# Pretty printing
. "${BUILD_DIR}/bin/pretty_print.sh"

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

# Reads key-value file as function argument, assigns variable to environment
function set_vars() {
  local file
  file="${1}"
  _build "Config pass #$config_pass"
  while read -r line
  do
    # Skip comments
    [[ $line == \#* ]] && continue
    # Skip lines that don't include an assignment =
    [[ $line =~ = ]] || continue
    # Fetch the key, whitespace trimmed
    key="$(echo "$line" | cut -d'=' -f1 | xargs)"
    # Fetch the value, whitespace trimmed
    value="$(echo "$line" | cut -d'=' -f2- | xargs)"
    # Current value (if set)
    current="${!key}"

    if [[ -z "$current" ]] || [[ $config_pass -gt 0 ]]
    then

      # Skip any variables set in the environment
      [[ $(contains "${env_parameters[@]}" "$key") == "y" ]] \
        && _build "[ENV] $key=${!key}" \
        && continue

      # This key is not set yet

      # The below darkmagick is required to build with default bash on OSX
      if [[ $bash_version -lt 4 ]]
      then
        # Urgh, eval is evil
        eval "${line}"
      else
        declare -g "$key=$value"
      fi

      # Print the details to notice
      if [[ $value != "${current}" ]]
      then
        _notice " ++ $key=$value"
      else
        _notice " -- $key=$value"
      fi
    else
      # This var is set in the environment and has priority
      _notice "[ENV] $key=${!key}"
      env_parameters+=($key)
    fi
  done < "${file}"
  let config_pass+=1
  export config_pass
  printf "\n"
}

# Reads key-value file as functionargument, extracts and wraps key with ${..} for use in envsubst
function get_var_array() {
  set -eu
  local file
  file="$1"
  declare -a var_array
  var_array=( $(grep '=' "${file}" | awk -F '=' '{if ($0!="" && $0 !~ /#/) print $1}' | sed -e "s/^/\"\${/" | sed -e "s/$/}\" \\\/" | tr -s '}') )
  echo "${var_array[@]}"
}



OPTIONS=':c:e:lprv'
while getopts $OPTIONS option
do
    case $option in
        c  )    CONFIG_FILE=$OPTARG;;
        e  )    BUILD_ENVIRONMENT=$OPTARG;;
        l  )    BUILD_LOCALLY='true';;
        p  )    PULL_IMAGES='true';;
        r  )    BUILD_REMOTELY='true';;
        v  )    VERBOSITY='debug'
                set -x;;
        *  )    >&2 echo "Unknown parameter"
                usage
                exit 1;;
    esac
done
shift $((OPTIND - 1))



_verbose "Building in $BUILD_DIR"

# [[ $(shellcheck -x "$(ack --ignore-dir=vendor --shell -l "" "${BUILD_DIR}")") -ne 0 ]] && exit $?

# Setup environment variables
. "${BUILD_DIR}/bin/env.sh"

if [[ -z "${GITHUB_OAUTH_TOKEN}" ]] && [[ -z "${CI:-}" ]]
then
  _build "GITHUB_OAUTH_TOKEN not found in environment. Please enter token now:"
  read GITHUB_OAUTH_TOKEN
fi

if [[ -z "${GITHUB_OAUTH_TOKEN}" ]]
then
  >&2 echo "ERROR: GITHUB_OAUTH_TOKEN environment variable not set"
  exit 1
fi

_build "Building environment: ${BUILD_ENVIRONMENT}"

[[ -d "${BUILD_DIR}/app/${GOOGLE_PROJECT_ID}/${BUILD_ENVIRONMENT}" ]] || _fatal "Directory not found: ./app/${GOOGLE_PROJECT_ID}/${BUILD_ENVIRONMENT}"

if [[ "$1" = "test" ]]
then
  BUILD_LOCALLY=true
fi

# Get all the project subdirectories
shopt -s nullglob

cd "${BUILD_DIR}/app/${GOOGLE_PROJECT_ID}/${BUILD_ENVIRONMENT}"
SOURCE_DIRECTORY=(*/)
cd "${BUILD_DIR}"
shopt -u nullglob

for IMAGE in "${SOURCE_DIRECTORY[@]}"
do

  IMAGE=${IMAGE%/}
  current_dir="${BUILD_DIR}/app/${GOOGLE_PROJECT_ID}/${BUILD_ENVIRONMENT}/${IMAGE}"

  [[ ! -f "$current_dir/config" ]] && _notice "No config in $current_dir, skipping..." && continue

  # Default templates
  dockerfile_template="${BUILD_DIR}/app/_templates/Dockerfile.in"
  readme_template="${BUILD_DIR}/app/_templates/README.md.in"

  _build "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BRANCH_NAME//[^[:alnum:]_]/-}"

  # Use any custom templates for this project/image
  if [ -d "${current_dir}/_templates" ]
  then
    if [ -f "${current_dir}/_templates/Dockerfile.in" ]
    then
      dockerfile_template="${current_dir}/_templates/Dockerfile.in"
    fi

    if [ -f "${current_dir}/_templates/README.md.in" ]
    then
      readme_template="${current_dir}/_templates/README.md.in"
    fi
  fi

  _build " - Dockerfile.in:  .${dockerfile_template//${BUILD_DIR}}"
  _build " - README.md.in:   .${readme_template//${BUILD_DIR}}"

  # Merge any project-specific configuration variables
  if [[ -f "${current_dir}/config" ]]
  then
    _build " - Config:         .${current_dir//${BUILD_DIR}}/config"
    set_vars "${current_dir}/config"
  fi

  # Rewrite only the cloudbuild variables we want to change
  envvars_array=($(get_var_array config.default))
  envvars="$(printf "%s:" "${envvars_array[@]}")"
  envvars="${envvars%:}"

  envsubst "${envvars}" < "${dockerfile_template}" > "${current_dir}/Dockerfile"
  envsubst "${envvars}" < "${readme_template}" > "${current_dir}/README.md"

  docker_build_string="# ${APP_NAME}
# Branch: ${BRANCH_NAME}
# Commit: ${CIRCLE_SHA1:-$(git rev-parse HEAD)}
# Build:  ${CIRCLE_BUILD_URL:-"(local)"}
# Date:   ${BUILD_DATE}
# ------------------------------------------------------------------------
#                     DO NOT MAKE CHANGES HERE
# This file is built automatically from ./templates/Dockerfile.in
# ------------------------------------------------------------------------
"

  current_dockerfile=$(cat "${current_dir}/Dockerfile")
  echo -e "${docker_build_string}\n${current_dockerfile}" > "${current_dir}/Dockerfile"
  current_readme=$(cat "${current_dir}/README.md")
  echo -e "${current_readme}\nBuild: ${CIRCLE_BUILD_URL:-"(local)"}" > "${current_dir}/README.md"

done

# Process array of cloudbuild substitutions
function getSubstitutions() {
  local -a arg=($@)
  s="$(printf "%s," "${arg[@]}" )"
  echo "${s%,}"
}

# Cloudbuild.yaml template substitutions
cloudbuild_substitutions_array=(
  "_BUILD_ENVIRONMENT=${BUILD_ENVIRONMENT}" \
  "_BUILD_NAMESPACE=${BUILD_NAMESPACE}" \
  "_BUILD_NUM=${BUILD_NUM}" \
  "_BRANCH_NAME=${BRANCH_NAME//[^[:alnum:]_]/-}" \
  "_BRANCH_TAG=${BRANCH_TAG}" \
  "_COMPOSER=${COMPOSER}" \
  "_GIT_REF=${GIT_REF}" \
  "_GITHUB_OAUTH_TOKEN=${GITHUB_OAUTH_TOKEN}" \
  "_SHORT_SHA=${SHORT_SHA:-$(git rev-parse --short HEAD)}" \
)
cloudbuild_substitutions=$(getSubstitutions "${cloudbuild_substitutions_array[@]}")

# Check if we're running on CircleCI
if [[ ! -z "${CIRCLECI:-}" ]]
then
  # Expect gcloud to be configured under the home directory
  GCLOUD="${HOME}/google-cloud-sdk/bin/gcloud"
else
  # Hope for the best
  GCLOUD=$(type -P gcloud)
fi
[[ -x "$GCLOUD" ]] || _fatal "gcloud binary not found in PATH"

# Submit the build
# @todo Implement local build
# $ circleci build . -e GCLOUD_SERVICE_KEY=$(base64 ~/.config/gcloud/Planet-4-circleci.json)
if [[ "${BUILD_LOCALLY:-}" = 'true' ]]
then
  if [[ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]]
  then
    _fatal "GOOGLE_APPLICATION_CREDENTIALS environment variable not set.

Please set GOOGLE_APPLICATION_CREDENTIALS to the path of your GCP service key and try again.
"
  fi

  if [[ $(type -P "circleci") ]]
  then
    _build "Building locally ..."
    circleci build . -e "GCLOUD_SERVICE_KEY=$(base64 "${GOOGLE_APPLICATION_CREDENTIALS}")"
  else
    _fatal "circlecli not found in PATH. Please install from https://circleci.com/docs/2.0/local-jobs/"
  fi
fi

if [[ "${BUILD_REMOTELY:-}" = 'true' ]]
then
  _build "Sending build request to GCR ..."
  # Avoid sending entire .git history as build context to save some time and bandwidth
  # Since git builtin substitutions aren't available unless triggered
  # https://cloud.google.com/container-builder/docs/concepts/build-requests#substitutions
  tar --exclude='.git/' --exclude='.circleci/' --exclude='vendor/' -zcf "${TMPDIR}/docker-source.tar.gz" .

  time "${GCLOUD}" container builds submit \
    --verbosity=${VERBOSITY:-"warning"} \
    --timeout=10m \
    --config "app/${GOOGLE_PROJECT_ID}/${BUILD_ENVIRONMENT}/cloudbuild.yaml" \
    --substitutions "${cloudbuild_substitutions}" \
    "${TMPDIR}/docker-source.tar.gz"
fi

if [[ -z "${BUILD_REMOTELY:-}" ]] && [[ -z "${BUILD_LOCALLY:-}" ]]
then
  _notice "No build option specified"
fi

if [[ "${PULL_IMAGES:-}" = "true" ]]
then
  _pull "Pulling images ..."
  for IMAGE in "${SOURCE_DIRECTORY[@]}"
  do
    IMAGE="${IMAGE%/}"
    _pull " - ${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BRANCH_NAME//[^[:alnum:]_]/-}"
    docker pull "${BUILD_NAMESPACE}/${GOOGLE_PROJECT_ID}/${IMAGE}:${BRANCH_NAME//[^[:alnum:]_]/-}" >/dev/null &
  done
fi

wait # until image pulls are complete
exit 0
