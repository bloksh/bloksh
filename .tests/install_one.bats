#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
BLOKSH_NONINTERACTIVE=true
BLOKSH_BLOKS="$BATS_TEST_DIRNAME/bloks"
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

@test "install_one: existing blok, without .install" {
	_bloksh_set_variables example

	run _bloksh_install_one

	[[ $status -eq 0 ]]
	[[ ${#lines[@]} = 0 ]]
}

@test "install_one: existing blok, with .install" {
	_bloksh_set_variables example_w_install

	run _bloksh_install_one

	[[ $status -eq 42 ]]
	[[ ${lines[1]} = 'i am install' ]]
	[[ ${#lines[@]} = 2 ]]
}

@test "install_one: missing blok, faulty url" {
	_bloksh_set_variables i_dont_exist "$BATS_TEST_DIRNAME/not/existing/repository" || true

	run _bloksh_install_one

	[[ $status -eq 1 ]]
	[[ ${lines[0]} =~ ^fatal: ]]
	! [[ -d "$BATS_TEST_DIRNAME/bloks/i_dont_exist" ]]
}

@test "install_one: missing blok, fake install with git mock" {
	git () {
		return 0 # pretend have done things
	}
	_bloksh_set_variables i_dont_exist "$BATS_TEST_DIRNAME/not/existing/repository" || true

	run _bloksh_install_one

	[[ $status -eq 0 ]]
	[[ ${#lines[@]} -eq 0 ]]
}
