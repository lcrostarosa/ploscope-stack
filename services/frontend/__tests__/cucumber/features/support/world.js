const { setWorldConstructor } = require('@cucumber/cucumber');
const { chromium, firefox, webkit } = require('playwright');

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

// Global browser manager - this persists across all World instances
class BrowserManager {
  constructor() {
    this.browser = null;
    this.context = null;
    this.page = null;
    this.isInitialized = false;
    this.initializationPromise = null;
  }

  async initialize() {
    if (this.isInitialized) {
      return { browser: this.browser, context: this.context, page: this.page };
    }

    if (this.initializationPromise) {
      return this.initializationPromise;
    }

    this.initializationPromise = this._createBrowser();
    return this.initializationPromise;
  }

  async _createBrowser() {
    if (this.isInitialized) {
      return { browser: this.browser, context: this.context, page: this.page };
    }

    const isHeadless =
      process.argv.includes('--headless') ||
      process.env.CUCUMBER_HEADLESS === 'true';
    logDebug(`Creating Playwright browser. Headless: ${isHeadless}`);

    // Log headless mode configuration
    if (process.env.CUCUMBER_HEADLESS === 'true') {
      logDebug('Running in headless mode');
    } else if (process.env.CUCUMBER_HEADLESS === 'false') {
      logDebug('Running in non-headless mode (browser will be visible)');
    }

    // Log environment information
    if (process.env.CUCUMBER_BASE_URL) {
      logDebug(`Base URL: ${process.env.CUCUMBER_BASE_URL}`);
    }
    if (process.env.NODE_ENV) {
      logDebug(`Node environment: ${process.env.NODE_ENV}`);
    }

    try {
      const browserType = process.env.CUCUMBER_BROWSER || 'chromium';
      let browser;

      switch (browserType) {
        case 'firefox':
          browser = firefox;
          break;
        case 'webkit':
          browser = webkit;
          break;
        default:
          browser = chromium;
      }

      this.browser = await browser.launch({
        headless: isHeadless,
        slowMo: process.env.CUCUMBER_SLOW_MO
          ? parseInt(process.env.CUCUMBER_SLOW_MO)
          : 0,
        // Configuration based on headless mode
        ...(isHeadless
          ? {
              // Headless-specific options
              devtools: false,
              downloadsPath: undefined,
              handleSIGINT: false,
              handleSIGTERM: false,
              handleSIGHUP: false,
              timeout: 30000,
              protocolTimeout: 30000,
              browserWSEndpoint: undefined,
              browserURL: undefined,
              ignoreDefaultArgs: false,
              ignoreAllDefaultArgs: false,
              dumpio: false,
              env: {
                ...process.env,
                // Additional environment variables to ensure headless mode
                DISPLAY: undefined,
                WAYLAND_DISPLAY: undefined,
                XDG_SESSION_TYPE: undefined,
              },
            }
          : {
              // Non-headless options for debugging
              devtools: process.env.CUCUMBER_DEVTOOLS === 'true',
              slowMo: process.env.CUCUMBER_SLOW_MO
                ? parseInt(process.env.CUCUMBER_SLOW_MO)
                : 100,
              timeout: 60000,
              protocolTimeout: 60000,
            }),
        args: [
          '--no-sandbox',
          '--disable-dev-shm-usage',
          '--disable-web-security',
          '--allow-running-insecure-content',
          '--ignore-certificate-errors',
          ...(isHeadless
            ? [
                // Headless-specific arguments
                '--disable-gpu',
                '--disable-extensions',
                '--disable-plugins',
                '--disable-background-timer-throttling',
                '--disable-backgrounding-occluded-windows',
                '--disable-renderer-backgrounding',
                '--disable-features=TranslateUI',
                '--disable-ipc-flooding-protection',
                '--disable-hang-monitor',
                '--disable-prompt-on-repost',
                '--disable-popup-blocking',
                '--disable-default-apps',
                '--disable-component-extensions-with-background-pages',
                '--disable-component-update',
                '--no-default-browser-check',
                '--no-first-run',
                '--disable-back-forward-cache',
                '--disable-breakpad',
                '--disable-client-side-phishing-detection',
                '--disable-field-trial-config',
                '--disable-background-networking',
                '--metrics-recording-only',
                '--password-store=basic',
                '--use-mock-keychain',
                '--no-service-autorun',
                '--export-tagged-pdf',
                '--disable-search-engine-choice-screen',
                '--unsafely-disable-devtools-self-xss-warnings',
                '--edge-skip-compat-layer-relaunch',
                '--enable-automation',
                '--enable-use-zoom-for-dsf=false',
                '--enable-unsafe-swiftshader',
                '--force-color-profile=srgb',
                '--use-gl=angle',
                '--use-angle=swiftshader-webgl',
                '--start-stack-profiler',
                '--gpu-preferences=UAAAAAAAAAAgAAAEAAAAAAAAAAAAAAAAAABgAAAAAAA4AAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaAcAAAAAAABoBwAAAAAAAHgCAABOAAAAcAIAAAAAAAB4AgAAAAAAAIACAAAAAAAAiAIAAAAAAACQAgAAAAAAAJgCAAAAAAAAoAIAAAAAAACoAgAAAAAAALACAAAAAAAAuAIAAAAAAADAAgAAAAAAAMgCAAAAAAAA0AIAAAAAAADYAgAAAAAAAOACAAAAAAAA6AIAAAAAAADwAgAAAAAAAPgCAAAAAAAAAAMAAAAAAAAIAwAAAAAAABADAAAAAAAAGAMAAAAAAAAgAwAAAAAAACgDAAAAAAAAMAMAAAAAAAA4AwAAAAAAAEADAAAAAAAASAMAAAAAAABQAwAAAAAAAFgDAAAAAAAAYAMAAAAAAABoAwAAAAAAAHADAAAAAAAAeAMAAAAAAACAAwAAAAAAAIgDAAAAAAAAkAMAAAAAAACYAwAAAAAAAKADAAAAAAAAqAMAAAAAAACwAwAAAAAAALgDAAAAAAAAwAMAAAAAAADIAwAAAAAAANADAAAAAAAA2AMAAAAAAADgAwAAAAAAAOgDAAAAAAAA8AMAAAAAAAD4AwAAAAAAAAAEAAAAAAAACAQAAAAAAAAQBAAAAAAAABgEAAAAAAAAIAQAAAAAAAAoBAAAAAAAADAEAAAAAAAAOAQAAAAAAABABAAAAAAAAEgEAAAAAAAAUAQAAAAAAABYBAAAAAAAAGAEAAAAAAAAaAQAAAAAAABwBAAAAAAAAHgEAAAAAAAAgAQAAAAAAACIBAAAAAAAAJAEAAAAAAAAmAQAAAAAAACgBAAAAAAAAKgEAAAAAAAAsAQAAAAAAAC4BAAAAAAAAMAEAAAAAAAAyAQAAAAAAADQBAAAAAAAANgEAAAAAAAAEAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAEAAAAQAAAAAAAAAAAAAAACAAAAEAAAAAAAAAAAAAAAAwAAABAAAAAAAAAAAAAAAAYAAAAQAAAAAAAAAAAAAAAHAAAAEAAAAAAAAAAAAAAACAAAABAAAAAAAAAAAAAAAAkAAAAQAAAAAAAAAAAAAAALAAAAEAAAAAAAAAAAAAAADAAAABAAAAAAAAAAAAAAAA4AAAAQAAAAAAAAAAAAAAAPAAAAEAAAAAAAAAAAAAAAEAAAABAAAAAAAAAAAQAAAAAAAAAQAAAAAAAAAAEAAAABAAAAEAAAAAAAAAABAAAAAgAAABAAAAAAAAAAAQAAAAMAAAAQAAAAAAAAAAEAAAAGAAAAEAAAAAAAAAABAAAABwAAABAAAAAAAAAAAQAAAAgAAAAQAAAAAAAAAAEAAAAJAAAAEAAAAAAAAAABAAAACwAAABAAAAAAAAAAAQAAAAwAAAAQAAAAAAAAAAEAAAAOAAAAEAAAAAAAAAABAAAADwAAABAAAAAAAAAAAQAAABAAAAAQAAAAAAAAAAQAAAAAAAAAEAAAAAAAAAAEAAAAAQAAABAAAAAAAAAABAAAAAIAAAAQAAAAAAAAAAQAAAADAAAAEAAAAAAAAAAEAAAABgAAABAAAAAAAAAABAAAAAcAAAAQAAAAAAAAAAQAAAAIAAAAEAAAAAAAAAAEAAAACQAAABAAAAAAAAAABAAAAAsAAAAQAAAAAAAAAAQAAAAMAAAAEAAAAAAAAAAEAAAADgAAABAAAAAAAAAABAAAAA8AAAAQAAAAAAAAAAQAAAAQAAAAEAAAAAAAAAAHAAAAAAAAABAAAAAAAAAABwAAAAEAAAAQAAAAAAAAAAcAAAACAAAAEAAAAAAAAAAHAAAAAwAAABAAAAAAAAAABwAAAAYAAAAQAAAAAAAAAAcAAAAHAAAAEAAAAAAAAAAHAAAACAAAABAAAAAAAAAABwAAAAkAAAAQAAAAAAAAAAcAAAALAAAAEAAAAAAAAAAHAAAADAAAABAAAAAAAAAABwAAAA4AAAAQAAAAAAAAAAcAAAAPAAAAEAAAAAAAAAAHAAAAEAAAABAAAAAAAAAACAAAAAAAAAAQAAAAAAAAAAgAAAABAAAAEAAAAAAAAAAIAAAAAgAAABAAAAAAAAAACAAAAAMAAAAQAAAAAAAAAAgAAAAGAAAAEAAAAAAAAAAIAAAABwAAABAAAAAAAAAACAAAAAgAAAAQAAAAAAAAAAgAAAAJAAAAEAAAAAAAAAAIAAAACwAAABAAAAAAAAAACAAAAAwAAAAQAAAAAAAAAAgAAAAOAAAAEAAAAAAAAAAIAAAADwAAABAAAAAAAAAACAAAABAAAAAQAAAAAAAAAAoAAAAAAAAAEAAAAAAAAAAKAAAAAQAAABAAAAAAAAAACgAAAAIAAAAQAAAAAAAAAAoAAAADAAAAEAAAAAAAAAAKAAAABgAAABAAAAAAAAAACgAAAAcAAAAQAAAAAAAAAAoAAAAIAAAAEAAAAAAAAAAKAAAACQAAABAAAAAAAAAACgAAAAsAAAAQAAAAAAAAAAoAAAAMAAAAEAAAAAAAAAAKAAAADgAAABAAAAAAAAAACgAAAA8AAAAQAAAAAAAAAAoAAAAQAAAACAAAAAAAAAAIAAAAAAAAAA==',
                '--lang=en-US',
                '--num-raster-threads=4',
                '--enable-zero-copy',
                '--enable-gpu-memory-buffer-compositor-resources',
                '--enable-main-frame-before-activation',
                '--renderer-client-id=1',
                '--time-ticks-at-unix-epoch=-1754006548988374',
                '--launch-time-ticks=507828541055',
                '--shared-files',
                '--metrics-shmem-handle=1752395122,r,15181582126503819488,11753049785692952355,2097152',
                '--field-trial-handle=1718379636,r,9593010321422035300,11270578987100227439,262144',
                '--disable-features=AcceptCHFrame,AutoDeElevate,AutoExpandDetailsElement,AvoidUnnecessaryBeforeUnloadCheckSync,CertificateTransparencyComponentUpdater,DestroyProfileOnBrowserClose,DialMediaRouteProvider,ExtensionManifestV2Disabled,GlobalMediaControls,HttpsUpgrades,ImprovedCookieControls,LazyFrameLoading,LensOverlay,MediaRouter,PaintHolding,ThirdPartyStoragePartitioning,Translate,AutoDeElevate',
                '--variations-seed-version',
                // Container-specific arguments for CI environment
                '--disable-dev-shm-usage',
                '--disable-setuid-sandbox',
                '--no-sandbox',
                '--single-process',
                '--disable-zygote',
                '--disable-gpu-sandbox',
                '--disable-software-rasterizer',
                '--disable-background-networking',
                '--disable-default-apps',
                '--disable-extensions',
                '--disable-sync',
                '--disable-translate',
                '--hide-scrollbars',
                '--mute-audio',
                '--no-first-run',
                '--safebrowsing-disable-auto-update',
                '--ignore-certificate-errors',
                '--ignore-ssl-errors',
                '--ignore-certificate-errors-spki-list',
                '--disable-web-security',
                '--allow-running-insecure-content',
                '--disable-features=VizDisplayCompositor',
              ]
            : [
                // Non-headless arguments for debugging
                '--disable-background-timer-throttling',
                '--disable-backgrounding-occluded-windows',
                '--disable-renderer-backgrounding',
                '--disable-features=TranslateUI',
                '--disable-ipc-flooding-protection',
                '--disable-hang-monitor',
                '--disable-prompt-on-repost',
                '--disable-popup-blocking',
                '--no-default-browser-check',
                '--no-first-run',
                '--disable-back-forward-cache',
                '--disable-breakpad',
                '--disable-client-side-phishing-detection',
                '--disable-field-trial-config',
                '--disable-background-networking',
                '--password-store=basic',
                '--use-mock-keychain',
                '--no-service-autorun',
                '--disable-search-engine-choice-screen',
                '--unsafely-disable-devtools-self-xss-warnings',
                '--edge-skip-compat-layer-relaunch',
                '--enable-automation',
                '--lang=en-US',
              ]),
        ],
      });

      this.context = await this.browser.newContext({
        viewport: { width: 1920, height: 1080 },
        userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        // Configuration based on headless mode
        ...(isHeadless
          ? {
              // Headless-specific settings
              hasTouch: false,
              isMobile: false,
              deviceScaleFactor: 1,
              colorScheme: 'light',
              reducedMotion: 'reduce',
              forcedColors: 'none',
            }
          : {
              // Non-headless settings for debugging
              hasTouch: false,
              isMobile: false,
              deviceScaleFactor: 1,
              colorScheme: 'light',
              reducedMotion: 'no-preference',
              forcedColors: 'none',
              // Enable more debugging features for non-headless mode
              bypassCSP: true,
              ignoreHTTPSErrors: true,
            }),
      });

      this.page = await this.context.newPage();

      this.page.setDefaultTimeout(30000);
      this.page.setDefaultNavigationTimeout(30000);

      this.isInitialized = true;
      logDebug('Playwright browser created successfully');

      return { browser: this.browser, context: this.context, page: this.page };
    } catch (error) {
      logError('Failed to create Playwright browser:', error.message);
      this.initializationPromise = null;
      throw error;
    }
  }

