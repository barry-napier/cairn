#!/usr/bin/env bash
out=$(npm run verify:full 2>&1)
ec=$?
if [ $ec -ne 0 ]; then
  echo "$out" | tail -100 >&2
  exit 2
fi
echo "$out" | tail -100
exit 0
