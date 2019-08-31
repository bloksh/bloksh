#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
BLOKSH_BLOKS="$BATS_TEST_DIRNAME/bloks"
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "sourceish - not existing file with absolute path" {
	run sourceish "$BATS_TEST_DIRNAME/i_dont_exist"

	[[ $status -eq 0 ]]
	[[ ${#lines[@]} -eq 0 ]]
}

@test "sourceish - existing file with absolute path" {
	run sourceish "$BATS_TEST_DIRNAME/bloks/example_w_install/.install"

	[[ $status -eq 42 ]]
	[[ ${lines[0]} = 'i am install' ]]
	[[ ${#lines[@]} -eq 1 ]]
}

@test "sourceish - existing file within blok" {
	_bloksh_set_variables example_w_install
	run sourceish .install

	[[ $status -eq 42 ]]
	[[ ${lines[0]} = 'i am install' ]]
	[[ ${#lines[@]} -eq 1 ]]
}

@test "sourceish - nonexisting file within blok" {
	_bloksh_set_variables example_w_install
	run sourceish i_dont_exist

	[[ $status -eq 0 ]]
	[[ ${#lines[@]} -eq 0 ]]
}

@test "sourceish - file within nonexisting blok" {
	_bloksh_set_variables i_dont_exist || true
	run sourceish .install

	[[ $status -eq 1 ]]
	error_regex='^\[BLOKSH\]\[i_dont_exist\] Missing from filesystem'
	[[ ${lines[0]} =~ $error_regex ]]
	[[ ${#lines[@]} -eq 1 ]]
}
