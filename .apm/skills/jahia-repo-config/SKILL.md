---
name: jahia-repo-config
description: >-
  Configure or audit a Jahia GitHub repository against the Product team's
  standards — visibility, license (MIT / Apache-2.0 / JSEL), general & pull-request
  settings, branch protection / rulesets, team access, custom properties, topics,
  README and LICENSE — and, when a repository is meant to be public, open the
  product-lifecycle open-source approval issue. Use when creating a new repo in the
  Jahia organization, or to check whether an existing repo is configured correctly.
---

# Jahia repository configuration

Bring a GitHub repository in the **Jahia** organization in line with the Product
team's repository standards, or verify that it already is. Works in two modes:

- **configure** — apply the standard configuration (hybrid: auto-apply everything
  safely automatable via `gh`, **after showing a plan and confirming**, then print a
  checklist for the org-level items a repo admin token can't change).
- **check** — read-only audit; report PASS / FAIL / MANUAL per rule and propose fixes.

The full desired state lives in [`references/guidelines.md`](references/guidelines.md)
— treat it as the source of truth for every setting and rationale. This file is the
procedure.

## Prerequisites

- `gh` authenticated as a user with **admin** on the target repo
  (`gh auth status`; needs at least the `repo` and `read:org` scopes).
- `jq` available.
- For writing files (README/LICENSE), a local clone of the target repo, or accept
  that the skill commits via the GitHub contents API.
- JSEL license access: fetching the JSEL text reads a **private** repo
  (`Jahia/jahia-private`); the user must have access.

## Step 1 — Identify the target & gather inputs

1. Determine the target repo: `OWNER/REPO`. Default to the current directory's
   `origin` remote (`gh repo view --json nameWithOwner -q .nameWithOwner`); confirm
   it is under the `Jahia` org. Otherwise ask.
2. Ask the operator (use `AskUserQuestion`; skip anything already known):
   - **Visibility intent**: public or private. *(A repo may legitimately be private
     now but already carry an MIT/Apache-2.0 license — e.g. early in development.)*
   - **Desired license**: `MIT`, `Apache-2.0`, or `JSEL`. Rule of thumb: private →
     `JSEL`; public → `MIT` or `Apache-2.0`. Do **not** assume — confirm.
   - **Support status**: `supported`, `community`, `core`, `qa`, `cloud` (drives topics).
   - **Owner team**: the team that maintains the repo (required — a repo MUST have an
     owner). Resolve to a team slug via `gh api orgs/Jahia/teams --paginate -q '.[].slug'`.
   - **Champion** (optional): an individual leading maintenance (must be on the Owner team).
   - **Area** custom property value, and a one-line **repository description**.
3. **Mode**: configure or check (ask if not stated).

## Step 2 — Open-source approval gate (public repos only)

If the repository is **intended to be public** (now or later), an approval issue in
[`Jahia/product-lifecycle`](https://github.com/Jahia/product-lifecycle) is required
**before** flipping visibility to public. **Private/closed-source repos skip this
entirely.**

Follow [`references/lifecycle-issue.md`](references/lifecycle-issue.md) to create the
issue from the `lifecycle-change.md` template. Create it **unassigned** and then
**remind the operator** to assign their DM (the approver). Do **not** set the repo
public until the issue carries the `Status:Approved` label.

## Step 3 — Configure (hybrid apply + report) or Check

### check mode

Run the audit and relay the result; offer to switch to configure for the FAILs:

```bash
bash scripts/audit.sh OWNER/REPO
```

### configure mode

1. Run `scripts/audit.sh` first to see the current gap.
2. Present a concise **plan** of the changes you will make (grouped as below) and the
   exact `gh` commands. **Get explicit confirmation before applying.**
3. Apply, group by group, using the desired values in
   [`references/guidelines.md`](references/guidelines.md):

   - **General & PR settings** — `gh api -X PATCH repos/OWNER/REPO -f ...`
     (default branch `main`, wikis/projects/discussions off, issues on, squash-only
     merges with PR-title commit message, auto-merge on, delete head branch on merge,
     suggest updating branches).
   - **Topics** — `gh api -X PUT repos/OWNER/REPO/topics -f names[]=...`
     (controlled vocabulary in the guidelines; e.g. `product`, `supported`, `core`).
   - **Repository description** — `gh api -X PATCH repos/OWNER/REPO -f description=...`.
   - **Custom properties** — `gh api -X PATCH repos/OWNER/REPO/properties/values`
     with `Area`, `Owner` (required), and `Champion` (optional). Requires the
     properties to be defined at org level.
   - **Team access** — for each team, `gh api -X PUT
     orgs/Jahia/teams/SLUG/repos/OWNER/REPO -f permission=admin|push|pull`
     (Engineering Leads = admin, Owner team = admin, Engineering = write,
     customer_support_contributor = write, jahians = read).
   - **Tag protection ruleset** — import the bundled ruleset (prevents tag
     deletion/update):
     ```bash
     gh api -X POST repos/OWNER/REPO/rulesets --input assets/rulesets/prevent-tag-deletion.json
     ```
   - **Branch protection / rulesets** — branch rulesets are **ported automatically by
     the organization**; verify coverage of `main` and `*_x` and **report** rather
     than re-create. Only offer to add classic branch protection if none exists
     (see the guidelines for the rule set).
   - **README.md & LICENSE.md** — see Step 4.

4. After applying, **always print the manual checklist** (Step 5).

## Step 4 — README and LICENSE

- **README.md** — ensure one exists. If missing, create a minimal, meaningful README
  (what the repo is, in a sentence or two — enough to understand it without reading
  the code). For public repos, invest a little more (it's the front door).
- **LICENSE** — write the chosen license. Fetch the text at runtime so it is always
  current:
  - **MIT**: `gh api /licenses/mit -q .body`
  - **Apache-2.0**: `gh api /licenses/apache-2.0 -q .body`
  - **JSEL**: `gh api repos/Jahia/jahia-private/contents/license/jsel.txt -q .content | base64 -d`
  - Substitute placeholders (`[year]` → current year, `[fullname]`/copyright holder →
    `Jahia Solutions Group SA`) for MIT/Apache-2.0. Write to `LICENSE` (or `LICENSE.md`).
  - Commit on a branch and open a PR (the repo's own rules require PRs), or, for a
    brand-new empty repo, commit directly to `main` if no protection is active yet.

## Step 5 — Manual checklist (always output)

Some items can't be set with a repo-admin token / via the API. Output them for the
operator to complete in the GitHub UI, each as a checkbox:

- [ ] **Release immutability** enabled (Settings → General → Releases).
- [ ] **Preserve this repository** / archive program, **Sponsorships** — per guidelines.
- [ ] **Auto-close issues with merged linked PRs** (Settings → Issues).
- [ ] **Org-ported branch rulesets** confirmed applied to `main` and `*_x`
      (see the Confluence ruleset page linked in the guidelines).
- [ ] Any **repository secret** also stored in `it.jahia.com` (never GitHub-only).
- [ ] If public: lifecycle issue **assigned to the DM** and **`Status:Approved`** before
      visibility is flipped.

## Notes

- Never flip a repo to **public** before the lifecycle issue is approved.
- The exact desired booleans for general/PR settings are recorded in
  `references/guidelines.md`; if GitHub's UI labels differ from the API fields, the
  guidelines map them. When in doubt, show the operator the diff and confirm.
- Re-running in **check** mode after configuring is the fastest way to confirm success.
