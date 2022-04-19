#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
SCRIPT_PATH="$SCRIPT_DIR/automator/src/lib/os.sh"
# shellcheck source=/dev/null
source "$SCRIPT_PATH"

# VERSION=$(git describe --tags --abbrev=0 | sed -Ee 's/^v|-.*//')
export name="rajasoun/$(basename ${PWD})"
LIST_TAGS=$(git tag -l)
# shellcheck disable=SC2015
# shellcheck disable=SC2155
# shellcheck disable=SC2005
export VERSION=$([ "${LIST_TAGS}" ] && echo "$(git describe --tags --abbrev=0 )" || ( echo "1.0.0";))


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

# Check if first release is made by
# if .devcontainer/version.txt exists
function check_and_make_first_release_if_not_done(){
    if [ ! -f "$(git rev-parse --show-toplevel)/.devcontainer/version.txt" ]; then
        echo "Building Base Version ->  $name:$VERSION"
        if [ ! "$(command -v "devcontainer" >/dev/null 2>&1)"  ];then
            echo "Install devcontainer cli"
            npm install -g "@vscode/dev-container-cli"
        fi
        make -f .devcontainer/Makefile build
        # Check wiImage with Tag Already Exists if not push it
        if [ ! "$(docker manifest inspect "$name:$VERSION" > /dev/null)" ];then
            make -f .devcontainer/Makefile push
        fi
        echo "$VERSION" >.devcontainer/version.txt
        git add .devcontainer/version.txt
        git commit -m "ci(devcontainer): new version - $VERSION"
        git push --no-verify
        git fetch --prune --tags
        git tag -a "$VERSION" -m "Dev Container new Build $VERSION"
	    git push origin "$VERSION" --no-verify
    fi
}

function launch(){
    GIT_REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
    echo "Launching ci-shell for $name:$VERSION"
    # shellcheck disable=SC2140
    _docker run --rm -it \
            --name "ci-shell-$GIT_REPO_NAME" \
            --sig-proxy=false \
            -a STDOUT -a STDERR \
            --entrypoint=/bin/zsh \
            --user vscode  \
            --mount type=bind,source="${PWD}/.devcontainer/dotfiles/.gitconfig",target="/home/vscode/.gitconfig",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.ssh",target="/home/vscode/.ssh",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.gpg2",target="/home/vscode/.gnupg",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.store",target="/home/vscode/.password-store",consistency=cached \
            --mount type=bind,source="${PWD}/.devcontainer/.aws",target="/home/vscode/.aws",consistency=cached \
            --mount type=bind,source="${PWD}",target="/workspaces/$GIT_REPO_NAME",consistency=cached \
            --mount source=/var/run/docker.sock,target=/var/run/docker-host.sock,type=bind \
            --mount type=volume,src=vscode,dst=/vscode -l vsch.local.folder="${PWD}" \
            -l vsch.quality=stable -l vsch.remote.devPort=0 \
            -w "/workspaces/$GIT_REPO_NAME" \
            "$name:$VERSION"
}

echo -e "\n${BOLD}${UNDERLINE}SSH & Git Configurations${NC}"
_configure_ssh_gitconfig
make -f .devcontainer/Makefile prerequisite

check_and_make_first_release_if_not_done
#launch
