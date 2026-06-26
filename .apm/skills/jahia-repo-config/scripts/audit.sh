#!/usr/bin/env bash
#
# Read-only audit of a Jahia repository against the Product team's standards.
# Prints PASS / FAIL / WARN / MANUAL per rule and a summary. Never mutates anything.
#
# Usage:   bash audit.sh [OWNER/REPO]
#          (defaults to the current directory's origin remote)
#
# Requires: gh (authenticated, repo admin for full coverage), jq.
# Desired state is documented in ../references/guidelines.md.
set -uo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi
if [ -z "$REPO" ]; then
  echo "ERROR: no repo given and none detected from the current directory." >&2
  echo "Usage: bash audit.sh OWNER/REPO" >&2
  exit 2
fi
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"

pass=0; fail=0; warn=0; manual=0
ok()    { printf '  [PASS] %s\n' "$1"; pass=$((pass+1)); }
no()    { printf '  [FAIL] %s\n' "$1"; fail=$((fail+1)); }
wa()    { printf '  [WARN] %s\n' "$1"; warn=$((warn+1)); }
man()   { printf '  [MANUAL] %s\n' "$1"; manual=$((manual+1)); }
section(){ printf '\n== %s ==\n' "$1"; }

echo "Auditing $REPO against Jahia Product repository standards"
echo "(read-only — no changes made)"

# --- fetch repo object once ---
REPO_JSON="$(gh api "repos/$OWNER/$NAME" 2>/dev/null)"
if [ -z "$REPO_JSON" ]; then
  echo "ERROR: cannot read repos/$OWNER/$NAME (auth? access?)." >&2
  exit 2
fi
get() { printf '%s' "$REPO_JSON" | jq -r "$1"; }

# Expect "field==value": pass if actual matches expected.
check_bool() { # <jq-path> <expected true|false> <label>
  local actual; actual="$(get "$1")"
  if [ "$actual" = "$2" ]; then ok "$3 ($actual)"; else no "$3 (is '$actual', want '$2')"; fi
}

section "General settings"
dflt="$(get '.default_branch')"
[ "$dflt" = "main" ] && ok "default branch is main" || no "default branch is '$dflt' (want main)"
check_bool '.has_wiki'        false "wikis disabled"
check_bool '.has_issues'      true  "issues enabled"
check_bool '.has_projects'    false "projects disabled"
check_bool '.has_discussions' false "discussions disabled"
desc="$(get '.description')"
{ [ "$desc" != "null" ] && [ -n "$desc" ]; } && ok "description set" || no "description missing"

section "Pull requests / merge"
check_bool '.allow_merge_commit'     false "merge commits disabled"
check_bool '.allow_squash_merge'     true  "squash merging enabled"
check_bool '.allow_rebase_merge'     false "rebase merging disabled"
check_bool '.allow_auto_merge'       true  "auto-merge enabled"
check_bool '.delete_branch_on_merge' true  "auto-delete head branches"
check_bool '.allow_update_branch'    true  "suggest updating PR branches"
sct="$(get '.squash_merge_commit_title')"
[ "$sct" = "PR_TITLE" ] && ok "squash commit title = PR title" || wa "squash commit title is '$sct' (want PR_TITLE)"

section "Commits"
check_bool '.web_commit_signoff_required' false "web commit sign-off not required"
man "Allow comments on individual commits (verify in UI)"

section "Topics"
topics="$(gh api "repos/$OWNER/$NAME/topics" -q '.names | join(",")' 2>/dev/null)"
if [ -n "$topics" ]; then
  ok "topics set: $topics"
  printf '%s' "$topics" | grep -qw product || wa "no 'product' topic (expected for product-owned repos)"
else
  no "no topics set (use product/supported/core/qa/community/cloud)"
fi

section "License"
lic="$(get '.license.spdx_id')"
if { [ "$lic" != "null" ] && [ -n "$lic" ]; }; then
  ok "license detected: $lic (verify it matches the desired JSEL/MIT/Apache-2.0)"
