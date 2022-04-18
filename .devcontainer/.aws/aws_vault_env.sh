#!/usr/bin/env bash

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
  echo AWS Profile: $AWS_PROFILE. CTRL-D to exit.
  AWS_VAULT=
  aws-vault exec $AWS_PROFILE --no-session --
}
aws_vault_exec
