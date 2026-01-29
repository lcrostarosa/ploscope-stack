#!/usr/bin/env node
// deduplicateStyles.js – removes duplicate declarations from styles/main.css
// USAGE:  node src/scripts/styles/deduplicateStyles.js
// -----------------------------------------------------------------------------
// A declaration is considered duplicate when the exact same selector + property
// + value appears in any other stylesheet under src/styles/.
// When such a duplicate is found, the declaration is removed from main.css so
// the more specific stylesheet becomes the single source of truth.
// -----------------------------------------------------------------------------

const fs = require('fs');
const path = require('path');

const glob = require('glob');
const postcss = require('postcss');
const safeParser = require('postcss-safe-parser');

const { logDebug, logError } = require('../../utils/logger');

// Resolve paths ----------------------------------------------------------------
const stylesDir = path.join(__dirname, '..', '..', 'styles');
const mainCssPath = path.join(stylesDir, 'main.css');

if (!fs.existsSync(mainCssPath)) {
  logError(
    `[deduplicateStyles] main.css not found at expected path: ${mainCssPath}`
  );
  process.exit(1);
}

// Gather all other css files ----------------------------------------------------
const otherCssFiles = glob.sync(path.join(stylesDir, '**', '*.css'), {
  ignore: [mainCssPath],
});

if (!otherCssFiles.length) {
  logDebug(
    '[deduplicateStyles] No additional CSS files found – nothing to deduplicate.'
  );
  process.exit(0);
}

// Build the set of declarations present in other stylesheets -------------------
// Build selector→file mapping and PostCSS roots for component/page stylesheets
const fileDataMap = {}; // filePath -> { root, selectorMap: { sel -> { ruleNode, props: Set } }, dirty }

otherCssFiles.forEach(filePath => {
  const cssContent = fs.readFileSync(filePath, 'utf8');
  const root = postcss.parse(cssContent, { parser: safeParser });
  const selectorMap = {};

  root.walkRules(rule => {
    const selectors = rule.selectors || [rule.selector];
    selectors.forEach(sel => {
      if (!selectorMap[sel]) {
        selectorMap[sel] = { ruleNode: rule, props: new Map() };
      }
      rule.walkDecls(decl => {
        selectorMap[sel].props.set(decl.prop, decl.value);
      });
    });
  });

  fileDataMap[filePath] = {
    root,
    selectorMap,
    dirty: false,
  };
});

// Parse main.css and move duplicates ------------------------------------------
const mainCssContent = fs.readFileSync(mainCssPath, 'utf8');
const mainRoot = postcss.parse(mainCssContent, { parser: safeParser });
let movedDecls = 0;

function processRule(ruleNode) {
  const selectors = ruleNode.selectors || [ruleNode.selector];

  selectors.forEach(sel => {
    // Find all files that contain this selector
    const candidateFiles = Object.entries(fileDataMap)
      .filter(([, data]) => sel in data.selectorMap)
      .map(([filePath]) => filePath);

    if (candidateFiles.length !== 1) {
      // Ambiguous ownership (0 or >1) – skip moving to avoid clashes
      return;
    }

    const targetFile = candidateFiles[0];
    const targetData = fileDataMap[targetFile];
    const targetRuleInfo = targetData.selectorMap[sel];

    ruleNode.walkDecls(decl => {
      const keyExists = targetRuleInfo.props.has(decl.prop);
      if (!keyExists) {
        // Clone declaration into target rule
        targetRuleInfo.ruleNode.append(decl.clone());
        targetRuleInfo.props.set(decl.prop, decl.value);
        movedDecls += 1;
        decl.remove();
      } else {
        // If prop already exists with same value, safe to remove duplicate
        const existingVal = targetRuleInfo.props.get(decl.prop);
        if (existingVal === decl.value) {
          movedDecls += 1;
          decl.remove();
        }
      }
    });

    // Mark target file as changed if we moved any declarations
    if (movedDecls > 0) {
      targetData.dirty = true;
    }
  });

  // After processing, if rule has no declarations left, remove it
  if (
    !ruleNode.nodes ||
    ruleNode.nodes.filter(n => n.type === 'decl').length === 0
  ) {
    ruleNode.remove();
  }
}

mainRoot.walkRules(processRule);

// --------------------------------------------------
// Output results
// --------------------------------------------------

if (movedDecls === 0) {
  logDebug(
    '[deduplicateStyles] 🎉 No duplicates to move – main.css unchanged.'
  );
  process.exit(0);
}

function writeFiles() {
  // Write updated component/page stylesheets
  Object.entries(fileDataMap).forEach(([filePath, data]) => {
    if (data.dirty) {
      fs.writeFileSync(filePath, data.root.toResult().css);
      logDebug(`   ↳ Updated ${path.relative(stylesDir, filePath)}`);
    }
  });
  // Write updated main.css
  fs.writeFileSync(mainCssPath, mainRoot.toResult().css);
  logDebug(
    `[deduplicateStyles] ✅ Moved ${movedDecls} declaration${movedDecls !== 1 ? 's' : ''} out of main.css.`
  );
}

// CLI entrypoint --------------------------------------------------------------
const args = process.argv.slice(2);
const shouldApply = args.includes('--apply');

if (shouldApply) {
  writeFiles();
} else {
  logDebug('[deduplicateStyles] DRY-RUN (no files written).');
  logDebug(
    `   Would move ${movedDecls} declaration${movedDecls !== 1 ? 's' : ''} into page/component stylesheets.`
  );
  logDebug('   Re-run with --apply to write changes.');
}
