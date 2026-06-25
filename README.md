# cortex

**Jahia's shared AI development capabilities, distributed via [APM](https://microsoft.github.io/apm/).**

`cortex` is the single place where Jahia authors AI **agents** (and, over time,
skills, hooks, prompts, and instructions) so they can be reused across many
repositories instead of copy-pasted. Author once here; consume everywhere via a
small `apm.yml`. The repository is **public** — anyone, including customers
building on Jahia, can consume it.

> Status: cornerstone / skeleton. It ships one real agent today and grows from there.

> ### cortex vs. [Jahia/agentic](https://github.com/Jahia/agentic)
> These are **complementary, not competing**. **cortex** holds AI capabilities for
> **developing Jahia itself** (engineering-facing). **[Jahia/agentic](https://github.com/Jahia/agentic)**
> is broader and **customer-facing**. The two may converge in the future — nothing
> is set in stone.

---

## Quick start

**New to APM?** APM (Agent Package Manager) installs shared AI capabilities into a
repository from a small `apm.yml` manifest — much like npm installs packages from
`package.json`. Install the CLI once per machine:

```bash
curl -sSL https://aka.ms/apm-unix | sh      # macOS / Linux
# Windows (PowerShell):  irm https://aka.ms/apm-windows | iex
apm --version
```

Pick the path that matches your situation:

### A. Starting from scratch (your repo has no `apm.yml` yet)

From the root of your repo, create an `apm.yml` that pulls in cortex:

```yaml
# apm.yml
name: my-repo                 # your repository's name
version: 0.0.0
targets:
  - claude                    # the assistant(s) you use: claude, copilot, codex, cursor, gemini, …
dependencies:
  apm:
    - Jahia/cortex#v0.1.0     # pin to a release tag (recommended)
```

Then install:

```bash
apm install
```

cortex's agents are deployed where your assistant looks for them (e.g.
`.claude/agents/` for Claude Code, `.github/agents/` for Copilot), and
`apm_modules/` is added to your `.gitignore` automatically. Open your assistant
and the capabilities are available.

### B. You cloned a repo that already has an `apm.yml`

Install whatever that manifest declares:

```bash
apm install
```

This pulls every capability listed in the repo's `apm.yml` (cortex included if it's
there) and deploys them for the configured targets. Re-run `apm install` (or
`apm update`) whenever the manifest changes or you want newer versions.

> **Pinning & access.** Pin cortex to a tag (`#v0.1.0`) to avoid drift — a bare
> `Jahia/cortex` follows the default branch and APM warns it's unpinned. No token
> is needed: cortex is public.

### Verify your setup

cortex ships a tiny self-test agent so you can confirm the whole pipeline
(author → `apm install` → assistant) actually reached your harness. After
`apm install`, open your assistant and ask the `cortex-selftest` agent for its
token. In Claude Code:

```bash
claude --agent cortex-selftest -p "What is the Cortex self-test token?"
```

A correct setup replies with exactly:

```
CORTEX-SELFTEST-OK-Zx9Q2pV7
```

If you see the token, cortex's agents are installed and discoverable — you're good
to go. (This is the same check cortex's own CI integration test runs.) If you don't,
re-run `apm install` and confirm the agent landed in your assistant's path (e.g.
`.claude/agents/cortex-selftest.md`).

---

## Day-to-day lifecycle

Once cortex (or any APM dependency) is declared in your `apm.yml`, these are the
commands you'll use over time. Run them from the repo root.

| Command | What it does |
|---|---|
| `apm install` | Install/refresh everything declared in `apm.yml` and deploy it for your targets. Safe to re-run. |
| `apm install --frozen` | CI-safe install: fails if `apm.lock.yaml` is missing or out of sync with `apm.yml` (no ref changes). |
| `apm outdated` | List locked dependencies that have a newer matching ref available (add `-v` to see available tags). |
| `apm update` | Refresh dependencies to the latest matching refs and rewrite the lockfile. Shows a plan to confirm; add `--dry-run` to preview, `--yes` for CI. |
| `apm uninstall <pkg>` | Remove a package, the files it deployed, and its `apm.yml` entry (`--dry-run` to preview). |
| `apm prune` | Remove deployed packages that are no longer listed in `apm.yml`. |
| `apm self-update` | Update the `apm` CLI binary itself. |

