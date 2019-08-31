#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
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
