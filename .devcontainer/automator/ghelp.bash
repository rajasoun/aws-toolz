#!/usr/bin/env bash

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="/workspaces"
SCRIPT_PATH="$SCRIPT_DIR/automator/src/lib/os.sh"
# shellcheck source=/dev/null
source "$SCRIPT_PATH"

case "$OSTYPE" in
darwin*)
	echo "${GREEN}Welcome $(git config user.name) | OS: OSX${NC}"
	;;
linux*)
	echo "${GREEN}${BOLD}Welcome $(git config user.name) | OS: Linux${NC}"
	;;
msys*)
	echo "${GREEN}${BOLD}Welcome $(git config user.name) | OS: Windows${NC}"
	;;
*)
	echo "unknown: $OSTYPE"
	exit 1
	;;
esac

function ghelp() {
	clear
	echo -e "
- - - - - - - - - - - - - -- - - - - - - - - - - - - -- - - - - - - - -
       			${BOLD}Shortcuts${NC}
- - - - - - - - - - - - - -- - - - - - - - - - - - - -- - - - - - - - -
ghelp 		 - 	List all Git Convenience commands and prompt symbols
gsetup		 - 	Install Git Flow, pre-commit & husky hooks
ghooks		 - 	Install only pre-commit & husky hooks
glogin		 - 	Web Login to GitHub
gstatus		 - 	GitHub Login status
grelease	 - 	Create Git Tag & Release through Automation
infra-test	 - 	Run End to End Test on Devcontainer Infrastructure
code-churn	 - 	Frequency of change to code base
pretty		 - 	Code prettier
precommit	 - 	Run Pre-commit checks on all Files
ci-cd		 - 	CI/CD for Devcontainer
alias		 - 	List all Alias
- - - - - - - - - - - - - -- - - - - - - - - - - - - -- - - - - - - - - -
"
}

function _git_tag() {
	CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
	if [ "$CUR_BRANCH" != "main" ]; then
		echo "${RED} Need to be in main branch ${NC}"
		return 1
	fi

	GIT_CLEAN="$(git status --porcelain)"
	if [ -z "$GIT_CLEAN" ]; then
		git fetch --prune --tags
		VERSION=$(git describe --tags --abbrev=0 | awk -F. '{OFS="."; $NF+=1; print $0}')
		git tag -a "$VERSION" -m "tip : $VERSION | For Release"
		git push origin "$VERSION" --no-verify
		git fetch --prune --tags
	else
		echo "${RED} Git Not Clean... ${NC}"
	fi
}

function _teardown_git_flow() {
	git config --remove-section "gitflow.path"
	git config --remove-section "gitflow.prefix"
	git config --remove-section "gitflow.branch"
}

function _init_git_flow() {
	if (git flow config >/dev/null 2>&1); then
		prompt "Git Flow Already Initialized..."
	else
		prompt "Git Flow Not Initialized. Initializing..."
		git flow init -fd
	fi
}

function _install_git_hooks() {
	prompt "Git Repository..."
	prompt "Installing Git Hooks"
	git config --unset-all core.hooksPath
	pre-commit install --config /workspaces/shift-left/.pre-commit-config.yaml
	# pre-commit install-hooks --config /workspaces/shift-left/.pre-commit-config.yaml
	pre-commit run --config /workspaces/shift-left/.pre-commit-config.yaml --all-files
	# rm -fr $(git rev-parse --show-toplevel)/.husky
	# cp -R /workspaces/husky $(git rev-parse --show-toplevel)/.husky
	# husky install
}

function _check_gg_api() {
	prompt "Checking Git Guardian API Validity"
	# shellcheck source=/dev/null
	curl -H "Authorization: Token $(dotenv get GITGUARDIAN_API_KEY)" "$(dotenv get GITGUARDIAN_API_URL)/v1/health"
	prompt ""
}

