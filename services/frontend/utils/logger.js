// Simple logger utility for webpack configuration
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m',
};

const logError = message => {
  console.error(`${colors.red}❌ ${message}${colors.reset}`);
};

const logWarn = message => {
  console.warn(`${colors.yellow}⚠️  ${message}${colors.reset}`);
};

const logDebug = message => {
  if (process.env.NODE_ENV === 'development') {
    console.log(`${colors.blue}🔍 ${message}${colors.reset}`);
  }
};

const logInfo = message => {
  console.log(`${colors.green}ℹ️  ${message}${colors.reset}`);
};

const logSuccess = message => {
  console.log(`${colors.green}✅ ${message}${colors.reset}`);
};

module.exports = {
  logError,
  logWarn,
  logDebug,
  logInfo,
  logSuccess,
};
