# PRD: CAIRN

> **Pattern name:** CAIRN
> **Type:** Documentation + reference implementation (v1 scope)
> **Target stack:** Vite+ · React 19 · TypeScript strict · Convex · Better Auth · Vercel · Claude Code
> **Audience:** Claude Code (and any future agent reading this for implementation)
> **Status:** Ready to implement

---

## Problem

Working with AI coding agents on real codebases has a structural failure mode: **the agent has no reliable way to validate its own work**. It writes code that looks correct, declares the task done, and moves on. "Looks correct" and "is correct" are different things. The cost is paid downstream — broken types reach commits, broken tests reach pushes, broken builds reach production, schema drift reaches users.

The conventional response is to give the agent more context: longer `CLAUDE.md`, more detailed instructions, more examples. This is the wrong fix. No amount of instruction prevents an agent from hallucinating a function signature, drifting from a Convex schema, or skipping a typecheck. The agent must be **told it's wrong by something other than itself** — by deterministic verifiers running in feedback loops the agent cannot bypass.

The pattern exists in classical engineering — static analysis, automated tests, pre-commit hooks, CI pipelines, branch protection. Tools exist. Discipline exists. What's missing is **formalization**: a single, opinionated, repeatable pattern wired specifically for the bnapier.dev stack and Claude Code, with every layer of enforcement defined, every script standardised, every gate documented. Without that pattern, every new app re-derives the same configuration from scratch — slowly, inconsistently, and usually under-specified.

The goal of this PRD is to define that pattern, called **CAIRN**, as a documented reference implementation that any new bnapier.dev app can adopt by copying the pattern into place. CAIRN is the verification scaffolding that surrounds AI-driven development across the bnapier.dev portfolio.

---

## Solution

CAIRN is a documented, opinionated verification stack specifically designed for AI-driven coding on the bnapier.dev standardised stack. It enforces correctness at seven gates, each independent, each bypass-resistant by something the agent cannot talk its way past.

From the developer's perspective, adopting CAIRN means: clone or copy the reference implementation into a new app, configure two environment-specific values, and immediately have a fully-enforced harness where Claude Code cannot ship broken code — to commit, to push, to merge, or to deploy.

From the agent's perspective, CAIRN provides: clear instructions in `CLAUDE.md` describing the verification contract, hook-driven feedback loops that inject errors into the agent's context as soon as they occur, and irrevocable enforcement gates downstream that catch anything the agent slips past locally.

The pattern is composed of four conceptual layers:

1. **Instruction layer** — `CLAUDE.md` and progressive-disclosure skills that tell the agent the rules.
2. **In-loop enforcement** — Claude Code hooks (`PostToolUse`, `Stop`, `PreToolUse`) that run verifiers as the agent works and inject failures into context.
3. **Local enforcement** — Vite+ managed git hooks (`.vite-hooks/`, installed by `vp config`) + commitlint that gate commits and pushes regardless of how the code was written.
4. **Authoritative enforcement** — GitHub Actions, branch protection, and Vercel build gates that run on infrastructure the agent cannot bypass.

All layers call the same `npm run verify:*` script contract, so the verification logic lives in exactly one place and every gate runs the same checks at the appropriate scope and depth.

The dev/prod pipeline split is built in: a "dev pipeline" gates merges to `main` with fast feedback, and a "prod pipeline" gates production deploys with strict checks. Two Convex deployments (dev and prod) prevent schema disasters from reaching users.

The deliverable for v1 is a **documentation repository** at `github.com/barry-napier/cairn` containing:

- A canonical `README.md` explaining the pattern and decision rationale
- A reference implementation directory containing every config file, script, and hook required
- Step-by-step adoption guide for new apps
- Step-by-step adoption guide for retrofitting existing apps
- A verification checklist for confirming a correctly-installed CAIRN

The first real-world use is to retrofit one existing app (`prompts.bnapier.dev` or `auth.bnapier.dev`) and document any deviations or gotchas encountered. Future scope (out of v1) includes a template repo, a scaffold CLI, and an npm package — each gated on lessons learned from manual adoption.

---

## User Stories

The "user" here is the developer (Barry) adopting CAIRN into a bnapier.dev app, and the "agent" is Claude Code operating inside that app. Stories cover both perspectives.

### Adoption — new apps