  async cleanup() {
    if (!this.isInitialized) {
      return;
    }

    logDebug('Cleaning up browser resources');

    try {
      // Close page with shorter timeout
      if (this.page) {
        try {
          await Promise.race([
            this.page.close(),
            new Promise((_, reject) =>
              setTimeout(() => reject(new Error('Page close timeout')), 2000)
            ),
          ]);
        } catch (error) {
          logError('Error closing page:', error.message);
        }
        this.page = null;
      }

      // Close context with shorter timeout
      if (this.context) {
        try {
          await Promise.race([
            this.context.close(),
            new Promise((_, reject) =>
              setTimeout(() => reject(new Error('Context close timeout')), 2000)
            ),
          ]);
        } catch (error) {
          logError('Error closing context:', error.message);
        }
        this.context = null;
      }

      // Close browser with shorter timeout and force kill
      if (this.browser) {
        try {
          await Promise.race([
            this.browser.close(),
            new Promise((_, reject) =>
              setTimeout(() => reject(new Error('Browser close timeout')), 3000)
            ),
          ]);
        } catch (error) {
          logError('Error closing browser:', error.message);
          // Force kill if normal close fails
          try {
            await this.browser.kill();
            logDebug('Force killed browser after close failure');
          } catch (killError) {
            logError('Error force killing browser:', killError.message);
          }
        }
        this.browser = null;
      }

      this.isInitialized = false;
      this.initializationPromise = null;

      logDebug('Browser cleanup completed');
    } catch (error) {
      logError('Error during browser cleanup:', error.message);
      // Force kill as last resort
      if (this.browser) {
        try {
          await this.browser.kill();
          logDebug('Force killed browser as last resort');
        } catch (killError) {
          logError(
            'Error force killing browser as last resort:',
            killError.message
          );
        }
      }
    }
  }

