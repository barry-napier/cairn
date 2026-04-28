# CAIRN

> A verification scaffolding for AI-driven coding on the bnapier.dev stack.

CAIRN is a documented, opinionated set of enforcement gates wrapped around a single `npm run verify:*` script contract. It exists so Claude Code (or any agent operating inside one of these repos) cannot ship broken code — to commit, to push, to merge, or to deploy.

This repository is both the canonical reference and the GitHub template. To start a new app, click **Use this template** at the top of the GitHub page (or `gh repo create <name> --template barry-napier/cairn`). The harness is preinstalled; the post-clone steps are listed below.

**Stack assumed:** Vite+ · React 19 · TypeScript strict · Convex · Better Auth · Vercel · Claude Code. Anything outside that stack is out of scope.

For motivation, full requirements, and the design rationale, read [docs/PRD.md](docs/PRD.md).

---

## Why

Working with coding agents has a structural failure mode: the agent has no reliable way to validate its own work. It writes code that looks correct, declares the task done, and moves on. The cost is paid downstream — broken types reach commits, broken tests reach pushes, broken builds reach production, schema drift reaches users.

The conventional response — more `CLAUDE.md`, more examples, more instructions — is the wrong fix. Instructions cannot prevent hallucination. The agent has to be **told it is wrong by something other than itself**: deterministic verifiers running in feedback loops it cannot bypass.

CAIRN is the formalisation of that idea for one specific stack: every gate defined, every script standardised, every layer documented, no flexibility for hypothetical alternatives.

---

## The four layers

| Layer            | What it is                                       | What it catches                                                          | Bypassable by                |
| ---------------- | ------------------------------------------------ | ------------------------------------------------------------------------ | ---------------------------- |
| 1. Instruction   | [CLAUDE.md](CLAUDE.md), skills                   | The agent self-corrects before help arrives                              | The agent itself, easily     |
| 2. In-loop       | Claude Code hooks: PostToolUse, Stop, PreToolUse | Errors injected back into the agent's context the moment they appear     | The Claude Code harness only |
| 3. Local         | Git hooks via Vite+ (`vp config`) + commitlint   | Anything that escapes the loop, before it leaves the developer's machine | `--no-verify` (forbidden)    |
| 4. Authoritative | GitHub Actions, branch protection, Vercel build  | Anything that reaches the remote, irrespective of how it was authored    | Nothing the agent can reach  |

Each layer is independently bypassable by the layer above; combined, they are functionally airtight.

---

## The script contract

Every gate calls one of these. Verification logic lives in **exactly one place**.

| Script               | Used by                                  | What it runs                                             |
| -------------------- | ---------------------------------------- | -------------------------------------------------------- |
| `verify:fast`        | PostToolUse hook · pre-commit            | `vp check --fix` (oxlint + oxfmt + tsc on staged files)  |
| `verify:test`        | `verify:full` chain                      | `vp test` (Vitest, excludes `e2e/`)                      |
| `verify:e2e`         | `verify:dev` chain                       | Playwright                                               |
| `verify:convex:dev`  | `verify:full` chain                      | `convex dev --once --typecheck=enable`                   |
| `verify:convex:prod` | `verify:prod` chain                      | `scripts/verify-convex-prod.sh` (refuses anonymous mode) |
| `verify:build`       | `verify:full` chain                      | `tsc && vp build`                                        |
| `verify:full`        | Stop hook · pre-push                     | convex:dev + fast + test + build                         |
| `verify:dev`         | PR CI (`.github/workflows/dev.yml`)      | full + e2e                                               |
| `verify:prod`        | prod CI (planned, gated on Convex cloud) | dev + convex:prod                                        |

Anything not in this table is not a gate. Adding a new gate means adding a `verify:*` script first.

---

## Repository layout

This repo is the reference implementation. Adopters copy the relevant files directly.

```
cairn/
├── CLAUDE.md                          # the verification contract for the agent
├── README.md                          # this file
├── package.json                       # script contract lives here
├── commitlint.config.js
├── vercel.json
├── docs/
│   └── PRD.md                         # full requirements + design rationale
├── scripts/
│   └── verify-convex-prod.sh          # fails loud in anonymous mode
├── .github/workflows/
│   ├── dev.yml                        # PR gate → verify:dev
│   └── prod.yml                       # main gate → verify:dev (verify:prod once Convex cloud is live)
├── .claude/
│   ├── settings.json                  # hook wiring
│   └── hooks/
│       ├── block-dangerous.sh         # PreToolUse: blocks rm -rf /, force-push, schema replace, etc.
│       ├── session-context.sh         # SessionStart: branch / last commit / dirty state
│       ├── verify-fast.sh             # PostToolUse: runs verify:fast, exit 2 on failure
│       └── verify-full.sh             # Stop: runs verify:full, exit 2 on failure
├── convex/                            # backend lives here; convex/_generated is generated
└── e2e/                               # Playwright suites
```

