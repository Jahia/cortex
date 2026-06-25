#!/usr/bin/env bash
#
# Integration test: prove that packaged Cortex content actually reaches an AI
# assistant when consumed via APM.
#
# Pipeline under test:  author -> `apm pack` -> `apm install` -> Copilot CLI
#
# It packs the marketplace into a bundle, installs that bundle into a throwaway
# consumer project, then asks GitHub Copilot CLI — through the `cortex-selftest`
# agent — for a token that exists ONLY inside that agent's body. If the token
# comes back, every link in the chain works: the agent was packed, installed to
# the assistant's discovery path (.github/agents/), and loaded by Copilot.
#
# Requirements:
#   - apm        (https://microsoft.github.io/apm/ — `curl -sSL https://aka.ms/apm-unix | sh`)
#   - copilot    (GitHub Copilot CLI: `npm install -g @github/copilot`), authenticated
#                via COPILOT_GITHUB_TOKEN / GH_TOKEN / GITHUB_TOKEN.
#
# Overrides (env):
#   APM_BIN      path to the apm binary       (default: apm)
#   COPILOT_BIN  path to the copilot binary   (default: copilot)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APM_BIN="${APM_BIN:-apm}"
COPILOT_BIN="${COPILOT_BIN:-copilot}"

AGENT="cortex-selftest"
EXPECTED_TOKEN="CORTEX-SELFTEST-OK-Zx9Q2pV7"
PROMPT="What is the Cortex self-test token?"

cd "$REPO_ROOT"

echo "==> Packing marketplace bundle"
"$APM_BIN" pack --archive --output ./build >/dev/null
ZIP="$(ls -1t "$REPO_ROOT"/build/cortex-*.zip 2>/dev/null | head -1 || true)"
[ -n "$ZIP" ] || { echo "FAIL: no bundle produced by 'apm pack'"; exit 1; }
echo "    bundle: ${ZIP#"$REPO_ROOT"/}"

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "==> Installing bundle into throwaway consumer: $WORK"
( cd "$WORK" && "$APM_BIN" install "$ZIP" )

# Sanity check: the agent must land where Copilot CLI discovers custom agents.
AGENT_FILE="$WORK/.github/agents/${AGENT}.agent.md"
[ -f "$AGENT_FILE" ] || {
  echo "FAIL: agent not deployed to .github/agents/${AGENT}.agent.md"
  echo "Deployed files:"; find "$WORK" -type f | sed "s#$WORK#.#"
  exit 1
}
echo "    deployed: ${AGENT_FILE#"$WORK"/}"

echo "==> Asking Copilot CLI (agent: $AGENT) for the self-test token"
OUT="$("$COPILOT_BIN" -C "$WORK" --agent "$AGENT" \
        -p "$PROMPT" --allow-all-tools --no-color 2>&1)" || true
echo "----- copilot output -----"
echo "$OUT"
echo "--------------------------"

if printf '%s' "$OUT" | grep -q "$EXPECTED_TOKEN"; then
  echo "PASS: canary token surfaced through Copilot CLI — content pipeline verified."
  exit 0
fi

echo "FAIL: expected token '$EXPECTED_TOKEN' not found in Copilot CLI output."
exit 1
