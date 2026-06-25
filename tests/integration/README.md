# Integration tests

These tests verify the **repository's own content** end to end — not just that
files are well-formed, but that a packaged capability actually reaches an AI
assistant when consumed via APM.

## `copilot-selftest.sh`

Pipeline under test:

```
author  ->  apm pack  ->  apm install  ->  GitHub Copilot CLI
```

The `cortex-selftest` agent (`.apm/agents/cortex-selftest.agent.md`) carries a
unique token that exists nowhere else. The test packs the marketplace, installs
the bundle into a throwaway consumer project (the agent lands in
`.github/agents/`, where Copilot CLI discovers custom agents), then asks Copilot
CLI — through that agent — for the token. If the token comes back, every link in
the chain works.

### Run locally

Prerequisites:

- **APM CLI** — `curl -sSL https://aka.ms/apm-unix | sh` (see
  <https://microsoft.github.io/apm/>)
- **GitHub Copilot CLI** — `npm install -g @github/copilot`, authenticated via
  `copilot login` or one of `COPILOT_GITHUB_TOKEN` / `GH_TOKEN` / `GITHUB_TOKEN`
  (a fine-grained PAT with the **Copilot Requests** permission). Requires an
  active Copilot subscription; each run consumes a small number of AI credits.

```bash
bash tests/integration/copilot-selftest.sh
```

Override the binaries if they are not on `PATH`:

```bash
APM_BIN=/path/to/apm COPILOT_BIN=/path/to/copilot bash tests/integration/copilot-selftest.sh
```

Expected tail:

```
PASS: canary token surfaced through Copilot CLI — content pipeline verified.
```

### In CI

`.github/workflows/integration.yml` runs this on every PR **only when** the repo
or org secret `COPILOT_GITHUB_TOKEN` is set. Without it the job no-ops so forks
and external contributors stay green. The token must be a fine-grained PAT with
the **Copilot Requests** permission — the default `GITHUB_TOKEN` cannot call
Copilot.
