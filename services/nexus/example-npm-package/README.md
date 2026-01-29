# PLOScope Nexus Test Package

This is a test package for verifying the PLOScope Nexus NPM registry functionality.

## Installation

```bash
npm install @ploscope/nexus-test-package --registry https://nexus.ploscope.com/repository/npm-all/
```

## Usage

```javascript
const { greet, getPackageInfo } = require('@ploscope/nexus-test-package');

// Greet someone
console.log(greet('PLOScope')); // Hello, PLOScope! This is a test package from PLOScope Nexus.

// Get package info
console.log(getPackageInfo());
```

## Publishing

To publish this test package to the Nexus registry:

```bash
# Set up authentication
export NPM_TOKEN="your-npm-token"

# Publish the package
npm publish
```

## Registry Configuration

This package is configured to publish to the PLOScope Nexus internal repository:
- Registry: `https://nexus.ploscope.com/repository/npm-internal/`
- Group Registry: `https://nexus.ploscope.com/repository/npm-all/`
