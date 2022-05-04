#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

BASE_DIR="${PWD}/.devcontainer"
BASE_URL="https://raw.githubusercontent.com/rajasoun/aws-toolz/main/all-in-one/.devcontainer"

GIT_CONFIG_DIR="${PWD}/.devcontainer/dotfiles"
GIT_CONFIG_FILE="${GIT_CONFIG_DIR}/.gitconfig"

export name="rajasoun/aws-toolz"
export VERSION=1.0.1

# Returns true (0) if this is an OS X server or false (1) otherwise.
function _is_os_darwin {
  [[ $(uname -s) == "Darwin" ]]
}

# Replace a line of text that matches the given regular expression in a file with the given replacement.
# Only works for single-line replacements.
function _file_replace_text {
  local -r original_text_regex="$1"
  local -r replacement_text="$2"
  local -r file="$3"

  local args=()
  args+=("-i")

  if _is_os_darwin; then
    # OS X requires an extra argument for the -i flag (which we set to empty string) which Linux does no:
    # https://stackoverflow.com/a/2321958/483528
    args+=("")
  fi

  args+=("s|$original_text_regex|$replacement_text|")
  args+=("$file")

  sed "${args[@]}" >/dev/null
}

# Workaround for Path Limitations in Windows
function _docker() {
  export MSYS_NO_PATHCONV=1
  export MSYS2_ARG_CONV_EXCL='*'

  case "$OSTYPE" in
      *msys*|*cygwin*) os="$(uname -o)" ;;
      *) os="$(uname)";;
  esac

  if [[ "$os" == "Msys" ]] || [[ "$os" == "Cygwin" ]]; then
      # shellcheck disable=SC2230
      realdocker="$(which -a docker | grep -v "$(readlink -f "$0")" | head -1)"
      printf "%s\0" "$@" > /tmp/args.txt
      # --tty or -t requires winpty
      if grep -ZE '^--tty|^-[^-].*t|^-t.*' /tmp/args.txt; then
          #exec winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          return 0
      fi
  fi
  docker "$@"
  return 0
}

function check_create_dir(){
    DIR_PATH=$1
    if [ ! -d "$DIR_PATH" ];then
        mkdir -p "$DIR_PATH"
        echo -e "Directory -> $DIR_PATH Created"
    else
        echo -e "${GREEN}Directory -> $DIR_PATH Exists${NC}"
    fi
}

function check_download_file(){
    FILE=$1
    FILE_DIR=$2
    if [ ! -f "$BASE_DIR/$FILE" ];then
        wget -q "$BASE_URL/$FILE" -P "$FILE_DIR"
        echo -e "     File -> $FILE_DIR/$FILE Download Done "
    else
        echo -e "${GREEN}     File -> $FILE_DIR/$FILE Exists ${NC}"
    fi
}

function _git_config() {
  #_backup_remove_git_config
  if [ ! -f $GIT_CONFIG_FILE ];then
    cp .devcontainer/dotfiles/.gitconfig.sample $GIT_CONFIG_FILE
	echo -e "${GREEN}${UNDERLINE}Generating .gitconfig${NC}\n"
    MSG="${ORANGE}  Full Name ${NC}${ORANGE}(without eMail) : ${NC}"
    printf "$MSG"
    read -r "USER_NAME"
    _file_replace_text "___YOUR_NAME___"  "$USER_NAME"  ".devcontainer/dotfiles/.gitconfig"
    MSG="${ORANGE}  EMail ${NC}${ORANGE} : ${NC}"
    printf "$MSG"
    read -r "EMAIL"
    _file_replace_text "___YOUR_EMAIL___" "$EMAIL" ".devcontainer/dotfiles/.gitconfig"
    echo -e "\nGit Config Gneration for $USER_NAME Done !!!"
	else
		echo -e "${ORANGE}\n.devcontainer/dotfiles/.gitconfig Exists${NC}"
	fi

}

function launch(){
    ENTRY_POINT_CMD=$1
    GIT_REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
    echo "Launching ci-shell for $name:$VERSION"
    # shellcheck disable=SC2140
    _docker run --rm -it \
            --name "ci-shell-$GIT_REPO_NAME" \
            --sig-proxy=false \
            -a STDOUT -a STDERR \
            --entrypoint=$ENTRY_POINT_CMD \
            --user vscode  \
            --mount type=bind,source="${PWD}/.devcontainer/dotfiles/.gitconfig",target="/home/vscode/.gitconfig",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.ssh",target="/home/vscode/.ssh",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.gpg2/keys",target="/home/vscode/.gnupg",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.store",target="/home/vscode/.password-store",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.aws",target="/home/vscode/.aws",consistency=cached \
            --mount type=bind,source="${PWD}",target="/workspaces/$GIT_REPO_NAME",consistency=cached \
            --mount source=/var/run/docker.sock,target=/var/run/docker-host.sock,type=bind \
            --mount type=volume,src=vscode,dst=/vscode -l vsch.local.folder="${PWD}" \
            -l vsch.quality=stable -l vsch.remote.devPort=0 \
            -w "/workspaces/$GIT_REPO_NAME" \
            "$name:$VERSION"
}

function check_create_local_git(){
    git init
    git add -A
    git commit -m "feat(shell): aws-toolz initial checkin"
}

function create_workspace(){
    workspace_dir=$1
    if [ ! -d $workspace_dir ];then
        mkdir -p $workspace_dir
        cd $workspace_dir
        echo -e "Workspace -> $workspace_dir Created"
    else
        echo -e "${GREEN}Workspace -> $workspace_dir Exists${NC}"
    fi
}

function prepare_environment(){
    echo -e "${BOLD} Zero Configuration Environment Setup ${NC}"
    create_workspace "$BASE_DIR/aws-toolz-1.0.1"
    check_create_dir "$BASE_DIR/.aws"
    check_create_dir "$BASE_DIR/.gpg2"
    check_create_dir "$BASE_DIR/.gpg2/keys"
    check_create_dir "$BASE_DIR/.ssh"
    check_create_dir "$BASE_DIR/.store"
    check_create_dir "$BASE_DIR/dotfiles"
    check_download_file "dotfiles/.gitconfig.sample" "$BASE_DIR/dotfiles"
    check_download_file "Makefile" "$BASE_DIR"
    check_download_file "devcontainer.json" "$BASE_DIR"
    check_download_file "Dockerfile" "$BASE_DIR"
    _git_config
    check_create_local_git
}

ENV=$1
ENTRY_POINT_CMD=$2

prepare_environment

if [ "$ENV" = "dev" ]; then
    echo "$(date)" > "$(git rev-parse --show-toplevel)/.dev"
    echo -e "\n${BOLD}${UNDERLINE}CI Shell For Dev${NC}"
    rm -fr "$(date)" > "$(git rev-parse --show-toplevel)/.ops"
else
    echo "$(date)" > "$(git rev-parse --show-toplevel)/.ops"
    echo -e "\n${BOLD}${UNDERLINE}CI Shell For Ops${NC}"
    rm -fr "$(date)" > "$(git rev-parse --show-toplevel)/.ops"
fi

if [ -z $ENTRY_POINT_CMD ]; then
    ENTRY_POINT_CMD="/bin/zsh"
fi

launch $ENTRY_POINT_CMD