function _populate_dot_env() {
	prompt "Populating .env File"
	if [ -f "$(git rev-parse --show-toplevel)/.env" ]; then
		mv .env .env.bak
	fi
	cp .env.sample .env

	prompt "${BLUE}To Get the GitHub Key  ${NC}"
	prompt "${YELLOW} Visit https://www.$(dotenv -f .env.sample get GITHUB_URL)/settings/tokens ${NC}"
	prompt "${BOLD}Enter Git Token: ${NC}"
	read -r GITTOKEN
	_file_replace_text "1__________FILL_ME__________1" "$GITTOKEN" "$(git rev-parse --show-toplevel)/.env"

	prompt "${BLUE}To Get the GG Key - Register to Git Guardian ${NC}"
	prompt "${YELLOW} Visit $(dotenv -f .env.sample get GITGUARDIAN_URL) ${NC}"
	prompt "${BOLD}Enter Git Guardian API Key: ${NC}"
	read -r GG_KEY
	_file_replace_text "2__________FILL_ME__________2" "$GG_KEY" "$(git rev-parse --show-toplevel)/.env"
	_check_gg_api

	prompt "${BLUE}To Get the Sentry DSN  ${NC}"
	prompt "${YELLOW} Visit $(dotenv -f .env.sample get SENTRY_URL) ${NC}"
	prompt "${BOLD}Enter Sentry DSN: ${NC}"
	read -r SENTRYDSN
	_file_replace_text "3__________FILL_ME__________3" "$SENTRYDSN" "$(git rev-parse --show-toplevel)/.env"
}

function gsetup() {
	if [ "$(git rev-parse --is-inside-work-tree)" = true ]; then
		if [[ $(git diff --stat) != '' ]]; then
			prompt "${RED} Git Working Tree Not Clean. Aborting setup !!! ${NC}"
			EXIT_CODE=1
			log_sentry "$EXIT_CODE" "gsetup | Git Working Tree Not Clean. Aborting setup"
		else
			start=$(date +%s)
			prompt "Git Working Tree Clean"
			cp .env .env.bak
			_install_git_hooks || prompt "_install_git_hooks ❌"
			_populate_dot_env || prompt "_populate_dot_env ❌"
			_init_git_flow || prompt "_init_git_flow ❌ [Proceeding...]"
			end=$(date +%s)
			runtime=$((end - start))
			prompt "gsetup DONE in $(_display_time $runtime)"
			/workspaces/tests/system/e2e_tests.sh
			EXIT_CODE="$?"
			log_sentry "$EXIT_CODE" "gsetup "
		fi
	fi
}

function release_dev_container(){
	git_hub_login token
	make -f .devcontainer/Makefile prerequisite
	make -f .devcontainer/Makefile git
	make -f .devcontainer/Makefile build
	make -f .devcontainer/Makefile push
}

# Gits Churn -  "frequency of change to code base"
#
# $ ./git-churn.bash
# 30 src/multipass/actions.bash
# 38 test/test_integration.bats
# 97 .github/workflows/pipeline.yml
#
# This means that
# actions.bash has changed 30 times.
# pipeline.yml has changed 97 times.
#
# Show churn for specific directories:
#   $ $ ./git-churn.bash src
#
# Show churn for a time range:
#   $ $ ./git-churn.bash --since='1 month ago'
#
# All standard arguments to git log are applicable
function code_churn() {
	git log --all -M -C --name-only --format='format:' "$@" | sort | grep -v '^$' | uniq -c | sort -n
}

function git_push() {
	git push
	EXIT_CODE="$?"
	log_sentry "$EXIT_CODE" "git push | Branch: $(git rev-parse --abbrev-ref HEAD)"
}

function check_git_config() {
	user_name=$(git config user.name)
	user_email=$(git config user.email)
	if [ -z "$user_name" ] || [ -z "$user_email" ]; then
		log_sentry "1" "git config | user_name and user_email not set"
		_git_config
	else
		log_sentry "0" "git config "
	fi
}

function check_hooks_config() {
	#if [ ! -f "$(git rev-parse --show-toplevel)/.husky" ]; then
		rm -fr $(git rev-parse --show-toplevel)/.husky
		cp -R /workspaces/husky $(git rev-parse --show-toplevel)/.husky
		husky install
		EXIT_CODE="$?"
		log_sentry "$EXIT_CODE" "Git Hooks Config Check"
	#fi
}

