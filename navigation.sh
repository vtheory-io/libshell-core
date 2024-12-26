#!/usr/bin/env bash
# navigation.sh

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

lib.nav.history() {
  dirs -p | nl -v 0
}

lib.nav.mkd() { ## mkdir and go to it or go to it if already existing
  [ -d "$1" ] || mkdir -p "$1"
  cd $@
}

lib.nav.register_pre_cd() {
  echo "${LIB_NAV_PRE_CD}" | grep " ${1} " > /dev/null || \
  export LIB_NAV_PRE_CD="${LIB_NAV_PRE_CD} ${1} "
}

lib.nav.register_post_cd() {
  echo "${LIB_NAV_POST_CD}" | grep " ${1} " > /dev/null || \
  export LIB_NAV_POST_CD="${LIB_NAV_POST_CD} ${1} "
}

lib.nav.record_wd() {
  pushd . > /dev/null;
}
lib.nav.register_pre_cd lib.nav.record_wd

cd() {
  if [ ! -z ${LIB_USE_BUILTIN_CD} ]; then
    builtin cd "$@";
  else
    for precommand in ${LIB_NAV_PRE_CD}; do
      $precommand $@
    done;
    builtin cd "$@";
    for postcommand in ${LIB_NAV_POST_CD}; do
      $postcommand $@
    done;
  fi
} 

lib.nav.back() { ## go back in navigation history n times (n defaults to 1)
  local steps
  if [ -z "$1" ]; then
    steps=1
  else
    steps="$1"
  fi
  
  history_depth=$(lib.nav.history | wc -l)
  if ! ([ "$steps" -ge "0" ] && [ "$steps" -lt "$history_depth" ]) 2> /dev/null; then
    err "FATAL: index ($steps) out of bounds, must be blank or an integer between 0 and $((history_depth-1))"
    return 1
  fi

  local entry 
  local target_path
  entry=$(lib.nav.history | grep "^\s*$steps\s")
  target_path=$(echo $entry | ( read num dir; echo $dir ) | sed "s#^~#$HOME#")
  if [ ! -d "$target_path" ]; then
    err "FATAL: path does not exist: $target_path";
    return 1;
  fi
  
  for ((n=1;n<$steps;n++)); do
    popd -n > /dev/null
  done

  if [ $steps -gt 0 ]; then
    popd > /dev/null
  fi
  builtin cd $target_path
}

lib.nav.revisit() {
  available_paths=$(dirs -p | grep "$1" | lib.util.dedupe | sed "s#^~#$HOME#")
  available_paths_count=$(printf "$available_paths" | grep -v "^$" | wc -l)

  if [ $available_paths_count -eq 1 ]; then
    cd $available_paths
    return $?
  elif [ $available_paths_count -eq 0 ]; then
    err "FATAL: no available paths found"
    return 1
  fi

  select target_path in $available_paths
  do
    if [ ! -z "$target_path" ]; then
      cd $target_path
      return $?
    fi
  done
}
