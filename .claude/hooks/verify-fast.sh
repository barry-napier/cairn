#!/usr/bin/env bash
out=$(npm run verify:fast 2>&1)
ec=$?
if [ $ec -ne 0 ]; then
  echo "$out" | tail -50 >&2
  exit 2
fi
echo "$out" | tail -50
exit 0