  async resetState() {
    if (!this.isInitialized || !this.context || !this.page) {
      return;
    }

    try {
      logDebug('Resetting browser state');
      await this.context.clearCookies();
      await this.page.evaluate(() => {
        localStorage.clear();
        sessionStorage.clear();
      });
      // Don't automatically navigate to about:blank - let the test control navigation
      logDebug('Browser state reset completed');
    } catch (error) {
      logError('Error resetting browser state:', error.message);
    }
  }
}

// Create a single instance of BrowserManager
const browserManager = new BrowserManager();

class CustomWorld {
  constructor() {
    this.baseUrl = process.env.CUCUMBER_BASE_URL || 'http://localhost';
    this.testData = {};
    this.screenshots = [];
    this.testStartTime = null;

    // These will be set by setupDriver
    this.browser = null;
    this.context = null;
    this.page = null;

    // Store reference to browser manager for cleanup
    this.browserManager = browserManager;
  }

  async setupDriver() {
    try {
      const { browser, context, page } = await browserManager.initialize();

      this.browser = browser;
      this.context = context;
      this.page = page;

      return browser;
    } catch (error) {
      logError('Failed to setup driver:', error.message);
      throw error;
    }
  }

  async teardownDriver() {
    // This will be called only at the very end
    await browserManager.cleanup();
  }