1. As a developer starting a new bnapier.dev app, I want a single canonical pattern to follow, so that I don't re-derive verification scaffolding from scratch every time.
2. As a developer starting a new bnapier.dev app, I want a documented adoption guide with step-by-step instructions, so that I can stand up a fully-enforced stack in under 90 minutes.
3. As a developer starting a new bnapier.dev app, I want every config file, hook script, and CI workflow available as copy-paste reference, so that I am not transcribing from memory.
4. As a developer starting a new bnapier.dev app, I want a verification checklist after installation, so that I know CAIRN is correctly wired before I write any feature code.
5. As a developer starting a new bnapier.dev app, I want CAIRN to assume my exact stack (Vite+, React 19, TypeScript strict, Convex, Better Auth, Vercel), so that I am not paying an abstraction tax for flexibility I do not need.

### Adoption — retrofitting existing apps

6. As a developer with an existing bnapier.dev app, I want a separate retrofit guide, so that I can apply CAIRN incrementally without breaking the in-flight project.
7. As a developer retrofitting an existing app, I want guidance on what order to introduce gates, so that I am not blocked by pre-existing failures piling up at once.
8. As a developer retrofitting an existing app, I want explicit guidance on dealing with pre-existing typecheck or test failures, so that adoption is not gated on a full repo audit.
9. As a developer retrofitting an existing app, I want each enforcement layer to be independently adoptable, so that I can ship value at each step rather than all-or-nothing.

### Instruction layer

10. As a developer, I want a canonical `CLAUDE.md` template with every rule earned by a real failure mode, so that the file remains short and high-signal.
11. As a developer, I want the `CLAUDE.md` to reference `npm run verify:*` scripts rather than duplicate their contents, so that the script contract is the single source of truth.
12. As a developer, I want the `CLAUDE.md` to explicitly call out Convex, Better Auth, and TypeScript strict mode rules, so that the agent does not reinvent conventions per session.
13. As an agent reading `CLAUDE.md`, I want the verification contract clearly stated, so that I know which scripts to run after edits and before declaring done.
14. As an agent reading `CLAUDE.md`, I want explicit "do not" rules for the most common failure modes, so that I can self-correct without waiting for hook feedback.

### In-loop enforcement (Claude Code hooks)

15. As an agent, I want a `PostToolUse` hook running `npm run verify:fast` after every Edit/Write/MultiEdit, so that I receive immediate feedback when I introduce a type error or lint violation.
16. As an agent, I want a `Stop` hook running `npm run verify:full` before I declare a task done, so that I cannot prematurely claim victory on broken code.
17. As an agent, I want a `PreToolUse` hook on Bash commands that blocks destructive operations (`rm -rf /`, force-push, schema replace, prod force-deploy), so that I cannot accidentally cause irreversible damage.
18. As an agent, I want hook output piped through `tail -50` or `tail -100`, so that long error logs do not consume my context window.
19. As a developer, I want a `SessionStart` hook that injects current branch, last commit, and uncommitted-files state into the agent context, so that the agent knows where the project currently stands without asking.
20. As a developer, I want all hook scripts to live under `.claude/hooks/` in plain JavaScript or shell, so that they are version-controlled, transparent, and auditable.
21. As a developer, I want hook scripts to exit 0 silently on success and exit non-zero with terse stderr on failure, so that the success case is free and the failure case is actionable.

### Script contract layer

22. As a developer, I want a standardised set of `npm run verify:*` scripts as the single source of truth for verification logic, so that every enforcement layer above runs the same checks.
23. As a developer, I want `verify:fast` to complete in under 10 seconds on a typical edit, so that the in-loop feedback loop does not slow agent work.
24. As a developer, I want `verify:full` to run all tests, build, and bundle checks, so that the Stop hook and pre-push gate catch what `verify:fast` does not.
25. As a developer, I want a `verify:dev` and `verify:prod` distinction, so that production-strict checks (full test suite, bundle size, prod schema dry-run) do not slow PR iteration.
26. As a developer, I want the script contract to use `npm-run-all` for parallel and serial composition, so that independent checks run concurrently and dependent checks run in order.
27. As a developer, I want individual script atoms (`verify:lint`, `verify:types`, `verify:convex`, `verify:test`, `verify:build`) callable independently, so that I can debug a single failing layer without running the whole stack.

### Local enforcement (vite-hooks + commitlint)

