#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

mock_git () {
	use_case="$1"
	git () {
		if [[ $3 = status ]]; then
			tr '\n' '\0' < "$BATS_TEST_DIRNAME/fixtures/git_status_$use_case"
		fi
	}
}

@test "git_fetch: 2 ahead, 3 behind, wd clean" {
	mock_git ahead_behind_clean

	run _bloksh_git_fetch

	[[ $status -eq 3 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '3' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: 2 ahead, 3 behind, wd dirty" {
	mock_git ahead_behind_dirty

	run _bloksh_git_fetch

	[[ $status -eq 3 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '3' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: 2 ahead, wd clean" {
	mock_git ahead_clean

	run _bloksh_git_fetch

	[[ $status -eq 3 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '0' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: 2 ahead, wd dirty" {
	mock_git ahead_dirty

	run _bloksh_git_fetch

	[[ $status -eq 3 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '0' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: 3 behind, wd clean" {
	mock_git behind_clean

	run _bloksh_git_fetch

	[[ $status -eq 0 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '3' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: 3 behind, wd dirty" {
	mock_git behind_dirty

	run _bloksh_git_fetch

	[[ $status -eq 4 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '3' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: 0 ahead, 0 behind, wd clean" {
	mock_git sync_clean

	run _bloksh_git_fetch

	[[ $status -eq 0 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '0' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: 0 ahead, 0 behind, wd dirty" {
	mock_git sync_dirty

	run _bloksh_git_fetch

	[[ $status -eq 4 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${lines[1]} = '0' ]]
	[[ ${#lines[@]} -eq 2 ]]
}

@test "git_fetch: remote is gone" {
	mock_git gone

	run _bloksh_git_fetch

	[[ $status -eq 5 ]]
	[[ ${lines[0]} = 'branch-name' ]]
	[[ ${#lines[@]} -eq 1 ]]
}
