#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/test-utils.sh"

# Run common tests
checkCommon

# Definition specific tests
#checkExtension "ms-azuretools.vscode-docker"
check "commitlint" commitlint --version
check "pre-commit" pre-commit --version
check "git flow" git flow version
check "gh" gh --version
check "dotenv" dotenv --version
check "syft" syft --version
check "grype" grype version
check "sentry" sentry-cli --version
check "goss" goss --version
check "go" go version

#check "pre-commit" pre-commit run --all-files
# Report result
reportResults

EXIT_CODE="$?"
log_sentry "$EXIT_CODE" "e2e_tests.sh "
