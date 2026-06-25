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
