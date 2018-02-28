#!/usr/bin/env bash
set -e

# ----------------------------------------------------------------------------

# Find real file path of current script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within

source="${BASH_SOURCE[0]}"
while [[ -h "$source" ]]
do # resolve $source until the file is no longer a symlink
  dir="$( cd -P "$( dirname "$source" )" && pwd )"
  source="$(readlink "$source")"
  [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
git_root_dir="$( cd -P "$( dirname "$source" )/.." && pwd )"

set -x

# Remove generated composer lock files
[[ -f "${git_root_dir}/composer.lock" ]] && rm "${git_root_dir}/composer.lock"

# Remove vendor directory
rm -fr "${git_root_dir}/vendor"

# Remove generated Dockerfiles
find "${git_root_dir}/app" -name "Dockerfile" -exec rm -r "{}" \;
# find "${git_root_dir}/app" -name "README.md" -exec rm -r "{}" \;

set +x
