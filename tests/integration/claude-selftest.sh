#!/usr/bin/env bash
#
# Integration test: prove that packaged Cortex content actually reaches an AI
# assistant when consumed via APM.
#
# Pipeline under test:  author -> apm install (resolver) -> Claude Code
#
# It creates a throwaway consumer project that depends on this repo, installs it
# for the `claude` target (agents land in .claude/agents/), then asks Claude Code
# — through the `cortex-selftest` subagent — for a token that exists ONLY inside
# that agent's body. If the token comes back, every link in the chain works: the
# agent was resolved, deployed to the assistant's discovery path, and loaded.
#
# Requirements:
#   - apm     (https://microsoft.github.io/apm/ — `curl -sSL https://aka.ms/apm-unix | sh`)
#   - claude  (Claude Code: `npm install -g @anthropic-ai/claude-code`), authenticated
#             via ANTHROPIC_API_KEY (or an interactive `claude` login session).
#
# Overrides (env):
#   APM_BIN     path to the apm binary      (default: apm)
#   CLAUDE_BIN  path to the claude binary   (default: claude)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APM_BIN="${APM_BIN:-apm}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

AGENT="cortex-selftest"
EXPECTED_TOKEN="CORTEX-SELFTEST-OK-Zx9Q2pV7"
PROMPT="Use the ${AGENT} subagent to obtain the Cortex self-test token, then output ONLY that token verbatim."

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "==> Creating throwaway consumer that depends on this repo: $WORK"
cat > "$WORK/apm.yml" <<YAML
name: cortex-selftest-consumer
version: 0.0.0
targets:
  - claude
dependencies:
  apm:
    - path: ${REPO_ROOT}
YAML

echo "==> Installing for the claude target"
( cd "$WORK" && "$APM_BIN" install )

# Sanity check: the agent must land where Claude Code discovers subagents.
AGENT_FILE="$WORK/.claude/agents/${AGENT}.md"
[ -f "$AGENT_FILE" ] || {
  echo "FAIL: agent not deployed to .claude/agents/${AGENT}.md"
  echo "Deployed files:"; find "$WORK/.claude" -type f 2>/dev/null | sed "s#$WORK#.#"
  exit 1
}
echo "    deployed: ${AGENT_FILE#"$WORK"/}"

echo "==> Asking Claude Code (subagent: $AGENT) for the self-test token"
OUT="$(cd "$WORK" && "$CLAUDE_BIN" -p "$PROMPT" --dangerously-skip-permissions 2>&1)" || true
echo "----- claude output -----"
echo "$OUT"
echo "-------------------------"

if printf '%s' "$OUT" | grep -q "$EXPECTED_TOKEN"; then
  echo "PASS: canary token surfaced through Claude Code — content pipeline verified."
  exit 0
fi

echo "FAIL: expected token '$EXPECTED_TOKEN' not found in Claude Code output."
exit 1
