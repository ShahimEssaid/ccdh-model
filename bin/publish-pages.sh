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

BRANCHES=($(git for-each-ref --format="%(refname)"))

cd ${GIT_ROOT}/../stage-gh-pages

# clean directories for non existing branches
IFSO="$IFS"
IFS=$'\n'
for i in $(ls -d */); do
  echo checking directory $i
  if [[ "${BRANCHES[@]}" != *"/${i%%/} "* ]]; then
    echo deleting directory ${i%%/}
    rm -rf ${i%%/}
  fi
done

# copy over build
cp -ra ${GIT_ROOT}/jekyll/_site "$GIT_BRANCH"
cp ${GIT_ROOT}/jekyll/.travis.yml .
rm README.md
echo "# Built branches" >README.md
for i in $(ls -d */); do
  echo >>README.md
  echo Branch "["${i%%/}"]("${i}") is [published](https://ShahimEssaid.github.io/ccdh-model/"${i}")" >>README.md
done

echo >>README.md
echo "### This file is overwritten with each build. Manual edits will be lost!" >>README.md

git reset gh-pages-start
git add -A &>/dev/null
git commit -m "#TravisBuild of $GIT_BRANCH"
git push -f --set-upstream "https://${TOKEN}@github.com${GIT_REPO}" gh-pages
echo ================= FINISHED PUBLISHING =========================

#env
