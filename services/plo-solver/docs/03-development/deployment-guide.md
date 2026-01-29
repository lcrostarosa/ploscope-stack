# Deployment Guide

This guide explains how to deploy the PLOSolver application to different environments using the GitHub Actions workflows.

## Deployment Workflows

### 1. Manual Deployment (`deploy.yml`)

Use this workflow for manual deployments to staging or production environments.

#### Triggering a Manual Deployment

1. Go to the **Actions** tab in GitHub
2. Select **Deployment** workflow
3. Click **Run workflow**
4. Fill in the required parameters:

**Required Parameters:**
- **Environment**: Choose `staging` or `production`
- **Branch or PR**: Specify the branch name or PR number to deploy from
- **Tag** (Production only): Specify the image tag for production deployments
- **Force Deploy**: Optional flag to force deployment even if no changes

#### Examples

**Staging Deployment from Feature Branch:**
- Environment: `staging`
- Branch or PR: `feature/new-feature`
- Tag: (leave empty - will use branch name as tag)

**Production Deployment:**
- Environment: `production`
- Branch or PR: `master` (only master is allowed for production)
- Tag: `1.2.3` (required for production)

### 2. PR Deployment (`pr-deploy.yml`)

This workflow automatically deploys PRs to staging when triggered by a comment.

#### Triggering PR Deployment

1. Create a pull request
2. Add a comment with the exact text: **`Deploy staging`**
3. The workflow will automatically:
   - **Immediately comment** with deployment status and action link
   - Deploy the PR branch to staging
   - Use tag format: `pr-{PR_NUMBER}`
   - **Fallback to `staging` tag if PR-specific images don't exist**
   - **Update the comment** with final deployment results

#### Example PR Comment
```
Deploy staging
```

#### Comment Behavior

**Initial Comment (Immediate):**
```
🚀 Staging deployment started!

Details:
- 🌿 Branch: feature/new-feature
- 🏷️  Requested Tag: pr-123
- 🌐 Environment: Staging
- 🔗 View Deployment Progress

Deployment is in progress... ⏳
```

**Final Comment (Success):**
```
🎉 Staging deployment successful!

Details:
- 🌿 Branch: feature/new-feature
- 🏷️  Requested Tag: pr-123
- 🌐 Environment: Staging
- 🔗 Application: https://ploscope.com
- 📦 Images:
  - Frontend: pr-123
  - Backend: pr-123
- 📋 View Deployment Logs

Your changes are now live on staging! ✅
```

**Final Comment (Failure):**
```
❌ Staging deployment failed!

Details:
- 🌿 Branch: feature/new-feature
- 🏷️  Tag: pr-123
- 🌐 Environment: Staging
- 📋 View Deployment Logs

Please check the deployment logs for more details. 🔍
```

#### Fallback Behavior

If PR-specific images (e.g., `pr-123`) haven't been built yet, the deployment will automatically fallback to the `staging` tag:

- **Frontend**: Tries `pr-{PR_NUMBER}` → Falls back to `staging`
- **Backend**: Tries `pr-{PR_NUMBER}` → Falls back to `staging`

This ensures deployments don't fail when PR images are still being built or don't exist.

#### Example PR Deployment Output

**Successful deployment with PR images:**
```
🎉 Staging deployment successful!

Details:
- 🌿 Branch: feature/new-feature
- 🏷️  Requested Tag: pr-123
- 🌐 Environment: Staging
- 🔗 Application: https://ploscope.com
- 📦 Images:
  - Frontend: pr-123
  - Backend: pr-123

Your changes are now live on staging!
```

**Successful deployment with fallback:**
```
🎉 Staging deployment successful!

Details:
- 🌿 Branch: feature/new-feature
- 🏷️  Requested Tag: pr-123
- 🌐 Environment: Staging
- 🔗 Application: https://ploscope.com
- 📦 Images:
  - Frontend: staging
  - Backend: staging

⚠️ Fallback Information:
- Requested tag: pr-123
- Frontend used: staging (fallback to staging)
- Backend used: staging (fallback to staging)

Your changes are now live on staging!
```

## Branch Restrictions

### Production Deployments
- **Only the `master` branch is allowed** for production deployments
- A specific image tag must be provided
- This ensures production stability and version control

### Staging Deployments
- Any branch can be deployed to staging
- Feature branches, PR branches, and master are all allowed
- Useful for testing changes before production

## Tag Naming Convention

### Manual Deployments
- **Production**: Use semantic versioning (e.g., `1.2.3`)
- **Staging**: Defaults to branch name if no tag specified

### PR Deployments
- **Format**: `pr-{PR_NUMBER}`
- **Example**: `pr-123` for PR #123

## Environment-Specific Configuration

### Staging Environment
- **URL**: https://ploscope.com
- **Purpose**: Testing and validation
- **Deployment**: Any branch allowed
- **Tag**: Flexible naming

### Production Environment
- **URL**: https://ploscope.com
- **Purpose**: Live application
- **Deployment**: Master branch only
- **Tag**: Semantic versioning required

## Health Checks

Both workflows include health checks that:
1. Wait 60 seconds for deployment to complete
2. Perform up to 10 health check attempts
3. Verify the application is responding at https://ploscope.com
4. Fail the deployment if health checks fail

## Monitoring

### Deployment Status
- Check the **Actions** tab for workflow status
- Review deployment logs for detailed information
- Monitor health check results

### Application Monitoring
- **Traefik Dashboard**: https://ploscope.com:8080
- **Application**: https://ploscope.com

## Troubleshooting

### Common Issues

1. **Production Branch Restriction**
   - Error: "Production deployments can only be made from the 'master' branch"
   - Solution: Ensure you're deploying from the master branch

2. **Missing Production Tag**
   - Error: "For production deployments, you must provide the image tag"
   - Solution: Provide a semantic version tag (e.g., 1.2.3)

3. **Health Check Failures**
   - Error: "Application health check failed"
   - Solution: Check application logs and ensure services are starting correctly

4. **PR Comment Trigger Not Working**
   - **Issue**: Commenting "Deploy staging" doesn't trigger deployment
   - **Debug Steps**:
     1. Check the **Actions** tab to see if any workflows are triggered
     2. Look for the "Test PR Comment Trigger" workflow for debug information
     3. Verify the comment is on a Pull Request (not an Issue)
     4. Ensure the comment contains exactly "Deploy staging" (case sensitive)
     5. Check repository permissions for workflow execution
   - **Common Solutions**:
     - Make sure you're commenting on a PR, not an issue
     - Use exact text: "Deploy staging" (with capital D and S)
     - Check that the PR is open and not draft
     - Verify you have permission to trigger workflows in the repository

### Getting Help

If you encounter issues:
1. Check the workflow logs in the Actions tab
2. Verify all required secrets are configured
3. Ensure the target environment is accessible
4. Contact the development team for assistance

## Security Considerations

- All deployments require proper GitHub permissions
- Production deployments are restricted to master branch only
- SSH keys and secrets are required for server access
- Environment-specific secrets are used for each deployment
