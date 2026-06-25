# cortex

**Jahia's shared AI development capabilities, distributed via [APM](https://microsoft.github.io/apm/).**

`cortex` is the single place where Jahia authors AI **agents** (and, over time,
skills, hooks, prompts, and instructions) so they can be reused across many
repositories instead of copy-pasted. Author once here; consume everywhere via a
small `apm.yml`. The repository is **public** — anyone, including customers
building on Jahia, can consume it.

> Status: cornerstone / skeleton. It ships one real agent today and grows from there.

---

## Use cortex in your repo

1. **Install the APM CLI** (once per machine):

   ```bash
   curl -sSL https://aka.ms/apm-unix | sh      # macOS / Linux
   # Windows (PowerShell):  irm https://aka.ms/apm-windows | iex
   ```

2. **Declare the dependency** in your repo's `apm.yml`:

   ```yaml
   # Pick the assistant(s) you use; agents deploy to each one's location.
   targets:
     - claude          # also supported: copilot, codex, cursor, gemini, …
   dependencies:
     apm:
       - Jahia/cortex#v0.1.0     # pin to a release tag (recommended)
   ```

   > Pin to a tag (`#v0.1.0`) to avoid drift. A bare `Jahia/cortex` tracks the
   > default branch and APM will warn that it's unpinned. No token is needed —
   > cortex is public.

3. **Install**:

   ```bash
   apm install
   ```

   The agents are deployed where your assistant discovers them (e.g.
   `.claude/agents/` for Claude Code, `.github/agents/` for Copilot). `apm install`
   adds `apm_modules/` to your `.gitignore` automatically.

To update later, bump the pinned tag and re-run `apm install` (or `apm update`).

### What you get today

| Capability | Type | Purpose |
|---|---|---|
| `cypress-test-developer` | agent | Writes & maintains Cypress e2e tests for jExperience |
| `cortex-selftest` | agent | Internal integration-test fixture — safe to ignore as a consumer |

---

## Contribute to cortex

See **[CONTRIBUTING.md](CONTRIBUTING.md)** for the full workflow. In short: add an
agent under `.apm/agents/<name>.agent.md`, validate locally, and open a PR.

```bash
apm marketplace check                                 # entries resolve
apm pack --check-versions --check-clean --dry-run     # versions + marketplace.json in sync
```

---

## How it works

- **Producer layout**: `apm.yml` (plugin identity + marketplace block) and primitives
  under `.apm/`. The checked-in `.claude-plugin/marketplace.json` is what consumers
  resolve from; CI keeps it in sync with `apm.yml`.
- **CI** (`.github/workflows/`):
  - `validate.yml` — on every PR/push: `apm marketplace check`, hidden-Unicode audit,
    and release-gate dry-run.
  - `integration.yml` — on PRs: end-to-end test that installs this repo into a throwaway
    consumer and verifies the content reaches **Claude Code** (gated on the
    `ANTHROPIC_API_KEY` secret; no-ops without it).
  - `release.yml` — on a `v*` tag: packs the bundle, adds `sha256` checksums, and
    creates a GitHub Release.

### Repository layout

```
cortex/
  apm.yml                       # plugin identity + marketplace block (source ./)
  plugin.json                   # plugin manifest
  .claude-plugin/
    marketplace.json            # generated; consumers resolve from this
  .apm/
    agents/                     # the shared agents
  .github/
    workflows/                  # validate / integration / release
    CODEOWNERS
    pull_request_template.md
  tests/integration/            # end-to-end content test (Claude Code)
  CONTRIBUTING.md
  LICENSE
```

---

## License

[MIT](LICENSE) © Jahia Solutions Group SA.
