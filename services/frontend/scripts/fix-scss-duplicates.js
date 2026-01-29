#!/usr/bin/env node
// fix-scss-duplicates.js – fixes duplicate selectors and properties in SCSS files
// USAGE: node scripts/fix-scss-duplicates.js
// -----------------------------------------------------------------------------
// This script identifies and suggests fixes for:
// 1. Duplicate selectors across files
// 2. Duplicate properties within selectors
// 3. Common patterns that can be consolidated
// -----------------------------------------------------------------------------

/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');

const glob = require('glob');

// Import logger utility
const { logDebug } = require('../utils/logger');

// Configuration
const SCSS_DIR = path.join(__dirname, '..', 'styles', 'scss');
const IGNORE_FILES = ['_index.scss', 'GONE_main.scss'];

// Data structures
const selectorMap = new Map(); // selector -> [file, line, properties]
const commonPatterns = new Map(); // pattern -> [selectors]

// Common patterns to look for
const PATTERNS = {
  BUTTONS: [
    '.btn',
    '.btn-primary',
    '.btn-secondary',
    '.btn--primary',
    '.btn--secondary',
    '.nav-login-btn',
    '.nav-cta-btn',
    '.hero-cta-primary',
    '.hero-cta-secondary',
  ],
  CARDS: ['.card', '.player-card', '.mode-card', '.card-picker-card'],
  FORMS: ['input', 'select', 'textarea', '.form-group', '.form-control'],
  LAYOUT: ['.container', '.hero-container', '.app-home-container'],
  NAVIGATION: ['.nav', '.landing-nav', '.nav-container', '.nav-actions'],
};

