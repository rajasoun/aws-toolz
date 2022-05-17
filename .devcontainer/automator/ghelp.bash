#!/usr/bin/env bash


if [ -d "/workspaces" ];then
	# Within DevContainer
	SCRIPT_DIR="/workspaces"
else
	# Within Host
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.devcontainer/"
fi

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

function dev_help() {
	clear
	echo -e "
- - - - - - - - - - - - - -- - - - - - - - - - - - - -- - - - - - - - -
       			${BOLD}Shortcuts${NC}
- - - - - - - - - - - - - -- - - - - - - - - - - - - -- - - - - - - - -
gsetup		 - 	Install Git Flow, pre-commit & husky hooks
ghooks		 - 	Install only pre-commit & husky hooks
glogin		 - 	Web Login to GitHub
ssh-config	 - 	Generate SSH public & private Keys for Git
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

function ops_help() {
	clear
	echo -e "
- - - - - - - - - - - - - -- - - - - - - - - - - - - -- - - - - - - - -
       			${BOLD}Shortcuts${NC}
- - - - - - - - - - - - - -- - - - - - - - - - - - - -- - - - - - - - -
aws-env		 - 	Wrapper to aws-vault
aws-whoami	 - 	Prints AWS Identity of the current aws-vault env
aws-bill	 - 	Generates AWS Bill for the given aws-vault Profile
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

function _install_git_hooks() {
	prompt "Git Repository..."
	prompt "Installing Git Hooks"
	git config --unset-all core.hooksPath
	pre-commit install --config /workspaces/shift-left/.pre-commit-config.yaml
	run_pre_commit
}

function _check_gg_api() {
	prompt "Checking Git Guardian API Validity"
	# shellcheck source=/dev/null
	curl -H "Authorization: Token $(dotenv get GITGUARDIAN_API_KEY)" \
		"$(dotenv get GITGUARDIAN_API_URL)/v1/health"
	prompt ""
}

function _populate_dot_env() {
	prompt "Populating .env File"
	if [ -f "$(git rev-parse --show-toplevel)/.env" ]; then
		mv .env .env.bak
	fi
	cp .env.sample .env

	prompt "${BLUE}To Get the GitHub Key  ${NC}"
	prompt "${ORANGE} Visit https://www.$(dotenv -f .env.sample get GITHUB_URL)/settings/tokens ${NC}"
	prompt "${BOLD}Enter Git Token: ${NC}"
	read -r GITTOKEN
	_file_replace_text "1__________FILL_ME__________1" "$GITTOKEN" "$(git rev-parse --show-toplevel)/.env"

	prompt "${BLUE}To Get the GG Key - Register to Git Guardian ${NC}"
	prompt "${ORANGE} Visit $(dotenv -f .env.sample get GITGUARDIAN_URL) ${NC}"
	prompt "${BOLD}Enter Git Guardian API Key: ${NC}"
	read -r GG_KEY
	_file_replace_text "2__________FILL_ME__________2" "$GG_KEY" "$(git rev-parse --show-toplevel)/.env"
	_check_gg_api

	prompt "${BLUE}To Get the Sentry DSN  ${NC}"
	prompt "${ORANGE} Visit $(dotenv -f .env.sample get SENTRY_URL) ${NC}"
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
- Source code repository: $(git config --get remote.origin.url)" > "$(git rev-parse --show-toplevel)/.devcontainer/signature.txt"
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

function create_gpg_keys(){
	check_git_config
	CN=$(git config user.name)
	EMAIL=$(git config user.email)
    gpg2 --full-generate-key --batch  <<EOF
%echo Generating a GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: encrypt
Name-Real: $CN
Name-Email: $EMAIL
Expire-Date: 1y
%no-protection
%commit
%echo Done
EOF
}

function store_gpg_keys(){
    gpg2 --export -a "$EMAIL" > "${PWD}/.devcontainer/.gpg2/keys/public.key"
    gpg2 --export-secret-keys --armor > "${PWD}/.devcontainer/.gpg2/keys/private.key"
}

function list_gpg_keys(){
    gpg2 --list-keys
}

function generate_gpg_keys(){
	mkdir -p .devcontainer/.gpg2/keys
	find "$PGP_DIR" -type f -exec chmod 600 {} \; # Set 600 for files
	find "$PGP_DIR" -type d -exec chmod 700 {} \; # Set 700 for directories
	if [ ! -d "${PWD}/.devcontainer/.gpg2/keys/public.key" ]; then
		create_gpg_keys
		list_gpg_keys
		store_gpg_keys
	else
		echo -e "GPG Key Exists. Run -> clean_configs to remove all configs"
	fi
}

function init_pass_store(){
	EMAIL=$(gpg2 --list-keys | grep uid | awk '{print $5}' | tr -d '<>')
	if [ ! -f ".devcontainer/.store/.gpg-id" ];then
		pass init $EMAIL
	fi
}

function clean_configs(){
	rm -fr .devcontainer/dotfiles/.gitconfig
	rm -fr .devcontainer/.ssh/known_hosts
	rm -fr .devcontainer/.ssh/id_rsa
	rm -fr .devcontainer/.ssh/id_rsa.pub
	rm -fr .devcontainer/.gpg2/keys/
	rm -fr .devcontainer/.store/aws-vault
	rm -fr .devcontainer/.store/.gpg-id
	rm -fr .devcontainer/.aws/config
	## Temp Fix - To restore keys directory with .gitkeep
	## Find ways to clean directory with exclusion filter
	mkdir -p .devcontainer/.gpg2/keys
	touch .devcontainer/.gpg2/keys/.gitkeep
}

function backup_configs(){
	mkdir -p .devcontainer/.ssh/backup
	mv .devcontainer/.ssh/known_hosts .devcontainer/.ssh/backup
	mv .devcontainer/.ssh/*id_rsa*	  .devcontainer/.ssh/*id_rsa*
}

function aws_whoami(){
	AWS_PROFILE="$1"
	AWS_WHOAMI_CMD="/workspaces/tools/identity.py"
	AWS_VAULT_WRAPPER="$(git rev-parse --show-toplevel)/.devcontainer/.aws/aws_vault_env.sh"
	if [ -z $AWS_PROFILE ];then
		#AWS_PROFILE Empty
		echo -e "\n${BOLD}${RED}AWS Profile parameter missing  ${NC}"
		echo -e "aws-whoami <aws_profile>\n"
	else
		#AWS_PROFILE Not Empty
		export AWS_PROFILE=$AWS_PROFILE && $AWS_VAULT_WRAPPER $AWS_WHOAMI_CMD
	fi
}

function aws_bill(){
	AWS_PROFILE="$1"
	if [ -z $AWS_PROFILE ];then
		#AWS_PROFILE Empty
		echo -e "\n${BOLD}${RED}AWS Profile parameter missing  ${NC}"
		echo -e "aws-bill <aws_profile>\n"
	else
		#AWS_PROFILE Not Empty
		AWS_BILL_CMD="/workspaces/tools/bill.sh"
		AWS_VAULT_WRAPPER="$(git rev-parse --show-toplevel)/.devcontainer/.aws/aws_vault_env.sh"
		export AWS_PROFILE=$AWS_PROFILE && $AWS_VAULT_WRAPPER $AWS_BILL_CMD
	fi
}

function pretty_csv {
    column -t -s, -n "$@" | less -F -S -X -K
}

function pretty_tsv {
    column -t -s $'\t' -n "$@" | less -F -S -X -K
}


#-------------------------------------------------------------
# Help Alias Commands
#-------------------------------------------------------------
alias aws-help='ops_help'
alias dev-help='dev_help'

#-------------------------------------------------------------
# Git Alias Commands
#-------------------------------------------------------------
alias gss="git status -s"
alias gaa="git add --all"
alias gc="cz commit"
alias gp="git_push"
alias gclean="git fetch --prune origin && git gc"
alias glogin="git_hub_login $@"
alias ssh-config="_generate_ssh_keys"
alias gstatus="_gstatus"
alias ghooks="_install_git_hooks"
alias generate_git_config="_git_config"
alias gssh_config="_configure_ssh_gitconfig"
alias grelease="_git_tag"

#-------------------------------------------------------------
# Generic Alias Commands
#-------------------------------------------------------------
#alias pretty="npx prettier --config /workspaces/shift-left/.prettierrc.yml --write ."
alias precommit="run_pre_commit"
alias infra-test='/workspaces/tests/system/e2e_tests.sh'
alias aws-env="$(git rev-parse --show-toplevel)/.devcontainer/.aws/aws_vault_env.sh"
alias aws-whoami="aws_whoami $@"
alias aws-bill="aws_bill $@"

# For Sentry
alias init-debug='init_debug'

#-------------------------------------------------------------
# DevContainer CI/CD Alias Commands
#-------------------------------------------------------------
alias ci-cd="make -f .devcontainer/Makefile $@"
alias code-churn="code_churn"

if [ -f "$(git rev-parse --show-toplevel)/.dev" ]; then
	echo -e "${BOLD}Environment : ${UNDERLINE}dev${NC}"
	if ! [ -f "$(git rev-parse --show-toplevel)/.env" ]; then
		prompt "${ORANGE} Starting gsetup ${NC}"
		gsetup
	fi
	git_hub_login token
	init_debug
	EXIT_CODE="$?"
	log_sentry "$EXIT_CODE" "DevContainer Initialization for Dev"
	check_git_config
	rm -fr $(git rev-parse --show-toplevel)/.dev
	echo -e "${GREEN}Help : dev-help${NC}\n"
else
	echo -e "${BOLD}Environment : ${UNDERLINE}ops${NC}\n"
	if ! [ -f "$(git rev-parse --show-toplevel)/.env" ]; then
		prompt "${ORANGE} Starting gsetup ${NC}"
		gsetup
	fi
fi

export PRE_COMMIT_ALLOW_NO_CONFIG=1
