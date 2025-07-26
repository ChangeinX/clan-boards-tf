# Guidelines for Codex

This repository contains `OpenTofu` code for deploying AWS infrastructure. 
You have tofu installed, but no access to deployed resources.

## Development Guidelines
- Use 2 spaces for indentation in all `.tf` files.
- Format configuration with `tofu fmt -recursive` before committing.
- Validate configuration using:
  ```bash
  tofu init -backend=false
  tofu fmt -check -recursive
  tofu validate
  ```

- Check for updates to `main` before starting work:
  ```bash
  git fetch origin
  git log HEAD..origin/main --oneline
  ```
  Merge or rebase if new commits exist.

- Do not modify `.terraform.lock.hcl`.
- Do not commit state files or the `.terraform` directory.
- Update `README.md` when variables, outputs or modules change.

## Commit Messages
- Begin with a short imperative summary, e.g. "Add new module".
- Include additional context below the first line if useful.

## Pull Requests
- In the PR description, summarize what changed.
- Mention that `tofu fmt` and `tofu validate` were run.
