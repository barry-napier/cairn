#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks destructive commands.
set -euo pipefail

input="$(cat)"
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

case "$command" in
  *"rm -rf /"*|*"rm -rf ~"*|*"rm -rf \$HOME"*) block "rm -rf on root/home" ;;
  *"git push --force"*|*"git push -f "*) block "force push" ;;
  *"git reset --hard origin"*) block "hard reset to origin" ;;
  *"git push origin "*main*--force*|*"git push --force origin main"*) block "force push to main" ;;
  *"convex import --replace"*) block "convex schema replace" ;;
  *"convex deploy --prod --force"*|*"vercel --prod --force"*) block "forced prod deploy" ;;
  *":(){:|:&};:"*) block "fork bomb" ;;
esac

exit 0