### Updating cortex specifically

How `apm update` behaves depends on how you referenced cortex:

- **Pinned to a tag** (`Jahia/cortex#v0.1.0`, recommended): `apm update` will **not**
  move you off that tag. To take a new release, bump the tag in `apm.yml`
  (e.g. `#v0.2.0`) and run `apm install`. Use `apm outdated` to see what's available.
- **Unpinned** (`Jahia/cortex`): `apm update` pulls the latest commit on the default
  branch and updates `apm.lock.yaml`. Convenient, but less reproducible — prefer pinning.

Commit the resulting `apm.yml` (and `apm.lock.yaml`, if you keep one) so teammates
and CI resolve the same versions.

---

## Keeping your own agents alongside cortex

Pulling cortex does **not** lock you into only shared capabilities. A repo can keep
its own private agents/skills next to the ones it installs, and `apm install` makes
them coexist cleanly.

**APM only manages what it deployed.** Every install records the exact files it
wrote in `apm.lock.yaml` — dependency files under `deployed_files` and your repo's
own under `local_deployed_files`, each with a content hash. `apm install`,
`apm update`, `apm prune`, and `apm uninstall` only ever touch files in that
ledger. Anything else in `.claude/agents/` (or another harness path) that APM
didn't create is left untouched.

### Recommended: author your own primitives in `.apm/`

Mirror how cortex itself works — put your repo-local agents in `.apm/agents/` and
let APM compile and deploy them alongside cortex's. Keep `includes: auto` in your
`apm.yml` (the default):

```
your-repo/
  apm.yml                       # includes: auto  +  Jahia/cortex#v0.1.0
  .apm/
    agents/
      my-team-agent.agent.md    # your own, authored locally
```

```yaml
# apm.yml
name: your-repo
version: 0.0.0
targets:
  - claude
includes: auto                  # compile this repo's own .apm/ content too
dependencies:
  apm:
    - Jahia/cortex#v0.1.0
```

`apm install` then deploys **both** into `.claude/agents/`:

```
  [+] Jahia/cortex #v0.1.0      |-- 2 agents integrated -> .claude/agents/
  [+] <project root> (local)    |-- 1 agents integrated -> .claude/agents/
```

This keeps a single source of truth (`.apm/`), gives you the same validation
(`apm compile --validate`) cortex uses, and means `.claude/` is fully reproducible
from `apm install`.

> **Name collisions = local override.** If your local `.apm/` agent has the **same
> `name`** as a cortex agent, your local one is deployed last and **wins** (it
> overrides the installed copy). Use distinct names unless overriding is what you
> intend.

### Alternative: hand-place files directly in `.claude/`

You can also drop a file straight into `.claude/agents/my-agent.md` without going
through `.apm/`. APM won't manage or remove it (it's not in the lock), so it
survives installs and updates — but you lose APM validation and the single-source
guarantee. Prefer the `.apm/` approach above unless you have a reason not to.

### Committing deployed files

The simplest, most portable choice is to **commit** `apm.yml`, `apm.lock.yaml`, and
the deployed `.claude/` files. Teammates and CI then get the capabilities without
needing to run `apm install`, and diffs show exactly what changed. (`apm_modules/`
— the dependency cache — is gitignored for you automatically; never commit it.) In
CI, `apm install --frozen` fails if the deployed tree drifts from the lockfile.

---

## Contribute to cortex

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full workflow. In short: add an
agent under `.apm/agents/<name>.agent.md`, validate locally, and open a PR.

```bash
apm marketplace check                                 # entries resolve
apm pack --check-versions --check-clean --dry-run     # versions + marketplace.json in sync
```

---

## License

[MIT](LICENSE) © Jahia Solutions Group SA.
