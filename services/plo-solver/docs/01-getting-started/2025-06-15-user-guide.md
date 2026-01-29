# PLOSolver Dynamic Documentation System

This project includes a comprehensive dynamic documentation system that automatically generates documentation for both your Flask API and React components.

## 🚀 Quick Start

### Generate All Documentation

```bash
# Generate both API and React documentation
npm run docs:generate

# Or run directly with Python
python scripts/docs/generate_docs.py
```

### Generate Specific Documentation

```bash
# Generate only API documentation
npm run docs:api

# Generate only React component documentation  
npm run docs:react
```

### View Documentation

1. **Start your Flask server:**
   ```bash
   cd backend
   python equity_server.py
   ```

2. **Visit the documentation:**
   - Main documentation hub: `http://localhost:5001/docs`
- API documentation: `http://localhost:5001/docs/openapi.json`
- React components: `http://localhost:5001/docs/react-components.html`

## 📋 Features

### API Documentation Generator

- **Automatic Flask Route Analysis**: Scans your Flask application to extract all routes
- **OpenAPI 3.0 Specification**: Generates industry-standard OpenAPI/Swagger documentation
- **Request/Response Schema Detection**: Analyzes code to infer request and response formats
- **Interactive Testing**: Built-in API testing capabilities in the documentation UI
- **Parameter Documentation**: Extracts URL parameters, query parameters, and request body schemas

### React Component Documentation Generator

- **Component Analysis**: Scans all React components in your `src/` directory
- **Props Extraction**: Automatically detects component props and their types
- **Hooks Usage**: Documents which React hooks each component uses
- **JSX Element Mapping**: Shows which HTML/React elements each component renders
- **Import Dependencies**: Tracks component dependencies and imports
- **Component Types**: Identifies function components, class components, and arrow functions

### Interactive Documentation Dashboard

- **Unified Interface**: Single dashboard to view both API and React documentation
- **Live API Testing**: Test API endpoints directly from the documentation
- **Component Playground**: Interactive component documentation with examples
- **Search and Filter**: Easy navigation through your documentation
- **Responsive Design**: Works on desktop and mobile devices

## 🔧 System Architecture

### Backend Components

1. **`api_docs_generator.py`**: Flask route analyzer and OpenAPI generator
2. **`docs_routes.py`**: Flask blueprint for serving documentation
3. **Documentation endpoints**: Integrated into your main Flask application

### Frontend Components

1. **`react_docs_generator.js`**: React component analyzer (Node.js)
2. **`DocumentationDashboard.js`**: React component for viewing documentation
3. **Static HTML output**: Generated documentation pages

### Unified Generator

1. **`generate_docs.py`**: Master script that coordinates both generators
2. **Automatic setup**: Installs required dependencies and sets up directories
3. **Public serving**: Copies documentation to `public/docs` for easy serving

## 📁 Generated Files

After running the documentation generator, you'll find these files:

```
docs/
├── index.html              # Main documentation hub
├── openapi.json            # OpenAPI 3.0 specification
├── api_docs.md             # API documentation in Markdown
├── react-components.json   # React components data
└── react-components.html   # React components documentation

public/docs/               # Same files, served by your web server
├── index.html
├── openapi.json
├── api_docs.md
├── react-components.json
└── react-components.html
```

## 🎯 Integration Examples

### Adding to Your React App

```jsx
import DocumentationDashboard from './components/DocumentationDashboard';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/docs" element={<DocumentationDashboard />} />
        {/* your other routes */}
      </Routes>
    </Router>
  );
}
```

### Flask Route Documentation

Enhance your Flask routes with better documentation by adding docstrings:

```python
@app.route('/api/example', methods=['POST'])
def example_endpoint():
    """
    Create a new example resource
    
    This endpoint creates a new example resource with the provided data.
    
    Parameters:
    - name (string, required): The name of the resource
    - description (string, optional): Resource description
    
    Returns:
    - 201: Resource created successfully
    - 400: Invalid input data
    - 500: Server error
    """
    data = request.get_json()
    # your logic here
    return jsonify({"id": 123, "name": data["name"]})
```

### React Component Documentation

Add JSDoc comments to your React components for better documentation:

```jsx
/**
 * PlayerCard Component
 * 
 * Displays information about a poker player including stats and profile.
 * Used in the player selection and game setup screens.
 */
function PlayerCard({ name, winRate, handsPlayed, isSelected, onClick }) {
    // component implementation
}
```

## 🔄 Continuous Documentation

### Automatic Generation

Add documentation generation to your development workflow:

```json
{
  "scripts": {
    "dev": "npm run docs:generate && npm start",
    "build": "npm run docs:generate && npm run build:app",
    "pre-commit": "npm run docs:generate"
  }
}
```

### CI/CD Integration

Include documentation generation in your CI/CD pipeline:

```yaml
# .github/workflows/docs.yml
name: Generate Documentation
on: [push, pull_request]
jobs:
  docs:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v2
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: |
          npm install
          pip install -r src/backend/requirements.txt
      - name: Generate documentation
        run: npm run docs:generate
      - name: Deploy docs
        # Deploy to GitHub Pages or your hosting service
```

## 🛠️ Customization

### API Documentation

Customize the API documentation by modifying `src/backend/api_docs_generator.py`:

- Add custom schemas
- Modify response examples
- Add authentication documentation
- Customize OpenAPI metadata

### React Documentation

Enhance React documentation by modifying `scripts/react_docs_generator.js`:

- Add TypeScript support
- Parse PropTypes definitions
- Extract component examples
- Add component relationships

### Documentation UI

Customize the documentation dashboard in `src/components/DocumentationDashboard.js`:

- Add custom themes
- Modify the layout
- Add additional features
- Integrate with your design system

## 🐛 Troubleshooting

### Common Issues

1. **"Module not found" errors**: Run `npm install` to install required dependencies
2. **Python import errors**: Ensure you're running from the project root directory
3. **No documentation generated**: Check that your Flask app is properly configured
4. **React components not found**: Verify your `src/` directory structure

### Debug Mode

Enable debug output by setting environment variables:

```bash
export DEBUG=1
npm run docs:generate
```

### Manual Generation

If automatic generation fails, you can run each step manually:

```bash
# 1. Generate API docs
cd backend
python api_docs_generator.py

# 2. Generate React docs  
cd ..
node scripts/react_docs_generator.js

# 3. Copy to public directory
cp docs/* public/docs/
```

## 📚 API Reference

### Documentation Endpoints

- `GET /docs/` - Main documentation hub
- `GET /docs/openapi.json` - OpenAPI specification
- `GET /docs/react-components.json` - React components data
- `GET /docs/react-components.html` - React components HTML
- `GET /docs/generate` - Trigger documentation generation
- `GET /docs/status` - Documentation generation status

### Configuration

The documentation system can be configured by modifying:

- `src/backend/api_docs_generator.py` - API documentation settings
- `scripts/react_docs_generator.js` - React documentation settings  
- `scripts/docs/generate_docs.py` - Generation script settings

## 🤝 Contributing

To contribute to the documentation system:

1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Test with `npm run docs:generate`
5. Submit a pull request

## 📄 License

This documentation system is part of the PLOSolver project and follows the same license terms. 