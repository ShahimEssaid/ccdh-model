#!/usr/bin/env bash
set -x
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

cd ${GIT_ROOT}

git status
git branch
cat .git/config
git log -5

echo ================================  ADDING BUILD RESULT  ===========================================
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git add -A &>/dev/null
echo ================================  COMMITTING BUILD RESULT  ===========================================
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git commit -m "#TravisBuild of $GIT_BRANCH"
echo ================================  PUSHING BUILD RESULT  ===========================================
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git push --set-upstream "https://${TOKEN}@github.com${GIT_REPO}" HEAD:$GIT_BRANCH
echo ================= FINISHED COMMIT AND PUSH OF BUILD =========================

#env
