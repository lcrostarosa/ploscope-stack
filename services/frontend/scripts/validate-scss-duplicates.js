#!/usr/bin/env node
// validate-scss-duplicates.js – validates SCSS files for duplicate selectors and properties
// USAGE: node scripts/validate-scss-duplicates.js
// -----------------------------------------------------------------------------
// This script analyzes all SCSS files to find:
// 1. Duplicate selectors across files
// 2. Duplicate properties within the same selector
// 3. Conflicting CSS custom properties
// -----------------------------------------------------------------------------

const fs = require('fs');
const path = require('path');

const glob = require('glob');

// Import logger utility
const { logDebug, logWarn, logError } = require('../utils/logger');

// Configuration
const SCSS_DIR = path.join(__dirname, '..', 'styles', 'scss');
const IGNORE_FILES = ['_index.scss', 'GONE_main.scss'];

// Data structures to track duplicates
const selectorMap = new Map(); // selector -> [file, line, properties]
const propertyMap = new Map(); // selector -> Map(property -> [values])
const cssVars = new Map(); // variable -> [file, line, value]

// Helper to extract selectors from SCSS content
function extractSelectors(content, filePath) {
  const lines = content.split('\n');
  // const selectors = []; // TODO: Implement selector extraction
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

    // Check for CSS custom properties
    if (line.includes('--') && line.includes(':')) {
      const match = line.match(/--([^:]+):\s*([^;]+);?/);
      if (match) {
        const [, varName, value] = match;
        if (cssVars.has(varName)) {
          cssVars
            .get(varName)
            .push({ file: filePath, line: i + 1, value: value.trim() });
        } else {
          cssVars.set(varName, [
            { file: filePath, line: i + 1, value: value.trim() },
          ]);
        }
      }
    }

    // Find selector lines (lines that end with { or contain {)
    if (line.includes('{') && !line.startsWith('@')) {
      const selectorMatch = line.match(/^([^{]+)\s*\{/);
      if (selectorMatch) {
        const selector = selectorMatch[1].trim();
        if (selector && !selector.startsWith('//')) {
          currentSelector = selector;
          inSelector = true;
          braceCount =
            (line.match(/\{/g) || []).length - (line.match(/\}/g) || []).length;

          // Extract properties from the same line if they exist
          const propertyMatch = line.match(/\{([^}]+)\}/);
          if (propertyMatch) {
            extractProperties(
              propertyMatch[1],
              currentSelector,
              filePath,
              i + 1
            );
          }
        }
      }
    } else if (inSelector && currentSelector) {
      // Count braces to track nested blocks
      braceCount += (line.match(/\{/g) || []).length;
      braceCount -= (line.match(/\}/g) || []).length;

      // Extract properties from this line
      if (line.includes(':') && !line.startsWith('//')) {
        extractProperties(line, currentSelector, filePath, i + 1);
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

// Helper to extract properties from a line
function extractProperties(line, selector, filePath, lineNum) {
  // Split by semicolon and process each property
  const properties = line.split(';').filter(p => p.trim());

  properties.forEach(prop => {
    const match = prop.match(/^\s*([^:]+):\s*(.+)$/);
    if (match) {
      const [, property, value] = match;
      const cleanProperty = property.trim();
      const cleanValue = value.trim();

      if (cleanProperty && cleanValue) {
        // Track selector
        if (!selectorMap.has(selector)) {
          selectorMap.set(selector, []);
        }
        selectorMap
          .get(selector)
          .push({
            file: filePath,
            line: lineNum,
            property: cleanProperty,
            value: cleanValue,
          });

        // Track properties for this selector
        if (!propertyMap.has(selector)) {
          propertyMap.set(selector, new Map());
        }

        const selectorProps = propertyMap.get(selector);
        if (!selectorProps.has(cleanProperty)) {
          selectorProps.set(cleanProperty, []);
        }
        selectorProps
          .get(cleanProperty)
          .push({ file: filePath, line: lineNum, value: cleanValue });
      }
    }
  });
}

// Main validation function
function validateSCSS() {
  logDebug('🔍 Validating SCSS files for duplicates...\n');

  // Find all SCSS files
  const scssFiles = glob.sync(path.join(SCSS_DIR, '**', '*.scss'), {
    ignore: IGNORE_FILES.map(file => path.join(SCSS_DIR, '**', file)),
  });

  logDebug(`📁 Found ${scssFiles.length} SCSS files to analyze\n`);

  // Process each file
  scssFiles.forEach(filePath => {
    const relativePath = path.relative(SCSS_DIR, filePath);
    logDebug(`  📄 Processing: ${relativePath}`);

    try {
      const content = fs.readFileSync(filePath, 'utf8');
      extractSelectors(content, relativePath);
    } catch (error) {
      logError(`  ❌ Error reading ${relativePath}:`, error.message);
    }
  });

  logDebug('\n' + '='.repeat(60));
  logDebug('📊 VALIDATION RESULTS');
  logDebug('='.repeat(60));

  // Check for duplicate selectors
  const duplicateSelectors = [];
  selectorMap.forEach((entries, selector) => {
    if (entries.length > 1) {
      const files = [...new Set(entries.map(e => e.file))];
      if (files.length > 1) {
        duplicateSelectors.push({ selector, entries });
      }
    }
  });

  // Check for duplicate properties within selectors
  const duplicateProperties = [];
  propertyMap.forEach((properties, selector) => {
    properties.forEach((values, property) => {
      if (values.length > 1) {
        const uniqueValues = [...new Set(values.map(v => v.value))];
        if (uniqueValues.length > 1) {
          duplicateProperties.push({ selector, property, values });
        }
      }
    });
  });

  // Check for duplicate CSS custom properties
  const duplicateCSSVars = [];
  cssVars.forEach((entries, varName) => {
    if (entries.length > 1) {
      const uniqueValues = [...new Set(entries.map(e => e.value))];
      if (uniqueValues.length > 1) {
        duplicateCSSVars.push({ varName, entries });
      }
    }
  });

  // Report results
  logDebug(`\n🎯 DUPLICATE SELECTORS: ${duplicateSelectors.length}`);
  if (duplicateSelectors.length > 0) {
    logWarn('⚠️  The following selectors appear in multiple files:');
    duplicateSelectors.forEach(({ selector, entries }) => {
      logDebug(`\n   Selector: ${selector}`);
      entries.forEach(entry => {
        logDebug(
          `     📄 ${entry.file}:${entry.line} - ${entry.property}: ${entry.value}`
        );
      });
    });
  } else {
    logDebug('✅ No duplicate selectors found across files');
  }

  logDebug(`\n🎯 DUPLICATE PROPERTIES: ${duplicateProperties.length}`);
  if (duplicateProperties.length > 0) {
    logWarn('⚠️  The following properties have conflicting values:');
    duplicateProperties.forEach(({ selector, property, values }) => {
      logDebug(`\n   Selector: ${selector}`);
      logDebug(`   Property: ${property}`);
      values.forEach(value => {
        logDebug(`     📄 ${value.file}:${value.line} - ${value.value}`);
      });
    });
  } else {
    logDebug('✅ No conflicting properties found');
  }

  logDebug(`\n🎯 DUPLICATE CSS VARIABLES: ${duplicateCSSVars.length}`);
  if (duplicateCSSVars.length > 0) {
    logWarn('⚠️  The following CSS custom properties have conflicting values:');
    duplicateCSSVars.forEach(({ varName, entries }) => {
      logDebug(`\n   Variable: --${varName}`);
      entries.forEach(entry => {
        logDebug(`     📄 ${entry.file}:${entry.line} - ${entry.value}`);
      });
    });
  } else {
    logDebug('✅ No conflicting CSS variables found');
  }

  // Summary
  const totalIssues =
    duplicateSelectors.length +
    duplicateProperties.length +
    duplicateCSSVars.length;
  logDebug('\n' + '='.repeat(60));
  logDebug(`📈 SUMMARY: ${totalIssues} potential issues found`);
  logDebug('='.repeat(60));

  if (totalIssues === 0) {
    logDebug('🎉 All SCSS files are clean! No duplicates or conflicts found.');
  } else {
    logDebug(
      '💡 Consider consolidating duplicate styles or using SCSS features like:'
    );
    logDebug('   - @extend for shared styles');
    logDebug('   - Mixins for reusable patterns');
    logDebug('   - CSS custom properties for theming');
    logDebug('   - Organizing styles by component/page');
  }

  return totalIssues;
}

// Run validation
if (require.main === module) {
  const issues = validateSCSS();
  process.exit(issues > 0 ? 1 : 0);
}

module.exports = { validateSCSS };
