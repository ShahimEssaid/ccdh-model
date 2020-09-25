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
[ -f "bin/.config" ] && . bin/.config

[ "$M_SETX" = "true" ] && set -x

echo "======== running local-to-excel ================="
OLDIFS=$IFS

IFS="|"
read -ra MODELSETS <<<"${M_MODEL_SETS}"
for MODELSET in "${MODELSETS[@]}"; do
  # handling a model set config
  IFS="@"
  read -ra MSPARTS <<<"${MODELSET}"
  IFS=","
  read -ra PARTS <<<"${MSPARTS[1]}"
  MSDIR="${PARTS[0]}"
  # we need to consider alternative write directory in configuration
  if [ ! -z "${M_MODEL_SETS_WRITE_PATH}" ]; then
    MSDIR="${M_MODEL_SETS_WRITE_PATH}/${MSDIR##*/}"
  fi

  MDIRS=("${PARTS[@]:1}")
  for MDIR in "${MDIRS[@]}"; do
    FILEPATH="${MSDIR}/${MDIR}.xlsx"
    echo "converting file: ${FILEPATH}"
    java -jar "${DIR}/converter.jar" --file "${FILEPATH}" --direction excel
  done
done
echo "======== finished local-to-excel ================="
