#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
BLOKSH_BLOKS="$BATS_TEST_DIRNAME/bloks"
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "source - not existing file with absolute path" {
	run bloksh_source "$BATS_TEST_DIRNAME/i_dont_exist"

	[[ $status -eq 0 ]]
	[[ ${#lines[@]} -eq 0 ]]
}

@test "source - existing file with absolute path" {
	run bloksh_source "$BATS_TEST_DIRNAME/bloks/example_w_install/.install"

	[[ $status -eq 42 ]]
	[[ ${lines[0]} = 'i am install' ]]
	[[ ${#lines[@]} -eq 1 ]]
}

@test "source - existing file within blok" {
	_bloksh_set_variables example_w_install
	run bloksh_source .install

	[[ $status -eq 42 ]]
	[[ ${lines[0]} = 'i am install' ]]
	[[ ${#lines[@]} -eq 1 ]]
}

@test "source - nonexisting file within blok" {
	_bloksh_set_variables example_w_install
	run bloksh_source i_dont_exist

	[[ $status -eq 0 ]]
	[[ ${#lines[@]} -eq 0 ]]
}

@test "source - file within nonexisting blok" {
	_bloksh_set_variables i_dont_exist || true
	run bloksh_source .install

	[[ $status -eq 1 ]]
	error_regex='^\[BLOKSH\]\[i_dont_exist\] Missing from filesystem'
	[[ ${lines[0]} =~ $error_regex ]]
	[[ ${#lines[@]} -eq 1 ]]
}
