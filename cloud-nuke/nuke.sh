#!/usr/bin/env bash

AWS_IDENTITY_COMMAND="$(git rev-parse --show-toplevel)/cost-explorer/libs/identity.py"
AWS_NUKE_COMMAND="cloud-nuke aws --region us-east-1 --config nuke.yml"

$AWS_IDENTITY_COMMAND 
$AWS_NUKE_COMMAND 