  async resetBrowserState() {
    await browserManager.resetState();
  }

  async waitForElement(selector, timeout = 10000) {
    return await this.page.waitForSelector(selector, { timeout });
  }

  async waitForElementVisible(selector, timeout = 10000) {
    return await this.page.waitForSelector(selector, {
      state: 'visible',
      timeout,
    });
  }

  async waitForElementClickable(selector, timeout = 10000) {
    return await this.page.waitForSelector(selector, {
      state: 'visible',
      timeout,
    });
  }

  async clickElement(selector) {
    await this.page.click(selector);
  }

  async inputText(selector, text) {
    await this.page.fill(selector, text);
  }

  async getElementText(selector) {
    return await this.page.textContent(selector);
  }

  async isElementDisplayed(selector) {
    try {
      const element = await this.page.$(selector);
      return element !== null && (await element.isVisible());
    } catch (error) {
      return false;
    }
  }

  async waitForUrl(url, timeout = 10000) {
    await this.page.waitForURL(url, { timeout });
  }

  async waitForUrlContains(text, timeout = 10000) {
    await this.page.waitForURL(`**/*${text}*`, { timeout });
  }

  async takeScreenshot(name) {
    try {
      const filename = `${name}_${Date.now()}.png`;
      const filepath = `./screenshots/${filename}`;
      await this.page.screenshot({ path: filepath, fullPage: true });
      this.screenshots.push(filepath);
      logDebug(`Screenshot saved: ${filepath}`);
      return filepath;
    } catch (error) {
      logError('Failed to take screenshot:', error.message);
      return null;
    }
  }

