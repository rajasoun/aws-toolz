#!/usr/bin/env bash

# Replace a line of text that matches the given regular expression in a file with the given replacement.
# Only works for single-line replacements.
function file_replace_text {
  local -r original_text_regex="$1"
  local -r replacement_text="$2"
  local -r file="$3"

  local args=()
  args+=("-i")

  args+=("s|$original_text_regex|$replacement_text|")
  args+=("$file")

  sed "${args[@]}" >/dev/null
}

if [ ! -f .devcontainer/dotfiles/.gitconfig ];then
    cp .devcontainer/dotfiles/.gitconfig.sample .devcontainer/dotfiles/.gitconfig
    if [[ "$USER" == "vscode" ]]; then
        echo -e "Generating .gitconfig\n"
        printf "User Name : "
        read -r "USER_NAME"
        file_replace_text "___YOUR_NAME___"  "$USER_NAME"  ".devcontainer/dotfiles/.gitconfig"
        printf "Email : "
        read -r "EMAIL"
        file_replace_text "___YOUR_EMAIL___" "$EMAIL" ".devcontainer/dotfiles/.gitconfig" 
    fi
fi



