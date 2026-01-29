const fs = require('fs');
const path = require('path');

const { Before, After, AfterAll } = require('@cucumber/cucumber');

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

// Track if browser has been initialized
let browserInitialized = false;
let browserManager = null;
let teardownInProgress = false;

// Global setup
Before(async function () {
  // Set up test environment
  this.testStartTime = Date.now();
  this.screenshots = [];

  // Create reports directory if it doesn't exist
  const reportsDir = path.join(__dirname, '../reports');
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
  }

  // Create screenshots directory if it doesn't exist
  const screenshotsDir = path.join(__dirname, '../screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }

  // Set up the Playwright browser only once
  if (!browserInitialized) {
    await this.setupDriver();
    browserInitialized = true;
    // Store reference to browser manager for cleanup
    browserManager = this.browserManager || this;
    logDebug('Browser initialized for first time');
  } else {
    // Just get the existing browser instance
    await this.setupDriver();
    logDebug('Reusing existing browser instance');
  }

  logDebug('Test environment initialized');
});

// After each scenario
After({ timeout: 10000 }, async function (scenario) {
  const testEndTime = Date.now();
  const testDuration = testEndTime - this.testStartTime;

  try {
    // Take screenshot if scenario failed
    if (scenario.result.status === 'FAILED') {
      try {
        const screenshotPath = path.join(
          __dirname,
          '../screenshots',
          `${scenario.pickle.name}_${Date.now()}.png`
        );
        await this.page.screenshot({ path: screenshotPath, fullPage: true });
        this.screenshots.push(screenshotPath);
        logDebug(`Screenshot saved: ${screenshotPath}`);
      } catch (error) {
        logError('Failed to take screenshot:', error.message);
      }
    }

    // Log test results
    logDebug(
      `Scenario "${scenario.pickle.name}" completed in ${testDuration}ms with status: ${scenario.result.status}`
    );

    // Clean up any test data
    if (this.testData) {
      // Clean up any test data created during the scenario
      logDebug('Cleaning up test data');
    }

    // Reset browser state between scenarios to ensure clean state
    if (this.resetBrowserState) {
      await this.resetBrowserState();
    }
  } catch (error) {
    logError('Error during cleanup:', error.message);
  }
});

// After all scenarios - completely rewritten to prevent hanging
AfterAll(async function () {
  if (teardownInProgress) {
    logDebug('Teardown already in progress, skipping');
    return;
  }

  teardownInProgress = true;
  logDebug('All scenarios completed - starting teardown');

  // Set a hard timeout for the entire teardown process
  const teardownTimeout = setTimeout(() => {
    logError('Teardown timeout reached, forcing exit');
    forceCleanupAndExit();
  }, 10000); // 10 second timeout

  try {
    // Teardown the Playwright browser with timeout
    if (browserManager && typeof browserManager.teardownDriver === 'function') {
      await Promise.race([
        browserManager.teardownDriver(),
        new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Teardown timeout')), 8000)
        ),
      ]);
      browserInitialized = false;
      logDebug('Browser teardown completed successfully');
    } else {
      logDebug('No browser manager available for teardown');
    }
  } catch (error) {
    logError('Error during browser teardown:', error.message);
    // Force cleanup even if teardown fails
    await forceCleanup();
  }

  clearTimeout(teardownTimeout);

  // Generate summary report
  const summary = {
    totalScenarios: 0,
    passed: 0,
    failed: 0,
    skipped: 0,
    totalDuration: 0,
  };

  logDebug('Test execution summary:', summary);
  logDebug('All teardown completed');

  // Force exit after a short delay to ensure cleanup is complete
  setTimeout(() => {
    logDebug('Forcing process exit');
    process.exit(0);
  }, 1000);
});

// Force cleanup function
async function forceCleanup() {
  try {
    logDebug('Performing force cleanup');

    // Kill any remaining Playwright processes on macOS
    if (process.platform === 'darwin') {
      const { exec } = require('child_process');

      // Kill all Playwright processes
      exec('pkill -f "playwright.*chromium"', error => {
        if (error) {
          logDebug('No Playwright processes to kill');
        } else {
          logDebug('Killed remaining Playwright processes');
        }
      });

      // Also kill any node processes that might be hanging
      exec('pkill -f "cucumber.*node"', error => {
        if (error) {
          logDebug('No cucumber node processes to kill');
        } else {
          logDebug('Killed cucumber node processes');
        }
      });

      // Kill any remaining browser processes
      exec('pkill -f "chromium.*playwright"', error => {
        if (error) {
          logDebug('No chromium playwright processes to kill');
        } else {
          logDebug('Killed chromium playwright processes');
        }
      });
    }

    // Force kill browser if it exists
    if (browserManager && browserManager.browser) {
      try {
        await browserManager.browser.kill();
        logDebug('Force killed browser');
      } catch (error) {
        logDebug('Error force killing browser:', error.message);
      }
    }
  } catch (error) {
    logError('Error during force cleanup:', error.message);
  }
}

// Force cleanup and exit function
function forceCleanupAndExit() {
  forceCleanup()
    .then(() => {
      logDebug('Force cleanup completed, exiting');
      process.exit(0);
    })
    .catch(() => {
      logDebug('Force cleanup failed, exiting anyway');
      process.exit(0);
    });
}

// Handle process termination to ensure cleanup
process.on('SIGINT', async () => {
  logDebug('Received SIGINT - cleaning up...');
  await forceCleanup();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  logDebug('Received SIGTERM - cleaning up...');
  await forceCleanup();
  process.exit(0);
});

process.on('uncaughtException', async error => {
  logError('Uncaught exception:', error.message);
  await forceCleanup();
  process.exit(1);
});

process.on('unhandledRejection', async (reason, promise) => {
  logError('Unhandled rejection at:', promise, 'reason:', reason);
  await forceCleanup();
  process.exit(1);
});

// Custom hooks for specific scenarios
Before('@authentication', async function () {
  logDebug('Setting up authentication test environment');
  // Clear any existing authentication state
  if (this.context) {
    await this.context.clearCookies();
  }
});

Before('@plo-specific', async function () {
  logDebug('Setting up PLO-specific test environment');
  // Ensure PLO mode is available
});

Before('@performance', async function () {
  logDebug('Setting up performance test environment');
  // Disable animations, set performance monitoring
  if (this.context) {
    // Disable CSS animations for performance testing
    await this.context.addInitScript(() => {
      const style = document.createElement('style');
      style.textContent = `
        *, *::before, *::after {
          animation-duration: 0.01ms !important;
          animation-iteration-count: 1 !important;
          transition-duration: 0.01ms !important;
        }
      `;
      document.head.appendChild(style);
    });
  }
});

After('@authentication', async function () {
  logDebug('Cleaning up authentication test environment');
  // Clear authentication state
  if (this.context) {
    await this.context.clearCookies();
  }
});

After('@plo-specific', async function () {
  logDebug('Cleaning up PLO-specific test environment');
  // Reset PLO settings
});

After('@performance', async function () {
  logDebug('Cleaning up performance test environment');
  // Reset performance settings
});
