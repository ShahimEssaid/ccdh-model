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
cd $GIT_ROOT

for m in $(find model_sets/src -maxdepth 1 -mindepth 1 -type d -printf '%f\n'); do
  java -jar "${DIR}/converter.jar" --file "model_sets/src/${m}.xlsx" --direction excel
done
