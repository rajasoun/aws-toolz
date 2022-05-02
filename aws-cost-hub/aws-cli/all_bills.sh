#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

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

function report_path(){
    base_path="/tmp"
    # Is Git Directory
    if [[ $(is_git_dir) == "yes" ]]; then
        # Is report directory in .gitignore
        if [[ $(is_dir_in_gitignore ) == "yes"  ]];then
            base_path="${PWD}"
        fi
    fi
    report_dir="${base_path}/reports/aws-cost-hub/aws-cli"
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

function sso_login(){
    login_status=$(duo-sso -config ~/.aws/sso.json  > /dev/null 2>&1)
    if [ $? -eq 0 ]; then
        echo "yes"
    else
        echo "no"
    fi
}

function check_sso_login(){
    if [[ $(sso_login) == "yes"  ]];then
        echo "${GREEN}SSO Login successfull${NC}"
    else
        echo "${RED}SSO Login failed${NC}"
    fi
}

function get_authentication_mode(){
    bill_cmd="aws-cost-hub/aws-cli/bill.sh $(report_path)/bill.csv"
    read  -r -p 'Mode [sso | aws-vault] : ' opt
    choice=$(tr '[:upper:]' '[:lower:]' <<<"$opt")
    echo -e "\nSetting up $choice\n"
    case ${choice} in
        sso)
            check_sso_login
            export CREDENTIAL_CMD="$bill_cmd"
        ;;
        aws-vault)
            aws_vault_backend_passphrase
            export CREDENTIAL_CMD=".devcontainer/.aws/aws_vault_env.sh $bill_cmd"
        ;;
    esac
}

function generate_bill(){
    get_authentication_mode
    for aws_profile in $(aws configure list-profiles);do
        echo -e "Getting Bill for $aws_profile"
        export AWS_PROFILE=$aws_profile
        $CREDENTIAL_CMD
    done
}

function main(){
    echo "Account ID,Account Alias,Bill" > $(report_path)/bill.csv
    generate_bill
}

main
