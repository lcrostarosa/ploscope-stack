# PLO Solver Testing Guide

This document provides comprehensive information about testing in the PLO Solver project, including setup, running tests, and writing new tests.

## 📋 Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Setup](#setup)
- [Running Tests](#running-tests)
- [Frontend Testing](#frontend-testing)
- [Backend Testing](#backend-testing)
- [Writing Tests](#writing-tests)
- [Coverage Reports](#coverage-reports)
- [Continuous Integration](#continuous-integration)

## 🔍 Overview

The PLO Solver project uses a comprehensive testing strategy that includes:

- **Unit Tests**: Test individual components and functions in isolation
- **Integration Tests**: Test interactions between components and systems
- **Frontend Tests**: React component testing with Jest and React Testing Library
- **Backend Tests**: Python API testing with pytest and Flask-Testing

## 🏗️ Test Structure

```
PLOSolver/
├── src/
│   └── __tests__/
│       ├── utils/
│       │   └── testUtils.js          # Test utilities and mocks
│       ├── unit/
│       │   ├── utils/
│       │   │   └── auth.test.js      # Auth utility tests
│       │   └── components/
│       │       ├── AuthModal.test.js # Component unit tests
│       │       └── SavedSpots.test.js
│       └── integration/
│           └── SpotMode.integration.test.js # Integration tests
├── backend/
│   ├── tests/
│   │   ├── unit/
│   │   │   ├── test_models.py        # Model unit tests
│   │   │   └── test_spot_routes.py   # Route unit tests
│   │   └── integration/
│   │       └── test_spot_workflow.py # Full workflow tests
│   ├── conftest.py                   # Pytest configuration and fixtures
│   └── pytest.ini                   # Pytest settings
├── run_tests.sh                      # Test runner script
└── TESTING.md                        # This file
```

## ⚙️ Setup

### Frontend Dependencies

The frontend testing setup uses:
- **Jest**: JavaScript testing framework
- **React Testing Library**: React component testing utilities
- **@testing-library/user-event**: User interaction simulation
- **MSW**: Mock Service Worker for API mocking

Dependencies are automatically installed with:
```bash
npm install
```

### Backend Dependencies

The backend testing setup uses:
- **pytest**: Python testing framework
- **pytest-flask**: Flask application testing
- **pytest-mock**: Mocking utilities
- **pytest-cov**: Coverage reporting
- **factory-boy**: Test data generation
- **freezegun**: Time mocking
- **responses**: HTTP request mocking

Install backend test dependencies:
```bash
cd backend
pip install -r requirements-test.txt
```

## 🚀 Running Tests

### Quick Start

Run all tests:
```bash
./run_tests.sh
```

### Test Runner Options

```bash
# Run only frontend tests
./run_tests.sh --frontend-only

# Run only backend tests
./run_tests.sh --backend-only

# Run tests with coverage reports
./run_tests.sh --coverage

# Run frontend tests in watch mode
./run_tests.sh --frontend-only --watch

# Show help
./run_tests.sh --help
```

### Manual Test Execution

#### Frontend Tests
```bash
# Run all frontend tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run only unit tests
npm run test:unit

# Run only integration tests
npm run test:integration
```

#### Backend Tests
```bash
cd backend

# Run all backend tests
pytest

# Run with verbose output
pytest -v

# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration

# Run with coverage
pytest --cov=. --cov-report=term-missing

# Run specific test file
pytest tests/unit/test_models.py

# Run specific test
pytest tests/unit/test_models.py::TestUser::test_user_creation
```

## 🎭 Frontend Testing

### Testing Philosophy

Frontend tests focus on:
- **User interactions**: Testing how users interact with the UI
- **Component behavior**: Ensuring components render and behave correctly
- **Integration**: Testing component interactions and data flow
- **Accessibility**: Ensuring components are accessible

### Test Utilities

The `testUtils.js` file provides:
- **renderWithProviders**: Renders components with necessary providers
- **Mock data**: Predefined mock objects for testing
- **Helper functions**: Common testing utilities

### Example Component Test

```javascript
import { screen, fireEvent } from '@testing-library/react';
import { renderWithProviders } from '../utils/testUtils';
import MyComponent from '../../components/MyComponent';

describe('MyComponent', () => {
  test('should render correctly', () => {
    renderWithProviders(<MyComponent />);
    expect(screen.getByText('Expected Text')).toBeInTheDocument();
  });

  test('should handle user interaction', async () => {
    const mockCallback = jest.fn();
    renderWithProviders(<MyComponent onAction={mockCallback} />);
    
    fireEvent.click(screen.getByRole('button'));
    expect(mockCallback).toHaveBeenCalled();
  });
});
```

### Mocking

Frontend tests use various mocking strategies:
- **Component mocks**: Mock child components for isolation
- **API mocks**: Mock fetch requests with MSW
- **Context mocks**: Mock React context providers
- **Utility mocks**: Mock utility functions

## 🐍 Backend Testing

### Testing Philosophy

Backend tests focus on:
- **API endpoints**: Testing HTTP request/response cycles
- **Business logic**: Testing core application logic
- **Data persistence**: Testing database operations
- **Authentication**: Testing security and access control

### Fixtures

The `conftest.py` file provides:
- **app**: Flask application instance for testing
- **client**: Test client for making HTTP requests
- **db_session**: Database session for test isolation
- **user/spot**: Pre-created test data
- **auth_headers**: Authentication headers for protected endpoints

### Example API Test

```python
def test_create_spot_success(client, auth_headers, user):
    """Test successful spot creation."""
    spot_data = {
        'name': 'Test Spot',
        'description': 'A test spot',
        'top_board': ['Ah', 'Kh'],
        'bottom_board': ['2c', '3c'],
        'players': [['As', 'Ad']],
        'simulation_runs': 1000
    }
    
    response = client.post('/api/spots', 
                         headers=auth_headers,
                         data=json.dumps(spot_data),
                         content_type='application/json')
    
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['message'] == 'Spot saved successfully'
```

### Test Markers

Backend tests use pytest markers:
- `@pytest.mark.unit`: Unit tests
- `@pytest.mark.integration`: Integration tests
- `@pytest.mark.slow`: Slow-running tests

## ✍️ Writing Tests

### Frontend Test Guidelines

1. **Test user behavior, not implementation details**
2. **Use semantic queries** (getByRole, getByLabelText, etc.)
3. **Test accessibility** (ARIA labels, keyboard navigation)
4. **Mock external dependencies** (APIs, third-party libraries)
5. **Use descriptive test names** that explain the expected behavior

### Backend Test Guidelines

1. **Test the API contract** (request/response format)
2. **Test error conditions** (validation, authentication, etc.)
3. **Use factories for test data** to avoid duplication
4. **Test database constraints** and relationships
5. **Mock external services** (email, payment processors, etc.)

### Test Naming Conventions

#### Frontend
```javascript
describe('ComponentName', () => {
  test('should render when condition is met', () => {});
  test('should call callback when button is clicked', () => {});
  test('should show error message when validation fails', () => {});
});
```

#### Backend
```python
class TestSpotRoutes:
    def test_get_spots_success(self):
        """Test successful retrieval of user's spots."""
        
    def test_get_spots_unauthorized(self):
        """Test getting spots without authentication."""
        
    def test_create_spot_invalid_data(self):
        """Test creating spot with invalid data."""
```

## 📊 Coverage Reports

### Frontend Coverage

Coverage reports are generated in the `coverage/` directory:
```bash
npm run test:coverage
open coverage/lcov-report/index.html
```

### Backend Coverage

Coverage reports are generated in the `htmlcov/` directory:
```bash
cd backend
pytest --cov=. --cov-report=html:htmlcov
open htmlcov/index.html
```

### Coverage Thresholds

- **Frontend**: 70% minimum coverage for branches, functions, lines, and statements
- **Backend**: 70% minimum coverage (configured in pytest.ini)

## 🔄 Continuous Integration

### GitHub Actions (Recommended)

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: self-hosted
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '18'
        
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.11'
        
    - name: Install frontend dependencies
      run: npm install
      
    - name: Install backend dependencies
      run: |
        cd backend
        pip install -r requirements.txt
        pip install -r requirements-test.txt
        
    - name: Run tests
      run: ./run_tests.sh --coverage
      
    - name: Upload coverage reports
      uses: codecov/codecov-action@v1
```

## 🐛 Debugging Tests

### Frontend Debugging

1. **Use screen.debug()** to see the rendered DOM
2. **Add console.log** statements in components
3. **Use React DevTools** browser extension
4. **Run tests in watch mode** for faster feedback

### Backend Debugging

1. **Use pytest -s** to see print statements
2. **Use pytest --pdb** to drop into debugger on failure
3. **Add logging** to see request/response data
4. **Use pytest -x** to stop on first failure

## 📝 Best Practices

### General
- **Write tests first** (TDD approach when possible)
- **Keep tests simple** and focused on one thing
- **Use descriptive names** that explain what is being tested
- **Avoid testing implementation details**
- **Mock external dependencies** to ensure test isolation

### Frontend Specific
- **Test from the user's perspective**
- **Use semantic HTML** and proper ARIA labels
- **Test keyboard navigation** and accessibility
- **Avoid testing CSS styles** unless critical to functionality

### Backend Specific
- **Test the API contract** rather than internal implementation
- **Use database transactions** for test isolation
- **Test authentication and authorization** thoroughly
- **Validate input/output data** formats

## 🆘 Troubleshooting

### Common Issues

#### Frontend
- **Tests timing out**: Increase timeout or use proper async/await
- **Components not rendering**: Check for missing providers or mocks
- **Mock not working**: Ensure mocks are properly configured and imported

#### Backend
- **Database errors**: Check test database setup and migrations
- **Authentication failures**: Verify JWT token generation and headers
- **Import errors**: Check Python path and module structure

### Getting Help

1. Check the test output for specific error messages
2. Review the test setup and configuration files
3. Look at existing tests for examples
4. Check the documentation for testing libraries used

---

## 📚 Additional Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [pytest Documentation](https://docs.pytest.org/)
- [Flask Testing](https://flask.palletsprojects.com/en/2.0.x/testing/)

Happy Testing! 🎉 