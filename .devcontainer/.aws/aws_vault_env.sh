#!/usr/bin/env bash

if [ -d "/workspaces" ];then
	SCRIPT_DIR="/workspaces"
else
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.devcontainer/"
fi

SCRIPT_PATH="$SCRIPT_DIR/automator/src/lib/os.sh"
# shellcheck source=/dev/null
source "$SCRIPT_PATH"

function add_profile_to_aws_vault(){
    while true
    do
        read -r -p 'Add Profile to aws-vault (y/n)? ' choice
        case "$choice" in
        n|N) break;;
        y|Y)
            read -r -p 'AWS Profile Name : ' profile
            aws-vault add $profile;;
        *) echo 'Response not valid';;
        esac
    done
}

function aws_vault_exec() {
  if ! which aws-vault >/dev/null; then
    echo -e "You must have 'aws-vault' installed.\nSee https://github.com/99designs/aws-vault/\n"
    return 1
  fi

  if [ ! -f ~/.aws/config ]; then
    echo -e "You must have AWS profiles set up to use this.\nSee https://github.com/99designs/aws-vault/\n"
    add_profile_to_aws_vault
    return 1
  fi

  local list=$(grep '^[[]profile' <~/.aws/config | awk '{print $2}' | sed 's/]$//')
  if [[ -z $list ]]; then
    echo -e "You must have AWS profiles set up to use this.\nSee https://github.com/99designs/aws-vault/"
    add_profile_to_aws_vault
    return 1
  fi

  local nlist=$(echo "$list" | nl)
  while [[ -z $AWS_PROFILE ]]; do
      local AWS_PROFILE=$(read -p "AWS profile? `echo $'\n\r'`$nlist `echo $'\n> '`" N; echo "$list" | sed -n ${N}p)
  done
  aws-vault list | awk '{print $2}' | grep -c "$AWS_PROFILE" >/dev/null 2>&1 && \
    (echo -e "\n✅ AWS Profile $AWS_PROFILE") || \
    (echo -e "\n💣 Missing Credentials For $AWS_PROFILE \n";aws-vault add $AWS_PROFILE)
  AWS_VAULT=
  CMD="$@"
  if [ -z "$CMD" ];then
    echo AWS Profile: $AWS_PROFILE. CTRL-D to exit.
    aws-vault exec $AWS_PROFILE --no-session --
  else
    echo -e "\n${BOLD}${GREEN}Executing $CMD ${NC}\n"
    aws-vault exec $AWS_PROFILE --no-session -- $CMD
  fi
}
aws_vault_exec "$@"
