# 📊 PLO Solver Analytics Setup Guide

This guide will help you integrate **Google Analytics 4**, **Microsoft Clarity**, and **PostHog** into your PLO Solver application for comprehensive user behavior tracking and insights.

## 🎯 What You'll Get

- **Google Analytics 4**: Traffic analysis, user acquisition, conversion tracking
- **Microsoft Clarity**: Session recordings, heatmaps, user behavior insights
- **PostHog**: Product analytics, feature flags, A/B testing, funnels

## 📋 Prerequisites

- React application (PLO Solver)
- Environment variable support
- Admin access to create analytics accounts

## 🚀 Quick Start

### 1. Set Up Analytics Accounts

#### Google Analytics 4
1. Go to [Google Analytics](https://analytics.google.com/)
2. Create a new GA4 property
3. Get your **Measurement ID** (format: `G-XXXXXXXXXX`)

#### Microsoft Clarity
1. Go to [Microsoft Clarity](https://clarity.microsoft.com/)
2. Create a new project
3. Get your **Project ID** (format: `xxxxxxxxxx`)

#### PostHog
1. Go to [PostHog](https://posthog.com/) or use self-hosted
2. Create a new project
3. Get your **API Key** (format: `phc_xxxxxxxxxx`)

### 2. Configure Environment Variables

Copy `analytics-config.example.env` to your `.env` file and update with your credentials:

```bash
# Google Analytics 4
REACT_APP_GA_MEASUREMENT_ID=G-YOUR-MEASUREMENT-ID

# Microsoft Clarity
REACT_APP_CLARITY_PROJECT_ID=your-project-id

# PostHog
REACT_APP_POSTHOG_API_KEY=phc_your-api-key
REACT_APP_POSTHOG_HOST=https://app.posthog.com

# Feature flags (optional)
REACT_APP_ENABLE_GA=true
REACT_APP_ENABLE_CLARITY=true
REACT_APP_ENABLE_POSTHOG=true
```

### 3. Import and Use Analytics

The analytics utility is already created at `src/utils/analytics.js`. Here's how to use it:

```javascript
import { 
    trackPageView, 
    trackEvent, 
    trackEquityCalculation,
    identifyUser 
} from '../utils/analytics.js';

// Track page views
trackPageView('/equity-calculator', 'Equity Calculator');

// Track user actions
trackEvent('button_click', {
    category: 'interaction',
    button_name: 'calculate_equity'
});

// Track equity calculations
trackEquityCalculation(parameters, results, duration, success);

// Identify users
identifyUser('user_123', {
    subscription_tier: 'premium',
    signup_date: '2024-01-01'
});
```

## 📊 Available Tracking Methods

### Core Tracking
- `trackPageView(path, title)` - Track page navigation
- `trackEvent(eventName, properties)` - Track custom events
- `identifyUser(userId, properties)` - Identify users across platforms
- `setUserProperties(properties)` - Set user attributes

### PLO Solver Specific
- `trackEquityCalculation(params, results, duration, success)` - Track calculations
- `trackSpotAnalysis(spotData, success)` - Track training activities
- `trackFeatureUsage(featureName, category, duration, interactions)` - Track feature adoption

### Advanced Features
- `trackError(errorType, message, context)` - Error monitoring
- `trackPerformance(metricName, value, context)` - Performance tracking
- `trackConversion(conversionName, value, context)` - Conversion tracking
- `getFeatureFlag(flagKey)` - A/B testing with PostHog
- `isFeatureEnabled(flagKey)` - Feature flag checks

### Privacy Controls
- `optOut()` - Allow users to opt out of tracking
- `optIn()` - Allow users to opt back in

## 🔧 Integration Examples

### Basic Page Component

```javascript
import React, { useEffect } from 'react';
import { trackPageView, trackFeatureUsage } from '../utils/analytics.js';

const EquityCalculator = () => {
    useEffect(() => {
        // Track page view
        trackPageView('/equity-calculator', 'Equity Calculator');
        
        // Track feature usage
        trackFeatureUsage('equity_calculator', 'calculation', null, 1);
    }, []);

    return (
        <div>
            {/* Your component content */}
        </div>
    );
};
```

### User Authentication

```javascript
import { identifyUser, setUserProperties, trackEvent } from '../utils/analytics.js';

const handleLogin = (userData) => {
    // Identify user across all platforms
    identifyUser(userData.id, {
        email: userData.email,
        subscription_tier: userData.subscription_tier,
        signup_date: userData.created_at
    });

    // Set additional properties
    setUserProperties({
        user_type: userData.subscription_tier,
        last_login: new Date().toISOString()
    });

    // Track login event
    trackEvent('user_login', {
        category: 'authentication',
        method: 'email'
    });
};
```

### Equity Calculation Tracking

```javascript
import { trackEquityCalculation, trackError } from '../utils/analytics.js';

const calculateEquity = async (parameters) => {
    const startTime = performance.now();
    
    try {
        const results = await api.calculateEquity(parameters);
        const duration = (performance.now() - startTime) / 1000;
        
        // Track successful calculation
        trackEquityCalculation(parameters, results, duration, true);
        
        return results;
    } catch (error) {
        const duration = (performance.now() - startTime) / 1000;
        
        // Track failed calculation
        trackEquityCalculation(parameters, null, duration, false);
        trackError('calculation_error', error.message, {
            feature: 'equity_calculator'
        });
        
        throw error;
    }
};
```

### A/B Testing with PostHog

```javascript
import { getFeatureFlag, isFeatureEnabled } from '../utils/analytics.js';

const MyComponent = () => {
    // Get feature flag value
    const buttonColor = getFeatureFlag('button_color_test');
    
    // Check if feature is enabled
    const showAdvancedFeatures = isFeatureEnabled('advanced_features');
    
    return (
        <div>
            <button 
                style={{ 
                    backgroundColor: buttonColor === 'green' ? '#4CAF50' : '#2196F3' 
                }}
            >
                Calculate Equity
            </button>
            
            {showAdvancedFeatures && (
                <div>Advanced features content</div>
            )}
        </div>
    );
};
```

## 🎛️ Dashboard Access

### Google Analytics 4
- **URL**: https://analytics.google.com/
- **Key Reports**: 
  - Realtime overview
  - Acquisition reports
  - Engagement reports
  - Conversion tracking

### Microsoft Clarity
- **URL**: https://clarity.microsoft.com/
- **Key Features**:
  - Session recordings
  - Heatmaps
  - Insights dashboard
  - User behavior analysis

### PostHog
- **URL**: https://app.posthog.com/ (or your self-hosted URL)
- **Key Features**:
  - Event tracking
  - Funnel analysis
  - Feature flags
  - A/B testing
  - Cohort analysis

## 🔍 What Gets Tracked

### Automatic Tracking
- Page views and navigation
- Session duration
- User agent and device info
- JavaScript errors (via error boundaries)

### Manual Tracking (You Add)
- Button clicks and interactions
- Equity calculations with parameters
- Spot analysis activities
- Feature usage patterns
- User authentication events
- Performance metrics

### Privacy-Safe Data
- No personal information stored
- User IDs are hashed
- IP addresses anonymized
- GDPR compliant opt-out options

## 🛠️ Testing Your Setup

Use the provided `AnalyticsIntegrationExample` component to test your integration:

```javascript
import { AnalyticsIntegrationExample } from './components/AnalyticsIntegrationExample';

// Add to your app for testing
<AnalyticsIntegrationExample />
```

This component provides:
- Live analytics status indicators
- Test buttons for all tracking methods
- Real-time feedback on tracking calls
- Feature flag demonstrations

## 🚨 Troubleshooting

### Analytics Not Loading
1. Check environment variables are set correctly
2. Verify network isn't blocking analytics scripts
3. Check browser console for errors
4. Ensure you're not in an ad-blocker environment

### Events Not Appearing
1. **Google Analytics**: Events may take 24-48 hours to appear in reports
2. **Microsoft Clarity**: Sessions appear within minutes
3. **PostHog**: Events appear immediately in live view

### Feature Flags Not Working
1. Ensure PostHog is properly initialized
2. Check that feature flags are created in PostHog dashboard
3. Verify user is identified before checking flags

### Common Issues

```javascript
// ❌ Wrong - checking flags before initialization
const flag = getFeatureFlag('my_flag'); // May return null

// ✅ Correct - wait for initialization or provide fallback
const flag = getFeatureFlag('my_flag') || 'default_value';
```

## 📈 Best Practices

### Event Naming
- Use consistent naming conventions
- Include category for organization
- Add context properties for filtering

```javascript
// ✅ Good event structure
trackEvent('equity_calculation_complete', {
    category: 'calculation',
    success: true,
    duration: 2.5,
    iterations: 10000,
    player_count: 2
});
```

### User Privacy
- Always provide opt-out options
- Don't track sensitive information
- Be transparent about data collection

### Performance
- Analytics calls are async and won't block UI
- Failed analytics calls won't crash your app
- Consider batching events for high-frequency actions

### Testing
- Test in development with debug mode enabled
- Use the integration example component
- Verify events in each platform's dashboard

## 🔒 Privacy & Compliance

### GDPR Compliance
- Users can opt out via `optOut()` method
- No personal data is tracked by default
- IP addresses are anonymized
- Data retention follows platform policies

### Cookie Usage
- Google Analytics uses cookies for user identification
- Microsoft Clarity uses session storage
- PostHog can work without cookies (cookieless mode)

### Data Processing
- All platforms process data according to their privacy policies
- Consider adding privacy policy updates
- Inform users about analytics in your terms of service

## 🎯 Next Steps

1. **Set up accounts** for all three platforms
2. **Configure environment variables** with your credentials
3. **Test the integration** using the example component
4. **Add tracking calls** to your existing components
5. **Set up dashboards** and alerts in each platform
6. **Create feature flags** in PostHog for A/B testing
7. **Monitor and optimize** based on insights

## 📞 Support

If you need help with the integration:

1. Check the browser console for error messages
2. Verify your environment variables are correct
3. Test with the provided example component
4. Review each platform's documentation:
   - [Google Analytics 4 Docs](https://developers.google.com/analytics/devguides/collection/ga4)
   - [Microsoft Clarity Docs](https://docs.microsoft.com/en-us/clarity/)
   - [PostHog Docs](https://posthog.com/docs)

Happy tracking! 🚀 