28. As a developer, I want a `.vite-hooks/pre-commit` running `vp staged` on every commit, so that broken code cannot enter the repo locally.
29. As a developer, I want `.vite-hooks/pre-push` running `npm run verify:full` on every push, so that broken pushes are caught before reaching CI.
30. As a developer, I want `vp staged` to re-stage auto-fix output automatically, so that there is no "unstaged changes" loop after format fixes.
31. As a developer, I want commitlint enforcing Conventional Commits format on every commit message, so that history is structured and changelogs are mechanically generatable.
32. As a developer, I want `vp staged` to scope linters and formatters to staged files, so that hooks stay fast on incremental changes.
33. As a developer, I want `vp check` to typecheck the whole project (not staged files), so that type-checking is correct rather than scoped-and-misleading.

### Authoritative enforcement (GitHub Actions + branch protection + Vercel)

34. As a developer, I want a GitHub Actions workflow `dev.yml` triggered on every PR to main, so that PRs cannot merge without passing dev-level verification.
35. As a developer, I want a separate GitHub Actions workflow `prod.yml` triggered on push to main, so that prod-level checks gate the production deploy without slowing PR iteration.
36. As a developer, I want branch protection on `main` requiring the dev pipeline to pass, so that no PR can merge with a failing build.
37. As a developer, I want branch protection requiring linear history and disallowing force pushes, so that `main` history remains clean and auditable.
38. As a developer, I want Vercel's `buildCommand` set to `npm run verify:dev && vite build` for previews, so that broken previews never produce a working URL.
39. As a developer, I want Vercel production deploys gated on the prod GitHub Actions workflow passing, so that broken code never reaches production users.
40. As a developer, I want CI workflows to use Node 22 with npm caching, so that pipeline runs are fast and reproducible.

### Dev/prod pipeline separation

41. As a developer, I want two Convex deployments (dev and prod) configured per app, so that schema mistakes during development cannot corrupt production data.
42. As a developer, I want preview Vercel deployments to point at the dev Convex deployment, so that PR previews are safe to break.
43. As a developer, I want production Vercel deployments to point at the prod Convex deployment, so that releases hit a stable backend.
44. As a developer, I want `verify:convex:dev` (using `convex dev --once --typecheck=enable`) to run on every commit, so that frontend/backend type drift is caught immediately.
45. As a developer, I want `verify:convex:prod` (using `convex deploy --dry-run --typecheck=enable`) to run on PR CI, so that schema migrations that would fail in production are caught before merge.
46. As a developer, I want the prod pipeline to include bundle size checks and full test coverage, so that performance and correctness regressions cannot reach users without being flagged.

### Skills and progressive disclosure

47. As a developer, I want CAIRN to ship with a starter set of Claude Code skills, so that the agent has structured knowledge of common tasks (Convex mutations, Better Auth flows, debugging types) without bloating `CLAUDE.md`.
48. As a developer, I want each skill to be a self-contained directory under `.claude/skills/<name>/SKILL.md`, so that skills are individually addable and removable.
49. As a developer, I want skill descriptions to follow the "Use when X" trigger format, so that the agent loads them only when contextually relevant.
50. As a developer, I want skills to follow Pocock's "earn each line" discipline, so that every skill exists because of a real failure mode.

### Documentation and adoption

51. As a developer, I want a top-level `README.md` in the CAIRN repo that explains the pattern in under 5 minutes of reading, so that future-me or any contributor can orient quickly.
52. As a developer, I want a `docs/architecture.md` explaining the four layers and their interaction, so that the design rationale is captured beyond just the configs.
53. As a developer, I want a `docs/adoption-new.md` for greenfield app adoption, so that I can follow it linearly when starting a new app.
54. As a developer, I want a `docs/adoption-retrofit.md` for existing app adoption, so that I can apply CAIRN incrementally to in-flight projects.
55. As a developer, I want a `docs/checklist.md` enumerating "what good looks like" after install, so that I can confirm correctness without re-reading the entire pattern.
56. As a developer, I want a `docs/rationale.md` linking each gate to its motivating failure mode, so that future-me does not delete a rule whose purpose has been forgotten.
57. As a developer, I want every doc file to link to the exact reference implementation files, so that doc and reference cannot drift independently.
58. As a developer, I want a `CHANGELOG.md` tracking changes to the pattern, so that downstream apps can see what is new and decide whether to adopt it.

### Verification of correct installation

