#!/usr/bin/env bash
#set -x
set -e
set -u
set -o pipefail
set -o noclobber

# See http://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
GIT_ROOT="$(dirname "$DIR")"
cd "${GIT_ROOT}"
[  -f "bin/.config" ] &&  . bin/.config

# find git branch for the original commit
export GIT_BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-${TRAVIS_BRANCH}}
export GIT_REPO="/ShahimEssaid/ccdh-model.git"
export BASE_URL="ccdh-model/${GIT_BRANCH}"

bin/travis-pre-build.sh
bin/local-install_dependencies.sh
bin/local-to-csv.sh
bin/local-build-jekyll.sh
bin/local-prettify-html.sh
bin/local-to-excel.sh
bin/travis-publish-pages.sh
bin/travis-push-build.sh
