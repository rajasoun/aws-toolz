#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

GIT_CONFIG_FILE="${PWD}/.devcontainer/dotfiles/.gitconfig"
KEYS_PATH="${PWD}/.devcontainer/.ssh"
PRIVATE_KEY="$KEYS_PATH/id_rsa"
PUBLIC_KEY="${PRIVATE_KEY}.pub"

# Create Directory if the given directory does not exists
# @param $1 The directory to create
function _create_directory_if_not_exists() {
  DIR_NAME=$1
  ## Create Directory If Not Exists
  if [ ! -d "$DIR_NAME" ]; then
    mkdir -p "$DIR_NAME"
  fi
}

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

# Returns true (0) if the given file exists contains the given text and false (1) otherwise. The given text is a
# regular expression.
function _file_contains_text {
  local -r text="$1"
  local -r file="$2"
  grep -q "$text" "$file"
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

# Returns true (0) if this is an OS X server or false (1) otherwise.
function _is_os_darwin {
  [[ $(uname -s) == "Darwin" ]]
}

# Returns true (0) if this the given command/app is installed and on the PATH or false (1) otherwise.
function _is_command_found {
  local -r name="$1"
  command -v "$name" >/dev/null ||
    raise_error "${RED}$name is not installed. Exiting...${NC}"
}

# Wrapper function for echo
function prompt() {
  echo -e "${1}" >&2
}

# Example colour function
function all_colors() {

  debug "${RED}RED${NC}"
  debug "${GREEN}GREEN${NC}"
  debug "${ORANGE}ORANGE${NC}"
  debug "${BLUE}BLUE${NC}"
  debug "${LIGHT_BLUE}LIGHT_BLUE${NC}"
  debug "${BOLD}BOLD${NC}"
  debug "${UNDERLINE}UNDERLINE${NC}"

  prompt "$BOLD $UNDERLINE Colour Formatting Example $NC"
  prompt "$RED R $NC $GREEN A  $NC $BLUE J $NC $RED A. $BLUE $NC S"
}

# ls, with chmod-like permissions and more.
# @param $1 The directory to ls
function lls() {
  #If Not Paramter is Passed assumes current directory
  local LLS_PATH=${1:-"."}
  prompt "${GREEN} ls with chmod-like permissions ${NC}"
  # shellcheck disable=SC2012 # Reason: This is for human consumption
  ls -AHl "$LLS_PATH" | awk "{k=0;for(i=0;i<=8;i++)k+=((substr(\$1,i+2,1)~/[rwx]/) \
                            *2^(8-i));if(k)printf(\"%0o \",k);print}"
}

# Run Pre Commit and Git Add on Changed Files
function run_pre_commit() {
  pre-commit run --config /workspaces/shift-left/.pre-commit-config.yaml --all-files
  #pre-commit run --all-files
}

# echo message when VERBOSE == 1
function debug() {
  message=$1
  if [ "$VERBOSE" = 1 ]; then
    printf "${ORANGE}\n [DEBUG] %s${NC}\n" "${message}"
  fi
}

# set debug option based on option
function _debug_option() {
  opt="$1" # if -d for debug mode
  choice=$(tr '[:upper:]' '[:lower:]' <<<"$opt")
  echo "choice: $choice"
  case ${choice} in
    -d) VERBOSE=1 ;;
  esac
}

# Check Connection
function _check_connection() {
  server=$1
  port=$2
  if nc -z "$server" "$port" 2>/dev/null; then
    echo -e "${GREEN}Internet Connection $server  ✓${NC}\n"
    return 0
  else
    echo -e "${RED}Internet Connection $server  ✗${NC}\n"
    return 1
  fi
}

function _copy_to_clipboard() {
  CONTENT=$1
  MSG=""
  case "$OSTYPE" in
  *msys* | *cygwin*)
    os="$(uname -o)"
    if [[ "$os" == "Msys" ]] || [[ "$os" == "Cygwin" ]]; then
      clip <"$CONTENT"
      MSG="Copied content To Windows Clipboard"
      debug "$MSG"
    fi
    ;;
  *darwin* | *Darwin*)
    os="$(uname -s)"
    pbcopy <"$CONTENT"
    MSG="Copied content To macOS Clipboard"
    debug "$MSG"
    ;;
  *)
    os="$(uname -s)"
    debug "${ORANGE}Headless Linux - Manual Copy Required${NC}"
    echo ""
    cat "$CONTENT"
    echo ""
    MSG="Copy Public Key from Terminal..."
    debug "$MSG"
    ;;
  esac
  echo -e "\n${GREEN}$MSG${NC}\n"
}

