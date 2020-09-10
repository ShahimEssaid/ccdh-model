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

cd $DIR

cd ${DIR}/model_sets
for m in $(find  src -maxdepth 1 -mindepth 1 -type f -iname '*.xlsx')
do
  java -jar "${DIR}/bin/converter.jar" --file "../model_sets/${m}" --direction csv
done

${DIR}/run.sh


for m in $(find  src -maxdepth 1 -mindepth 1 -type f -iname '*.xlsx')
do
  java -jar "${DIR}/bin/converter.jar" --file "../model_sets/${m}" --direction excel
done


