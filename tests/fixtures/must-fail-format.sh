#!/usr/bin/env bash
# Must fail shfmt and nothing else: it parses and lints clean, but is indented by four
if true; then
    echo "four-space indent"
fi
