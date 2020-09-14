#!/usr/bin/env bash
set -x
set -e
set -u
set -o pipefail
set -o noclobber

# See http://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

GIT_ROOT="$(dirname "$DIR")"


# reset origin to default to work around Travis'
git remote remove origin
git remote add origin https://github.com${GIT_REPO}
git fetch --all --tags

# first make sure we clean any previous published pages in case
# this build fails early
git worktree add -b gh-pages ${GIT_ROOT}/../stage-gh-pages origin/gh-pages
rm -rf "${GIT_ROOT}/../stage-gh-pages/$GIT_BRANCH" || true 
cd ${GIT_ROOT}/../stage-gh-pages
git reset gh-pages-start
git add -A &> /dev/null
git commit -m "Preparing build of $GIT_BRANCH" || true
git push -f --set-upstream "https://${TOKEN}@github.com${GIT_REPO}" gh-pages || true


echo ================= FINISHED PRE BUILDING =========================