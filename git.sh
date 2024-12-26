#!/usr/bin/env bash
# git.sh

lib.require.DEV_PATH() {
    [ -z $DEV_PATH ] && export DEV_PATH=$HOME/dev
}

lib.require.CODE_PATH() {
    lib.require.DEV_PATH
    [ -z $CODE_PATH ] && export CODE_PATH=$DEV_PATH/src
}

lib.git.list_repos() {
  lib.require.CODE_PATH
  find $CODE_PATH -path "*/.git" -type d | \
    sed "s#$CODE_PATH/##" | \
    sed "s#/.git##"
}

lib.git.repo_info() { ## details of a repo; defaults to git info, uses path as backup
  local is_git
  git status > /dev/null 2>&1 && is_git=1 || is_git=0
  git_origin=$(git remote get-url origin 2> /dev/null)
  if [[ "${is_git}" -gt 0 && ! -z "${git_origin}" ]] ; then
    git_local_path=$(git rev-parse --show-toplevel)
    local parts && parts=$(echo $git_origin | sed 's#.git$##g' | sed 's#[@/:]# #g')
    git_domain=$(awk '{print $2}' <<< $parts)
    git_org=$(awk '{print $3}' <<< $parts)
    git_repo=$(awk '{print $4}' <<< $parts)
    local pwd && pwd=$(pwd)
    git_tree=$(echo ${pwd#$git_local_path})
    git_branch=$(git rev-parse --abbrev-ref HEAD)
  else
    lib.git.repo_info_path_based -s
  fi

  if [[ ! $* == *"-s"* ]] ; then
    local output_format && output_format="${YELLOW}%-17s${LT_GREEN}%7s:${DEFAULT_FMT} %s\n"
    printf "$output_format" "(git_origin)" "origin" "$git_origin"
    printf "$output_format" "(git_local_path)" "path" "$git_local_path"
    printf "$output_format" "(git_domain)" "domain" "$git_domain"
    printf "$output_format" "(git_org)" "org" "$git_org"
    printf "$output_format" "(git_repo)" "repo" "$git_repo"
    printf "$output_format" "(git_tree)" "tree" "$git_tree"
    printf "$output_format" "(git_branch)" "branch" "$git_branch"
  fi
}

lib.git.repo_info_path_based() { ## details of a repo based on path
  lib.require.CODE_PATH
  local dir && dir=$(pwd)
  [[ $dir != *"$CODE_PATH/"* ]] && export git_local_path="." && return 1
  local current_path && current_path=$(echo ${dir#$CODE_PATH})
  local count && count=$(echo "${current_path}" | awk -F"/" '{print NF-1}')
  export git_path=""
  [ $count -ge 1 ] && export git_domain=$(echo $current_path | cut -d'/' -f2) && git_path=$git_domain || export git_domain=""
  [ $count -ge 2 ] && export git_org=$(echo $current_path | cut -d'/' -f3) && git_path="$git_path/$git_org" || export git_org=""
  [ $count -ge 3 ] && export git_repo=$(echo $current_path | cut -d'/' -f4) && git_path="$git_path/$git_repo" || export git_repo=""
  export git_tree=$(echo ${dir#$CODE_PATH/$git_domain/$git_org/$git_repo})
  export git_local_path="$CODE_PATH/$git_path"
  [ "$git_tree" != "$dir" ] || export git_tree=""
  [ ! -z $git_repo ] && export git_branch=$(git rev-parse --abbrev-ref HEAD)

  if [[ ! $* == *-s* ]] ; then
    local output_format && output_format="${YELLOW}%-17s${LT_GREEN}%7s:${DEFAULT_FMT} %s\n"
    printf "$output_format" "(git_local_path)" "path" "$git_local_path"
    printf "$output_format" "(git_domain)" "domain" "$git_domain"
    printf "$output_format" "(git_org)" "org" "$git_org"
    printf "$output_format" "(git_repo)" "repo" "$git_repo"
    printf "$output_format" "(git_tree)" "tree" "$git_tree"
    printf "$output_format" "(git_branch)" "branch" "$git_branch"
  fi
}

lib.git.clone() { ## clones a git repo into appropriate directory
lib.require.CODE_PATH
  repo="$1"
  sepcount=$(sed "s/[^:\/@]//g" <<< "$repo" | wc -m)
  if [[ $sepcount -le 2 ]] ; then
    repo_info -s || (err "no repo found" && return 1)
    if [[ $repo != *"/"* ]] ; then
      repo="git@$git_domain:$git_org/$repo.git"
    else
      org=$(cut -d/ -f1 <<< "$repo")
      project=$(cut -d/ -f2 <<< "$repo")
      repo="git@$git_domain:$org/$project.git"
    fi
  fi
  echo $repo
  clone_dir=$(echo $repo | sed "s/.*:\//:\//g" | sed "s/git@/:\/\//g" | sed "s/:\/\///g" | sed "s/:/\//g" | sed "s/\.git//g")
  clone_dir="$CODE_PATH/$clone_dir"
  git clone $repo $clone_dir
  cd $clone_dir
}
