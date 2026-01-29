// Import logger utility
const { logDebug } = require('./src/utils/logger');

// Jest teardown file to clean up after all tests
module.exports = async () => {
  // Clean up any remaining timers
  if (typeof jest !== 'undefined') {
    jest.clearAllTimers();

    // Clean up any remaining mocks
    jest.clearAllMocks();

    // Reset all modules to clear any cached state
    jest.resetModules();
  }

  // Clean up localStorage and sessionStorage
  if (global.localStorage) {
    global.localStorage.clear();
  }
  if (global.sessionStorage) {
    global.sessionStorage.clear();
  }

  // Clean up any remaining event listeners
  if (global.removeEventListener) {
    // Remove any global event listeners that might have been added
    global.removeEventListener('beforeunload', () => {});
    global.removeEventListener('unload', () => {});
  }

  // Clean up any remaining promises
  await new Promise(resolve => setTimeout(resolve, 0));

  logDebug('🧹 Test teardown completed');
};
