#!/usr/bin/env bash
# Must fail shellcheck and nothing else: it parses and is shfmt-clean, but the unquoted
# expansion below splits and globs (SC2086)
rm -- $1
