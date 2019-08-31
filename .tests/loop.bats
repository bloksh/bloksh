#!/usr/bin/env bats

BLOKSH_NOCOLOR=true
BLOKSH_BLOKS="$BATS_TEST_DIRNAME/bloks"
BLOKSH_SECRETS="$BATS_TEST_DIRNAME/secrets"
# shellcheck source=../bloksh.bash
source "$BATS_TEST_DIRNAME/../bloksh.bash" noop

bloks_ini_one_existing () {
	echo 'example' >"$BLOKSH_BLOKS_INI"
}

bloks_ini_one_existing_one_dont () {
	cat <<- EOF >"$BLOKSH_BLOKS_INI"
		example;i am a comment
		i_dont_exist=blabla; another comment

		; lonely comment
	EOF
}

echo_blok_name () {
	echo "$BLOKSH_NAME"
}

@test "loop: missing bloks.ini" {
	[[ -f $BLOKSH_BLOKS_INI ]] && rm "$BLOKSH_BLOKS_INI"
	! [[ -r $BLOKSH_BLOKS_INI ]]

	run _bloksh_loop echo_blok_name

	[[ $status -eq 3 ]]
	[[ ${#lines[@]} = 0 ]]
}

@test "loop: empty bloks.ini" {
	: >"$BLOKSH_BLOKS_INI"
	[[ -r $BLOKSH_BLOKS_INI ]]

	run _bloksh_loop echo_blok_name

	[[ $status -eq 0 ]]
	[[ ${#lines[@]} = 0 ]]
}

@test "loop: one blok" {
	bloks_ini_one_existing

	run _bloksh_loop echo_blok_name

	[[ $status -eq 0 ]]
	[[ ${lines[0]} = example ]]
	[[ ${#lines[@]} = 1 ]]
}


@test "loop: one existing blok and one missing - loop just fine" {
	bloks_ini_one_existing_one_dont

	run _bloksh_loop true

	[[ $status -eq 0 ]]
	[[ $output = "" ]]
}

@test "loop: one existing blok and one missing - display error if internal command fail" {
	bloks_ini_one_existing_one_dont

	run _bloksh_loop false

	[[ $status -eq 0 ]]
	[[ $output = "[BLOKSH] Errors in bloks: example i_dont_exist" ]]
}

@test "loop: one existing blok and one missing - calling function on everyone" {
	bloks_ini_one_existing_one_dont

	run _bloksh_loop echo_blok_name

	[[ $status -eq 0 ]]
	[[ ${lines[0]} = example ]]
	[[ ${lines[1]} = i_dont_exist ]]
	[[ ${#lines[@]} = 2 ]]
}