# Prompt to User for Continue or Exit
function _prompt_confirm() {
  # call with a prompt string or use a default
  local response msg="${1:-${ORANGE}Do you want to continue${NC}} (y/[n])? "
  if test -n "$ZSH_VERSION"; then
    read -q "response?$msg"
  elif test -n "$BASH_VERSION"; then
    shift
    read -r "$@" -p "$msg" response || echo
  fi

  case "$response" in
  [yY][eE][sS] | [yY])
    return 0
    ;;
  [nN][no][No] | [nN])
    echo -e "${BOLD}${RED}Exiting setup${NC}\n"
    exit 1
    ;;
  *)
    return 1
    ;;
  esac
}

function _backup_remove_git_config() {
  if [ -f "$GIT_CONFIG_FILE" ]; then
    echo "Backing Up $GIT_CONFIG_FILE to $GIT_CONFIG_FILE.bak"
    cp "$GIT_CONFIG_FILE" "$GIT_CONFIG_FILE.bak"
    echo "Removing $GIT_CONFIG_FILE"
    rm -fr "$GIT_CONFIG_FILE"
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
    git config --global user.name   "$USER_NAME"
    git config --global user.emanil "$EMAIL"
    echo -e "\nGit Config Gneration for $USER_NAME Done !!!"
	else
		echo -e "${ORANGE}\n.devcontainer/dotfiles/.gitconfig Exists${NC}"
	fi

}

function backup_ssh_keys(){
    echo -e "Backing up existing keys"
    rm -fr $(dirname $PRIVATE_KEY)/backup
    mkdir -p $(dirname $PRIVATE_KEY)/backup
    cp $PRIVATE_KEY $(dirname $PRIVATE_KEY)/backup
    cp $PUBLIC_KEY $(dirname $PRIVATE_KEY)/backup
}

