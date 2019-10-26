#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
BLOKSH_BLOKS="$BATS_TEST_DIRNAME/bloks"
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "add_to_path: add if missing" {
	OLD_PATH="$PATH"
	bloksh_add_to_path "/hello/there"
	[[ $PATH = "/hello/there:$OLD_PATH" ]]
}

@test "add_to_path: don't add twice" {
	bloksh_add_to_path "/hello/there"
	OLD_PATH="$PATH"
	bloksh_add_to_path "/hello/there"
	[[ $PATH = "$OLD_PATH" ]]
}

@test "add_to_path: remove trailing slash" {
	OLD_PATH="$PATH"
	bloksh_add_to_path "/hello/trailing/slash/"
	[[ $PATH = "/hello/trailing/slash:$OLD_PATH" ]]
}

@test "add_to_path: add from blok" {
	_bloksh_set_variables example_w_install
	OLD_PATH="$PATH"
	bloksh_add_to_path "somewhere/in/blok"
	[[ $PATH = "$BLOKSH_PATH/somewhere/in/blok:$OLD_PATH" ]]
}

@test "add_to_path: path within nonexisting blok" {
	_bloksh_set_variables i_dont_exist || true
	run bloksh_add_to_path "nothing/there"

	[[ $status -eq 1 ]]
	error_regex='^\[i_dont_exist\] Missing from filesystem'
	[[ ${lines[0]} =~ $error_regex ]]
	[[ ${#lines[@]} -eq 1 ]]
}
