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

bundle exec rdebug-ide --host 127.0.0.1 --port 1234 -- ${DIR}/../gems/ruby/2.6.0/bin/jekyll b --trace 
