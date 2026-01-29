# Support Integration Setup Guide

This guide will help you integrate Zoho Desk for support ticketing and knowledge base, along with Tawk.to for live chat functionality into your PLO Solver application.

## Overview

The support integration provides:
- **Zoho Desk**: Professional support ticketing system and knowledge base
- **Tawk.to**: Free live chat widget for real-time customer support
- **Unified Interface**: Single support widget that provides access to all support channels
- **Cookie Consent**: Respects user privacy preferences for functional cookies
- **User Context**: Automatically identifies users and passes relevant information

## Features

### Zoho Desk Integration
- **Support Portal Widget**: Embedded widget for creating and tracking tickets
- **Knowledge Base**: Direct access to help articles and documentation
- **Quick Ticket Creation**: In-app form for rapid ticket submission
- **User Context**: Automatic user identification with subscription and session data
- **Custom Fields**: Captures user type, browser info, URL, and session details

### Tawk.to Integration
- **Live Chat Widget**: Real-time chat with your support team
- **Offline Messages**: Users can leave messages when agents are offline
- **User Identification**: Passes user details to chat agents
- **Mobile Responsive**: Works seamlessly on desktop and mobile
- **Customizable**: Configurable positioning and styling

### Unified Support Widget
- **Single Entry Point**: One widget for all support options
- **Context-Aware**: Shows available options based on configuration
- **Dark Mode Support**: Matches your application's theme
- **Privacy Compliant**: Only loads when functional cookies are allowed

## Setup Instructions

### 1. Zoho Desk Setup