59. As a developer who has just installed CAIRN, I want to deliberately introduce a type error and confirm it is caught at every gate (in-loop, pre-commit, CI, Vercel), so that I know the stack is fully wired.
60. As a developer who has just installed CAIRN, I want to deliberately attempt a non-conventional commit message and confirm it is rejected, so that I know commitlint is wired.
61. As a developer who has just installed CAIRN, I want to deliberately attempt a force-push and confirm it is rejected by branch protection, so that I know GitHub-side enforcement is correct.
62. As a developer who has just installed CAIRN, I want to deliberately make a Convex schema change that would fail in production and confirm it is caught by `verify:convex:prod`, so that I know schema safety is wired.

### Failure handling and observability

63. As a developer, I want hook failures to log to a `.cairn/logs/` directory in the consumer repo, so that I can inspect historic failures without re-running them.
64. As a developer, I want each gate's expected duration documented, so that "this is slow" can be measured against the design budget rather than vibes.
65. As a developer, I want a documented escape hatch for emergency `--no-verify` use, so that genuine emergencies are possible without abandoning the pattern.
66. As a developer, I want CI failures to surface useful error context (last 100 lines of relevant output), so that debugging from GitHub UI is possible.

### Future scope acknowledgement (informational)

67. As a developer, I want the v1 PRD to acknowledge planned graduations to a template repo, scaffold CLI, and npm package, so that the long-term vision is captured.
68. As a developer, I want explicit entry criteria for each future graduation (e.g., "graduate to template repo after manually copying CAIRN into 3 apps"), so that I do not prematurely build tooling.

---

## Implementation decisions

### Architectural

- **Four-layer enforcement model.** Instruction → in-loop → local → authoritative. Each layer is independently bypassable by the layer above; combined, they are functionally airtight. This mirrors the principle that AGENTS.md/CLAUDE.md is instruction, not enforcement — real enforcement lives in git, CI, and infra.
- **Single script contract.** All gates call `npm run verify:*` scripts. The verification logic lives in exactly one place. This is non-negotiable: any rule that lives in a hook or CI workflow but not in the script contract is a duplication waiting to drift.
- **Stack lock-in.** CAIRN assumes Vite+, React 19, TS strict, Convex, Better Auth, Vercel. No abstraction for hypothetical alternatives. Loosening the assumptions is a future-scope concern, not v1.
- **Dev/prod pipeline split.** Two pipelines, two Convex deployments, two Vercel environments. Dev pipeline gates merges (fast feedback). Prod pipeline gates deploys (strict checks). Critical for preventing the "PR iteration is slow because we run prod-level checks on every push" failure mode.
- **Documentation as deliverable.** v1 is a documentation repo, not a template, CLI, or package. The pattern must be proven by manual application before it earns automation.
- **Pocock's PRD discipline applied to all rules.** Every rule in `CLAUDE.md`, every gate, every config file traces to a specific failure mode. Rules without traceable motivation are removed.

### Tooling choices

- **Vite+ managed hooks (`.vite-hooks/`) over Husky/lefthook.** Bundled with Vite+ via `vp config`, no extra dependency, single source of truth alongside the rest of the toolchain. `vp staged` provides staged-file linting and auto-restage out of the box.
- **commitlint with `@commitlint/config-conventional`.** Industry-standard Conventional Commits enforcement.
- **Biome over ESLint + Prettier.** Already bundled in Vite+. Faster. Single tool, single config. ESLint plugins are not needed for the bnapier.dev stack.
- **Vitest over Jest.** Bundled in Vite+. Native Vite/Vite+ integration. `--changed` flag for fast incremental runs.
- **GitHub Actions over alternative CI.** Native GitHub integration. Free for public repos and within Barry's existing usage tier.
- **Vercel for deploy.** Standard across all bnapier.dev apps. Native preview deploy per branch.
- **Convex CLI's `--typecheck=enable` flag.** Catches frontend/backend drift during dev verification. Convex's typed contract is the single most valuable verification primitive in the stack.

### Hook design