else
  if gh api "repos/$OWNER/$NAME/contents/LICENSE" >/dev/null 2>&1 || \
     gh api "repos/$OWNER/$NAME/contents/LICENSE.md" >/dev/null 2>&1; then
    wa "LICENSE file present but not recognized by GitHub (likely JSEL — verify)"
  else
    no "no LICENSE file"
  fi
fi

section "README"
gh api "repos/$OWNER/$NAME/readme" >/dev/null 2>&1 && ok "README present" || no "no README"

section "Branch protection / rulesets"
rs_json="$(gh api "repos/$OWNER/$NAME/rulesets" 2>/dev/null || echo '[]')"
branch_rs="$(printf '%s' "$rs_json" | jq '[.[] | select(.target=="branch")] | length')"
[ "${branch_rs:-0}" -gt 0 ] && ok "$branch_rs branch ruleset(s) present (org-ported — confirm they cover main and *_x)" \
                              || wa "no branch rulesets visible — confirm org porting, else add protection for main and *_x"
# classic protection on main (best-effort; needs admin)
if gh api "repos/$OWNER/$NAME/branches/main/protection" >/dev/null 2>&1; then
  ok "classic branch protection present on main"
else
  wa "no classic branch protection on main (OK if a ruleset covers it)"
fi
# production branches *_x
xbr="$(gh api "repos/$OWNER/$NAME/branches" --paginate -q '.[].name' 2>/dev/null | grep -E '_x$' || true)"
[ -n "$xbr" ] && wa "production branches found ($(echo "$xbr" | tr '\n' ' ')) — confirm each is protected"

section "Tags"
tag_rs="$(printf '%s' "$rs_json" | jq '[.[] | select(.target=="tag")] | length')"
[ "${tag_rs:-0}" -gt 0 ] && ok "tag ruleset present (should prevent deletion/update)" \
                          || no "no tag ruleset — import assets/rulesets/prevent-tag-deletion.json"

section "Custom properties"
props="$(gh api "repos/$OWNER/$NAME/properties/values" 2>/dev/null || echo '[]')"
owner_val="$(printf '%s' "$props" | jq -r '.[] | select(.property_name=="Owner") | .value // empty' 2>/dev/null)"
[ -n "$owner_val" ] && ok "custom property Owner = $owner_val" || no "custom property Owner not set (required)"
area_val="$(printf '%s' "$props" | jq -r '.[] | select(.property_name=="Area") | .value // empty' 2>/dev/null)"
[ -n "$area_val" ] && ok "custom property Area = $area_val" || wa "custom property Area not set"

section "Team access"
declare -A want=( [admin]="Engineering Leads + Owner team" [push]="Engineering + customer_support_contributor" [pull]="jahians" )
teams_json="$(gh api "repos/$OWNER/$NAME/teams" --paginate 2>/dev/null || echo '[]')"
if [ "$(printf '%s' "$teams_json" | jq 'length')" = "0" ]; then
  wa "no team permissions readable (need admin) — verify Engineering Leads=admin, Owner=admin, Engineering=write, customer_support_contributor=write, jahians=read"
else
  printf '%s' "$teams_json" | jq -r '.[] | "  [INFO] team \(.slug): \(.permission)"'
  wa "review the team list above against the guidelines"
fi

section "Manual (UI / org) — not auto-checked"
man "Release immutability enabled"
man "Auto-close issues with merged linked PRs"
man "Actions: read/write GITHUB_TOKEN, allow create/approve PRs, org-accessible"
man "Any repo secret also stored in it.jahia.com"

echo ""
echo "Summary for $REPO: PASS=$pass  FAIL=$fail  WARN=$warn  MANUAL=$manual"
[ "$fail" -eq 0 ] && echo "No hard failures." || echo "Address the FAIL items above."
exit 0
