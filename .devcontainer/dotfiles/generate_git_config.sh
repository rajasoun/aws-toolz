#!/usr/bin/env bash

# Returns true (0) if this is an OS X server or false (1) otherwise.
function _is_os_darwin {
  [[ $(uname -s) == "Darwin" ]]
}

# Replace a line of text that matches the given regular expression in a file with the given replacement.
# Only works for single-line replacements.
function file_replace_text {
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

if [ ! -f .devcontainer/dotfiles/.gitconfig ];then
  cp .devcontainer/dotfiles/.gitconfig.sample .devcontainer/dotfiles/.gitconfig
  echo -e "Generating .gitconfig\n"
  printf "User Name : "
  read -r "USER_NAME"
  file_replace_text "___YOUR_NAME___"  "$USER_NAME"  ".devcontainer/dotfiles/.gitconfig"
  printf "Email : "
  read -r "EMAIL"
  file_replace_text "___YOUR_EMAIL___" "$EMAIL" ".devcontainer/dotfiles/.gitconfig" 
fi



