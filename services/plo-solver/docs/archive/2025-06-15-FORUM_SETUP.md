# Forum Integration Setup Guide

This guide will help you integrate a Discourse forum with PLO Solver's authentication system using Single Sign-On (SSO).

## Overview

The forum integration provides:
- Seamless login with existing PLO Solver accounts
- Single Sign-On (SSO) between the app and forum
- Automatic user profile synchronization
- Secure authentication flow

## Prerequisites

1. A running Discourse forum instance
2. Admin access to your Discourse forum
3. PLO Solver backend running with authentication

## 1. Discourse Configuration

### Enable SSO Provider

1. Go to your Discourse admin panel (`https://your-forum.com/admin`)
2. Navigate to **Settings > Login**
3. Find the **SSO** section and configure:

   ```
   enable sso provider = true
   sso url = https://your-plosolver-app.com/api/discourse/sso_provider
   sso secret = [generate a secure random string]
   ```

### Generate SSO Secret

Generate a secure random string (32+ characters) for the SSO secret. You can use:

```bash
# Using openssl
openssl rand -hex 32

# Using Python
python3 -c "import secrets; print(secrets.token_hex(32))"

# Online generator
# Visit: https://www.random.org/strings/
```

### Additional Discourse Settings

Configure these optional settings in Discourse admin:

```
sso overrides email = true
sso overrides username = true
sso overrides name = true
```

## 2. PLO Solver Configuration

### Environment Variables

Add these variables to your `.env` file:

```bash
# Discourse Forum Integration
DISCOURSE_URL=https://your-forum.com
DISCOURSE_SSO_SECRET=your-generated-sso-secret-here
DISCOURSE_WEBHOOK_SECRET=optional-webhook-secret-here
```

### Backend Routes

The forum integration adds these endpoints to your Flask app:

- `GET /api/discourse/sso` - Generate SSO URL for authenticated users
- `GET /api/discourse/sso_provider` - Handle SSO requests from Discourse
- `GET /api/discourse/sso_callback` - Complete SSO authentication
- `POST /api/discourse/webhook` - Handle Discourse webhooks (optional)

## 3. Testing the Integration

### Test SSO Flow

1. Start your PLO Solver backend
2. Log in to PLO Solver with a test account
3. Navigate to the Forum tab
4. Click "Access Forum" - you should be redirected to Discourse and automatically logged in

### Troubleshooting

#### Common Issues

**"Forum integration not configured" error:**
- Check that `DISCOURSE_SSO_SECRET` is set in your environment
- Restart your Flask application after adding environment variables

**"Invalid SSO signature" error:**
- Verify the SSO secret matches between Discourse and PLO Solver
- Ensure there are no extra spaces or characters in the secret

**Authentication redirect loops:**
- Check that your `DISCOURSE_URL` is correct and accessible
- Verify Discourse SSO settings are properly configured

#### Debug Mode

Enable debug logging in your Flask app:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

Check the logs for detailed error messages during SSO flow.

## 4. Production Deployment

### Security Considerations

1. **Use HTTPS**: Both PLO Solver and Discourse must use HTTPS in production
2. **Secure Secrets**: Use strong, randomly generated secrets
3. **Environment Variables**: Never commit secrets to version control

### SSL Configuration

Ensure both services have valid SSL certificates:

```bash
# PLO Solver
https://your-app.com

# Discourse
https://your-forum.com
```

### CORS Configuration

Update CORS settings in your Flask app to allow requests from Discourse:

```python
CORS(app, origins=[
    "https://your-app.com",
    "https://your-forum.com"
])
```

## 5. User Experience

### How It Works for Users

1. User logs into PLO Solver
2. Clicks the "Forum" tab
3. Clicks "Access Forum" 
4. Gets redirected to Discourse and automatically signed in
5. Can participate in forum discussions with their PLO Solver identity

### User Profile Mapping

PLO Solver user data maps to Discourse as follows:

- `user.id` → `external_id`
- `user.email` → `email`
- `user.username` → `username` (or generated if not set)
- `user.first_name + user.last_name` → `name`

## 6. Optional: Webhooks

Set up webhooks to keep user data synchronized:

### Discourse Webhook Configuration

1. Go to **Admin > API > Webhooks**
2. Create a new webhook:
   ```
   Payload URL: https://your-app.com/api/discourse/webhook
   Content Type: application/json
   Secret: your-webhook-secret
   Events: user_created, user_updated
   ```

### Webhook Security

The webhook endpoint verifies signatures using the `DISCOURSE_WEBHOOK_SECRET`.

## 7. Customization

### Custom User Fields

Add custom fields to the SSO payload in `discourse_routes.py`:

```python
sso_params = {
    'nonce': nonce,
    'external_id': str(user.id),
    'email': user.email,
    'username': user.username or f"user_{user.id}",
    'name': f"{user.first_name} {user.last_name}".strip(),
    'custom_field_name': user.custom_value,  # Add custom fields
}
```

### UI Customization

Modify the Forum component (`src/components/Forum.js`) to customize:
- Welcome messages
- Feature descriptions
- Button styles
- Loading states

## 8. Monitoring and Analytics

### Log Important Events

The integration logs key events:
- SSO URL generation
- Successful authentications
- Error conditions

### Monitor Usage

Track forum engagement through:
- Discourse analytics
- PLO Solver user metrics
- SSO success/failure rates

## Support

For issues with the forum integration:

1. Check the troubleshooting section above
2. Review backend logs for error details
3. Verify Discourse admin settings
4. Test with debug logging enabled

---

## Quick Setup Checklist

- [ ] Discourse forum running and accessible
- [ ] Admin access to Discourse
- [ ] Generated secure SSO secret
- [ ] Configured Discourse SSO settings
- [ ] Added environment variables to PLO Solver
- [ ] Tested SSO flow end-to-end
- [ ] Configured HTTPS for production
- [ ] Set up monitoring and logging 