- **Hook output through `tail`.** `npm run verify:fast 2>&1 | tail -50` keeps the most recent (typically root-cause) errors and avoids context bloat from cascading typecheck failures.
- **Exit code semantics.** Exit 0 = silent success, exit 2 = blocking error injected into agent loop, exit 1 = non-blocking warning. This is the Claude Code hook convention.
- **`PreToolUse` blocks dangerous commands by default.** Pattern matches against `rm -rf /`, `git push --force`, `git reset --hard origin`, `convex import --replace`, `vercel --prod --force`. Patterns are extensible per app.
- **`Stop` hook is non-negotiable.** It's the single gate that prevents the "agent declares done on broken code" failure mode.

### Pipeline design

- **Pre-commit budget: under 15 seconds.** Anything slower causes developers (and agents) to use `--no-verify`, which defeats the gate.
- **Pre-push budget: under 45 seconds.** Slower than pre-commit because it includes the full verify, but still fast enough that the developer waits rather than walks away.
- **Dev CI budget: under 5 minutes.** Includes full test suite, bundle check, schema dry-run.
- **Prod CI budget: under 10 minutes.** Adds coverage and any prod-only gates.
- **Branch protection is mandatory.** Without it, the entire authoritative layer is theatre.

### What is deliberately not included in v1

- No template repo (deferred until pattern is copied 2-3 times manually).
- No scaffold CLI (deferred until template is stable).
- No npm package (deferred until shared runtime config exists across multiple apps).
- No semantic verification / LLM-as-judge tier (the deterministic stack catches 90% of issues; tier 5 is a future enhancement).
- No multi-agent coordination (out of scope — CAIRN is for solo Claude Code workflows).
- No mutation testing (deferred — Stryker/mutmut are valuable but not v1-critical).
- No pre-built skills beyond a starter set (more skills are added in future versions as failure modes earn them).

---

## Testing decisions

### What makes a good test

- **Test external behavior, not implementation details.** A good test for CAIRN is one that confirms a real-world scenario works (or fails as expected). Bad tests inspect internal config structure or mock too aggressively.
- **CAIRN is itself the system under test.** The test for CAIRN is not "does this hook script parse JSON correctly" but "does a deliberately introduced type error get caught at every gate."
- **End-to-end verification scenarios are primary.** Each scenario in the verification checklist (user stories 59–62) is itself a test of the pattern.
- **Determinism matters.** Tests must produce the same result on every run. Flaky tests are a louder signal than failing tests because they erode trust in the entire stack.

### Verification scenarios (each is a test of the pattern)

- Scenario A: introduce a type error → confirm caught by Claude Code `PostToolUse` hook → confirm caught by vite-hooks pre-commit → confirm caught by CI → confirm Vercel build fails.
- Scenario B: introduce a non-conventional commit message → confirm rejected by commitlint at commit-msg hook.
- Scenario C: attempt force-push to main → confirm rejected by branch protection.
- Scenario D: introduce a Convex schema change incompatible with production → confirm caught by `verify:convex:prod` in prod pipeline.
- Scenario E: agent attempts destructive bash command → confirm blocked by `PreToolUse` hook.
- Scenario F: agent declares task done with failing tests → confirm `Stop` hook re-injects errors and prevents premature completion.
- Scenario G: pre-commit hook completes in under 15 seconds on a typical 3–5 file change set.
- Scenario H: full pipeline (commit → push → PR → CI → merge → prod deploy) succeeds end-to-end on a clean change.

### Prior art

- Pocock's `setup-pre-commit` skill — pre-commit pattern with lint-staged and Prettier.
- Pocock's `git-guardrails-claude-code` skill — Claude Code hook for blocking dangerous git commands.
- Anthropic's harness design documentation — long-running agent harness patterns.
- HumanLayer's "skill issue" framing — agent failures as configuration problems.
- Osmani's "Agent Harness Engineering" essay — the canonical taxonomy this PRD is built on.

### Tests that should NOT be written

- Unit tests for individual hook scripts. They are short, declarative, and tested by the end-to-end scenarios.
- Tests for npm scripts in isolation. The scripts are wrappers around tools that are themselves tested upstream.
- Mock-heavy tests of CI workflows. CI is tested by running it against real PRs.

### How the pattern itself is "tested" (proven correct)

- v1 is proven correct by being applied end-to-end to one real bnapier.dev app, with each verification scenario passing.
- Adoption time is measured. Target: under 90 minutes for retrofit, under 60 minutes for greenfield.
- Pre-commit and pre-push durations are measured against the budgets in implementation decisions.
- Any failure mode discovered during real-world use is documented in `CHANGELOG.md` and resolved in the next pattern version.

---

