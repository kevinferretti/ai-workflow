# Requirements Workflow Skills

This repo tracks a reusable Codex requirements workflow implemented as separate manually invoked skills.

## Skills

- `$requirements-workflow-init`
- `$requirements-workflow-digest`
- `$requirements-workflow-resolve`
- `$requirements-workflow-update`
- `$requirements-workflow-status`
- `$requirements-workflow-spec`
- `$requirements-workflow-plan`
- `$requirements-workflow-enhancement-plan`
- `$requirements-workflow-tasks`

Shared conventions and templates live in `skills/requirements-workflow-shared/`.

## Install Or Update Locally

From this repo root:

```powershell
$dest = Join-Path $HOME ".codex\skills"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Recurse -Force -Path ".\skills\requirements-workflow-*" -Destination $dest
```

Start a new Codex thread after installing or updating skills so discovery can refresh.

## Push To GitHub

Create an empty GitHub repo, then run:

```powershell
git remote add origin <github-repo-url>
git branch -M main
git push -u origin main
```
