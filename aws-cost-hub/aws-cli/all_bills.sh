#!/usr/bin/env bash

function is_git_dir(){
    git_dir_check=$(git rev-parse --is-inside-work-tree > /dev/null 2>&1)
    if [ $? -eq 0 ]; then
        echo "yes"
    else
        echo "no"
    fi

}

function is_dir_in_gitignore(){
    dir_in_gitignore=$(git check-ignore -v reports/* > /dev/null 2>&1 )
    if [ $? -eq 0  ];then
        echo "yes"
    else
        echo "no"
    fi
}

function report_path(){
    base_path="/tmp"
    # Is Git Directory
    if [[ $(is_git_dir) == "yes" ]]; then
        echo "Executing within Git Repository"
        # Is report directory in .gitignore
        if [[ $(is_dir_in_gitignore) == "yes"  ]];then
            echo "reports dir included as part of .gitignore"
            base_path="${PWD}"
        fi
    fi
    report_dir="${base_path}/reports/aws-cost-hub/aws-cli"
    if [ ! -d $report_dir ];then
        mkdir -p $report_dir
    fi
    echo $report_dir
}

case "$OSTYPE" in
    # MacOS
    darwin*)
        read -s -r -p 'AWS Vault Passphrase : ' PASSPHRASE
        export AWS_VAULT_FILE_PASSPHRASE=$PASSPHRASE
    ;;
    *);;
esac

echo "Account ID,Account Alias,Bill" > $(report_path)/bill.csv
for aws_profile in $(aws configure list-profiles);do
    echo -e "Getting Bill for $aws_profile"
    export AWS_PROFILE=$aws_profile
    .devcontainer/.aws/aws_vault_env.sh "aws-cost-hub/aws-cli/bill.sh $(report_path)/bill.csv"
done
