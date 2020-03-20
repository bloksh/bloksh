#!/bin/bash
BLOKSH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${BLOKSH_BLOKS:="$BLOKSH_ROOT/bloks"}"
: "${BLOKSH_SECRETS:="$BLOKSH_ROOT/secrets"}"
: "${BLOKSH_BLOKS_INI:="$BLOKSH_BLOKS/bloks.ini"}"

BLOKSH_ERRORS=()

_bloksh_msg () {
	local level="$1"; shift
	local color color_reset
	if [[ -z $BLOKSH_NOCOLOR ]]; then
		color_reset='\e[0m'
		case "$level" in
			debug) color='\e[1;30m';;
			info) color='\e[1;34m';;
			error) color='\e[1;31m';;
		esac
	fi
	if [[ $level = debug ]] && ! [[ $BLOKSH_DEBUG ]]; then
		return 0
	fi
	printf "%b%s%b\n" "$color" "[${BLOKSH_NAME:-bloksh}] $*" "$color_reset" >&2
}

_bloksh_show_errors () {
	[[ ${#BLOKSH_ERRORS[@]} -gt 0 ]] &&
		_bloksh_msg error "Errors in bloks: ${BLOKSH_ERRORS[*]}"
	BLOKSH_ERRORS=()
}

_bloksh_set_variables () {
	local git_url_regex='^([^#]+)(#(.*)){0,1}$'
	BLOKSH_NAME="${1:-BLOKSH_NAME}"
	BLOKSH_GIT_URL=
	BLOKSH_GIT_BRANCH=
	if [[ $2 =~ $git_url_regex ]]; then
		BLOKSH_GIT_URL="${BASH_REMATCH[1]}"
		BLOKSH_GIT_BRANCH="${BASH_REMATCH[3]:-master}"
	fi
	BLOKSH_PATH="$BLOKSH_BLOKS/$BLOKSH_NAME"
	BLOKSH_SECRET_PATH="$BLOKSH_SECRETS/$BLOKSH_NAME"
	export BLOKSH_PATH BLOKSH_NAME BLOKSH_SECRET_PATH BLOKSH_GIT_URL BLOKSH_GIT_BRANCH
	[[ -d $BLOKSH_PATH ]] || return 1
	bloksh_add_to_path "$BLOKSH_PATH"
}

_bloksh_clean_variables () {
	unset BLOKSH_PATH BLOKSH_NAME BLOKSH_SECRET_PATH BLOKSH_GIT_URL BLOKSH_GIT_BRANCH
}

_bloksh_loop () {
	[[ -r $BLOKSH_BLOKS_INI ]] || return 3
	local line_regex='^([^=[:space:];]+)(=([^[:space:];]*)){0,1}'
	while IFS= read -r -u3 line || [[ $line ]]; do
		_bloksh_msg debug "Analyzing bloks.ini: '$line'"
		[[ $line =~ $line_regex ]] || continue
		_bloksh_set_variables "${BASH_REMATCH[1]}" "${BASH_REMATCH[3]}"
		_bloksh_msg debug "Running '$*' for '$BLOKSH_NAME'"
		"$@" ||
			BLOKSH_ERRORS+=("$BLOKSH_NAME")
	done 3< "$BLOKSH_BLOKS_INI"
	_bloksh_clean_variables
	_bloksh_msg debug "Loop completed."
	_bloksh_show_errors
}

_bloksh_install_one () {
	if ! [[ -d $BLOKSH_PATH ]]; then
		_bloksh_confirm "Download and install '$BLOKSH_GIT_URL'?" &&
		git clone --branch "$BLOKSH_GIT_BRANCH" --depth 1 --recurse-submodules "$BLOKSH_GIT_URL" "$BLOKSH_PATH" ||
			return 1
	fi
	[ -r "$BLOKSH_PATH/.install" ] || return 0
	_bloksh_msg info 'Installing...'
	(cd "$BLOKSH_PATH" && exec "$SHELL" .install)
}

bloksh_install () {
	# untested
	_bloksh_loop _bloksh_install_one

	local DOTFILES=(.bashrc)
	for f in "${DOTFILES[@]}"; do
		if ! grep -q "/bloksh.bash" "$HOME/$f" &>/dev/null; then
			_bloksh_msg info "Adding bloksh to '$f'..."
			echo "source '$BLOKSH_ROOT/bloksh.bash'" >> "$HOME/$f"
			#TODO: add something like || echo "maybe you moved or removed bloksh"
		fi
	done
	bloksh_restart
}

_bloksh_update_one () {
	# untested
	_bloksh_git_update "$BLOKSH_PATH" "$BLOKSH_GIT_BRANCH"
	local update_result=$?
	case $update_result in
		3) # no updates
			return 0
			;;
		0)
			_bloksh_install_one
			;;
		*)
			return $update_result
			;;
	esac
}

