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
GROUP_NAME=${2:-"ProwlerSecurityAudit"}
POLICY_NAME=${3:-"ProwlerAuditAdditions"}
POLICY_FILE=${4:-"/iam/prowler-policy-additions.json"}
USER_NAME=${5:-"prowler"}

export AWS_DEFAULT_PROFILE=$ADMIN_PROFILE
export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' | tr -d '"')

echo "Setup Initiated"
## Create Group
aws iam create-group --group-name $GROUP_NAME

## Create User
aws iam create-user --user-name $USER_NAME

## Add User To Group
aws iam add-user-to-group --user-name $USER_NAME --group-name $GROUP_NAME

## Create and Attach Policy to the Group
aws iam create-policy --policy-name $POLICY_NAME --policy-document file://$(pwd)/$POLICY_FILE
aws iam attach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::aws:policy/$GROUP_NAME
aws iam attach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/$POLICY_NAME

echo "Creating Access Keys for $USER_NAME--------------"
## Create Access Keys for User
ACCESS_KEY=$(aws iam create-access-key --user-name $USER_NAME)
AWS_ACCESS_KEY_ID=$(echo $ACCESS_KEY | jq '.AccessKey.AccessKeyId' | xargs)
AWS_SECRET_ACCESS_KEY=$(echo $ACCESS_KEY | jq '.AccessKey.SecretAccessKey' | xargs)

# # Configure  profile for the User
aws configure --profile $USER_NAME set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure --profile $USER_NAME set aws_secret_access_key $AWS_SECRET_ACCESS_KEY

echo "Setup Completed"
unset ACCOUNT_ID AWS_DEFAULT_PROFILE
