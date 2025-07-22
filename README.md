# Dependabot Reviewers to CODEOWNERS Migration

This GitHub Actions workflow automatically migrates reviewers from your `.github/dependabot.yml` file to the `CODEOWNERS`.

## Purpose

Dependabot is [deprecating](https://github.blog/changelog/2025-04-29-dependabot-reviewers-configuration-option-being-replaced-by-code-owners/) the reviewers feature which will be replaced by CODEOWNERS file. Existing users who are still using `dependabot.yml` reviewers feature will not able to use review process configured through `dependabot.yml` file. This action workflow facilitates easier transition from reviwers to CODEOWNERS based reviewers management. 

## Features

- **One step migration**: Migrate reviewers permissions with single action run
- **Precise Permissions**: Only adds CODEOWNERS entries for actual manifest files
- **No Over-Permissioning**: Avoids granting access to entire directories
- **Preserve existing permissions**: maintains existing permissions in CODEOWNERS file 
- **Manual Trigger**: Runs on-demand via `workflow_dispatch`

## How It Works

### Input (dependabot.yml)
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/frontend"
    reviewers:
      - "alice"
      - "frontend-team"
    
  - package-ecosystem: "docker"
    directories:
      - "/"
      - "/backend"
    reviewers:
      - "devops-team"
    
  - package-ecosystem: "bundler"
    directory: "/"
    reviewers:
      - "backend-team"
```

### Output (CODEOWNERS)
```
# Dependabot reviewers (migrated from .github/dependabot.yml)

/*.dockerfile @devops-team
/*.gemspec @backend-team
/Dockerfile @devops-team
/Dockerfile.* @devops-team
/Gemfile @backend-team
/Gemfile.lock @backend-team
/backend/*.dockerfile @devops-team
/backend/Dockerfile @devops-team
/backend/Dockerfile.* @devops-team
/frontend/package.json @frontend-team @alice
/frontend/package-lock.json @frontend-team @alice
/frontend/npm-shrinkwrap.json @frontend-team @alice
```

## Configuration and Usage

### Workflow File
Place this file at `.github/workflows/sync-dependabot-reviewers.yml` in your repository.

### Manual Trigger

1. Go to **Actions** tab in your GitHub repository
2. Select **"Migrate Dependabot Reviewers to CODEOWNERS"** workflow
3. Click **"Run workflow"**
4. The workflow will create a PR if changes are needed


### Required Permissions
The workflow needs:
- `contents: write` - to update CODEOWNERS file
- `pull-requests: write` - to create pull requests

## Troubleshooting

### No Reviewers Found
```
No reviewers found in dependabot.yml
```
**Solution**: Ensure your `dependabot.yml` has `reviewers` sections defined for the package ecosystems you want to sync.

### File Not Found
```
dependabot.yml file not found
```
**Solution**: Make sure `.github/dependabot.yml` exists in your repository.

### No Changes Detected
```
No changes needed - CODEOWNERS is already up to date
```
**This is normal**: The workflow only creates PRs when there are actual changes to make.

### Can't see the new PR when existing migration PR is open

If action migration PR is already open, changes are made to open PR instead of creating new PR

-----


_Dependabot team_
