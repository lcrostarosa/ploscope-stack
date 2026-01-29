module.exports = {
  // Lint and fix JavaScript/TypeScript files
  '*.{js,jsx,ts,tsx}': ['eslint --fix', 'npx prettier --write'],

  // Format other files
  '*.{json,md,yml,yaml}': ['npx prettier --write'],

  // Run type checking on TypeScript files (non-failing)
  '*.{ts,tsx}': [() => 'npm run typecheck:ci'],
};
