# Bloksh

[![Build Status](https://travis-ci.org/bloksh/bloksh.svg)](https://travis-ci.org/bloksh/bloksh)

> An unified way to install things on bash!

## Install

It is recommended to use git, or you'll need to install/update _bloks_ manually. Which is unfortunate.

* Clone this repository.
* Setup your `bloks.ini` file (see §The _bloks_).
* `source bloksh.bash`.
* `bloksh_install` loops over the _bloks_, (re-)`.install` them, injects itself in `.bashrc`, restart console.

## Update

* `bloksh_update` updates this repository, loops over the _bloks_, looks for new commits, rerun `.install` if needed, restart console.

## The _bloks_

By default, no _blok_ is installed. In order to do so, create the `bloks/bloks.ini` file, and fill it:

```ini
blok_name=git@host:vendor/blok_name.git ; this will checkout 'master' (and not the default branch for the remote)
another_blok=git@host:vendor/another_blok.git#v0.2.1 ; will checkout this tag
local_blok ; no need for git repository
; etc...
```

The order is kept when executing _bloks_.

Run `bloksh_install` to download and install the _blok(s)_ added.
For a faster experience, only the selected branch is cloned, with a depth of 1. If you need to work with the repository, you may need to run something like `git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*" && git fetch --unshallow`.

Note that _bloks_ removed from `bloks.ini` are not deleted from filesystem, but they are not loaded anymore.

### Anatomy

* The blok directory is added to `$PATH`.
* `.install` is run by `bloks_install` in its own sub-shell, from the directory of the _blok_ (and re-run after a successful update).
* `.bashrc` is sourced from its homonym.

All the scripts are optional, and they must be idempotent (that is: running `.install` multiple times must be fine).
It is recommended to _not_ set the executable bit, in order to avoid accidental execution from the interactive shell.

These env variables are set and exported when sourcing/running the mentioned scripts:

* `BLOKSH_NAME` - from `bloks.ini`.
* `BLOKSH_PATH` - the absolute path to the _blok_, corresponds to `bloks/$BLOKSH_NAME`.
* `BLOKSH_SECRET_PATH` - the absolute path to the _blok_'s private space, corresponds to `secrets/$BLOKSH_NAME`. If your _blok_ plans to use it, it should `mkdir -p` its way in.
* `BLOKSH_GIT_URL` - from `bloks.ini`.
* `BLOKSH_GIT_BRANCH` - from `bloks.ini`, after the #, if present.

From your `.bashrc` files you will have access to some juicy functions:

* `bloksh_source <file>` - will source `<file>` if it is readable, relative paths are resolved from `$BLOKSH_PATH`.
* `bloksh_add_to_path <dir>` - will add `<dir>` at the beginning of `$PATH`.

## Custom directories

By default, _bloks_ and secrets are located respectively in the subdirectories `bloks` and `secrets` of this repository.
This is customizable with the variables `BLOKSH_BLOKS` and `BLOKSH_SECRETS`, that must be set **before** sourcing `bloksh.bash`.
The location of the `bloks.ini` file can be customized with the variable `BLOKSH_BLOKS_INI` (defaults to `$BLOKSH_BLOKS/bloks.ini`).
