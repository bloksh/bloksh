#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "show_errors: no output if no errors" {
	BLOKSH_ERRORS=()
	run _bloksh_show_errors
	[[ $status -eq 0 ]]
	[[ $output = "" ]]
}

@test "show_errors: output if errors" {
	BLOKSH_ERRORS=(one two three)
	run _bloksh_show_errors
	[[ $status -eq 0 ]]
	[[ $output = "[BLOKSH] Errors in bloks: one two three" ]]
}

@test "show_errors: clean on the second call" {
	BLOKSH_ERRORS=(four five six)
	_bloksh_show_errors
	run _bloksh_show_errors
	[[ $status -eq 0 ]]
	[[ $output = "" ]]
}
