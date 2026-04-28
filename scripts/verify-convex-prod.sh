#!/usr/bin/env bash
# Runs `convex deploy --dry-run` against the configured Convex cloud
# deployment. Fails loud if the project is in anonymous/local mode,
# because `convex deploy` silently no-ops in that state and would let
# a broken schema reach production undetected.
set -euo pipefail

if [ -z "${CONVEX_DEPLOY_KEY:-}" ]; then
  deployment="${CONVEX_DEPLOYMENT:-}"
  if [ -z "$deployment" ] && [ -f .env.local ]; then
    deployment=$(grep -E '^CONVEX_DEPLOYMENT=' .env.local | tail -1 | cut -d= -f2- | tr -d '"' || true)
  fi

  if [ -z "$deployment" ] || [[ "$deployment" == anonymous:* ]]; then
    echo "verify:convex:prod cannot run: no CONVEX_DEPLOY_KEY, and CONVEX_DEPLOYMENT is empty or anonymous (\"$deployment\")." >&2
    echo "Local: 'npx convex login' and link a cloud deployment. CI: set CONVEX_DEPLOY_KEY in repo secrets." >&2
    exit 1
  fi
fi

exec npx convex deploy --dry-run --typecheck=enable
