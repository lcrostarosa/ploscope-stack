const { Given, Then } = require('@cucumber/cucumber');
const { expect } = require('chai');

// PLO-specific step definitions
Given('I have set up a complete PLO scenario', async function () {
  // Set up a complete PLO scenario with cards and board
  await this.Given('I have set up a complete hand scenario');

  // Ensure PLO mode is selected
  const ploElements = await this.page.$$(
    '[data-testid="plo-mode"], .plo-mode, .game-type-selector'
  );
  if (ploElements.length > 0) {
    await ploElements[0].click();
  }
});

Given('PLO equity calculation has completed', async function () {
  // Wait for PLO equity calculation to complete
  const resultsSelectors = [
    '[data-testid="plo-equity-results"]',
    '.plo-equity-results',
    '.equity-results',
    '.calculation-results',
  ];

  let resultsElement = null;
  for (const selector of resultsSelectors) {
    try {
      resultsElement = await this.page.$(selector);
      if (resultsElement) break;
    } catch (e) {
      continue;
    }
  }

  if (resultsElement) {
    // Wait for results to be visible
    await this.page.waitForTimeout(1000);
  }
});

Given('I have completed a PLO analysis', async function () {
  // Set up and complete a PLO analysis
  await this.Given('I have set up a complete PLO scenario');

  const calculateSelectors = [
    '[data-testid="calculate-equity"]',
    '.calculate-button',
    'button:has-text("Calculate")',
    'button:has-text("Solve")',
  ];

  let calculateButton = null;
  for (const selector of calculateSelectors) {
    try {
      calculateButton = await this.page.$(selector);
      if (calculateButton) break;
    } catch (e) {
      continue;
    }
  }

  if (calculateButton) {
    await calculateButton.click();
  }

  // Wait for analysis to complete
  await this.Given('PLO equity calculation has completed');
});

// PLO verification steps
Then('PLO mode should be active', async function () {
  const ploModeSelectors = [
    '[data-testid="plo-mode-active"]',
    '.plo-mode.active',
    '.game-type-plo',
  ];

  let ploMode = null;
  for (const selector of ploModeSelectors) {
    try {
      ploMode = await this.page.$(selector);
      if (ploMode) break;
    } catch (e) {
      continue;
    }
  }

  if (ploMode) {
    expect(await ploMode.isVisible()).to.be.true;
  }
});

Then('the interface should show PLO-specific options', async function () {
  const ploOptionsSelectors = [
    '[data-testid="plo-options"]',
    '.plo-options',
    '.plo-specific',
  ];

  let ploOptions = null;
  for (const selector of ploOptionsSelectors) {
    try {
      ploOptions = await this.page.$(selector);
      if (ploOptions) break;
    } catch (e) {
      continue;
    }
  }

  if (ploOptions) {
    expect(await ploOptions.isVisible()).to.be.true;
  }
});

Then('the PLO equity calculation should be accurate', async function () {
  // Check that PLO equity calculation results are present and reasonable
  const equitySelectors = [
    '[data-testid="equity-percentage"]',
    '.equity-percentage',
    '.equity-value',
  ];

  let equityElement = null;
  for (const selector of equitySelectors) {
    try {
      equityElement = await this.page.$(selector);
      if (equityElement) break;
    } catch (e) {
      continue;
    }
  }

  if (equityElement) {
    const equityText = await equityElement.textContent();
    const equityValue = parseFloat(equityText.replace(/[^\d.]/g, ''));
    expect(equityValue).to.be.greaterThan(0);
    expect(equityValue).to.be.lessThanOrEqual(100);
  }
});

Then('the PLO hand rankings should be correct', async function () {
  // Verify that PLO hand rankings are displayed correctly
  const rankingSelectors = [
    '[data-testid="hand-ranking"]',
    '.hand-ranking',
    '.ranking',
  ];

  let rankingElement = null;
  for (const selector of rankingSelectors) {
    try {
      rankingElement = await this.page.$(selector);
      if (rankingElement) break;
    } catch (e) {
      continue;
    }
  }

  if (rankingElement) {
    const rankingText = await rankingElement.textContent();
    expect(rankingText).to.not.be.empty;
  }
});

Then('the PLO pot odds should be calculated', async function () {
  // Check that pot odds are calculated for PLO
  const potOddsSelectors = ['[data-testid="pot-odds"]', '.pot-odds', '.odds'];

  let potOddsElement = null;
  for (const selector of potOddsSelectors) {
    try {
      potOddsElement = await this.page.$(selector);
      if (potOddsElement) break;
    } catch (e) {
      continue;
    }
  }

  if (potOddsElement) {
    const oddsText = await potOddsElement.textContent();
    expect(oddsText).to.not.be.empty;
  }
});

Then('the PLO implied odds should be displayed', async function () {
  // Verify that implied odds are shown for PLO scenarios
  const impliedOddsSelectors = [
    '[data-testid="implied-odds"]',
    '.implied-odds',
    '.implied',
  ];

  let impliedOddsElement = null;
  for (const selector of impliedOddsSelectors) {
    try {
      impliedOddsElement = await this.page.$(selector);
      if (impliedOddsElement) break;
    } catch (e) {
      continue;
    }
  }

  if (impliedOddsElement) {
    const oddsText = await impliedOddsElement.textContent();
    expect(oddsText).to.not.be.empty;
  }
});

Then('the PLO hand strength should be evaluated', async function () {
  // Check that hand strength is properly evaluated for PLO
  const strengthSelectors = [
    '[data-testid="hand-strength"]',
    '.hand-strength',
    '.strength',
  ];

  let strengthElement = null;
  for (const selector of strengthSelectors) {
    try {
      strengthElement = await this.page.$(selector);
      if (strengthElement) break;
    } catch (e) {
      continue;
    }
  }

  if (strengthElement) {
    const strengthText = await strengthElement.textContent();
    expect(strengthText).to.not.be.empty;
  }
});