  async scrollToElement(selector) {
    await this.page.locator(selector).scrollIntoViewIfNeeded();
  }

  async hoverOverElement(selector) {
    await this.page.hover(selector);
  }

  async pressKey(key) {
    await this.page.keyboard.press(key);
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async clearTestData() {
    this.testData = {};
  }

  async setTestData(key, value) {
    this.testData[key] = value;
  }

  async getTestData(key) {
    return this.testData[key];
  }

  async logTestStep(step) {
    logDebug(`Executing step: ${step}`);
  }

  async waitForCondition(condition, timeout = 10000) {
    // For Playwright, we'll use a polling approach
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
      try {
        if (await condition()) {
          return true;
        }
      } catch (error) {
        // Continue polling
      }
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    throw new Error(`Condition not met within ${timeout}ms`);
  }

  async executeScript(script, ...args) {
    return await this.page.evaluate(script, ...args);
  }

  async getCurrentUrl() {
    return this.page.url();
  }

  async getPageTitle() {
    return await this.page.title();
  }

  async refreshPage() {
    await this.page.reload();
  }

  async goBack() {
    await this.page.goBack();
  }

  async goForward() {
    await this.page.goForward();
  }

  async maximizeWindow() {
    // Playwright handles viewport size through context
    await this.context.setViewportSize({ width: 1920, height: 1080 });
  }

  async setWindowSize(width, height) {
    await this.context.setViewportSize({ width, height });
  }

  async getWindowSize() {
    const viewport = this.page.viewportSize();
    return { width: viewport.width, height: viewport.height };
  }

  async acceptAlert() {
    this.page.on('dialog', dialog => dialog.accept());
  }

  async dismissAlert() {
    this.page.on('dialog', dialog => dialog.dismiss());
  }

  async getAlertText() {
    return new Promise(resolve => {
      this.page.on('dialog', dialog => {
        resolve(dialog.message());
        dialog.accept();
      });
    });
  }

  async sendKeysToAlert(text) {
    this.page.on('dialog', dialog => {
      dialog.accept(text);
    });
  }

  async switchToFrame(frameSelector) {
    const frame = await this.page.frameLocator(frameSelector);
    return frame;
  }

  async switchToDefaultContent() {
    // In Playwright, we're always in the main frame by default
    // This method is kept for compatibility
  }

  async switchToWindow(windowHandle) {
    // In Playwright, we handle multiple windows differently
    // This is a simplified implementation for compatibility
    const pages = this.context.pages();
    if (pages[windowHandle]) {
      this.page = pages[windowHandle];
    }
  }

  async getAllWindowHandles() {
    return this.context.pages();
  }

  async getCurrentWindowHandle() {
    return this.page;
  }

  async closeCurrentWindow() {
    await this.page.close();
  }

  async deleteAllCookies() {
    await this.context.clearCookies();
  }

  async addCookie(cookie) {
    await this.context.addCookies([cookie]);
  }

  async getCookies() {
    return await this.context.cookies();
  }

  async getCookie(name) {
    const cookies = await this.context.cookies();
    return cookies.find(cookie => cookie.name === name);
  }

  async deleteCookie(name) {
    const cookies = await this.context.cookies();
    const cookieToDelete = cookies.find(cookie => cookie.name === name);
    if (cookieToDelete) {
      await this.context.clearCookies([cookieToDelete]);
    }
  }

  // Playwright-specific methods for better integration
  async goto(url) {
    await this.page.goto(url);
  }

  async waitForSelector(selector, options = {}) {
    return await this.page.waitForSelector(selector, options);
  }

  async click(selector) {
    await this.page.click(selector);
  }

  async fill(selector, text) {
    await this.page.fill(selector, text);
  }

  async type(selector, text) {
    await this.page.type(selector, text);
  }

  async selectOption(selector, value) {
    await this.page.selectOption(selector, value);
  }

  async check(selector) {
    await this.page.check(selector);
  }

  async uncheck(selector) {
    await this.page.uncheck(selector);
  }

  async textContent(selector) {
    return await this.page.textContent(selector);
  }

  async innerText(selector) {
    return await this.page.innerText(selector);
  }

  async getAttribute(selector, attribute) {
    return await this.page.getAttribute(selector, attribute);
  }

  async isChecked(selector) {
    return await this.page.isChecked(selector);
  }

  async isDisabled(selector) {
    return await this.page.isDisabled(selector);
  }

  async isEnabled(selector) {
    return await this.page.isEnabled(selector);
  }

  async isHidden(selector) {
    return await this.page.isHidden(selector);
  }

  async isVisible(selector) {
    return await this.page.isVisible(selector);
  }
}

setWorldConstructor(CustomWorld);

module.exports = CustomWorld;
