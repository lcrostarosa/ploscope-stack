# AWS Budget and Cost Monitoring Setup

This document describes the AWS Budget configuration for PLOSolver that provides cost monitoring and alerts via email and SMS notifications.

## Overview

The budget system provides:
- **Daily Budget Monitoring**: Alerts when daily spend exceeds $2.00
- **Monthly Budget Tracking**: Monitors overall monthly AWS costs
- **Multi-channel Notifications**: Email and SMS alerts for cost thresholds
- **Tiered Alerting**: Warnings at 80%, alerts at 100%, and forecasts at 120%

## Budget Configuration

### Daily Budget
- **Threshold**: $2.00 USD per day
- **Services Monitored**: Amazon SQS, CloudWatch (expandable)
- **Alert Levels**:
  - 80% ($1.60) - Warning notification
  - 100% ($2.00) - Alert notification  
  - 120% forecasted - Forecast alert

### Monthly Budget
- **Development**: $30.00 USD per month
- **Production**: $50.00 USD per month
- **Services Monitored**: All AWS services
- **Alert Levels**: Same as daily (80%, 100%, 120%)

## Notification Channels

### Email Notifications
- **Address**: lcrostar@gmail.com
- **Triggers**: All budget thresholds
- **Format**: AWS Budget email with detailed cost breakdown

### SMS Notifications
- **Phone**: +1 (561) 846-1866
- **Triggers**: All budget thresholds via SNS
- **Format**: Short text message with alert summary

## Terraform Configuration

### Environment Variables

The notification settings are configured in `env.budget`:

```bash
# Email for budget notifications
BUDGET_NOTIFICATION_EMAIL=lcrostar@gmail.com

# Phone number for SMS notifications (international format)
BUDGET_NOTIFICATION_PHONE=+15618461866

# Budget thresholds
DAILY_BUDGET_THRESHOLD=2.00
MONTHLY_BUDGET_THRESHOLD_DEV=30.00
MONTHLY_BUDGET_THRESHOLD_PROD=50.00
```

### Terraform Resources

The budget infrastructure includes:

```hcl
# SNS Topic for notifications
resource "aws_sns_topic" "budget_notifications"

# Email subscription
resource "aws_sns_topic_subscription" "budget_email"

# SMS subscription
resource "aws_sns_topic_subscription" "budget_sms"

# Daily budget with cost filters
resource "aws_budgets_budget" "daily_budget"

# Monthly budget for overall costs
resource "aws_budgets_budget" "monthly_budget"
```

## Deployment

### Initial Setup

1. **Deploy Infrastructure**:
   ```bash
   cd terraform
   terraform plan -var-file=environments/dev/terraform.tfvars
   terraform apply -var-file=environments/dev/terraform.tfvars
   ```

2. **Confirm Subscriptions**:
   - Check email for SNS subscription confirmation
   - Reply to SMS with "YES" to confirm SMS subscription

3. **Test Notifications** (Optional):
   ```bash
   aws sns publish \
     --topic-arn $(terraform output -raw budget_notifications_topic_arn) \
     --message "Test budget notification"
   ```

### Environment-Specific Configuration

#### Development Environment
```hcl
daily_budget_threshold = 2.00
monthly_budget_threshold = 30.00
```

#### Production Environment
```hcl
daily_budget_threshold = 2.00
monthly_budget_threshold = 50.00
```

## Cost Optimization Features

### Service Filtering
Daily budgets are filtered to monitor specific high-cost services:
- Amazon Simple Queue Service (SQS)
- Amazon CloudWatch
- Additional services can be added as needed

### Smart Alerting
- **80% Threshold**: Early warning for cost management
- **100% Threshold**: Immediate action required
- **120% Forecast**: Predictive alert for projected overruns

## Monitoring and Management

### AWS Console Access

1. **View Budgets**:
   - Navigate to AWS Billing → Budgets
   - View `plosolver-{env}-daily-budget` and `plosolver-{env}-monthly-budget`

2. **SNS Topic**:
   - Navigate to Amazon SNS → Topics
   - View `plosolver-{env}-budget-notifications`

3. **Cost Explorer**:
   - Use AWS Cost Explorer for detailed cost analysis
   - Filter by service, time period, and usage type

### Alert Management

#### Email Notifications
- **Unsubscribe**: Use link in budget email
- **Change Email**: Update `budget_notification_email` in terraform.tfvars
- **Re-deploy**: Run `terraform apply` to update subscription

#### SMS Notifications
- **Unsubscribe**: Reply "STOP" to any SMS
- **Change Phone**: Update `budget_notification_phone` in terraform.tfvars
- **Re-deploy**: Run `terraform apply` to update subscription

## Cost Breakdown

### Expected Daily Costs
| Service | Estimated Daily Cost |
|---------|---------------------|
| SQS Standard Queue | $0.10 - $0.50 |
| CloudWatch Logs | $0.05 - $0.20 |
| CloudWatch Metrics | $0.05 - $0.15 |
| CloudWatch Alarms | $0.10 - $0.30 |
| **Total Estimated** | **$0.30 - $1.15** |

### Cost Drivers
- **SQS Messages**: $0.40 per million requests
- **CloudWatch Logs**: $0.50 per GB ingested
- **CloudWatch Metrics**: $0.30 per metric per month
- **CloudWatch Alarms**: $0.10 per alarm per month

## Troubleshooting

### Common Issues

1. **No Email Notifications**:
   - Check spam folder
   - Verify SNS subscription is confirmed
   - Check email address in terraform.tfvars

2. **No SMS Notifications**:
   - Verify phone number format (+1XXXXXXXXXX)
   - Confirm SMS subscription via initial text
   - Check SNS topic permissions

3. **False Alerts**:
   - Review cost filters in budget configuration
   - Adjust thresholds if needed
   - Check for one-time charges vs. recurring costs

### Debug Commands

```bash
# Check SNS topic
aws sns get-topic-attributes \
  --topic-arn $(terraform output -raw budget_notifications_topic_arn)

# List budget subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw budget_notifications_topic_arn)

# View budget details
aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name $(terraform output -raw daily_budget_name)

# Check recent costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost
```

## Security Considerations

### IAM Permissions
The application has minimal SNS permissions:
- `sns:Publish` - Only to budget notification topic
- No ability to create/delete topics or subscriptions

### Data Privacy
- Phone numbers and emails are marked as sensitive in Terraform
- No personal data is stored in cost/usage reports
- SNS messages contain only cost information

### Access Control
- Budget management requires AWS console access
- Terraform state contains sensitive subscription details
- Use proper state file encryption and access controls

## Cost Alerts Action Plan

### When You Receive an Alert

1. **80% Alert (Warning)**:
   - Review current day's usage in AWS Cost Explorer
   - Identify unexpected cost drivers
   - Consider reducing non-essential operations

2. **100% Alert (Threshold Exceeded)**:
   - Immediate investigation required
   - Check for runaway processes or unexpected usage
   - Consider temporarily stopping non-critical services

3. **120% Forecast Alert**:
   - Projected to exceed budget
   - Review and optimize current usage patterns
   - Plan for potential service scaling

### Emergency Response
If costs are significantly higher than expected:
1. Check SQS queue depths and worker activity
2. Review CloudWatch log retention settings
3. Temporarily reduce worker counts
4. Contact AWS Support if charges seem incorrect

This budget system provides comprehensive cost monitoring to keep your PLOSolver infrastructure costs predictable and manageable while ensuring you're immediately notified of any unexpected spend. 