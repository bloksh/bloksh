#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
BLOKSH_BLOKS="$BATS_TEST_DIRNAME/bloks"
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "resolve_path: file with absolute path" {
	file_path="$BATS_TEST_DIRNAME/i_dont_exist"
	run _bloksh_resolve_path "$file_path"

	[[ $status -eq 0 ]]
	[[ ${lines[0]} = "$file_path" ]]
	[[ ${#lines[@]} -eq 1 ]]
}

@test "resolve_path: file with absolute path while being in blok context" {
	_bloksh_set_variables example_w_install
	file_path="$BATS_TEST_DIRNAME/i_dont_exist"
	run _bloksh_resolve_path "$file_path"

	[[ $status -eq 0 ]]
	[[ ${lines[0]} = "$file_path" ]]
	[[ ${#lines[@]} -eq 1 ]]
}

@test "resolve_path: file within blok" {
	_bloksh_set_variables example_w_install
	run _bloksh_resolve_path .install

	[[ $status -eq 0 ]]
	[[ ${lines[0]} = "$BLOKSH_PATH/.install" ]]
	[[ ${#lines[@]} -eq 1 ]]
}

@test "resolve_path: file within nonexisting blok" {
	_bloksh_set_variables i_dont_exist || true
	run _bloksh_resolve_path .install

	[[ $status -eq 1 ]]
	error_regex='^\[i_dont_exist\] Missing from filesystem'
	[[ ${lines[0]} =~ $error_regex ]]
	[[ ${#lines[@]} -eq 1 ]]
}
