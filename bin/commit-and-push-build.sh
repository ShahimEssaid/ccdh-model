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

git add -A &>/dev/null
git commit -m "Travis build of $GIT_BRANCH"
git push --set-upstream "https://${TOKEN}@github.com${GIT_REPO}" $GIT_BRANCH
echo ================= FINISHED COMMIT AND PUSH OF BUILD =========================

#env
