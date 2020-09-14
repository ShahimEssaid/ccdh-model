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

[  -f ".env" ] &&  . .env

BASE_URL="${BASE_URL:-}"

bundle exec jekyll b --trace --baseurl "${BASE_URL}" -s jekyll -d jekyll/_site --config jekyll/_config.yml

echo ===================== RUNNING PRETTIFY ========================
for html_file_path in $(find jekyll/_site -name '*.html' | sort); do
  echo -n "${html_file_path} ..."
  bin/prettify_html.js "${html_file_path}"
  echo " Done"
done

echo ================= FINISHED BUILDING =========================
