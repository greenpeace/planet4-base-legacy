#!/usr/bin/env bash
# shellcheck disable=SC2034
set -aeo pipefail

set +u

# CONFIG FILE
# Read parameters from key->value configuration files
# Note this will override environment variables at this stage
# @todo prioritise ENV over config file ?

config_pass=${config_pass:-0}

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


TMPDIR=$(mktemp -d "${TMPDIR:-/tmp/}$(basename 0).XXXXXXXXXXXX")

# Pretty printing
. "${current_dir}/pretty_print.sh"

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

bash_version=$(bash --version | head -n 1| cut -d' ' -f4 | cut -d '.' -f 1)

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

# Envsubst and cloudbuild.yaml variable consolidation
BRANCH_NAME="${CIRCLE_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
BRANCH_TAG="${CIRCLE_TAG:-$(git tag -l --points-at HEAD)}"
BRANCH_TAG="${BRANCH_TAG:-"untagged"}"
BUCKET_NAME="${BRANCH_TAG:-${BRANCH_NAME}}"
BUILD_NUM="${BUILD_NUM:-${CIRCLE_BUILD_NUM:-"local"}}"
BUILD_DATE="$(date)"

DEFAULT_CONFIG_FILE="${current_dir}/../config.default"

if [[ ! -f "${DEFAULT_CONFIG_FILE}" ]]
then
  >&2 echo "Default configuration file not found: ${DEFAULT_CONFIG_FILE}"
fi
set_vars "$DEFAULT_CONFIG_FILE"

# Read from custom config file from command line parameter
if [[ "${CONFIG_FILE}" ]]
then

  if [[ ! -f "${CONFIG_FILE}" ]]
  then
    >&2 echo "Custom config file not found: ${CONFIG_FILE}"
  fi

  echo "Reading config from: ${CONFIG_FILE}"

  set_vars "${CONFIG_FILE}"
fi

[[ -z "${WP_STATELESS_MEDIA_ROOT_DIR}" ]] && WP_STATELESS_MEDIA_ROOT_DIR="${BUCKET_NAME:-}"

# Clean variables before set -a automatically exports them
unset current_dir
unset dir
unset source
