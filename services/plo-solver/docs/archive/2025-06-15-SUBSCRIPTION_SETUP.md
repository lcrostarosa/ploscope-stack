# PLO Solver Subscription Setup Guide

This guide will help you set up Stripe subscriptions for the PLO Solver application using Stripe's hosted checkout pages.

## Prerequisites

1. A Stripe account (sign up at https://stripe.com)
2. Node.js and Python environment set up
3. PLO Solver application running

## Stripe Configuration

### 1. Get Your Stripe Keys

1. Log into your Stripe Dashboard
2. Go to Developers > API keys
3. Copy your Publishable key and Secret key

### 2. Create Products and Prices

In your Stripe Dashboard:

1. Go to Products > Add product
2. Create the following products:

#### PLO Solver Pro
- Name: PLO Solver Pro
- Description: Professional PLO analysis tools
- Create two prices:
  - Monthly: $19/month (recurring)
  - Yearly: $190/year (recurring)

#### PLO Solver Elite  
- Name: PLO Solver Elite
- Description: Elite PLO analysis with advanced features
- Create two prices:
  - Monthly: $99/month (recurring)
  - Yearly: $990/year (recurring)

3. Copy the Price IDs for each price (they start with `price_`)

### 3. Set Up Webhooks

1. Go to Developers > Webhooks
2. Add endpoint: `https://yourdomain.com/api/webhook`
3. Select these events:
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
   - `invoice.payment_succeeded`
4. Copy the webhook signing secret

### 4. Environment Configuration

Create a `.env` file in your backend directory with:

```env
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Stripe Price IDs
STRIPE_PRICE_PRO_MONTHLY=price_your_pro_monthly_id
STRIPE_PRICE_PRO_YEARLY=price_your_pro_yearly_id
STRIPE_PRICE_ELITE_MONTHLY=price_your_elite_monthly_id
STRIPE_PRICE_ELITE_YEARLY=price_your_elite_yearly_id
```

**Note**: Frontend no longer needs Stripe publishable key since we're using hosted checkout.

## Features Implemented

### User Tier System
- **Free**: Default tier for all new users
- **Pro**: $19/month or $190/year - Enhanced features
- **Elite**: $99/month or $990/year - Premium features

### Secure Checkout Flow
1. User clicks "Subscribe" on pricing page
2. App creates Stripe Checkout Session
3. User is redirected to Stripe's secure hosted checkout page
4. After payment, user is redirected back to success page
5. Webhook confirms subscription and updates user account

### UI Components
- **Checkout Page**: Redirects to Stripe's hosted checkout
- **CheckoutSuccess Page**: Confirms successful subscription
- **TierIndicator**: Shows user's current tier next to their profile
- **Upgrade Button**: For free and pro users to upgrade
- **Pricing Page**: Updated with secure checkout integration

### Backend API Endpoints
- `POST /api/create-checkout-session` - Create Stripe checkout session
- `GET /api/checkout-success` - Verify successful checkout
- `POST /api/cancel-subscription` - Cancel subscription at period end
- `POST /api/reactivate-subscription` - Reactivate canceled subscription
- `GET /api/subscription-status` - Get current subscription status
- `POST /api/webhook` - Handle Stripe webhooks

### Database Schema
New fields added to User model:
- `subscription_tier` - User's current tier (free/pro/elite)
- `stripe_customer_id` - Stripe customer ID
- `stripe_subscription_id` - Stripe subscription ID
- `subscription_status` - Current subscription status
- `subscription_current_period_end` - When current period ends
- `subscription_cancel_at_period_end` - If subscription will cancel

## Security Benefits

### Why Stripe Hosted Checkout is Better:
- **No PCI DSS Compliance Required**: Your server never touches credit card data
- **Reduced Security Risk**: No sensitive payment data passes through your application
- **Built-in Fraud Protection**: Stripe's advanced fraud detection
- **3D Secure Support**: Automatic SCA compliance for European customers
- **Mobile Optimized**: Stripe's checkout is optimized for all devices
- **Multiple Payment Methods**: Support for cards, Apple Pay, Google Pay, etc.

## Testing

### Test Cards
Use these test card numbers in Stripe's hosted checkout:
- Success: `4242424242424242`
- Requires authentication: `4000002500003155`
- Declined: `4000000000000002`

### Test Webhooks
Use Stripe CLI to test webhooks locally:
```bash
stripe listen --forward-to localhost:5001/api/webhook
```

### Test Checkout Flow
1. Go to `/pricing`
2. Click "Subscribe" for Pro plan
3. You'll be redirected to Stripe's test checkout
4. Use test card number and any future expiry date
5. Complete checkout and verify redirect to success page

## Deployment Considerations

1. **Environment Variables**: Ensure all Stripe keys are set in production
2. **HTTPS**: Stripe webhooks require HTTPS in production
3. **Database Migrations**: Run migrations to add subscription fields
4. **Error Handling**: Monitor Stripe webhook delivery
5. **Customer Support**: Set up processes for subscription management
6. **Domain Verification**: Ensure your domain is properly configured in Stripe

## Customer Experience

### Checkout Flow:
1. User selects plan on pricing page
2. Clicks "Subscribe" button
3. Redirected to professional Stripe checkout page
4. Enters payment details securely on Stripe's servers
5. Completes payment with optional 3D Secure verification
6. Redirected back to success page with subscription activated

### Features:
- Professional, trustworthy checkout experience
- Automatic tax calculation (if configured)
- Support for promotion codes
- Multiple payment methods
- Automatic invoice generation
- Email receipts from Stripe

## Security Notes

- Your application never handles sensitive payment data
- All credit card processing happens on Stripe's secure servers
- PCI DSS compliance is handled by Stripe
- Webhook signatures are verified to ensure authenticity
- Session verification prevents tampering

## Troubleshooting

### Common Issues:
1. **Checkout session creation fails**: Check Stripe price IDs in environment variables
2. **Webhook not received**: Verify webhook endpoint URL and signing secret
3. **Success page doesn't load**: Check that success URL matches your application routing
4. **User subscription not updated**: Check webhook event handling and database updates

### Debug Commands:
```bash
# Test webhook endpoint
curl -X POST http://localhost:5001/api/webhook -H "Content-Type: application/json"

# Check subscription status
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:5001/api/subscription-status

# View Stripe logs
stripe logs tail
```

## Support

For issues with Stripe integration:
1. Check Stripe Dashboard logs
2. Review webhook delivery status
3. Verify environment variables
4. Test with Stripe CLI

For PLO Solver specific issues, refer to the main application documentation. 