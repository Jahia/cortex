# Filing the product-lifecycle open-source approval issue

**When**: the repository is intended to become **public** (open-source). Do this
**before** flipping visibility. **Skip entirely for private/closed-source repos.**

**Why**: opening a Product-team codebase goes through a light approval/documentation
process so that, years later, the rationale for making the repo public is recorded.
Approval is ultimately the VP of Product's call, handled via the DM (assignee).

## How

Create an issue in [`Jahia/product-lifecycle`](https://github.com/Jahia/product-lifecycle)
from the **`lifecycle-change.md`** ("Lifecycle Change Request") template.

- **Title**: `jahia/REPO` (the org-qualified repo name, lower-case), matching the
  template default.
- **Assignee**: create **unassigned**, then remind the operator to assign their **DM**
  (the approver) — see below.
- **Body**: fill the template fields. Current template shape:

```
* Repository: https://github.com/Jahia/REPO
* Type of change: OPEN SOURCE
* Current repository status: PRIVATE
* Current support status: <SUPPORTED|COMMUNITY|LABS|NONE>
* Desired support status: <SUPPORTED|COMMUNITY|LABS|NONE>
* Current license: <e.g. JSEL, or "none">
* Desired license: <MIT|Apache 2>
* Associated initiative: <GitHub issue link, if any>

## Context
<1–3 sentences: why this repo should be public and the desired outcome.>
```

> Always re-read the live template before composing the body — fields may change:
> `gh api repos/Jahia/product-lifecycle/contents/.github/ISSUE_TEMPLATE/lifecycle-change.md -q .content | base64 -d`

## Create it

```bash
gh issue create \
  --repo Jahia/product-lifecycle \
  --title "jahia/REPO" \
  --body-file /tmp/lifecycle-body.md
# (no --assignee: created unassigned by design)
```

Capture the returned issue URL.

## After creating

1. **Remind the operator** (explicitly, in the final summary):
   > Assign the lifecycle issue <URL> to your DM (the approver). The repo must not be
   > made public until the issue has the `Status:Approved` label.
2. Approval flow: the assignee comments and adds **`Status:Approved`** (or
   **`Status:Rejected`** with justification).
3. Only after `Status:Approved`: set the repo public
   (`gh repo edit Jahia/REPO --visibility public --accept-visibility-change-consequences`)
   and complete the template's post-approval checklist (topics, license, custom
   properties — especially Owner, permissions).
