#!/usr/bin/env bash

if [ -d "/workspaces" ];then
	SCRIPT_DIR="/workspaces"
else
	SCRIPT_DIR=".devcontainer"
fi

SCRIPT_PATH="$SCRIPT_DIR/automator/src/lib/os.sh"
# shellcheck source=/dev/null
source "$SCRIPT_PATH"

function generate_git_config(){
	if [ ! -f .devcontainer/dotfiles/.gitconfig ];then
		cp .devcontainer/dotfiles/.gitconfig.sample .devcontainer/dotfiles/.gitconfig
		echo -e "${GREEN}Generating .gitconfig${NC}\n"
		printf "User Name : "
		read -r "USER_NAME"
		_file_replace_text "___YOUR_NAME___"  "$USER_NAME"  ".devcontainer/dotfiles/.gitconfig"
		printf "Email : "
		read -r "EMAIL"
		_file_replace_text "___YOUR_EMAIL___" "$EMAIL" ".devcontainer/dotfiles/.gitconfig"
	else
		echo -e "${YELLOW}\nAborting Generation.\n .devcontainer/dotfiles/.gitconfig Exists${NC}"
	fi
}
generate_git_config
