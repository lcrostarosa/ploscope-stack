# PLOSolver Core Package Publishing

This document explains how to publish the `plosolver-core` package to GitHub Packages using the automated workflow.

## Prerequisites

1. **GitHub CLI**: Install and authenticate with GitHub CLI
   ```bash
   # macOS
   brew install gh
   
   # Ubuntu/Debian
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   sudo apt update && sudo apt install gh
   
   # Authenticate
   gh auth login
   ```

2. **Repository Access**: Ensure you have write access to the repository

## Publishing Methods

### Method 1: Manual Workflow Trigger (Recommended)

Use the Makefile target to trigger the GitHub Actions workflow:

```bash
make publish-package
```

This will:
- Check that GitHub CLI is installed and authenticated
- Prompt you for a version number (e.g., `1.0.1`, `2.0.0`)
- Trigger the "Publish PLOSolver Core Package" workflow
- Provide a link to monitor the progress

### Method 2: Git Tag (Automatic)

Create and push a version tag to automatically trigger publishing:

```bash
make publish-tag
```

This will:
- Prompt you for a version number
- Create a git tag with the format `v{version}` (e.g., `v1.0.1`)
- Push the tag to GitHub
- Automatically trigger the publishing workflow

### Method 3: Manual GitHub Actions

You can also trigger the workflow manually through the GitHub web interface:

1. Go to **Actions** → **Publish PLOSolver Core Package**
2. Click **Run workflow**
3. Enter the version number
4. Click **Run workflow**

## Version Numbering

Follow semantic versioning (SemVer):
- **Major version** (1.0.0 → 2.0.0): Breaking changes
- **Minor version** (1.0.0 → 1.1.0): New features, backward compatible
- **Patch version** (1.0.0 → 1.0.1): Bug fixes, backward compatible

## Installation

Once published, the package can be installed from GitHub Packages:

```bash
# Install from GitHub Packages
pip install plosolver-core --extra-index-url https://pip.pkg.github.com/PLOScope/plo-solver/

# Or using a GitHub token
pip install plosolver-core --extra-index-url https://__token__:${GITHUB_TOKEN}@pip.pkg.github.com/PLOScope/plo-solver/
```

## Monitoring

After triggering the workflow, you can monitor the progress at:
https://github.com/PLOScope/plo-solver/actions

The workflow will:
1. Build the package
2. Run tests
3. Publish to GitHub Packages
4. Create a GitHub release (for tag-based publishing)

## Troubleshooting

### GitHub CLI Not Authenticated
```bash
gh auth login
```

### Permission Denied
Ensure you have write access to the repository and packages:write permissions.

### Workflow Failed
Check the GitHub Actions logs for detailed error messages and ensure all tests pass.

### Package Already Exists
GitHub Packages does not allow overwriting existing versions. Increment the version number.
