# PLOSolver Development Guide

This guide covers the development workflow, coding standards, and best practices for the PLOSolver project.

## Project Structure

```
PLOSolver/
├── src/
│   ├── frontend/           # React frontend application
│   │   ├── components/     # React components
│   │   ├── pages/         # Page components
│   │   ├── hooks/         # Custom React hooks
│   │   ├── contexts/      # React contexts
│   │   ├── utils/         # Frontend utilities
│   │   └── __tests__/     # Frontend tests
│   ├── backend/           # Flask backend application
│   │   ├── core/          # Core application modules
│   │   ├── routes/        # API routes
│   │   ├── services/      # Business logic services
│   │   ├── models/        # Database models
│   │   ├── utils/         # Backend utilities
│   │   ├── tests/         # Backend tests
│   │   └── migrations/    # Database migrations
│   └── src/simulation/    # Simulation and analysis tools
├── scripts/               # Development and deployment scripts
├── docs/                  # Documentation
├── public/                # Static assets
├── dist/                  # Build output
├── node_modules/          # Node.js dependencies
├── src/frontend/package.json           # Frontend dependencies
├── requirements.txt       # Backend dependencies
├── docker compose.yml     # Docker configuration
└── Makefile              # Development commands
```

## Development Environment Setup

### Prerequisites

- Python 3.9+
- Node.js 18+
- PostgreSQL
- RabbitMQ
- Docker (optional)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd PLOSolver
   ```

2. **Install dependencies**
   ```bash
   make deps
   ```

3. **Start development environment**
   ```bash
   make run
   ```

### Manual Setup

If you prefer to set up manually:

1. **Frontend setup**
   ```bash
   npm install
   ```

2. **Backend setup**
   ```bash
   cd src/backend
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   pip install -r requirements-test.txt
   ```

3. **Database setup**
   ```bash
   make db-reset
   ```

## Development Workflow

### Two-Terminal Workflow for Local Development

For local development, you should use a two-terminal workflow:

1. **Terminal 1:** Start backend and frontend (and infrastructure services)
   ```bash
   make run-local
   ```
   This will start the backend and frontend with hot reloading, and all infrastructure services (Postgres, RabbitMQ, Traefik) in Docker. **It does NOT start the Celery worker by default.**

2. **Terminal 2:** Start the Celery worker (with hot reloading)
   ```bash
   make run-celery-dev
   ```
   This will start the Celery worker natively, with code reload on changes. You must keep this running in a separate terminal for background jobs to be processed.

> **Note:** This workflow gives you full control and avoids accidental multiple workers. You can stop and restart the worker independently of the main app.

### Running the Application

- **Full application**: `make run`
- **Frontend only**: `npm start`
- **Backend only**: `cd src/backend && python -m core.app`
- **Celery worker only**: `make run-celery-dev`
- **Workers only**: `make workers`

### Testing

- **All tests**: `make test`
- **Frontend tests**: `npm test`
- **Backend tests**: `cd src/backend && python -m pytest`
- **Integration tests**: `make test-integration`

### Code Quality

- **Linting**: `make lint`
- **Formatting**: `make format`
- **Security checks**: `make security`

## Coding Standards

### Python (Backend)

- Follow PEP 8 style guide
- Use type hints
- Write docstrings for all functions
- Maximum line length: 88 characters (Black default)
- Use Black for code formatting
- Use flake8 for linting

### JavaScript/React (Frontend)

- Use ESLint configuration
- Follow React best practices
- Use functional components with hooks
- Use TypeScript for type safety
- Use Prettier for code formatting

### Testing

- Write unit tests for all new functionality
- Maintain minimum 70% code coverage
- Use descriptive test names
- Test both success and error cases

## API Development

### Adding New Routes

1. Create route in `src/backend/routes/`
2. Add route to `src/backend/core/app.py`
3. Write tests in `src/backend/tests/`
4. Update API documentation

Example:
```python
# src/backend/routes/new_feature.py
from flask import Blueprint, jsonify, request
from services.new_feature_service import NewFeatureService

bp = Blueprint('new_feature', __name__)

@bp.route('/api/new-feature', methods=['POST'])
def create_new_feature():
    data = request.get_json()
    service = NewFeatureService()
    result = service.create(data)
    return jsonify(result), 201
```

### Database Models

1. Create model in `src/backend/models/`
2. Create migration: `flask db migrate -m "Add new model"`
3. Apply migration: `flask db upgrade`
4. Write tests

Example:
```python
# src/backend/models/new_model.py
from plosolver_core.models import db
from datetime import datetime

class NewModel(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'created_at': self.created_at.isoformat()
        }
```

## Frontend Development

### Adding New Components

1. Create component in `src/frontend/components/`
2. Add to appropriate page in `src/frontend/pages/`
3. Write tests in `src/frontend/__tests__/`

Example:
```jsx
// src/frontend/components/NewComponent.js
import React from 'react';
import './NewComponent.css';

const NewComponent = ({ data, onAction }) => {
  return (
    <div className="new-component">
      <h2>{data.title}</h2>
      <button onClick={onAction}>Action</button>
    </div>
  );
};

export default NewComponent;
```

### State Management

- Use React Context for global state
- Use local state for component-specific data
- Use custom hooks for reusable logic

## Debugging

### Backend Debugging

- Use Flask debug mode: `FLASK_DEBUG=true`
- Check logs: `tail -f src/backend/equity_server.log`
- Use Python debugger: `import pdb; pdb.set_trace()`

### Frontend Debugging

- Use React Developer Tools
- Check browser console
- Use React error boundaries

### Database Debugging

- Check database status: `make db-reset info`
- View migrations: `flask db history`
- Reset database: `make db-reset reset`

## Performance Optimization

### Backend

- Use database indexes
- Implement caching where appropriate
- Use async/await for I/O operations
- Monitor with New Relic

### Frontend

- Use React.memo for expensive components
- Implement code splitting
- Optimize bundle size
- Use lazy loading

## Security

### Backend Security

- Validate all input data
- Use parameterized queries
- Implement proper authentication
- Use HTTPS in production
- Run security checks: `make security`

### Frontend Security

- Sanitize user input
- Use Content Security Policy
- Implement proper CORS
- Use secure cookies

## Deployment

### Development Deployment

```bash
make deploy-dev
```

### Production Deployment

```bash
make deploy-prod
```

### Docker Deployment

```bash
make run-docker
```

## Troubleshooting

### Common Issues

1. **Database connection errors**
   - Check PostgreSQL is running
   - Verify connection settings in `.env`
   - Run `make db-reset`

2. **RabbitMQ connection errors**
   - Check RabbitMQ is running
   - Verify credentials in `.env`
   - Run `make test-integration`

3. **Frontend build errors**
   - Clear node_modules: `rm -rf node_modules && npm install`
   - Check for syntax errors
   - Verify all dependencies are installed

4. **Backend import errors**
   - Activate virtual environment
   - Install dependencies: `pip install -r requirements.txt`
   - Check Python path

### Getting Help

- Check the logs in `src/backend/logs/`
- Run health checks: `make health`
- Check service status: `make check-docker`
- Review documentation in `docs/`

## Contributing

1. Create a feature branch
2. Make your changes
3. Write tests
4. Run all tests: `make test`
5. Submit a pull request

### Code Review Checklist

- [ ] Code follows style guidelines
- [ ] Tests are written and passing
- [ ] Documentation is updated
- [ ] No security vulnerabilities
- [ ] Performance impact is considered

## Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [React Documentation](https://reactjs.org/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Docker Documentation](https://docs.docker.com/) 