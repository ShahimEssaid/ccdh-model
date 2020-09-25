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

echo "======== running local-prettify-html.sh ================="
for html_file_path in $(find jekyll/_site -name '*.html' | sort); do
  echo "${html_file_path} ..."
  bin/local-prettify-html-file.sh "${html_file_path}"
done
echo "======== finished local-prettify-html.sh ================="