function git_hub_login() {
	AUTH_TYPE=$1
	case "$AUTH_TYPE" in
	web)
		gh auth login --hostname "$(dotenv get GITHUB_URL)" --git-protocol https --web
		EXIT_CODE="$?"
		log_sentry "$EXIT_CODE" "Github Login via Web"
		;;
	token)
		GIT_REPO_DIR="$(git rev-parse --show-toplevel)"
		GT="$(dotenv get GITHUB_TOKEN)"
		[ "$GT" ] || (echo "GITHUB_TOKEN Not set in .env" && exit 1)
		# The minimum required scopes for the token are: "repo", "read:org".
		gh auth login --hostname "$(dotenv get GITHUB_URL)" --git-protocol ssh --with-token <<< $GT
		EXIT_CODE="$?"
		log_sentry "$EXIT_CODE" "Github Login via Token"
		;;
	*) gh auth login --hostname "$(dotenv get GITHUB_URL)" --git-protocol https --web ;;
	esac
}

function _gstatus(){
	echo -e "GitHub Authentication Check"
	gh auth status --hostname $(dotenv get GITHUB_URL)
	echo -e "GitHub SSH Check"
	ssh -T git@$(dotenv get GITHUB_URL)
}

function integrity(){
	sha256sum=$(find \
		"/workspaces/automator/"  \
		"/workspaces/shift-left/" \
		"/workspaces/tests" \
		"/opt/version.txt" \
		-type f -print0 \
	| sort -z | xargs -r0 sha256sum | sha256sum | awk '{print $1}')
	echo $sha256sum
}

function devcontainer_signature(){
echo -e "
Development container version information

- Image version: $(cat /opt/version.txt)
- SHA: $(integrity)
- Source code repository: https://www-github.cisco.com/LC-SecurityDPP/devcontainer-base" > "$(git rev-parse --show-toplevel)/.devcontainer/signature.txt"
	git add .devcontainer/signature.txt
	HUSKY=0 git commit -m "ci(devcontainer): signature generation" --no-verify
	git push
}

function check_integrity(){
	generated_integrity="$(integrity)"
	stored_integrity="$(cat /opt/signature.txt | grep SHA | awk '{print $3}')"
	if [ "$generated_integrity" = "$stored_integrity"  ]; then
		echo -e "${GREEN}Integrity Check - Passsed${NC}\n"
		return 0
	else
		echo -e "${RED}Integrity Check - Failed${NC}\n"
		return 1
	fi
}

#-------------------------------------------------------------
# Git Alias Commands
#-------------------------------------------------------------
alias gss="git status -s"
alias gaa="git add --all"
alias gc="git commit"
alias gp="git_push"
alias gclean="git fetch --prune origin && git gc"
alias glogin="git_hub_login $@"
alias gstatus="_gstatus"
alias ghooks="_install_git_hooks"
alias grelease="_git_tag"

#-------------------------------------------------------------
# Generic Alias Commands
#-------------------------------------------------------------
alias pretty="npx prettier --config /workspaces/shift-left/.prettierrc.yml --write ."
alias precommit="pre-commit run --config /workspaces/shift-left/.pre-commit-config.yaml --all-files"
alias infra-test='/workspaces/tests/system/e2e_tests.sh'

# For Sentry
alias init-debug='init_debug'

#-------------------------------------------------------------
# DevContainer CI/CD Alias Commands
#-------------------------------------------------------------
alias ci-cd="make -f .devcontainer/Makefile $@"
alias code-churn="code_churn"

if ! [ -f "$(git rev-parse --show-toplevel)/.env" ]; then
	prompt "${YELLOW} Starting gsetup ${NC}"
	gsetup
fi

#git-ssh-fix
git_hub_login token
init_debug
EXIT_CODE="$?"
log_sentry "$EXIT_CODE" "DevContainer Initialization"
check_git_config
#check_hooks_config
