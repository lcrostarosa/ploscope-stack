# Logging and Request Tracking System

## Overview

This document describes the enhanced logging and request tracking system implemented in PLOSolver, which provides:

- **IP Address Logging**: Track client IP addresses for all requests
- **User UUID Logging**: Use user UUIDs instead of email addresses (PII protection)
- **Request ID Tracking**: Correlate frontend and backend requests for better debugging and support
- **PII Removal**: Remove all personally identifiable information from logs

## Backend Implementation

### Enhanced Logging (`backend/logging_utils.py`)

The new logging system provides:

- **Context-aware logging**: Each log entry includes request ID, client IP, and user ID
- **PII-safe logging**: Automatically filters out sensitive information
- **Request tracking**: Links frontend and backend requests using request IDs

#### Key Functions

```python
from logging_utils import log_user_action, get_enhanced_logger

# Log user actions without PII
log_user_action('USER_LOGIN', user.id)
log_user_action('SPOT_SAVED', user.id, {'spot_name': 'Example Spot'})

# Get enhanced logger
logger = get_enhanced_logger(__name__)
logger.info("This will include request context automatically")
```

### Log Format

Enhanced logs now follow this format:
```
2024-01-15 10:30:45 - auth_routes - INFO - [ReqID:12ab34cd] [IP:192.168.1.100] [UserID:user-uuid-123] - User action: USER_LOGIN
```

### Request Context Setup

Each request automatically gets:
- **Request ID**: Unique identifier for tracking
- **Client IP**: Real client IP (handles proxies/load balancers)
- **User ID**: User UUID (only when authenticated)

## Frontend Implementation

### Request ID Utilities (`src/utils/requestId.js`)

The frontend automatically generates and sends request IDs:

```javascript
import { fetchWithRequestId } from './utils/requestId';

// Use enhanced fetch with automatic request ID
const response = await fetchWithRequestId('/api/endpoint', {
  method: 'POST',
  body: JSON.stringify(data)
});
```

### Axios Integration

For axios users, request ID tracking is automatically set up:

```javascript
import { setupAxiosRequestId } from './utils/requestId';

const api = axios.create({ baseURL: '/api' });
setupAxiosRequestId(api); // Automatically adds request IDs
```

## Configuration

### Environment Variables

- `LOG_LEVEL`: Set logging level (DEBUG, INFO, WARNING, ERROR)
- `LOG_FILE`: Optional file path for log output

### Example Configuration

```bash
# Development
LOG_LEVEL=DEBUG

# Production
LOG_LEVEL=INFO
LOG_FILE=/var/log/plosolver/app.log
```

## User Action Types

The system logs these standardized user actions:

| Action | Description | Additional Info |
|--------|-------------|-----------------|
| `USER_REGISTERED` | New user registration | `username` |
| `USER_LOGIN` | User login (email/password) | - |
| `GOOGLE_LOGIN` | Google OAuth login | - |
| `USER_LOGOUT` | Single session logout | - |
| `USER_LOGOUT_ALL` | All sessions logout | `sessions_revoked` |
| `PROFILE_UPDATED` | Profile changes | - |
| `PASSWORD_CHANGED` | Password change | `sessions_revoked` |
| `SPOT_SAVED` | New spot saved | `spot_name` |
| `SPOT_UPDATED` | Spot modified | `spot_name` |
| `SPOT_DELETED` | Spot deleted | `spot_name` |
| `DISCOURSE_SSO_REQUESTED` | Forum SSO requested | - |
| `DISCOURSE_SSO_COMPLETED` | Forum SSO completed | - |

## PII Removal

### What's Removed
- Email addresses from all log messages
- Full names from log entries
- Any user-provided content that might contain PII

### What's Kept
- User UUIDs (non-identifiable)
- IP addresses (needed for security)
- Request IDs (for tracking)
- Non-PII metadata (spot names, action types, etc.)

## Debugging and Support

### Request Tracking

When users report issues, you can:

1. Ask for the request ID from browser console
2. Search logs using the request ID
3. Follow the complete request flow

### Example Log Search

```bash
# Find all logs for a specific request
grep "ReqID:12ab34cd" /var/log/plosolver/app.log

# Find all actions by a user
grep "UserID:user-uuid-123" /var/log/plosolver/app.log
```

### Browser Console

In development mode, request IDs are logged to console:
```
Request [req_1642234567890_xyz123]: POST /api/spots -> 201 Created
```

## Security Considerations

1. **IP Address Logging**: Stored for security monitoring
2. **User UUID**: Non-reversible without database access
3. **Request IDs**: Contain timestamps but no sensitive data
4. **Log Rotation**: Implement log rotation in production
5. **Access Control**: Restrict log file access to authorized personnel

## Migration from Old System

The old logging system has been updated to:

- Replace `logger.info(f"User logged in: {user.email}")` 
- With `log_user_action('USER_LOGIN', user.id)`

All email references in logs have been removed and replaced with UUID-based logging.

## Best Practices

1. **Use log_user_action()** for all user-related activities
2. **Include request context** in error logs
3. **Avoid logging PII** in additional_info parameters
4. **Use structured logging** for better searchability
5. **Monitor log volume** in production

## Future Enhancements

- [ ] Log aggregation system (ELK stack)
- [ ] Real-time log monitoring
- [ ] Automated PII detection and removal
- [ ] Request performance metrics
- [ ] User behavior analytics (non-PII) 