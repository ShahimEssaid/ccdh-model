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

OLDIFS=$IFS

IFS="|"
read -ra MODELSETS <<< "${M_MODEL_SETS}"
for MODELSET in  "${MODELSETS[@]}"; do
  IFS="@"
  read -ra MSPARTS <<< "${MODELSET}"
  IFS=","
  read -ra PARTS <<< "${MSPARTS[1]}"
  MSDIR="${PARTS[0]}"
  MDIRS=("${PARTS[@]:1}")
  for MDIR in "${MDIRS[@]}"; do
      FILEPATH="${MSDIR}/${MDIR}.xlsx"
      java -jar "${DIR}/converter.jar" --file "${FILEPATH}" --direction csv
  done
done


#${DIR}/run.sh

#for m in $(find  src -maxdepth 1 -mindepth 1 -type f -iname '*.xlsx')
#do
#  java -jar "${DIR}/bin/converter.jar" --file "../model_sets/${m}" --direction excel
#done
