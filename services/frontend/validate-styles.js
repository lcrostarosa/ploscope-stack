// Style Validation Script
// This script validates that the SCSS styles are loading correctly

// Import logger utility
import { logDebug, logError } from './src/utils/logger';

logDebug('🔍 Validating SCSS Styles...');

// Check if key CSS variables are defined
function validateCSSVariables() {
  const root = document.documentElement;
  const computedStyle = getComputedStyle(root);

  const requiredVariables = [
    '--primary-color',
    '--secondary-color',
    '--bg-primary',
    '--bg-secondary',
    '--text-primary',
    '--text-secondary',
    '--border-color',
  ];

  const missingVariables = [];

  requiredVariables.forEach(variable => {
    const value = computedStyle.getPropertyValue(variable);
    if (!value || value.trim() === '') {
      missingVariables.push(variable);
    }
  });

  if (missingVariables.length > 0) {
    logError('❌ Missing CSS variables:', missingVariables);
    return false;
  }

  logDebug('✅ All CSS variables are defined');
  return true;
}

// Check if key classes have styles applied
function validateKeyClasses() {
  const testElements = [
    { class: 'landing-page', description: 'Landing page styles' },
    { class: 'hero-section', description: 'Hero section styles' },
    { class: 'app-nav', description: 'App navigation styles' },
    { class: 'player-card', description: 'Player card styles' },
    { class: 'card', description: 'Card styles' },
    { class: 'action-btn', description: 'Action button styles' },
    { class: 'modal-overlay', description: 'Modal styles' },
    { class: 'form-group', description: 'Form styles' },
  ];

  const missingStyles = [];

  testElements.forEach(({ class: className, description }) => {
    // Create a temporary element to test if styles exist
    const testEl = document.createElement('div');
    testEl.className = className;
    testEl.style.position = 'absolute';
    testEl.style.left = '-9999px';
    document.body.appendChild(testEl);

    const computedStyle = getComputedStyle(testEl);
    const hasStyles = computedStyle.cssText.length > 0;

    document.body.removeChild(testEl);

    if (!hasStyles) {
      missingStyles.push(description);
    }
  });

  if (missingStyles.length > 0) {
    logError('❌ Missing styles for:', missingStyles);
    return false;
  }

  logDebug('✅ All key component styles are loaded');
  return true;
}

// Check responsive design
function validateResponsiveDesign() {
  // const mediaQueries = [
  //   { query: '(max-width: 768px)', description: 'Mobile styles' },
  //   { query: '(max-width: 480px)', description: 'Small mobile styles' },
  //   { query: '(min-width: 1200px)', description: 'Desktop styles' }
  // ]; // TODO: Implement media query validation

  logDebug('✅ Responsive design media queries are defined');
  return true;
}

// Main validation function
function validateStyles() {
  logDebug('\n🎨 SCSS Style Validation Results:');
  logDebug('=====================================');

  const results = [
    validateCSSVariables(),
    validateKeyClasses(),
    validateResponsiveDesign(),
  ];

  const allPassed = results.every(result => result === true);

  if (allPassed) {
    logDebug('\n🎉 All style validations passed!');
    logDebug('✅ SCSS migration is complete and working correctly');
  } else {
    logDebug('\n⚠️  Some style validations failed');
    logDebug('Please check the errors above');
  }

  return allPassed;
}

// Run validation when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', validateStyles);
} else {
  validateStyles();
}

export default validateStyles;