#### A. Create Zoho Desk Account
1. Go to [Zoho Desk](https://desk.zoho.com/) and sign up for an account
2. Complete the initial setup and create your support portal

#### B. Configure Web Widget
1. In Zoho Desk, go to **Settings > Channels > Web Widget**
2. Create a new web widget or use the default one
3. Configure the widget settings:
   - **Widget Name**: PLO Solver Support
   - **Portal**: Your support portal
   - **Department**: Select appropriate department
   - **Position**: Bottom Right (or your preference)
   - **Theme**: Modern
   - **Button Text**: "Need Help?"

#### C. Get Widget Credentials
1. After creating the widget, note down:
   - **Widget ID**: Found in the widget settings
   - **Portal ID**: Your organization's portal ID
   - **Department ID**: The department handling support
   - **Domain**: Your Zoho Desk domain (e.g., `yourorg.desk.zoho.com`)

#### D. Setup Knowledge Base (Optional)
1. Go to **Knowledge Base** in Zoho Desk
2. Create categories and articles for common questions
3. Note the Knowledge Base URL for the configuration

### 2. Tawk.to Setup

#### A. Create Tawk.to Account
1. Go to [Tawk.to](https://www.tawk.to/) and create a free account
2. Complete the initial onboarding

#### B. Create Property
1. In the Tawk.to dashboard, create a new property
2. Set the property name as "PLO Solver"
3. Enter your website URL

#### C. Get Widget Credentials
1. After creating the property, go to **Administration > Chat Widget**
2. Note down:
   - **Property ID**: The site ID for your property
   - **Widget ID**: The widget ID (also called widget key)

#### D. Configure Widget (Optional)
1. Customize the widget appearance:
   - **Theme Color**: #2563eb (to match PLO Solver branding)
   - **Position**: Bottom Right
   - **Offline Message**: "Leave us a message!"
2. Set up departments and agents as needed

### 3. Application Configuration

#### A. Environment Variables
Add the following variables to your `.env` file:

```bash
# Zoho Desk Configuration
REACT_APP_ZOHO_DESK_ENABLED=true
REACT_APP_ZOHO_DESK_WIDGET_ID=your-zoho-desk-widget-id
REACT_APP_ZOHO_DESK_PORTAL_ID=your-zoho-desk-portal-id
REACT_APP_ZOHO_DESK_DEPARTMENT_ID=your-zoho-desk-department-id
REACT_APP_ZOHO_DESK_DOMAIN=yourorg.desk.zoho.com
REACT_APP_ZOHO_DESK_KB_URL=https://yourorg.desk.zoho.com/portal/kb
REACT_APP_ZOHO_DESK_POSITION=bottom-right

# Tawk.to Configuration
REACT_APP_TAWK_TO_ENABLED=true
REACT_APP_TAWK_TO_PROPERTY_ID=your-tawk-to-property-id
REACT_APP_TAWK_TO_WIDGET_ID=your-tawk-to-widget-id
REACT_APP_TAWK_TO_POSITION=BR
REACT_APP_TAWK_TO_OFFLINE_MSG=Leave us a message!
REACT_APP_TAWK_TO_VISITOR_NAME=PLO Solver User
```

#### B. Replace Placeholder Values
- Replace `your-zoho-desk-*` values with actual IDs from Zoho Desk
- Replace `your-tawk-to-*` values with actual IDs from Tawk.to
- Replace `yourorg` with your actual organization name

#### C. Optional Configuration
You can customize various aspects:
- **Widget Position**: `bottom-right`, `bottom-left`, `top-right`, `top-left`
- **Tawk.to Position**: `BR` (Bottom Right), `BL` (Bottom Left), `TR` (Top Right), `TL` (Top Left)
- **Domain**: For EU customers, use `desk.zoho.eu` instead of `desk.zoho.com`

### 4. Testing the Integration

#### A. Development Testing
1. Start your development server
2. Navigate to any page in your application
3. You should see a blue support button in the bottom-right corner
4. Click the button to see the support options
5. Test each option:
   - **Live Chat**: Should open Tawk.to widget
   - **Support Portal**: Should open Zoho Desk widget
   - **Knowledge Base**: Should open in new tab
   - **Quick Ticket**: Should show in-app form

#### B. Cookie Consent Testing
1. Clear your browser cookies
2. Visit the application - support widget should not appear
3. Accept functional cookies in the cookie consent banner
4. Support widget should now appear

#### C. User Context Testing
1. Log in with a test account
2. Open the support widget or chat
3. Verify that user information is passed correctly:
   - Name and email should be pre-filled
   - User ID and subscription tier should be visible to agents
   - Session information should be available

## Configuration Reference

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `REACT_APP_ZOHO_DESK_ENABLED` | Enable/disable Zoho Desk integration | `false` | No |
| `REACT_APP_ZOHO_DESK_WIDGET_ID` | Zoho Desk widget ID | - | Yes (if enabled) |
| `REACT_APP_ZOHO_DESK_PORTAL_ID` | Zoho Desk portal ID | - | Yes (if enabled) |
| `REACT_APP_ZOHO_DESK_DEPARTMENT_ID` | Zoho Desk department ID | - | Yes (if enabled) |
| `REACT_APP_ZOHO_DESK_DOMAIN` | Zoho Desk domain | `desk.zoho.com` | No |
| `REACT_APP_ZOHO_DESK_KB_URL` | Knowledge base URL | - | No |
| `REACT_APP_ZOHO_DESK_POSITION` | Widget position | `bottom-right` | No |
| `REACT_APP_TAWK_TO_ENABLED` | Enable/disable Tawk.to integration | `false` | No |
| `REACT_APP_TAWK_TO_PROPERTY_ID` | Tawk.to property ID | - | Yes (if enabled) |
| `REACT_APP_TAWK_TO_WIDGET_ID` | Tawk.to widget ID | - | Yes (if enabled) |
| `REACT_APP_TAWK_TO_POSITION` | Tawk.to widget position | `BR` | No |
| `REACT_APP_TAWK_TO_OFFLINE_MSG` | Offline message text | `Leave us a message!` | No |
| `REACT_APP_TAWK_TO_VISITOR_NAME` | Default visitor name | `PLO Solver User` | No |

### Widget Positions

**Support Widget Positions:**
- `bottom-right`: Bottom right corner
- `bottom-left`: Bottom left corner  
- `top-right`: Top right corner
- `top-left`: Top left corner

**Tawk.to Positions:**
- `BR`: Bottom Right
- `BL`: Bottom Left
- `TR`: Top Right
- `TL`: Top Left

## Customization

### Styling
The support widget uses Tailwind CSS classes and supports dark mode. You can customize the appearance by modifying the `SupportWidget.js` component.

### User Data
The integration automatically passes the following user data:
- User ID
- Email address
- First and last name
- Subscription tier
- Sign-up date
- Last login time
- Session ID
- Browser information
- Current URL

### Custom Fields
For Zoho Desk tickets, the following custom fields are automatically included:
- Category (from form selection)
- User Type (subscription tier)
- Browser (user agent)
- URL (current page)
- Session ID
- Platform ("PLO Solver Web App")

## Troubleshooting

### Common Issues

#### 1. Support Widget Not Appearing
- **Check cookie consent**: Ensure functional cookies are allowed
- **Verify environment variables**: Make sure at least one service is enabled
- **Check console errors**: Look for JavaScript errors in browser console

#### 2. Zoho Desk Widget Not Loading
- **Verify credentials**: Check widget ID, portal ID, and department ID
- **Check domain**: Ensure correct Zoho domain (`.com` vs `.eu`)
- **CORS issues**: Verify your domain is allowed in Zoho Desk settings

#### 3. Tawk.to Widget Not Loading
- **Verify property ID**: Check that property ID and widget ID are correct
- **Account status**: Ensure Tawk.to account is active
- **Firewall/Ad blockers**: Some ad blockers may block Tawk.to scripts

#### 4. User Information Not Passing
- **Authentication**: Ensure user is properly logged in
- **Timing**: User data is set after successful authentication
- **Format**: Check console logs for data format issues

### Debug Mode
Set `NODE_ENV=development` to enable debug logging for the support integration.

### Browser Compatibility
The support integration works with:
- Chrome 70+
- Firefox 65+
- Safari 12+
- Edge 79+

## Security Considerations

### Data Privacy
- User data is only shared with support services when users actively engage
- Cookie consent is respected for all functional features
- No sensitive data (passwords, payment info) is shared

### HTTPS Requirement
Both Zoho Desk and Tawk.to require HTTPS in production. Ensure your application is served over HTTPS.

### Content Security Policy
If you use CSP headers, you may need to allow:
- `https://*.desk.zoho.com` for Zoho Desk
- `https://embed.tawk.to` for Tawk.to
- `https://tawk.to` for Tawk.to

## Monitoring and Analytics

### Support Events
The integration automatically tracks support-related events:
- `support_widget_opened`
- `support_chat_started`
- `support_chat_ended`
- `support_ticket_created`
- `support_knowledge_base_opened`

### Performance Impact
- **Initial Load**: ~50KB additional JavaScript
- **Runtime**: Minimal performance impact
- **Memory**: ~2-5MB additional memory usage

## Advanced Configuration

### Custom Event Handlers
You can listen for support events:

```javascript
window.addEventListener('supportEvent', (event) => {
  console.log('Support event:', event.detail);
});
```

### Programmatic Control
Access the support integration programmatically:

```javascript
import { 
  showZohoWidget, 
  showTawkWidget, 
  createZohoTicket 
} from '../utils/supportIntegration.js';

// Show specific widgets
showZohoWidget();
showTawkWidget();

// Create ticket programmatically
createZohoTicket('Bug Report', 'Description of the bug', 'High');
```

## Support and Maintenance

### Regular Tasks
- Monitor support ticket volume and response times
- Update knowledge base articles regularly
- Review and optimize widget positioning and messaging
- Check for updates to Zoho Desk and Tawk.to APIs

### Backup Plans
- Always have email support as a fallback
- Consider multiple support channels for redundancy
- Document your configuration for easy restoration

---

## Quick Start Checklist

- [ ] Set up Zoho Desk account and configure web widget
- [ ] Set up Tawk.to account and create property
- [ ] Add environment variables to `.env` file
- [ ] Test support widget functionality
- [ ] Verify cookie consent integration
- [ ] Test user data passing
- [ ] Configure knowledge base (optional)
- [ ] Set up support team training
- [ ] Monitor support metrics

---

**Need help with this setup?** Use the support widget once it's configured, or reach out to the development team!

Last updated: January 2024 