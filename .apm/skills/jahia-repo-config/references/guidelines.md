# Jahia Product repository — desired configuration (source of truth)

This is the canonical desired state the `jahia-repo-config` skill applies and audits.
Each row maps the GitHub **UI** setting to the **API** field used to set/check it.
Where a setting can't be set by a repo-admin token, it is marked **MANUAL**.

> Some GitHub UI checkbox states are easy to misread. Treat the **Desired** column as
> authoritative; if a repo's reality differs from a customer/team expectation, surface
> it and confirm rather than silently overwriting.

## Visibility & license

| Item | Desired | Notes |
|---|---|---|
| Visibility | As decided per repo | **Public requires an approved product-lifecycle issue first** (see `lifecycle-issue.md`). Private needs no approval. |
| License (private) | **JSEL** | Jahia Sustainable Enterprise License. Text: `Jahia/jahia-private:license/jsel.txt` (private). |
| License (public) | **MIT** or **Apache-2.0** | Operator picks. Fetch via `gh api /licenses/mit` or `/licenses/apache-2.0`. |
| Copyright holder | `Jahia Solutions Group SA` | Used when substituting license placeholders. |

A repo may be **private yet already MIT/Apache-2.0** (e.g. early development before
going public). This is allowed — license intent and visibility are independent.

## General settings

| UI setting | Desired | API field (`PATCH /repos/{owner}/{repo}`) |
|---|---|---|
| Default branch | `main` | `default_branch` |
| Releases → immutability | Enabled | **MANUAL** (UI only) |
| Wikis | Off | `has_wiki=false` |
| Issues | On | `has_issues=true` |
| Sponsorships | Off | **MANUAL** |
| Preserve this repository | Default | **MANUAL** |
| Discussions | Off | `has_discussions=false` |
| Projects | Off | `has_projects=false` |
| Pull requests (feature) | On | n/a (always on) |
| PR creation allowed by | All users | repo default; no change |

## Pull requests / merge

PRs **must be merged with squash**, and the source branch removed afterwards.

| UI setting | Desired | API field |
|---|---|---|
| Allow merge commits | Off | `allow_merge_commit=false` |
| Allow squash merging | **On** | `allow_squash_merge=true` |
| Squash default commit message | **Pull request title** | `squash_merge_commit_title=PR_TITLE`, `squash_merge_commit_message=BLANK` |
| Allow rebase merging | Off | `allow_rebase_merge=false` |
| Always suggest updating PR branches | On | `allow_update_branch=true` |
| Allow auto-merge | On | `allow_auto_merge=true` |
| Automatically delete head branches | On | `delete_branch_on_merge=true` |

## Commits

| UI setting | Desired | API field |
|---|---|---|
| Require sign-off on web-based commits | Off | `web_commit_signoff_required=false` |
| Allow comments on individual commits | On | **MANUAL** |

## Issues

| UI setting | Desired | API |
|---|---|---|
| Auto-close issues with merged linked PRs | On | **MANUAL** |

## Team access (Collaborators and teams)

Set via `PUT /orgs/Jahia/teams/{team_slug}/repos/{owner}/{repo}` with `permission`.
Resolve slugs with `gh api orgs/Jahia/teams --paginate -q '.[] | [.slug,.name] | @tsv'`.

| Team | Permission | API `permission` | Notes |
|---|---|---|---|
| Engineering Leads (was `product_administrator`) | Admin | `admin` | |
| **Owner team** (e.g. `squad-goat`) | Admin | `admin` | The team currently owning the repo. |
| Engineering (`@jahia/engineering`, was `product_contributor`) | Write | `push` | |
| `customer_support_contributor` | Write | `push` | Lets support submit PRs without forking. |
| `jahians` | Read | `pull` | |

## Branches / Rulesets

All repos must have their development branch (`main`) and production branches (`*_x`)
protected. Configuration is **migrating from branch protection to Rulesets, which are
ported automatically by the organization** (filters match repos). The skill should:

1. **Verify** that org-ported branch rulesets (or classic protection) cover `main` and
   each `*_x` branch — **report**, don't recreate org rulesets.
2. Only offer **classic branch protection** as a fallback if nothing protects a branch.

Confluence reference (internal): https://jahia-confluence.atlassian.net/wiki/spaces/PR/pages/871104513

Classic branch-protection fallback (per branch, `PUT /repos/{owner}/{repo}/branches/{branch}/protection`):
- Require a pull request before merging; required approvals ≥ 1
- Dismiss stale approvals on new commits
- Require approval of the most recent reviewable push
- Require status checks to pass; require branches up to date
- Require conversation resolution before merging
- Require signed commits

## Tags

Import a **tag ruleset that prevents deletion/update** of tags — bundled at
`assets/rulesets/prevent-tag-deletion.json`, applied via
`POST /repos/{owner}/{repo}/rulesets`.

## Actions

Mostly org-managed; verify and report:
- Actions permissions: Allow all actions and reusable workflows
- Artifact/log retention: 90 days default (workflows often override to ~2 days)
- Run workflows from fork PRs: enabled
- Workflow permissions: **Read and write**; allow Actions to create & approve PRs
- Access: accessible from repositories in the `Jahia` org
- Runners: org-level (no repo change)

## Custom properties (org-defined, set per repo)

Set via `PATCH /repos/{owner}/{repo}/properties/values`. Required on all Product repos:

| Property | Required | Notes |
|---|---|---|
| `Area` | Yes | Pick from the org list. |
| `Owner` | **Yes** | The maintaining team. A repo MUST have an owner. |
| `Champion` | Optional | Individual leading maintenance; must be on the Owner team. |

## Repository description & topics

- **Description**: required and meaningful — understandable without the README.
- **Topics** (controlled vocabulary; set via `PUT /repos/{owner}/{repo}/topics`):

| Topic | Meaning |
|---|---|
| `product` | Owned by the product team |
| `supported` | Active; usually a supported module on the store |
| `core` | Part of Jahia core |
| `qa` | Used by QA |
| `community` | Not product-owned; community-status module on the store |
| `cloud` | Owned by the cloud team |

## Secrets & variables

If a repo-specific secret is created, **also store its value in https://it.jahia.com/** —
GitHub-only storage means it is lost for other use cases. (Operator action — MANUAL.)

## README.md / LICENSE.md

- **README.md** must exist and be meaningful (front door for public repos).
- **LICENSE** must exist: JSEL for private; MIT or Apache-2.0 for public.