// Helper to extract selectors from SCSS content
function extractSelectors(content, filePath) {
  const lines = content.split('\n');
  let currentSelector = null;
  let inSelector = false;
  let braceCount = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Skip comments and imports
    if (
      line.startsWith('//') ||
      line.startsWith('/*') ||
      line.startsWith('@use') ||
      line.startsWith('@import')
    ) {
      continue;
    }

    // Find selector lines
    if (line.includes('{') && !line.startsWith('@')) {
      const selectorMatch = line.match(/^([^{]+)\s*\{/);
      if (selectorMatch) {
        const selector = selectorMatch[1].trim();
        if (selector && !selector.startsWith('//')) {
          currentSelector = selector;
          inSelector = true;
          braceCount =
            (line.match(/\{/g) || []).length - (line.match(/\}/g) || []).length;

          // Track selector
          if (!selectorMap.has(selector)) {
            selectorMap.set(selector, []);
          }
          selectorMap
            .get(selector)
            .push({ file: filePath, line: i + 1, properties: [] });
        }
      }
    } else if (inSelector && currentSelector) {
      // Count braces
      braceCount += (line.match(/\{/g) || []).length;
      braceCount -= (line.match(/\}/g) || []).length;

      // Extract properties
      if (line.includes(':') && !line.startsWith('//')) {
        const match = line.match(/^\s*([^:]+):\s*(.+)$/);
        if (match) {
          const [, property, value] = match;
          const cleanProperty = property.trim();
          const cleanValue = value.trim().replace(/;$/, '');

          if (cleanProperty && cleanValue) {
            const entries = selectorMap.get(currentSelector);
            if (entries && entries.length > 0) {
              entries[entries.length - 1].properties.push({
                property: cleanProperty,
                value: cleanValue,
              });
            }
          }
        }
      }

      // End of selector block
      if (braceCount <= 0) {
        inSelector = false;
        currentSelector = null;
        braceCount = 0;
      }
    }
  }
}

// Analyze patterns
function analyzePatterns() {
  logDebug('🔍 Analyzing common patterns...\n');

  Object.entries(PATTERNS).forEach(([patternName, selectors]) => {
    const foundSelectors = [];
    selectors.forEach(selector => {
      if (selectorMap.has(selector)) {
        foundSelectors.push(selector);
      }
    });

    if (foundSelectors.length > 1) {
      commonPatterns.set(patternName, foundSelectors);
    }
  });
}

// Generate consolidation suggestions
function generateSuggestions() {
  logDebug('💡 GENERATING CONSOLIDATION SUGGESTIONS');
  logDebug('='.repeat(60));

  // 1. Button patterns
  if (commonPatterns.has('BUTTONS')) {
    logDebug('\n🎯 BUTTON PATTERNS');
    logDebug('Consider creating a button mixin in base/_base.scss:');
    logDebug('```scss');
    // eslint-disable-next-line no-console
    console.log('@mixin button-base($variant: "primary") {');
    // eslint-disable-next-line no-console
    console.log('  padding: 0.75rem 1.5rem;');
    // eslint-disable-next-line no-console
    console.log('  border: none;');
    // eslint-disable-next-line no-console
    console.log('  border-radius: 6px;');
    // eslint-disable-next-line no-console
    console.log('  font-weight: 600;');
    // eslint-disable-next-line no-console
    console.log('  cursor: pointer;');
    // eslint-disable-next-line no-console
    console.log('  transition: all 0.2s ease;');
    // eslint-disable-next-line no-console
    console.log('  text-decoration: none;');
    // eslint-disable-next-line no-console
    console.log('  display: inline-flex;');
    // eslint-disable-next-line no-console
    console.log('  align-items: center;');
    // eslint-disable-next-line no-console
    console.log('  justify-content: center;');
    // eslint-disable-next-line no-console
    console.log('  ');
    // eslint-disable-next-line no-console
    console.log('  @if $variant == "primary" {');
    // eslint-disable-next-line no-console
    console.log('    background: var(--primary-color);');
    // eslint-disable-next-line no-console
    console.log('    color: white;');
    // eslint-disable-next-line no-console
    console.log('    box-shadow: 0 2px 8px rgba(229, 57, 53, 0.3);');
    // eslint-disable-next-line no-console
    console.log('  } @else if $variant == "secondary" {');
    // eslint-disable-next-line no-console
    console.log('    background: var(--bg-secondary);');
    // eslint-disable-next-line no-console
    console.log('    color: var(--text-primary);');
    // eslint-disable-next-line no-console
    console.log('    border: 1px solid var(--border-color);');
    // eslint-disable-next-line no-console
    console.log('  }');
    // eslint-disable-next-line no-console
    console.log('  ');
    // eslint-disable-next-line no-console
    console.log('  &:hover:not(:disabled) {');
    // eslint-disable-next-line no-console
    console.log('    transform: translateY(-1px);');
    // eslint-disable-next-line no-console
    console.log('    box-shadow: 0 4px 12px rgba(229, 57, 53, 0.4);');
    // eslint-disable-next-line no-console
    console.log('  }');
    // eslint-disable-next-line no-console
    console.log('  ');
    // eslint-disable-next-line no-console
    console.log('  &:disabled {');
    // eslint-disable-next-line no-console
    console.log('    opacity: 0.6;');
    // eslint-disable-next-line no-console
    console.log('    cursor: not-allowed;');
    // eslint-disable-next-line no-console
    console.log('    transform: none;');
    // eslint-disable-next-line no-console
    console.log('  }');
    // eslint-disable-next-line no-console
    console.log('}');
    // eslint-disable-next-line no-console
    console.log('```');
  }

  // 2. Card patterns
  if (commonPatterns.has('CARDS')) {
    console.log('\n🎯 CARD PATTERNS');
    console.log('Consider creating a card mixin in base/_base.scss:');
    console.log('```scss');
    console.log('@mixin card-base($variant: "default") {');
    console.log('  background: var(--bg-secondary);');
    console.log('  border: 1px solid var(--border-color);');
    console.log('  border-radius: 8px;');
    console.log('  transition: all 0.3s ease;');
    console.log('  ');
    console.log('  &:hover {');
    console.log('    transform: translateY(-2px);');
    console.log('    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);');
    console.log('  }');
    console.log('}');
    console.log('```');
  }

  // 3. Form patterns
  if (commonPatterns.has('FORMS')) {
    console.log('\n🎯 FORM PATTERNS');
    console.log('Consider creating form mixins in components/Forms.scss:');
    console.log('```scss');
    console.log('@mixin form-input-base {');
    console.log('  width: 100%;');
    console.log('  padding: 0.75rem;');
    console.log('  border: 1px solid var(--border-color);');
    console.log('  border-radius: 4px;');
    console.log('  background: var(--input-bg);');
    console.log('  color: var(--text-primary);');
    console.log('  font-size: 1rem;');
    console.log('  transition: all 0.2s ease;');
    console.log('  ');
    console.log('  &:focus {');
    console.log('    outline: none;');
    console.log('    border-color: var(--primary-color);');
    console.log('    box-shadow: 0 0 0 2px rgba(229, 57, 53, 0.1);');
    console.log('  }');
    console.log('}');
    console.log('```');
  }

  // 4. Layout patterns
  if (commonPatterns.has('LAYOUT')) {
    console.log('\n🎯 LAYOUT PATTERNS');
    console.log('Consider creating layout mixins in layout/_layout.scss:');
    console.log('```scss');
    console.log('@mixin container-base($max-width: 1200px) {');
    console.log('  max-width: $max-width;');
    console.log('  margin: 0 auto;');
    console.log('  padding: 0 2rem;');
    console.log('  ');
    console.log('  @media (max-width: 768px) {');
    console.log('    padding: 0 1rem;');
    console.log('  }');
    console.log('}');
    console.log('```');
  }
}

// Show specific duplicates
function showSpecificDuplicates() {
  console.log('\n📊 SPECIFIC DUPLICATES FOUND');
  console.log('='.repeat(60));

  let duplicateCount = 0;

  selectorMap.forEach((entries, selector) => {
    if (entries.length > 1) {
      const files = [...new Set(entries.map(e => e.file))];
      if (files.length > 1) {
        duplicateCount++;

        // Only show first few duplicates to avoid overwhelming output
        if (duplicateCount <= 10) {
          console.log(`\n🔍 Selector: ${selector}`);
          console.log(`   Found in ${files.length} files:`);
          files.forEach(file => {
            console.log(`     📄 ${file}`);
          });

          // Show conflicting properties
          const allProperties = new Map();
          entries.forEach(entry => {
            entry.properties.forEach(prop => {
              if (!allProperties.has(prop.property)) {
                allProperties.set(prop.property, new Set());
              }
              allProperties.get(prop.property).add(prop.value);
            });
          });

          const conflicts = [];
          allProperties.forEach((values, property) => {
            if (values.size > 1) {
              conflicts.push({ property, values: Array.from(values) });
            }
          });

          if (conflicts.length > 0) {
            console.log(`   ⚠️  Conflicting properties:`);
            conflicts.forEach(conflict => {
              console.log(
                `      ${conflict.property}: ${conflict.values.join(' | ')}`
              );
            });
          }
        }
      }
    }
  });

  if (duplicateCount > 10) {
    console.log(`\n... and ${duplicateCount - 10} more duplicate selectors`);
  }

  return duplicateCount;
}

// Main function
function analyzeSCSS() {
  console.log('🔍 Analyzing SCSS files for duplicates and patterns...\n');

  // Find all SCSS files
  const scssFiles = glob.sync(path.join(SCSS_DIR, '**', '*.scss'), {
    ignore: IGNORE_FILES.map(file => path.join(SCSS_DIR, '**', file)),
  });

  console.log(`📁 Found ${scssFiles.length} SCSS files to analyze\n`);

  // Process each file
  scssFiles.forEach(filePath => {
    const relativePath = path.relative(SCSS_DIR, filePath);
    console.log(`  📄 Processing: ${relativePath}`);

    try {
      const content = fs.readFileSync(filePath, 'utf8');
      extractSelectors(content, relativePath);
    } catch (error) {
      console.error(`  ❌ Error reading ${relativePath}:`, error.message);
    }
  });

  // Analyze patterns
  analyzePatterns();

  // Show results
  const duplicateCount = showSpecificDuplicates();
  generateSuggestions();

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log(`📈 SUMMARY: ${duplicateCount} duplicate selectors found`);
  console.log('='.repeat(60));

  if (duplicateCount === 0) {
    console.log('🎉 No duplicates found! Your SCSS is well organized.');
  } else {
    console.log('\n💡 RECOMMENDATIONS:');
    console.log(
      '1. Use SCSS mixins for common patterns (buttons, cards, forms)'
    );
    console.log('2. Consolidate similar selectors into shared components');
    console.log('3. Use CSS custom properties for consistent theming');
    console.log(
      '4. Consider creating a design system with reusable components'
    );
    console.log(
      '5. Review the suggestions above for specific consolidation strategies'
    );
  }

  return duplicateCount;
}

// Run analysis
if (require.main === module) {
  const duplicates = analyzeSCSS();
  process.exit(duplicates > 0 ? 1 : 0);
}

module.exports = { analyzeSCSS };
