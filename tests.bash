#!/bin/bash

set -xe

bats .tests
shellcheck -x -- *.bash
(cd .tests && shellcheck -x -- *.bats)
