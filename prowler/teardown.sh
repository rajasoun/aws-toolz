#!/usr/bin/env sh

# Quick bash script to set up a "prowler" IAM user and "SecurityAudit" group with the required permissions.
# To run the script below, you need user with administrative permissions;
# set the AWS_DEFAULT_PROFILE to use that account.

# The aws iam create-access-key command will output the secret access key and the key id; keep these somewhere safe,
# and add them to ~/.aws/credentials with an appropriate profile name to use them with prowler.
# This is the only time they secret key will be shown. If you lose it, you will need to generate a replacement.

# VARIABLE=${1:-DEFAULTVALUE}
# Assigns 1st argument passed to the script or the value of DEFAULTVALUE if no such argument was passed to the Variable

ADMIN_PROFILE=${1:-"admin"}
GROUP_NAME=${2:-"SecurityAudit"}
POLICY_NAME=${3:-"ProwlerAuditAdditions"}
POLICY_FILE=${4:-"/iam/prowler-policy-additions.json"}
USER_NAME=${5:-"prowler"}

export AWS_DEFAULT_PROFILE=$ADMIN_PROFILE
export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' | tr -d '"')
export ACCESS_ID=$(aws iam list-access-keys --user-name $USER_NAME --query 'AccessKeyMetadata[*].AccessKeyId' | tr -d '[]' | xargs)

echo "TearDown Initiated"
## Delete Access Keys, Detach User from the Group and Delete User
aws iam delete-access-key --user-name $USER_NAME --access-key-id $ACCESS_ID
aws iam remove-user-from-group --user-name $USER_NAME --group-name $GROUP_NAME
aws iam delete-user --user-name $USER_NAME

## Detach Policies from Group and Delete Policy & Group
aws iam detach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/$POLICY_NAME
aws iam detach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::aws:policy/$GROUP_NAME
aws iam delete-policy  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/$POLICY_NAME
aws iam delete-group --group-name  $GROUP_NAME

echo "TearDown Completed"
unset ACCOUNT_ID AWS_DEFAULT_PROFILE ACCESS_ID
