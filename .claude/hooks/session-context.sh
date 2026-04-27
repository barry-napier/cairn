#!/usr/bin/env bash
# SessionStart hook. Injects current repo state into agent context.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

branch=$(git rev-parse --abbrev-ref HEAD)
last_commit=$(git log -1 --format='%h %s' 2>/dev/null || echo "no commits")
status=$(git status --short)

cat <<EOF
## Repo state

- Branch: $branch
- Last commit: $last_commit
- Uncommitted changes:
$(if [ -z "$status" ]; then echo "  (none)"; else echo "$status" | sed 's/^/  /'; fi)
EOF
