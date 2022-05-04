#!/usr/bin/env bash

NC=$'\e[0m' # No Color
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

# Displays Time in misn and seconds
function _display_time {
  local T=$1
  local D=$((T / 60 / 60 / 24))
  local H=$((T / 60 / 60 % 24))
  local M=$((T / 60 % 60))
  local S=$((T % 60))
  ((D > 0)) && printf '%d days ' $D
  ((H > 0)) && printf '%d hours ' $H
  ((M > 0)) && printf '%d minutes ' $M
  ((D > 0 || H > 0 || M > 0)) && printf 'and '
  printf '%d seconds\n' $S
}

# Displays Time in misn and seconds
function log(){
  EXIT_CODE="$1"
  MESSAGE="$2"
  if [[ -n "$EXIT_CODE" && "$EXIT_CODE" -eq 0 ]]; then
    echo "${GREEN}$MESSAGE | Success ✅${NC}"
  else
    echo "${RED}$MESSAGE | Failed ❌${NC}"
  fi
}

function clean_running_container(){
    echo "${ORANGE}Cleaning up Running Containers${NC}"
    running_dockers=$(docker ps -q)
    if [ -n "$running_dockers" ];then
        docker kill "$(docker ps -q)" &>/dev/null
        docker rm "$(docker ps -a -q)" &>/dev/null
    fi
}

function clean_docker_images(){
    echo "${ORANGE}Cleaning up Docker Images${NC}"
    docker_images=$(docker ps -q)
    if [ -n "$docker_images" ];then
        docker rmi "$(docker images -q)" &>/dev/null
    fi
}

function system_clean(){
    echo "${ORANGE}System Clean${NC}"
    docker system prune --all --volumes --force &>/dev/null
}

function docker_image_pull_time(){
    DOCKER_IMAGE=$1
    echo "${BLUE}Pulling Container - $DOCKER_IMAGE ${NC}"
    start=$(date +%s)
    docker pull "$DOCKER_IMAGE" > /dev/null
    EXIT_CODE="$?"
    end=$(date +%s)
    runtime=$((end-start))
    MESSAGE="docker pull $DOCKER_IMAGE | $USER_NAME | Duration: $(_display_time $runtime) "
    log "$EXIT_CODE" "$MESSAGE"
}

function speed_test(){
    MSYS_NO_PATHCONV=1  docker run --rm rajasoun/speedtest:0.1.0 "/go/bin/speedtest-go"
}

if [ -z $USERNAME ];then
  USER_NAME=$USER
else
  USER_NAME=$USERNAME
fi

_start=$(date +%s)
clean_running_container
clean_docker_images
system_clean
docker_image_pull_time "rajasoun/speedtest:0.1.0"
speed_test
docker_image_pull_time "rajasoun/aws-toolz:1.0.1"
EXIT_CODE="$?"
_end=$(date +%s)
_runtime=$((_end-_start))

MESSAGE="\n${UNDERLINE}Total Time | $USER_NAME | Duration: $(_display_time $_runtime) ${NC}"
log "$EXIT_CODE" "$MESSAGE"
printf "\n"
echo "DevContainer For $USER_NAME   Done | $(date)"
printf "\n"
