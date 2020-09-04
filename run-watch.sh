#!/usr/bin/env bash
#set -x
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

cd $DIR

bundle exec jekyll b --trace -s jekyll --config jekyll/_config.yml --watch

for html_file_path in $(find ./_site -name '*.html' | sort); do
    echo -n "${html_file_path} ..."
    bin/prettify_html.js "${html_file_path}"
    echo " Done"
done