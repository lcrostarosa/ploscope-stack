# Newman Integration Tests

This directory contains Newman integration tests for the PLOSolver API endpoints.

## Overview

Newman is a command-line collection runner for Postman. These tests verify that the PLOSolver API endpoints are working correctly by making actual HTTP requests to the running backend service.

## Files

- `PLOSolver-Integration-Tests.postman_collection.json` - The test collection containing all API endpoint tests
- `PLOSolver-CI-Environment.postman_environment.json` - Environment variables for the tests
- `README.md` - This documentation file

## Prerequisites

1. **Newman CLI**: Install Newman globally
   ```bash
   npm install -g newman
   ```

2. **Backend Service**: Ensure the PLOSolver backend is running locally
   ```bash
   make run-local
   ```

3. **Database & Services**: Make sure PostgreSQL and RabbitMQ are running
   ```bash
   docker ps  # Should show plosolver-db-local and plosolver-rabbitmq-local
   ```

## Running Tests

### Option 1: Using the Makefile (Recommended)
```bash
make test-newman
```

### Option 2: Using the Script Directly
```bash
./scripts/testing/run-newman-tests.sh
```

### Option 3: Manual Newman Command
```bash
newman run postman/PLOSolver-Integration-Tests.postman_collection.json \
  -e postman/PLOSolver-CI-Environment.postman_environment.json \
  --reporters cli,json \
  --reporter-json-export newman-results.json
```

## Test Coverage

The test collection covers the following API endpoints:

1. **Health Check** (`GET /api/health`)
   - Verifies the backend is running and healthy
   - Checks database and RabbitMQ connectivity

2. **User Registration** (`POST /api/auth/register`)
   - Tests user registration with unique email generation
   - Handles both new user creation and existing user conflicts

3. **User Login** (`POST /api/auth/login`)
   - Tests user authentication
   - Validates access token generation

4. **Submit Spot Simulation Job** (`POST /api/spots/simulate`)
   - Tests spot simulation job submission
   - Validates job creation and credits system

5. **Get Job Status** (`GET /api/jobs/{job_id}`)
   - Tests job status retrieval
   - Validates job data structure and status values

6. **Get Recent Jobs** (`GET /api/jobs/recent`)
   - Tests recent jobs endpoint
   - Validates jobs array structure

7. **Submit Solver Analysis Job** (`POST /api/solver/solve`)
   - Tests solver analysis job submission
   - Validates solver job creation

8. **Test Invalid Job Submission** (`POST /api/spots/simulate`)
   - Tests error handling for invalid requests
   - Validates proper error responses

## Test Features

### Unique Test Data
- Each test run generates unique email addresses using timestamps
- Prevents conflicts between multiple test runs
- Ensures test isolation

### Environment Variables
- `base_url`: Set to `http://localhost` for local testing (default port 5001)
- `access_token`: Automatically set after successful login
- `job_id`: Automatically set after successful job creation
- `user_id`: Automatically set after successful registration
- `user_email`: Automatically set after successful registration
- `solver_job_id`: Automatically set after successful solver job creation

### Response Validation
- Status code validation
- Response structure validation
- Data type validation
- Business logic validation

## Expected Results

When all tests pass, you should see:

```
✅ All Newman tests passed!
📊 Results saved to: newman-results.json

📋 Test Summary:
==================
✅ Health Check
✅ User Registration
✅ User Login
✅ Submit Spot Simulation Job
✅ Get Job Status
✅ Get Recent Jobs
✅ Submit Solver Analysis Job
✅ Test Invalid Job Submission
```

## Troubleshooting

### Common Issues

1. **Backend Not Running**
   ```
   ❌ Backend is not running at http://localhost:5001
   ```
   **Solution**: Start the backend with `make run-local`

2. **Database Connection Issues**
   ```
   "database": "disconnected"
   ```
   **Solution**: Ensure PostgreSQL container is running

3. **RabbitMQ Connection Issues**
   ```
   "rabbitmq": "disconnected"
   ```
   **Solution**: Ensure RabbitMQ container is running

4. **User Already Exists**
   ```
   POST /api/auth/register [409 CONFLICT]
   ```
   **Solution**: The test automatically handles this with unique emails

5. **Authentication Failures**
   ```
   "error": "Authentication failed"
   ```
   **Solution**: Check that the login test passed and access token is set

### Debug Mode

To run tests with more verbose output:
```bash
newman run postman/PLOSolver-Integration-Tests.postman_collection.json \
  -e postman/PLOSolver-CI-Environment.postman_environment.json \
  --reporters cli,json \
  --reporter-json-export newman-results.json \
  --verbose
```

## Manual Testing with Postman

### Importing the Collection
1. Open Postman
2. Click "Import" button
3. Select `PLOSolver-Integration-Tests.postman_collection.json`
4. Import the environment file: `PLOSolver-CI-Environment.postman_environment.json`

### Setting Up Environment
1. Select the "PLOSolver CI Environment" from the environment dropdown
2. Update `base_url` if your backend runs on a different port
3. The environment variables will be automatically populated during test execution

### Running Individual Tests
- Use Postman's "Send" button to run individual requests
- Tests will execute automatically and show results in the "Test Results" tab
- Environment variables are updated automatically between requests

## Integration with CI/CD

These tests can be integrated into CI/CD pipelines:

1. **GitHub Actions**: Add to workflow files
2. **Docker**: Run in containerized environments
3. **Local Development**: Use for pre-commit validation

## Maintenance

### Adding New Tests
1. Create the test in Postman
2. Export the collection
3. Update this README with new test details

### Updating Existing Tests
1. Modify the test in Postman
2. Export the updated collection
3. Test locally to ensure changes work

### Environment Updates
- Update `PLOSolver-CI-Environment.postman_environment.json` for new variables
- Ensure all tests use environment variables instead of hardcoded values 