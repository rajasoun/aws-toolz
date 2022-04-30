#!/usr/bin/env bash

case "$OSTYPE" in
    # MacOS
    darwin*)
        read -s -r -p 'AWS Vault Passphrase : ' PASSPHRASE
        export AWS_VAULT_FILE_PASSPHRASE=$PASSPHRASE
    ;;
    *);;
esac

echo "Account ID,Account Alias,Bill" > ${PWD}/aws-cost-hub/aws-cli/bill.csv
for aws_profile in $(aws configure list-profiles);do
    echo -e "Getting Bill for $aws_profile"
    export AWS_PROFILE=$aws_profile
    .devcontainer/.aws/aws_vault_env.sh "aws-cost-hub/aws-cli/bill.sh"
done
