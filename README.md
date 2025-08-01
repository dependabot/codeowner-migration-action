# Dependabot Reviewers to CODEOWNERS Migration

This GitHub Actions [workflow](https://raw.githubusercontent.com/dependabot/codeowner-migration-action/main/sync-dependabot-reviewers.yml) automatically migrates reviewers from your `.github/dependabot.yml` file to the `CODEOWNERS`.

## Purpose

Dependabot is [removing](https://github.blog/changelog/2025-04-29-dependabot-reviewers-configuration-option-being-replaced-by-code-owners/) the reviewers feature which can be replaced by CODEOWNERS file. This action workflow facilitates easier transition from reviewers to CODEOWNERS based reviewers management. 

## Features

- **One step migration**: Migrate reviewers permissions with single action run
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
Place [actions workflow](https://raw.githubusercontent.com/dependabot/codeowner-migration-action/main/sync-dependabot-reviewers.yml) file at `.github/workflows/sync-dependabot-reviewers.yml` in your repository.

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

# Alternative 1: Dependabot Reviewers Migration Script

Bash script to migrate Dependabot reviewers from `.github/dependabot.yml` to `CODEOWNERS` file. Works with Windows, Linux, Solaris, macOS, BSD etc (requires bash support to work).

## Quick Start

### Option 1 : Basic usage
1. **[Download](https://raw.githubusercontent.com/dependabot/codeowner-migration-action/main/migrate-dependabot-reviewers.sh) and place script** `migrate-dependabot-reviewers.sh` in your repository root folder
2. **Run script**: `./migrate-dependabot-reviewers.sh`
3. Script will update existing CODEOWNERS or generate a new file if required
4. **Review, commit and push** CODEOWNERS file

### Option 2 : Download and Execute
1. Navigate to repository root folder in Bash and execute following commands:

```bash
curl -O https://raw.githubusercontent.com/dependabot/codeowner-migration-action/main/migrate-dependabot-reviewers.sh
chmod +x migrate-dependabot-reviewers.sh
./migrate-dependabot-reviewers.sh
```

2. **Review, commit and push** CODEOWNERS file

## Requirements

### Minimum Requirements
- **bash shell** (only requirement - available on all target platforms)

## Platform Support

### Fully Supported Platforms

| Platform | Environment | Status | Notes |
|----------|-------------|--------|-------|
| **Linux** | All distributions | ✅ Full | All shells and distributions |
| **Windows** | Git Bash | ✅ Full | Recommended for Windows |
| **Windows** | WSL/WSL2 | ✅ Full | All Linux distributions |
| **Windows** | Command Prompt | ✅ Limited | Requires bash in PATH |
| **macOS** | Terminal | ✅ Full | Works with default bash 3.2+ |
| **Solaris** | All versions | ✅ Full | Modern and traditional |
| **FreeBSD** | All versions | ✅ Full | All BSD variants |
| **AIX** | All versions | ✅ Full | Enterprise Unix |

### Platform-Specific Examples

#### Linux (Any Distribution)
```bash
./migrate-dependabot-reviewers.sh
```

#### Windows
```bash
# Git Bash (Recommended)
./migrate-dependabot-reviewers.sh

# WSL Ubuntu
./migrate-dependabot-reviewers.sh

# Command Prompt (if bash is in PATH)
bash migrate-dependabot-reviewers.sh

# PowerShell (if bash is available)
bash ./migrate-dependabot-reviewers.sh
```

#### macOS
```bash
# Terminal (works with default bash 3.2)
./migrate-dependabot-reviewers.sh

# With newer bash from Homebrew
/usr/local/bin/bash ./migrate-dependabot-reviewers.sh
```

#### Solaris
```bash
# Modern Solaris
./migrate-dependabot-reviewers.sh

# Traditional Solaris
/usr/bin/bash ./migrate-dependabot-reviewers.sh
```

## Example Usage

### Simple Example

**Input (`dependabot.yml`):**
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/frontend"
    reviewers: 
      - "frontend-team"
      - "alice"
    schedule:
      interval: "weekly"
```

**Command:**
```bash
./migrate-dependabot-reviewers.sh
```

**Output (`CODEOWNERS`):**
```
# Dependabot reviewers (migrated from .github/dependabot.yml)
/frontend/package.json @frontend-team @alice
/frontend/package-lock.json @frontend-team @alice
/frontend/npm-shrinkwrap.json @frontend-team @alice
/frontend/yarn.lock @frontend-team @alice
/frontend/pnpm-lock.yaml @frontend-team @alice
```

### Complex Example

**Input (`dependabot.yml`):**
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    reviewers: 
      -  "frontend-team"
    
  - package-ecosystem: "bundler"
    directory: "/api"
    reviewers: 
      - "backend-team"
      - "senior-dev"
    
  - package-ecosystem: "docker"
    directory: "/containers"
    reviewers: 
      - "devops-team"
    
  - package-ecosystem: "terraform"
    directory: "/infrastructure"
    reviewers: 
      - "platform-team"
```

**Generated CODEOWNERS:**
```
# Dependabot reviewers (migrated from .github/dependabot.yml)
/*.gemspec @frontend-team
/package.json @frontend-team
/package-lock.json @frontend-team
/api/Gemfile @backend-team @senior-dev
/api/Gemfile.lock @backend-team @senior-dev
/api/*.gemspec @backend-team @senior-dev
/containers/Dockerfile @devops-team
/containers/Dockerfile.* @devops-team
/containers/*.dockerfile @devops-team
/infrastructure/*.tf @platform-team
/infrastructure/*.tfvars @platform-team
/infrastructure/*.hcl @platform-team
```

## Troubleshooting

### Common Issues

#### "dependabot.yml file not found"
**Problem**: Script cannot find the dependabot configuration
**Solutions**:
1. Ensure you're in the repository root
2. Check that `.github/dependabot.yml` exists
3. Verify file permissions

#### "No reviewers found in dependabot.yml"
**Problem**: No reviewers sections in dependabot.yml
**Solutions**:
1. Add `reviewers:` sections to your dependabot.yml
2. Verify YAML syntax is correct
3. Check that updates have reviewers defined

### Platform-Specific Issues

#### Windows Command Prompt
```cmd
# If bash not found
where bash
# Install Git for Windows or use WSL

# Run with full path
"C:\Program Files\Git\bin\bash.exe" migrate-dependabot-reviewers.sh
```

#### macOS Older Bash
```bash
# Check bash version
bash --version

# Use newer bash if available
/usr/local/bin/bash ./migrate-dependabot-reviewers.sh
```

#### Solaris Path Issues
```bash
# Use full path to bash
/usr/bin/bash ./migrate-dependabot-reviewers.sh

# Add to PATH if needed
export PATH="/usr/bin:$PATH"
```

-----

# Alternative 2: Manual Migration

For users who prefer to migrate reviewers manually without using any scripts or automated tools, this section provides step-by-step instructions to convert your `dependabot.yml` reviewers to `CODEOWNERS` entries.

### Step-by-Step Manual Process

#### Step 1: Locate Your Files
1. Open your repository's `.github/dependabot.yml` file
2. Create or open the `CODEOWNERS` file in one of these locations:
   - `CODEOWNERS` (repository root)
   - `.github/CODEOWNERS` 
   - `docs/CODEOWNERS`

#### Step 2: Identify Reviewers in dependabot.yml
Look for sections with `reviewers` in your dependabot.yml:
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/frontend"
    reviewers: 
      - "frontend-team"
      - "alice"
    
  - package-ecosystem: "bundler" 
    directory: "/"
    reviewers: 
      - "backend-team"
```

#### Step 3: Map Ecosystems to Manifest Files
For each package ecosystem, identify the specific manifest files it manages:

| Ecosystem | Manifest Files to Add to CODEOWNERS |
|-----------|-------------------------------------|
| `bundler` | `Gemfile`, `Gemfile.lock`, `*.gemspec` |
| `npm` | `package.json`, `package-lock.json`, `npm-shrinkwrap.json`, `yarn.lock`, `pnpm-lock.yaml` |
| `cargo` | `Cargo.toml`, `Cargo.lock` |
| `composer` | `composer.json`, `composer.lock` |
| `docker` | `Dockerfile`, `Dockerfile.*`, `*.dockerfile` |
| `pip` | `requirements.txt`, `requirements/*.txt`, `setup.py`, `setup.cfg`, `pyproject.toml`, `Pipfile`, `Pipfile.lock` |
| `gomod` | `go.mod`, `go.sum` |
| `gradle` | `build.gradle`, `build.gradle.kts`, `gradle.properties`, `settings.gradle`, `settings.gradle.kts` |
| `maven` | `pom.xml`, `*.pom` |
| `mix` | `mix.exs`, `mix.lock` |
| `pub` | `pubspec.yaml`, `pubspec.yml`, `pubspec.lock` |
| `swift` | `Package.swift`, `Package.resolved` |
| `github-actions` | `.github/workflows/*.yml`, `.github/workflows/*.yaml`, `action.yml`, `action.yaml` |
| `gitsubmodule` | `.gitmodules` |
| `devcontainers` | `.devcontainer/devcontainer.json`, `.devcontainer.json` |
| `nuget` | `*.csproj`, `*.fsproj`, `*.vbproj`, `*.sln`, `packages.config`, `Directory.Build.props`, `Directory.Packages.props` |
| `dotnet-sdk` | `*.csproj`, `*.fsproj`, `*.vbproj`, `*.sln`, `packages.config`, `global.json` |
| `terraform` | `*.tf`, `*.tfvars`, `*.hcl` |
| `elm` | `elm.json` |
| `helm` | `Chart.yaml`, `Chart.yml`, `values.yaml`, `values.yml` |

#### Step 4: Convert Directory Paths
Transform the `directory` value from dependabot.yml to CODEOWNERS patterns:

| dependabot.yml directory | CODEOWNERS pattern prefix |
|-------------------------|---------------------------|
| `"/"` | `/` (root files) |
| `"/frontend"` | `/frontend/` |
| `"/api"` | `/api/` |
| `"backend"` | `/backend/` (add leading slash) |

#### Step 5: Format Reviewers
Ensure all reviewers have the `@` prefix:
- `"frontend-team"` → `@frontend-team`
- `"alice"` → `@alice` 
- `"@already-formatted"` → `@already-formatted` (no change)

#### Step 6: Create CODEOWNERS Entries
Combine the directory path + manifest file + reviewers:

**Formula:** `[directory]/[manifest-file] [reviewers...]`

### Manual Migration Example

**Given this dependabot.yml:**
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/frontend"
    reviewers: 
      - "frontend-team"
      - "alice"
    
  - package-ecosystem: "bundler"
    directory: "/"
    reviewers: 
      - "backend-team"
    
  - package-ecosystem: "docker"
    directory: "/api"
    reviewers: 
      - "devops-team"
```

**Step-by-step conversion:**

1. **npm in /frontend with reviewers "frontend-team", "alice":**
   ```
   /frontend/package.json @frontend-team @alice
   /frontend/package-lock.json @frontend-team @alice
   /frontend/npm-shrinkwrap.json @frontend-team @alice
   /frontend/yarn.lock @frontend-team @alice
   /frontend/pnpm-lock.yaml @frontend-team @alice
   ```

2. **bundler in / with reviewers "backend-team":**
   ```
   /Gemfile @backend-team
   /Gemfile.lock @backend-team
   /*.gemspec @backend-team
   ```

3. **docker in /api with reviewers "devops-team":**
   ```
   /api/Dockerfile @devops-team
   /api/Dockerfile.* @devops-team
   /api/*.dockerfile @devops-team
   ```

**Final CODEOWNERS file:**
```
# Dependabot reviewers (migrated from .github/dependabot.yml)
/*.gemspec @backend-team
/Gemfile @backend-team
/Gemfile.lock @backend-team
/api/Dockerfile @devops-team
/api/Dockerfile.* @devops-team
/api/*.dockerfile @devops-team
/frontend/package.json @frontend-team @alice
/frontend/package-lock.json @frontend-team @alice
/frontend/npm-shrinkwrap.json @frontend-team @alice
/frontend/yarn.lock @frontend-team @alice
/frontend/pnpm-lock.yaml @frontend-team @alice
```

### Manual Migration Tips

#### ✅ Best Practices
- **Add a header comment** to identify the Dependabot section
- **Sort patterns logically**: root files first, then by directory depth
- **Test your patterns** by creating a test file and checking GitHub's code owners
- **Use consistent formatting** with spaces between patterns and reviewers

#### ⚠️ Common Mistakes to Avoid
- **Missing @ prefix** on reviewer names
- **Incorrect glob patterns** (use `*.ext` not `**.ext` for single directory)
- **Wrong directory separators** (use `/` even on Windows)
- **Forgetting manifest files** specific to each ecosystem

### Complex Scenarios

#### Multiple Directories for One Ecosystem
**dependabot.yml:**
```yaml
- package-ecosystem: "npm"
  directories: 
    - "/frontend"
    - "/admin"
    - "/mobile"
  reviewers: 
    - "frontend-team"
```

**Manual CODEOWNERS entries:**
```
/admin/package.json @frontend-team
/admin/package-lock.json @frontend-team
/frontend/package.json @frontend-team
/frontend/package-lock.json @frontend-team
/mobile/package.json @frontend-team
/mobile/package-lock.json @frontend-team
```

#### Root Directory with Subdirectories
**dependabot.yml:**
```yaml
- package-ecosystem: "docker"
  directory: "/"
  reviewers: 
    - "devops-team"
```

**Manual CODEOWNERS entries:**
```
/Dockerfile @devops-team
/Dockerfile.* @devops-team
/*.dockerfile @devops-team
/**/Dockerfile @devops-team
/**/Dockerfile.* @devops-team
/**/*.dockerfile @devops-team
```

#### Mixed Reviewer Types
**dependabot.yml:**
```yaml
- package-ecosystem: "npm"
  directory: "/app"
  reviewers: 
    - "frontend-team"
    - "alice"
    - "org/senior-devs"
```

**Manual CODEOWNERS entries:**
```
/app/package.json @frontend-team @alice @org/senior-devs
/app/package-lock.json @frontend-team @alice @org/senior-devs
```

### Validation Checklist

After manually creating your CODEOWNERS entries:

- [ ] All reviewer names have `@` prefix
- [ ] Directory paths start with `/`
- [ ] Patterns match the correct manifest files for each ecosystem
- [ ] No duplicate entries for the same file
- [ ] Entries are sorted logically (root patterns first)
- [ ] File is saved in correct location (`CODEOWNERS`, `.github/CODEOWNERS`, or `docs/CODEOWNERS`)

-----


_Dependabot team_
