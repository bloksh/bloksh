#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "msg: hide debug messages if \$BLOKSH_DEBUG is not active" {
	BLOKSH_DEBUG=
	run bloksh_msg debug "my debug message"
	[[ $status -eq 0 ]]
	[[ $output = "" ]]
}

@test "msg: show debug messages if \$BLOKSH_DEBUG is active" {
	BLOKSH_DEBUG=yep
	run bloksh_msg debug "my debug message"
	[[ $status -eq 0 ]]
	[[ $output = "[BLOKSH] my debug message" ]]
}

@test "msg: prepend blok name if \$BLOKSH_NAME is set" {
	BLOKSH_NAME=hellothere
	run bloksh_msg info "my info message"
	[[ $status -eq 0 ]]
	[[ $output = "[BLOKSH][hellothere] my info message" ]]
}
