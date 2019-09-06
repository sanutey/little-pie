#!/usr/bin/env bash

###########################################################################
# Usage: git_batch_clone.sh [clone-to-directory]
# if you ignore clone-to-directory, use the dir that runs the script
#
# should install jq first, for mac:brew install jq, for ubuntu:sudo apt-get install jq
#
# Documentation
# https://docs.gitlab.com/ce/api/projects.html#list-projects
# 
# base on https://gist.github.com/medusar/d0618bbea17e9d8e2b4cb1d6dd9f01e1
############################################################################

PRGDIR="$(cd ${1:-`dirname $0`}; pwd -P)"
echo "Will Clone To The Path: $PRGDIR"
# 1:debug 0:no-debug
DEBUG=0
BASE_PATH="https://gitlab-server"
PROJECT_SEARCH_PARAM=""
PROJECT_PROJECTION="{ "path": .path, "git": .http_url_to_repo }"
GITLAB_PRIVATE_TOKEN="your-gitlab-token"
FILENAME="repos.json"
ALL_PROJECTS_BASE_URL="${BASE_PATH}/api/v4/projects?private_token=$GITLAB_PRIVATE_TOKEN&simple=true&membership=true&search=$PROJECT_SEARCH_PARAM&per_page=100"
echo "all projects base url: $ALL_PROJECTS_BASE_URL"

trap "{ rm -f $PRGDIR/$FILENAME; }" EXIT

TOTAL_PAGES=$(curl --head -s "$ALL_PROJECTS_BASE_URL" | grep -e 'X-Total-Pages' -i | cut -d' ' -f2 | tr -d '\r')
echo "total pages: $TOTAL_PAGES"

i=1
while [[ $i -le $TOTAL_PAGES ]]; do
    echo ""
    echo "fetching page: $i"
    echo "$ALL_PROJECTS_BASE_URL&page=$i"
    curl -s  "$ALL_PROJECTS_BASE_URL&page=$i" \
        | jq --raw-output --compact-output ".[] | $PROJECT_PROJECTION" > "$PRGDIR/$FILENAME"
        
    while read repo; do
       echo ""
       THEPATH=$(echo "$repo" | jq -r ".path")
       GIT=$(echo "$repo" | jq -r ".git")
       GROUP_PATH=$(echo ${GIT} | awk -v prefix="$PRGDIR" -F '/' '{i=4;path="";while(i < NF) {path=path"/"$i;i++};print prefix""path}')

        if [ ! -d "$GROUP_PATH" ]; then
	       echo "Making Group Path ($GROUP_PATH)"
	       [ $DEBUG -eq 0 ] && mkdir -p "${GROUP_PATH}"
        fi
        echo "Changing Working Dir To $GROUP_PATH"
        [ $DEBUG -eq 0 ] && cd "$GROUP_PATH"
        
        if [ ! -d "$THEPATH" ]; then
            echo "Cloning $THEPATH ( $GIT )"
            #[ $DEBUG -eq 0 ] && git clone "$GIT" --quiet &
            [ $DEBUG -eq 0 ] && git clone "$GIT" --quiet
        else
	    echo "Pulling $THEPATH ( $GIT )"
            #[ $DEBUG -eq 0 ] && (cd "$THEPATH" && git pull --quiet) &
            [ $DEBUG -eq 0 ] && (cd "$THEPATH" && git pull --quiet) 
        fi
    done < "$PRGDIR/$FILENAME"
    i=$(($i+1))
done

wait
