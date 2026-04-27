# CAIRN

Verification contract for this app. The harness gates code at four layers: instructions (this file), Claude Code hooks, local git hooks, and CI. All gates call the same `npm run verify:*` script contract — use those, don't invoke tools directly.

## Verification contract

- `npm run verify:fast` — vp check with auto-fix; runs after every Edit/Write via PostToolUse hook.
- `npm run verify:test` — Vitest unit/integration; excludes `e2e/`.
- `npm run verify:e2e` — Playwright; auto-starts dev server.
- `npm run verify:convex:dev` — convex codegen + typecheck against local deployment.
- `npm run verify:convex:prod` — convex deploy --dry-run; catches schema migrations that would fail in prod.
- `npm run verify:full` — convex:dev + fast + test + build; runs at Stop hook and pre-push.
- `npm run verify:dev` — full + e2e; PR CI tier.
- `npm run verify:prod` — dev + convex:prod; production deploy tier.

Before declaring a task done: `verify:full` must pass. The Stop hook enforces this; do not work around it.

## Stack rules

- **Convex.** Backend code lives in `convex/`. Generated files in `convex/_generated/` are committed but auto-formatted — do not hand-edit. The convex dir has its own `tsconfig.json` with node types; root tsconfig does not.
- **Better Auth.** Wired via `@convex-dev/better-auth`. Auth state owned by the component (its own tables, not in `schema.ts`). Required env vars on the Convex deployment: `BETTER_AUTH_SECRET`, `SITE_URL`. Set via `npx convex env set`, never hardcode.
- **Vite+.** All package manager operations through `vp` wrappers, not raw npm/pnpm. Do not install `vitest` directly — it ships through the `vite-plus-test` override. Importing test utilities: `from "vite-plus/test"`, not `from "vitest"`.
- **TypeScript.** Strict mode is on. `noUnusedLocals` and `noUnusedParameters` are enforced — prefix intentionally unused with `_`.

## Do not

- Use `git push --no-verify` or `git commit --no-verify` to bypass gates. If a gate fails, fix the cause.
- Edit files under `convex/_generated/` or `dist/` by hand; they regenerate.
- Add `vitest` or `vite` as direct dependencies; both come from the Vite+ overrides.
- Commit secrets to `.env.local`; secrets go on the Convex deployment via `npx convex env set`.
- Skip Conventional Commits format — the commit-msg hook will reject anything else.

<!--VITE PLUS START-->

# Using Vite+, the Unified Toolchain for the Web

This project is using Vite+, a unified toolchain built on top of Vite, Rolldown, Vitest, tsdown, Oxlint, Oxfmt, and Vite Task. Vite+ wraps runtime management, package management, and frontend tooling in a single global CLI called `vp`. Vite+ is distinct from Vite, but it invokes Vite through `vp dev` and `vp build`.

## Vite+ Workflow

`vp` is a global binary that handles the full development lifecycle. Run `vp help` to print a list of commands and `vp <command> --help` for information about a specific command.

### Start

- create - Create a new project from a template
- migrate - Migrate an existing project to Vite+
- config - Configure hooks and agent integration
- staged - Run linters on staged files
- install (`i`) - Install dependencies
- env - Manage Node.js versions

### Develop

- dev - Run the development server
- check - Run format, lint, and TypeScript type checks
- lint - Lint code
- fmt - Format code
- test - Run tests

### Execute

- run - Run monorepo tasks
- exec - Execute a command from local `node_modules/.bin`
- dlx - Execute a package binary without installing it as a dependency
- cache - Manage the task cache

### Build

- build - Build for production
- pack - Build libraries
- preview - Preview production build

### Manage Dependencies

Vite+ automatically detects and wraps the underlying package manager such as pnpm, npm, or Yarn through the `packageManager` field in `package.json` or package manager-specific lockfiles.

- add - Add packages to dependencies
- remove (`rm`, `un`, `uninstall`) - Remove packages from dependencies
- update (`up`) - Update packages to latest versions
- dedupe - Deduplicate dependencies
- outdated - Check for outdated packages
- list (`ls`) - List installed packages
- why (`explain`) - Show why a package is installed
- info (`view`, `show`) - View package information from the registry
- link (`ln`) / unlink - Manage local package links
- pm - Forward a command to the package manager

### Maintain

- upgrade - Update `vp` itself to the latest version

These commands map to their corresponding tools. For example, `vp dev --port 3000` runs Vite's dev server and works the same as Vite. `vp test` runs JavaScript tests through the bundled Vitest. The version of all tools can be checked using `vp --version`. This is useful when researching documentation, features, and bugs.

## Common Pitfalls

- **Using the package manager directly:** Do not use pnpm, npm, or Yarn directly. Vite+ can handle all package manager operations.
- **Always use Vite commands to run tools:** Don't attempt to run `vp vitest` or `vp oxlint`. They do not exist. Use `vp test` and `vp lint` instead.
- **Running scripts:** Vite+ built-in commands (`vp dev`, `vp build`, `vp test`, etc.) always run the Vite+ built-in tool, not any `package.json` script of the same name. To run a custom script that shares a name with a built-in command, use `vp run <script>`. For example, if you have a custom `dev` script that runs multiple services concurrently, run it with `vp run dev`, not `vp dev` (which always starts Vite's dev server).
- **Do not install Vitest, Oxlint, Oxfmt, or tsdown directly:** Vite+ wraps these tools. They must not be installed directly. You cannot upgrade these tools by installing their latest versions. Always use Vite+ commands.
- **Use Vite+ wrappers for one-off binaries:** Use `vp dlx` instead of package-manager-specific `dlx`/`npx` commands.
- **Import JavaScript modules from `vite-plus`:** Instead of importing from `vite` or `vitest`, all modules should be imported from the project's `vite-plus` dependency. For example, `import { defineConfig } from 'vite-plus';` or `import { expect, test, vi } from 'vite-plus/test';`. You must not install `vitest` to import test utilities.
- **Type-Aware Linting:** There is no need to install `oxlint-tsgolint`, `vp lint --type-aware` works out of the box.

## CI Integration

For GitHub Actions, consider using [`voidzero-dev/setup-vp`](https://github.com/voidzero-dev/setup-vp) to replace separate `actions/setup-node`, package-manager setup, cache, and install steps with a single action.

```yaml
- uses: voidzero-dev/setup-vp@v1
  with:
    cache: true
- run: vp check
- run: vp test
```

## Review Checklist for Agents

- [ ] Run `vp install` after pulling remote changes and before getting started.
- [ ] Run `vp check` and `vp test` to validate changes.
<!--VITE PLUS END-->