---

## Adopting CAIRN in a new app (template flow)

```bash
gh repo create barry-napier/<app> --template barry-napier/cairn --private --clone
cd <app>
vp install
vp config                                  # reinstall .vite-hooks/ in the new clone
```

Then the per-app wiring (none of this is templatable — each app needs its own credentials):

```bash
# Convex
npx convex login                           # if not already
npx convex dev --once                      # creates dev cloud deployment
npx convex deploy                          # creates prod cloud deployment

# Better Auth secrets on Convex
npx convex env set BETTER_AUTH_SECRET "$(openssl rand -base64 32)" --prod
npx convex env set SITE_URL https://<app>.bnapier.dev --prod
# repeat without --prod for the dev deployment

# GitHub: clone branch protection from the template
gh api -X PUT repos/barry-napier/<app>/branches/main/protection \
  --input <(gh api repos/barry-napier/cairn/branches/main/protection)

# Convex deploy key for CI: dashboard → prod deployment → Settings → Deploy Keys
gh secret set CONVEX_DEPLOY_KEY -R barry-napier/<app>

# Vercel: import the repo in the dashboard, set VITE_CONVEX_URL + VITE_CONVEX_SITE_URL
```

Then change `index.html`'s `<title>`, edit `src/App.tsx` to whatever your app actually does, and you're building. Target time: under 15 minutes after `gh repo create`.

## Adopting CAIRN in an existing app

The retrofit path. `docs/adoption-retrofit.md` (forthcoming) covers it in full. The two non-obvious points:

- **Layers are independently adoptable.** Wire the script contract first, then the local hooks, then in-loop hooks, then CI/branch protection. Don't try to land all four in one PR.
- **Pre-existing failures are normal.** Expect a backlog the first time `verify:full` runs. Snapshot the failures, gate by gate, before flipping a layer to enforcing.

Target time: under 90 minutes retrofit.

---

## Verification scenarios

The pattern is "tested" by running each scenario against a real installation. Eight scenarios; each tests a single gate end-to-end.

| #   | Scenario                                                      | Gate exercised                       | Expected                                               |
| --- | ------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------ |
| A   | Edit code with a TS error                                     | PostToolUse                          | TS2322 injected back as blocking error                 |
| B   | `git commit -m "broken"`                                      | commit-msg                           | commitlint rejects "type may not be empty"             |
| C   | `git push --force` (or `rm -rf /`, `convex import --replace`) | PreToolUse                           | `block-dangerous.sh` blocks before the shell runs      |
| D   | Stage broken code and commit                                  | pre-commit                           | `verify:fast` fails, stash auto-reverts                |
| E   | Break Convex code, push                                       | pre-commit (or pre-push if it slips) | `verify:fast` (or `verify:full`) fails                 |
| F   | Push directly to main                                         | GitHub branch protection             | GH006: protected branch update failed                  |
| G   | Declare done with broken code                                 | Stop hook                            | `verify:full` injects failure, agent must keep working |
| H   | Pre-commit duration                                           | pre-commit budget                    | Under 15s wall-clock                                   |

Status on this repo: **all 8 PASS** (verified 2026-04-28). Convex prod deployment `festive-duck-897` is provisioned; `verify:prod` runs on every push to `main` against the actual deployment.

---

## Adoption philosophy

- **Earn each rule.** Every gate, every line in `CLAUDE.md`, every script entry traces to a real failure mode. Rules without traceable motivation are removed.
- **One source of truth.** Verification logic lives in `npm run verify:*`. Hooks and CI invoke; they do not duplicate.
- **No abstraction tax for flexibility you do not need.** Stack-locked is a feature.
- **Documentation as deliverable.** v1 ships when the pattern is proven by manual application to a real app. Templating, scaffold CLI, and npm packaging are deferred until the manual path has been walked at least three times.

---

## Status

- v1 ships when CAIRN has been used to start a real downstream app via the template flow. `todos.bnapier.dev` is the first.
- Documentation surface: README ✅ · PRD ✅ · architecture/adoption/checklist/rationale forthcoming.
- Convex cloud prod deployment: provisioned (`festive-duck-897`); `verify:prod` runs end-to-end on every push to `main`.
- GitHub template: enabled. Click **Use this template** to start a new app.

---

## License

TBD — internal use only until v1 ships.
