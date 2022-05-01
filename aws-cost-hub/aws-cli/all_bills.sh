#!/usr/bin/env bash

function report_path(){
    base_path="/tmp"
    # Is Git Directory
    if [ $(git rev-parse --is-inside-work-tree > /dev/null 2>&1) ]; then
        # Is report directory in .gitignore
        if [  $(git check-ignore -v reports | grep -c "reports") ];then
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