function _generate_ssh_keys() {
  if [ ! -f $PUBLIC_KEY  ];then
    echo -e "${GREEN}${UNDERLINE}\nGenerating SSH Keys for $USER_NAME${NC}\n"
    _is_command_found ssh-keygen
    echo -e "Generating SSH Keys for $USER_NAME"
    ssh-keygen -q -t rsa -N '' -f "$PRIVATE_KEY" -C "$EMAIL" <<<y 2>&1 >/dev/null

    echo "Set File Permissions"
    # Fix Permission For Private Key
    chmod 400 "$PUBLIC_KEY"
    chmod 400 "$PRIVATE_KEY"
    echo -e "SSH Keys Generated Successfully"
    _copy_to_clipboard "$PUBLIC_KEY"
    _print_details
    if  [ -f "$(git rev-parse --show-toplevel)/.env" ]; then
      GIT=$(dotenv get GITHUB_URL)
    else
      GIT=$(cat .env.sample | grep GITHUB_URL | sed s/"GITHUB_URL="//)
    fi
    _check_connection "$GIT" 443
    _prompt_confirm "Is SSH Public Added to GitHub"
    git-ssh-fix
    ssh -T git@$GIT
  else
    echo -e "${ORANGE}SSH Keys Exist\n${NC}"
  fi
}

function _print_details() {
  GIT=$(dotenv get GITHUB_URL)
  debug ""
  debug "========= PUBLIC KEY ============"
  debug "$(cat "$PUBLIC_KEY")"
  debug "======= END PUBLIC KEY ========="

  echo -e "${BOLD}GoTo${NC}: ${ORANGE}https://$GIT/settings/ssh/new\n${NC}"
}

function _configure_ssh_gitconfig() {
  debug "Git Config"
  _git_config

  debug "SSH Key Gneration"
  _generate_ssh_keys
}

# Git SSH Fix - If devcontainer Terminal starts before initialization
function git-ssh-fix() {
  ERROR_MSG="${RED}Private SSH Key Not Present. DONT PANIC.${NC}"
  NEXT_STEP="${ORANGE}Run -> ssh-config${NC} Exiting..."
  MSG="$ERROR_MSG \n $NEXT_STEP"
  [[ ! -f "$PRIVATE_KEY" ]] && echo -e "$MSG" && return 1

  ssh-add -l > /dev/null
  EXIT_CODE=$?
  if [  "$EXIT_CODE" = 1  ];then
      echo -e "${ORANGE}SSH Identities Not Present${NC}"
      echo -e "Starting Fresh ssh-agen & Adding $PRIVATE_KEY to ssh-add"
      echo -e "Running -> eval $(ssh-agent -s) && ssh-add $PRIVATE_KEY"
      eval "$(ssh-agent -s)" && ssh-add $PRIVATE_KEY
  else
      echo -e "${GREEN}SSH Identiies Present. Fix Not Required${NC}"
      echo -e "${ORANGE}Run -> gstatus${NC}"
      ssh-add -l
  fi
}

function init_debug() {
  command -v sentry-cli >/dev/null 2>&1 || curl -sL https://sentry.io/get-cli/ | bash
  # eval "$(sentry-cli bash-hook)"
}

function log_sentry() {
  EXIT_CODE="$1"
  MESSAGE="$2"
  GIT_VERSION=$(git describe --tags --always --dirty)
  GIT_USER=$(git config user.name)
  if [[ -n "$EXIT_CODE" && "$EXIT_CODE" -eq 0 ]]; then
    prompt "$MESSAGE | Success ✅"
    sentry-cli send-event --message "✅ $MESSAGE | $GIT_USER | Success " --tag version:"$GIT_VERSION" --user user:"$GIT_USER" --level info
  else
    prompt "$MESSAGE | Failed ❌"
    sentry-cli send-event --message "❌ $MESSAGE | $GIT_USER | Failed " --tag version:"$GIT_VERSION" --user user:"$GIT_USER" --level error
  fi
}

function is_git_dir(){
    git_dir_check=$(git rev-parse --is-inside-work-tree > /dev/null 2>&1)
    if [ $? -eq 0 ]; then
        echo "yes"
    else
        echo "no"
    fi
}

function is_dir_in_gitignore(){
    dir_to_check="${1:-reports}"
    if [ -d $dir_to_check ];then
        touch "$dir_to_check/test"
        dir_in_gitignore=$(git check-ignore -v $dir_to_check/* > /dev/null 2>&1 )
        if [ $? -eq 0  ];then
            echo "yes"
        else
            echo "no"
        fi
        rm -fr "$dir_to_check/test"
    fi
}

function report_base_path(){
    base_path="/tmp"
    # Is Git Directory
    if [[ $(is_git_dir) == "yes" ]]; then
        # Is report directory in .gitignore
        if [[ $(is_dir_in_gitignore ) == "yes"  ]];then
            base_path="${PWD}"
        fi
    fi
    report_dir="${base_path}/reports"
    if [ ! -d $report_dir ];then
        mkdir -p $report_dir
    fi
    echo $report_dir
}

function aws_vault_backend_passphrase(){
    case "$AWS_VAULT_BACKEND" in
        file)
            read -s -r -p 'AWS Vault Passphrase : ' PASSPHRASE
            export AWS_VAULT_FILE_PASSPHRASE=$PASSPHRASE
        ;;
        pass);; #Do Nothing
        *) echo -e "Non supported AWS_VAULT_BACKEND=$AWS_VAULT_BACKEND" ;;
    esac
}


# Wrapper To Aid TDD
function _run_main() {
  _create_directory_if_not_exists "$@"
  _is_command_found "$@"
  _display_time "$@"
  _file_exists "$@"
  _file_contains_text "$@"
  _file_replace_text "$@"
  _is_os_darwin "$@"
  _debug_option "$@"
  _check_connection "$@"
  _copy_to_clipboard "$@"
  _prompt_confirm "$@"
  _backup_remove_git_config "$@"
  _git_config "$@"
  _generate_ssh_keys "$@"
  _print_details "$@"
  _configure_ssh_gitconfig "$@"

  debug "$@"
  prompt "$@"
  all_colors "$@"
  lls "$@"
  run_pre_commit "$@"
  git-ssh-fix "$@"
  init_sentry "$@"
  is_git_dir "$@"
  is_dir_in_gitignore "$@"
  report_base_path "$@"
  aws_vault_backend_passphrase "$@"
}

# Wrapper To Aid TDD
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if ! _run_main "$@"; then
    exit 1
  fi
fi