## Out of scope

- Apps not on the standard bnapier.dev stack (Postgres, MySQL, Express backends, Next.js, etc.). CAIRN is deliberately stack-locked.
- Multi-developer / multi-agent workflows. CAIRN v1 assumes a solo developer + Claude Code.
- Aflac internal use. Aflac's tooling, security, and compliance constraints are different. A CAIRN-Aflac variant is a separate project.
- Other AI coding agents (Cursor, Codex, Aider, Cline). v1 is Claude Code-only. The vite-hooks/CI/Vercel layers happen to be agent-agnostic, but the in-loop hook layer is Claude Code-specific.
- Performance benchmarking infrastructure. Bundle size checks and timing budgets are in scope; full perf regression infrastructure is not.
- Visual regression testing. Out of scope until a real failure mode justifies it.
- Telemetry / observability of agent behavior over time. Interesting but not v1.
- Skill authoring tooling. The starter skills are documented; a richer skills system is a future concern.
- Migration from another harness pattern. v1 assumes either greenfield or "no current harness" as the starting state.

---

## Further notes

### Naming and family

CAIRN extends the existing CAIRN/Sevro architectural family. CAIRN was originally named for the Northern Irish cairn metaphor — a stack of marker stones placed deliberately by past travellers to guide future ones. The pattern is a literal cairn for future bnapier.dev apps: each rule is a stone placed because of a past failure, and the stack of stones marks the path through familiar terrain.

### Relationship to Sevro

Sevro is the agentic orchestration layer (Claude Code + launchd cron + MCP + bash). CAIRN is the verification scaffolding _inside_ a Sevro-orchestrated workflow. Sevro is "what the agent does." CAIRN is "what stops the agent from doing it wrong." The two are complementary; neither subsumes the other.

### The ratchet philosophy

CAIRN is a living pattern. Every rule should trace to a real failure. Every rule that the model has gotten reliably good at can be removed. Adding rules is easy; pruning rules is the harder discipline. v1 ships with the minimum set of rules that have been earned by failures observed in actual use. Future versions add or remove rules based on lessons learned.

### Adoption expectations

- **First app:** ~90 minutes manual install, following the documented adoption guide step-by-step. Expect to find at least one gotcha; document it in `CHANGELOG.md`.
- **Second app:** ~45 minutes. Pattern is now familiar, gotchas from app one are documented.
- **Third app:** ~30 minutes. By this point, the pattern has earned a template repo (graduation criterion for v2).

### Future graduations and entry criteria

- **v2 — template repo (`bnapier/cairn-template`).** Entry criterion: CAIRN has been manually applied to at least 3 apps without significant per-app variation.
- **v3 — scaffold CLI (`npx create-bnapier-app`).** Entry criterion: template repo has been used to start at least 2 new apps without modification.
- **v4 — npm package (`@bnapier/cairn`).** Entry criterion: at least one piece of CAIRN logic exists that benefits from being version-controlled and synchronously updated across apps (e.g., shared hook scripts, shared verify orchestration).

Each graduation must be earned by real-world use, not anticipated by speculation.

### Reference repository structure (target)

```
github.com/barry-napier/cairn/
├── README.md
├── CHANGELOG.md
├── docs/
│   ├── architecture.md
│   ├── adoption-new.md
│   ├── adoption-retrofit.md
│   ├── checklist.md
│   └── rationale.md
├── reference/
│   ├── package.json.snippet
│   ├── .vite-hooks/ (managed by `vp config`)
│   ├── commitlint.config.js
│   ├── vercel.json
│   ├── .github/workflows/dev.yml
│   ├── .github/workflows/prod.yml
│   ├── .claude/
│   │   ├── settings.json
│   │   ├── hooks/
│   │   │   ├── block-dangerous.js
│   │   │   └── session-context.js
│   │   └── skills/
│   │       ├── convex-mutations/SKILL.md
│   │       └── debugging-types/SKILL.md
│   └── CLAUDE.md
└── LICENSE
```

### What success looks like for v1

- One real bnapier.dev app is running CAIRN end-to-end.
- All eight verification scenarios pass on that app.
- Pre-commit, pre-push, dev CI, and prod CI all run within their budgets.
- Adoption notes, gotchas, and any pattern revisions are captured in `CHANGELOG.md`.
- Future-Barry can re-adopt the pattern from documentation alone, without referring to memory.
