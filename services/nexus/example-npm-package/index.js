/**
 * PLOScope Nexus Test Package
 * A simple test package for verifying NPM registry functionality
 */

/**
 * Simple greeting function
 * @param {string} name - Name to greet
 * @returns {string} Greeting message
 */
function greet(name = 'World') {
    return `Hello, ${name}! This is a test package from PLOScope Nexus.`;
}

/**
 * Get package information
 * @returns {object} Package information
 */
function getPackageInfo() {
    return {
        name: '@ploscope/nexus-test-package',
        version: '1.0.0',
        description: 'Test package for PLOScope Nexus NPM registry',
        registry: 'https://nexus.ploscope.com/repository/npm-internal/'
    };
}

module.exports = {
    greet,
    getPackageInfo
};
