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

export M_MODEL_SETS="current@model_sets/current,de fault,top|old@model_sets/old,co re,domain,elements,concepts"


echo "$M_MODEL_SETS"

OLDIFS=$IFS

IFS='| '
#set -x

bin/.bash-count-args.sh ${M_MODEL_SETS[@]}
#read -r -a array <<< "${M_MODEL_SETS}"
#
#for x in "${array[@]}"; do
#  IFS=','
#  read -r -a parts <<< "${x}"
#  bin/.bash-count-args.sh ${parts[*]}
#done

read -r -a parts  <<< "a|b|   c|c"
for x in "${parts[*]}"
do
  echo $x
  done
