# Contributing to cortex

`cortex` is Jahia's shared library of AI development capabilities (agents — and,
in time, skills, hooks, prompts, instructions), distributed with
[APM](https://microsoft.github.io/apm/). Author a capability **once** here and any
Jahia repo can consume it. This repo is **public** — never commit secrets or
internal-only information.

## Prerequisites

Install the APM CLI (the documented way):

```bash
curl -sSL https://aka.ms/apm-unix | sh      # macOS / Linux
# Windows (PowerShell):  irm https://aka.ms/apm-windows | iex
apm --version
```

## Add a capability

Today cortex ships **agents**. Add one as `.apm/agents/<name>.agent.md`:

```markdown
---
name: my-capability
description: One or two sentences on what it does and WHEN to use it. (required)
# optional: model, tools, color
---

The system prompt / instructions for the agent. Keep it focused and under ~300 lines.
```

Notes:
- `description` is **required**; it's how assistants decide when to reach for the agent.
- The filename stem becomes the deployed name. Avoid the reserved names `default` and `start`.
- Don't create empty `skills/`, `hooks/`, `prompts/`, or `instructions/` folders — add a
  directory only when you ship a real capability of that type.

## Validate locally (mirrors CI)

```bash
apm marketplace check                                 # marketplace entries resolve
apm audit --file .apm/agents/<name>.agent.md          # no hidden Unicode
apm pack --check-versions --check-clean --dry-run     # versions aligned + marketplace.json in sync
```

If you changed `apm.yml`, regenerate the checked-in marketplace file:

```bash
apm pack            # writes .claude-plugin/marketplace.json
git add .claude-plugin/marketplace.json
```

## Integration test (optional, end-to-end)

`tests/integration/claude-selftest.sh` installs this repo into a throwaway consumer
and asks Claude Code (running **as** the `cortex-selftest` agent) for a token that
lives only in that agent — proving packaged content reaches the assistant. See
[`tests/integration/README.md`](tests/integration/README.md). Requires `claude` and
`ANTHROPIC_API_KEY`.

## Open a PR

1. Branch, commit (Conventional Commits appreciated), push.
2. Open a PR against `main`. CI runs `validate` (and the gated Claude integration test).
3. A code owner reviews. Keep PRs small and focused.

## Releases

Releases are tag-driven. Maintainers bump `version` in `apm.yml` (and the package
entry), then push a tag matching `v{version}` (e.g. `v0.1.0`). The `release` workflow
packs the bundle, attaches checksums, and creates a GitHub Release. Consumers then
pin to that tag (see the README).
