const { Given } = require('@cucumber/cucumber');

// Import logger utility
const {
  logDebug: loggerDebug,
  logError: loggerError,
} = require('../../../../utils/logger');

// Simple logging functions
const logDebug = (message, ...args) => {
  if (process.env.CUCUMBER_VERBOSE) {
    loggerDebug(`[DEBUG] ${message}`, ...args);
  }
};

const logError = (message, ...args) => {
  loggerError(`[ERROR] ${message}`, ...args);
};

// Setup step definitions only - hooks are handled in support/hooks.js

// Setup step definitions
Given('the application is running', async function () {
  try {
    const baseUrl = this.baseUrl || 'http://localhost';
    logDebug(`Attempting to access application at: ${baseUrl}`);
    await this.page.goto(baseUrl);
    logDebug('Page loaded, waiting for body element...');
    await this.page.waitForSelector('body', { timeout: 10000 });
    logDebug('Body element found');

    // Handle common popups
    await handlePopups.call(this);

    logDebug('Application is running and accessible');
  } catch (error) {
    logError('Failed to access application:', error.message);
    // Take a screenshot for debugging
    try {
      const screenshotPath = `./screenshots/debug_${Date.now()}.png`;
      await this.page.screenshot({ path: screenshotPath, fullPage: true });
      logError(`Debug screenshot saved: ${screenshotPath}`);
    } catch (screenshotError) {
      logError('Failed to take debug screenshot:', screenshotError.message);
    }
    throw error;
  }
});

Given('I am on the home page', async function () {
  const baseUrl = this.baseUrl || 'http://localhost';
  await this.page.goto(baseUrl);
  // Wait for the app to load - look for any main content
  await this.page.waitForSelector('.app-home, .landing-page, main', {
    timeout: 10000,
  });

  // Handle common popups
  await handlePopups.call(this);
});

Given('I am on the solver page', async function () {
  const baseUrl = this.baseUrl || 'http://localhost';
  await this.page.goto(`${baseUrl}/app/solver`);
  // Wait for solver page to load
  await this.page.waitForSelector('.solver-mode, .solver-content', {
    timeout: 10000,
  });
});

Given('PLO mode is selected', async function () {
  // Look for PLO-specific elements on the solver page
  const ploElements = await this.page.$$(
    '[data-testid="plo-mode"], .plo-mode, .game-type-selector'
  );
  if (ploElements.length > 0) {
    await ploElements[0].click();
  }
});

// Helper function to handle common popups
async function handlePopups() {
  // Handle cookie consent popup if present
  try {
    const cookieConsent = await this.page.$(
      '[data-testid="cookie-consent"], .cookie-consent, .cookie-banner'
    );
    if (cookieConsent) {
      const acceptButton = await cookieConsent.$(
        'button[data-testid="accept"], .accept, .accept-cookies'
      );
      if (acceptButton) {
        await acceptButton.click();
        logDebug('Accepted cookie consent');
      }
    }
  } catch (e) {
    // Cookie consent not present, continue
  }
}

module.exports = { logDebug, logError, handlePopups };
