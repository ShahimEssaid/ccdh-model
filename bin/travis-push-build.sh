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

[ "$M_SETX" = "true" ] && set -x

echo "======== running travis-push-build.sh ================="
git status
git branch
cat .git/config
git log -2

GIT_CURL_VERBOSE=1 GIT_TRACE=1 git add -A &>/dev/null

GIT_CURL_VERBOSE=1 GIT_TRACE=1 git commit -m "#TravisBuild of $GIT_BRANCH"

GIT_CURL_VERBOSE=1 GIT_TRACE=1 git push --set-upstream "https://${TOKEN}@github.com${GIT_REPO}" HEAD:$GIT_BRANCH

echo "======== finished travis-push-build.sh ================="