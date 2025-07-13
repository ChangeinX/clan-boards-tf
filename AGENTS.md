# Guidelines for Codex

This repository contains OpenTofu code for deploying AWS infrastructure.

## Development Guidelines
- Use 2 spaces for indentation in all `.tf` files.
- Format configuration with `terraform fmt -recursive` before committing.
- Validate configuration using:
  ```bash
  terraform init -backend=false
  terraform fmt -check -recursive
  terraform validate
  ```

- Do not modify `.terraform.lock.hcl`.
- Do not commit state files or the `.terraform` directory.
- Update `README.md` when variables, outputs or modules change.

## Commit Messages
- Begin with a short imperative summary, e.g. "Add new module".
- Include additional context below the first line if useful.

## Pull Requests
- In the PR description, summarize what changed.
- Mention that `terraform fmt` and `terraform validate` were run.
