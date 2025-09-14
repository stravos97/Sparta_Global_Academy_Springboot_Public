# CI/CD and Mirroring Workflows

This repository (private) serves as the source of truth. A public repository mirrors a single-commit snapshot after private checks succeed, with only the public repository publishing Docker images to GitHub Container Registry (GHCR).

## Overview

### Private Repository (This Repository)
- Runs CI tests on all pushes and pull requests
- Executes a deploy job (placeholder) on the `main` branch
- After successful tests and deployment, mirrors a sanitized single-commit snapshot to the public repository `stravos97/Sparta_Global_Academy_Springboot_Public`

### Public Repository
- Publishes Docker images to GHCR (multi-architecture: linux/amd64, linux/arm64)
- Does not run tests or mirror content elsewhere

## Private Repository: `.github/workflows/ci.yml`

### Jobs

#### `test` (Private Only)
- **Trigger**: push/PR
- Ensures MySQL service is ready (TCP poll)
- Runs `mvn -B clean test`
- Publishes "Maven Tests" checks (requires `checks: write` permissions)

#### `deploy` (Private Only, `main` Branch)
- **Dependencies**: Requires `test` job to complete
- Verifies remote database is reachable
- Builds package (placeholder deploy step for your target environment)

#### `mirror_public` (Private Only, `main` Branch)
- **Dependencies**: Requires `test` and `deploy` jobs to complete
- Creates a single-commit snapshot of the current tree
- Temporarily removes branch protection on the public repository
- Force-pushes snapshot to `main`
- Re-applies strict branch protection

### Permissions
- Top-level default: `contents: read`
- `test` adds: `checks: write`, `pull-requests: read` (for test check)
- `deploy`/`mirror_public`: `contents: read` (uses `PUBLIC_REPO_TOKEN` for admin calls)

### Secrets Used
- `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` (used by `deploy` job)
- `PUBLIC_REPO_TOKEN` (admin token on public repository; scopes: repo admin) used by `mirror_public` job

## Public Repository: `.github/workflows/publish-docker.yml`

- **Job Guard**: Runs only in public repository
    - `if: github.repository == 'stravos97/Sparta_Global_Academy_Springboot_Public'`
- **Triggers**:
    - Push to `main`
    - Release published
    - Manual dispatch
- Builds multi-architecture images (amd64 + arm64) using Buildx/QEMU
- **Tags**:
    - `latest`
    - Branch name
    - Commit `sha-*`
    - Semantic version tags on release
- Publishes to GHCR: `ghcr.io/stravos97/sparta_global_academy_springboot_public`
- Attestation step enabled (works on public repository)

### Permissions
- `contents: read`
- `packages: write`
- `attestations: write`
- `id-token: write`

## Mirroring Behavior

- Snapshot contains no commit history
- Public repository is locked down with:
    - Enforced admin requirements
    - CI checks required
    - No force push or branch deletion
    - Linear history requirement
- Mirror job temporarily disables protection (using `PUBLIC_REPO_TOKEN`), pushes the snapshot, then re-enables protection

## Operating the System

- **Regular development**: Push branches and pull requests to the private repository; CI runs automatically
- **Merge to `main` (private)**: Sequence is `test` → `deploy` → `mirror_public`
- **Public repository**: Receives new snapshot and publishes Docker images to GHCR

## Troubleshooting

### Mirror Failing on Branch Protection
- Ensure `PUBLIC_REPO_TOKEN` is a Personal Access Token with admin rights on the public repository

### Attestation Errors
- Attestations must be published from the public repository; the private repository's job is explicitly guarded against running this step

### ARM Mac Pull Error (No Matching Manifest)
- Images are multi-architecture; ensure a recent publish has completed successfully
- Check that both amd64 and arm64 architectures were built in the latest image

## Manual Operations

### Re-run Mirror After Infrastructure Outage
- Dispatch "CI Pipeline" on `main` in private repository; `mirror_public` will run after `test` and `deploy` complete

### Publish Docker on Demand
- Dispatch "Publish Docker image" workflow in public repository

## Security Notes

- Never commit real credentials; use `.env` locally and GitHub Secrets in CI
- Public repository contains only sanitized snapshot history with no sensitive information
- Public GHCR package visibility can be toggled between public and private as needed
- All credentials in the public repository are placeholders or removed during the mirroring process