_bloksh_git_fetch () {
	local branch_regex='^# branch\.head (.+)$'
	local ab_regex='^# branch\.ab \+([0-9]+) -([0-9]+)$'
	local modification_regex='^[^#]'
	git -C "$1" fetch &&
	git -C "$1" status --porcelain=v2 --branch --ignore-submodules=none --untracked-files=no -z |
		while IFS= read -r -d '' line; do # hope that --porcelain does not change order
			[[ $line =~ $branch_regex ]] && echo "${BASH_REMATCH[1]}"
			if [[ $line =~ $ab_regex ]]; then
				echo "${BASH_REMATCH[2]}" # commits behind
				[[ ${BASH_REMATCH[1]} -gt 0 ]] && return 3 # local repository is ahead
				remote_found=true
			fi
			[[ $line =~ $modification_regex ]] && return 4 # local modifications
			( [[ $remote_found ]] || return 5 ) # not tracking a remote branch
			# NOTE: We are setting exit code in a subshell as we need to continue the loop.
			# This condition will be checked at every iteration, the result will stick
			# if no other return condition is met.
		done
}

_bloksh_git_update () {
	# untested
	_bloksh_msg info "Checking for updates..."
	local repository="$1"
	local expected_branch="$2"
	if ! [[ -e $repository/.git ]]; then
		_bloksh_msg info "Unable to update: not a git repository"
		return
	fi
	local repository_status current_branch commits_behind
	repository_status="$(_bloksh_git_fetch "$repository")"
	repository_dirty_status=$?
	current_branch="$(echo "$repository_status" | head -1)"
	commits_behind="$(echo "$repository_status" | tail -1)"
	case $repository_dirty_status in
		3)
			_bloksh_msg error "Refuse to update: local repository has commits ahead"
			return 1
			;;
		4)
			_bloksh_msg error "Refuse to update: working directory is not clean"
			return 1
			;;
		5)
			_bloksh_msg error "Unable to update: not tracking any remote branch"
			return 1
			;;
		0)
			if [[ $expected_branch ]] && [[ $current_branch != "$expected_branch" ]]; then
				_bloksh_msg error "Refuse to update: branch '$current_branch' does not match bloks.ini"
				return 1
			fi
			if [[ $commits_behind -eq 0 ]]; then
				return 3 # no updates
			fi
			if _bloksh_confirm "Update '$BLOKSH_NAME' ($commits_behind commits)?"; then
				#TODO: or maybe git -C "$repository" pull --rebase=false &&
				git -C "$repository" reset --hard 'HEAD@{upstream}' &&
				git -C "$repository" submodule update --init --recursive &&
				return 0
			fi
			;;
		*)
			return $repository_dirty_status
	esac
}

bloksh_update () {
	# untested
	_bloksh_clean_variables
	BLOKSH_NAME=bloksh _bloksh_git_update "$BLOKSH_ROOT"
	[[ -e $BLOKSH_SECRETS/.git ]] && BLOKSH_NAME=secrets _bloksh_git_update "$BLOKSH_SECRETS"
	_bloksh_loop _bloksh_update_one
	bloksh_restart
}

_bloksh_resolve_path () {
	local path="$1"
	if [[ $BLOKSH_PATH ]] && [[ $path =~ ^[^/] ]]; then
		if ! [[ -d $BLOKSH_PATH ]]; then
			_bloksh_msg error "Missing from filesystem. Try with bloksh_install, or remove this blok from bloks.ini."
			return 1
		fi
		_bloksh_msg debug "Assembling relative path to '$path'"
		path="$BLOKSH_PATH/$path"
	fi
	echo "$path"
}

bloksh_source () {
	local path
	path="$(_bloksh_resolve_path "$1")" || return
	_bloksh_msg debug "Sourcing '$path' if exists"
	if [[ -r $path ]]; then
		# shellcheck source=/dev/null
		source "$path"
	fi
}

bloksh_add_to_path () {
	local path
	path="$(_bloksh_resolve_path "${1%/}")" || return
	_bloksh_msg debug "Adding '$path' to PATH"
	#TODO: if present, remove, then re-add as first
	case ":$PATH:" in
		*":$path:"*) :;; # already there
		*) export PATH="$path:$PATH";;
	esac
}

_bloksh_confirm () {
	# untested
	local default=${2:-y}
	local answers='[Yn]'
	[[ $default = n ]] &&
		answers='[yN]'
	if [[ -z $BLOKSH_NONINTERACTIVE ]]; then
		while true; do
			read -p "$1 $answers " -r
			[[ ${REPLY:=$default} =~ ^[YyNn]$ ]] && break
		done
	else
		REPLY=$default
	fi
	[[ $REPLY =~ ^[Yy]$ ]]
}

bloksh_restart () {
	# untested
	_bloksh_clean_variables
	_bloksh_msg info "Restarting shell..."
	exec "$SHELL"
}


# untested
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then # sourced
	[[ $1 == 'noop' ]] && return #NOTE: could be extended as an alternative to BLOKSH_SOURCED_BY
	BLOKSH_SOURCED_BY="$(basename "${BASH_SOURCE[1]}")" # name of the file that sourced this file
	if [[ $BLOKSH_SOURCED_BY ]]; then
		_bloksh_clean_variables
		_bloksh_msg debug "'$(basename "${BASH_SOURCE[0]}")' sourced by '$BLOKSH_SOURCED_BY'"
		_bloksh_loop bloksh_source "$BLOKSH_SOURCED_BY" # source homonym file for each blok
	fi
fi
