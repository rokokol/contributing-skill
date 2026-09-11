#!/usr/bin/env bash
# Must fail `bash -n`: the if below is never closed
if true; then
  echo unterminated
