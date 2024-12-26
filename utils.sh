#!/usr/bin/env bash
# utils.sh

export CURRENT_SHELL=$(ps -o cmd= $$)

err() {
  echo "$(date +'%Y-%m-%dT%H:%M:%S%z')[${FUNCNAME[*]}${funcstack[*]}]: $*" >&2
}

lib.util.dedupe_lines() { ## remove duplicate lines, preserves order
  local SEPARATOR="DUPE_SEPARATOR"
  local values="${SEPARATOR}"
  while read data; do
    echo "$values" | grep "$SEPARATOR$data$SEPARATOR" > /dev/null || echo "$data";
    values="$values$data$SEPARATOR";
  done;
}

lib.util.dedupe_words() { ## remove duplicate words, preserves order
  local SEPARATOR="DUPE_SEPARATOR"
  local values="${SEPARATOR}"
  for data in $@; do
    echo "$values" | grep "$SEPARATOR$data$SEPARATOR" > /dev/null || printf "$data ";
    values="$values$data$SEPARATOR";
  done;
}

lib.reload() {
  source "${SHELL_LIB_DIR}/.load"
}
