# New Relic Setup Guide for PLOSolver

This guide explains how to set up New Relic monitoring for both the backend (Flask) and frontend (React) components of PLOSolver.

## Overview

New Relic provides comprehensive observability for your application, including:
- **Application Performance Monitoring (APM)** for the Flask backend
- **Browser monitoring** for the React frontend
- **Error tracking** and reporting
- **Custom event tracking** for user interactions
- **Performance metrics** and alerts

## Prerequisites

1. A New Relic account (free tier available)
2. Your New Relic license key
3. Access to your New Relic dashboard

## Step 1: Create New Relic Applications

### Backend Application (APM)
1. Log into your New Relic account
2. Go to **Add Data** → **Application monitoring** → **Python**
3. Name your application: `PLOSolver-Backend`
4. Copy your license key

### Frontend Application (Browser)
1. In New Relic, go to **Add Data** → **Browser monitoring**
2. Choose **Copy/Paste JavaScript code**
3. Name your application: `PLOSolver-Frontend`
4. Copy the application ID and other required values

## Step 2: Environment Configuration

Add the following environment variables to your `.env` files:

### For Development (.env.development)
```bash
# New Relic Configuration
NEW_RELIC_LICENSE_KEY=your-license-key-here
NEW_RELIC_ENVIRONMENT=development

# Frontend Browser Monitoring
REACT_APP_NEW_RELIC_LICENSE_KEY=your-license-key-here
REACT_APP_NEW_RELIC_APPLICATION_ID=your-app-id-here
REACT_APP_NEW_RELIC_ACCOUNT_ID=your-account-id-here
REACT_APP_NEW_RELIC_TRUST_KEY=your-trust-key-here
```

### For Production (.env.production)
```bash
# New Relic Configuration
NEW_RELIC_LICENSE_KEY=your-license-key-here
NEW_RELIC_ENVIRONMENT=production

# Frontend Browser Monitoring
REACT_APP_NEW_RELIC_LICENSE_KEY=your-license-key-here
REACT_APP_NEW_RELIC_APPLICATION_ID=your-app-id-here
REACT_APP_NEW_RELIC_ACCOUNT_ID=your-account-id-here
REACT_APP_NEW_RELIC_TRUST_KEY=your-trust-key-here
```

## Step 3: Install Dependencies

The New Relic agents have already been added to the project dependencies:

### Backend (Python)
```bash
pip install -r requirements.txt
```

### Frontend (React)
```bash
npm install
```

## Step 4: Configuration Files

### Backend Configuration
The New Relic Python agent configuration is in `src/backend/newrelic.ini`. Key settings:

- **Application name**: PLOSolver
- **License key**: Retrieved from environment variable
- **Log level**: Configurable per environment
- **SQL recording**: Enabled with obfuscation for security

### Frontend Configuration
The browser agent is configured in `src/utils/newrelic.js` with:

- **Distributed tracing**: Enabled
- **Session tracking**: Enabled
- **Error reporting**: Custom error handling
- **Custom events**: User action tracking

## Step 5: What's Being Monitored

### Backend Monitoring
- **HTTP requests** and response times
- **Database queries** (PostgreSQL)
- **Error rates** and exceptions
- **Custom transactions** for equity calculations
- **Memory and CPU usage**

### Frontend Monitoring
- **Page load times** and Core Web Vitals
- **JavaScript errors** and exceptions
- **AJAX requests** to the backend API
- **User interactions** (button clicks, form submissions)
- **Custom events**:
  - Equity simulation runs
  - Card selections
  - Spot saves/loads
  - User authentication events

### Custom Tracking Examples

#### User Actions Tracked:
- `RunEquitySimulation` - When users run equity calculations
- `SaveSpot` - When users save poker scenarios
- `LoadSpot` - When users load saved scenarios
- `UserLogin` - Authentication events
- `SimulationValidationFailed` - Form validation errors

#### Performance Metrics:
- `SimulationInitiationTime` - Time to start simulations
- `SimulationCompletionTime` - Total simulation duration
- `DatabaseQueryTime` - Database operation performance

## Step 6: Deployment Considerations

### Docker Environment
The Docker Compose configuration automatically passes New Relic environment variables to both services. No additional configuration needed.

### Production Deployment
1. Set environment variables in your production environment
2. Ensure the New Relic license key is secure (use secrets management)
3. Set `NEW_RELIC_ENVIRONMENT=production`
4. Monitor the New Relic dashboard for incoming data

## Step 7: Monitoring and Alerts

### Recommended Alerts
Set up alerts in New Relic for:

1. **High Error Rate**: > 5% error rate for 5 minutes
2. **Slow Response Time**: Average response time > 2 seconds
3. **High Memory Usage**: Memory usage > 80%
4. **Failed Simulations**: Custom alert for simulation errors

### Dashboards
Create custom dashboards to monitor:
- Equity calculation performance
- User engagement metrics
- Error rates by feature
- Database performance

## Step 8: Troubleshooting

### Common Issues

#### Backend Not Reporting
1. Check that `NEW_RELIC_LICENSE_KEY` is set
2. Verify the license key is correct
3. Check logs for New Relic initialization messages
4. Ensure `newrelic.ini` is in the correct location

#### Frontend Not Reporting
1. Verify all React environment variables are set
2. Check browser console for New Relic errors
3. Ensure the application ID matches your New Relic app
4. Check that the browser agent is initializing

#### No Custom Events
1. Verify custom tracking code is being called
2. Check browser console for tracking errors
3. Ensure events are properly formatted

### Log Files
- Backend: Check `/tmp/newrelic-python-agent.log`
- Frontend: Check browser console for New Relic messages

## Step 9: Cost Management

New Relic's free tier includes:
- 100 GB of data ingest per month
- 1 user
- 3 months of data retention

For PLOSolver's expected usage (< 500MB/day), this should be well within the free tier limits.

## Step 10: Security Considerations

- **High Security Mode**: Disabled by default, can be enabled in production
- **SQL Obfuscation**: Enabled to protect sensitive data
- **Parameter Capture**: Disabled to avoid capturing sensitive request data
- **License Key**: Store securely, never commit to version control

## Additional Resources

- [New Relic Python Agent Documentation](https://docs.newrelic.com/docs/agents/python-agent/)
- [New Relic Browser Agent Documentation](https://docs.newrelic.com/docs/browser/)
- [Custom Events and Attributes](https://docs.newrelic.com/docs/insights/event-data-sources/custom-events/)

## Support

If you encounter issues with New Relic setup:
1. Check the troubleshooting section above
2. Review New Relic's documentation
3. Check the New Relic support forums
4. Contact New Relic support if needed 