#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
BLOKSH_BLOKS="$BATS_TEST_DIRNAME/bloks"
BLOKSH_SECRETS="$BATS_TEST_DIRNAME/secrets"
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "set_variables: error if path does not exist" {
	run _bloksh_set_variables i_dont_exist
	[[ $status -eq 1 ]]
	[[ $output = '' ]]
}

@test "set_variables: variables are set even if path does not exist, but PATH is untouched" {
	OLD_PATH="$PATH"
	_bloksh_set_variables i_dont_exist neither_do_i || true
	[[ $BLOKSH_NAME = i_dont_exist ]]
	[[ $BLOKSH_GIT_URL = neither_do_i ]]
	[[ $BLOKSH_GIT_BRANCH = master ]]
	[[ $BLOKSH_PATH = "$BATS_TEST_DIRNAME/bloks/i_dont_exist" ]]
	[[ $BLOKSH_SECRET_PATH = "$BATS_TEST_DIRNAME/secrets/i_dont_exist" ]]
	[[ $PATH = "$OLD_PATH" ]]
}

@test "set_variables: variables are set and \$PATH is updated" {
	OLD_PATH="$PATH"
	_bloksh_set_variables example its_git_url#branch
	[[ $BLOKSH_NAME = example ]]
	[[ $BLOKSH_GIT_URL = its_git_url ]]
	[[ $BLOKSH_GIT_BRANCH = branch ]]
	[[ $BLOKSH_PATH = "$BATS_TEST_DIRNAME/bloks/example" ]]
	[[ $BLOKSH_SECRET_PATH = "$BATS_TEST_DIRNAME/secrets/example" ]]
	[[ $PATH = "$BLOKSH_PATH:$OLD_PATH" ]]
}

@test "clean_variables: variables are unset" {
	_bloksh_set_variables i_dont_exist neither_do_i#branch || true
	_bloksh_clean_variables
	[[ $BLOKSH_NAME = '' ]]
	[[ $BLOKSH_GIT_URL = '' ]]
	[[ $BLOKSH_GIT_BRANCH = '' ]]
	[[ $BLOKSH_PATH = '' ]]
	[[ $BLOKSH_SECRET_PATH = '' ]]
}
