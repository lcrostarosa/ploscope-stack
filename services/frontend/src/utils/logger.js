// CommonJS/JS shim for tests that import logger.js
const noop = () => {};

module.exports = {
  logDebug: noop,
  logInfo: noop,
  logWarn: noop,
  logError: noop,
};
