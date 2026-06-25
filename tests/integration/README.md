# Integration tests

These tests verify the **repository's own content** end to end — not just that
files are well-formed, but that a packaged capability actually reaches an AI
assistant when consumed via APM.

## `claude-selftest.sh`

Pipeline under test:

```
author  ->  apm install (resolver)  ->  Claude Code
```

The `cortex-selftest` agent (`.apm/agents/cortex-selftest.agent.md`) carries a
unique token that exists nowhere else. The test creates a throwaway consumer
project that depends on this repo, installs it for the `claude` target (the agent
lands in `.claude/agents/`, where Claude Code discovers subagents), then asks
Claude Code — through that subagent — for the token. If the token comes back,
every link in the chain works.

### Run locally

Prerequisites:

- **APM CLI** — `curl -sSL https://aka.ms/apm-unix | sh` (see
  <https://microsoft.github.io/apm/>)
- **Claude Code** — `npm install -g @anthropic-ai/claude-code`, authenticated via
  `ANTHROPIC_API_KEY` or an interactive `claude` login session. Each run makes a
  small model call.

```bash
bash tests/integration/claude-selftest.sh
```

Override the binaries if they are not on `PATH`:

```bash
APM_BIN=/path/to/apm CLAUDE_BIN=/path/to/claude bash tests/integration/claude-selftest.sh
```

Expected tail:

```
PASS: canary token surfaced through Claude Code — content pipeline verified.
```

### In CI

`.github/workflows/integration.yml` runs this on every PR **only when** the repo
or org secret `ANTHROPIC_API_KEY` is set. Without it the job no-ops so forks and
external contributors stay green.