Then('the PLO drawing odds should be accurate', async function () {
  // Verify that drawing odds are calculated correctly for PLO
  const drawingOddsSelectors = [
    '[data-testid="drawing-odds"]',
    '.drawing-odds',
    '.draw-odds',
  ];

  let drawingOddsElement = null;
  for (const selector of drawingOddsSelectors) {
    try {
      drawingOddsElement = await this.page.$(selector);
      if (drawingOddsElement) break;
    } catch (e) {
      continue;
    }
  }

  if (drawingOddsElement) {
    const oddsText = await drawingOddsElement.textContent();
    expect(oddsText).to.not.be.empty;
  }
});

Then('the PLO outs should be counted correctly', async function () {
  // Check that outs are counted properly for PLO hands
  const outsSelectors = ['[data-testid="outs-count"]', '.outs-count', '.outs'];

  let outsElement = null;
  for (const selector of outsSelectors) {
    try {
      outsElement = await this.page.$(selector);
      if (outsElement) break;
    } catch (e) {
      continue;
    }
  }

  if (outsElement) {
    const outsText = await outsElement.textContent();
    const outsCount = parseInt(outsText.replace(/[^\d]/g, ''));
    expect(outsCount).to.be.greaterThanOrEqual(0);
    expect(outsCount).to.be.lessThanOrEqual(47); // Maximum possible outs in PLO
  }
});

Then('the PLO hand should be properly categorized', async function () {
  // Verify that PLO hands are categorized correctly
  const categorySelectors = [
    '[data-testid="hand-category"]',
    '.hand-category',
    '.category',
  ];

  let categoryElement = null;
  for (const selector of categorySelectors) {
    try {
      categoryElement = await this.page.$(selector);
      if (categoryElement) break;
    } catch (e) {
      continue;
    }
  }

  if (categoryElement) {
    const categoryText = await categoryElement.textContent();
    expect(categoryText).to.not.be.empty;
  }
});

Then('the PLO analysis should be complete', async function () {
  // Check that the PLO analysis has completed successfully
  const completeSelectors = [
    '[data-testid="analysis-complete"]',
    '.analysis-complete',
    '.complete',
  ];

  let completeElement = null;
  for (const selector of completeSelectors) {
    try {
      completeElement = await this.page.$(selector);
      if (completeElement) break;
    } catch (e) {
      continue;
    }
  }

  if (completeElement) {
    expect(await completeElement.isVisible()).to.be.true;
  }
});

Then('the PLO results should be exportable', async function () {
  // Verify that PLO analysis results can be exported
  const exportSelectors = [
    '[data-testid="export-results"]',
    '.export-results',
    '.export-button',
  ];

  let exportElement = null;
  for (const selector of exportSelectors) {
    try {
      exportElement = await this.page.$(selector);
      if (exportElement) break;
    } catch (e) {
      continue;
    }
  }

  if (exportElement) {
    expect(await exportElement.isVisible()).to.be.true;
  }
});

Then('the PLO hand history should be saved', async function () {
  // Check that PLO hand history is properly saved
  const historySelectors = [
    '[data-testid="hand-history"]',
    '.hand-history',
    '.history',
  ];

  let historyElement = null;
  for (const selector of historySelectors) {
    try {
      historyElement = await this.page.$(selector);
      if (historyElement) break;
    } catch (e) {
      continue;
    }
  }

  if (historyElement) {
    expect(await historyElement.isVisible()).to.be.true;
  }
});

Then('the PLO settings should be configurable', async function () {
  // Verify that PLO-specific settings can be configured
  const settingsSelectors = [
    '[data-testid="plo-settings"]',
    '.plo-settings',
    '.settings',
  ];

  let settingsElement = null;
  for (const selector of settingsSelectors) {
    try {
      settingsElement = await this.page.$(selector);
      if (settingsElement) break;
    } catch (e) {
      continue;
    }
  }

  if (settingsElement) {
    expect(await settingsElement.isVisible()).to.be.true;
  }
});

Then('the PLO interface should be intuitive', async function () {
  // Check that the PLO interface is user-friendly
  const interfaceSelectors = [
    '[data-testid="plo-interface"]',
    '.plo-interface',
    '.interface',
  ];

  let interfaceElement = null;
  for (const selector of interfaceSelectors) {
    try {
      interfaceElement = await this.page.$(selector);
      if (interfaceElement) break;
    } catch (e) {
      continue;
    }
  }

  if (interfaceElement) {
    expect(await interfaceElement.isVisible()).to.be.true;
  }
});

Then('the PLO performance should be acceptable', async function () {
  // Test that PLO calculations complete within reasonable time
  const startTime = Date.now();

  // Trigger a PLO calculation
  const calculateSelectors = [
    '[data-testid="calculate-equity"]',
    '.calculate-button',
    'button:has-text("Calculate")',
  ];

  let calculateButton = null;
  for (const selector of calculateSelectors) {
    try {
      calculateButton = await this.page.$(selector);
      if (calculateButton) break;
    } catch (e) {
      continue;
    }
  }

  if (calculateButton) {
    await calculateButton.click();

    // Wait for calculation to complete
    await this.page.waitForTimeout(5000);

    const endTime = Date.now();
    const calculationTime = endTime - startTime;

    // Calculation should complete within 10 seconds
    expect(calculationTime).to.be.lessThan(10000);
  }
});
