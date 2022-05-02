#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/test-utils.sh"

# Run common tests
checkCommon

# Definition specific tests
#checkExtension "ms-azuretools.vscode-docker"
check "pre-commit" pre-commit --version
check "gh" gh --version
check "dotenv" dotenv --version
check "gpg2" gpg2 --version
check "pass" pass --version
check "sentry-cli" sentry-cli --version
check "syft" syft --version
check "grype" grype version
check "aws" aws --version
check "aws-vault" aws-vault --version
check "awless" awless --version
check "awsaudit" awsaudit --version
check "cloudsplaining" cloudsplaining --version
check "cloud-nuke" cloud-nuke --version
check "aws-nuke" aws-nuke version
check "fetch" fetch --version
check "aws-sso" aws-sso -version
check "http" http --version

#check "pre-commit" pre-commit run --all-files
# Report result
reportResults

EXIT_CODE="$?"
log_sentry "$EXIT_CODE" "e2e_tests.sh "
