module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:import/recommended',
    'plugin:import/typescript',
  ],
  parser: '@typescript-eslint/parser',
  plugins: ['react', 'react-hooks', 'import'],
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  env: {
    browser: true,
    es6: true,
    node: true,
    jest: true,
  },
  settings: {
    react: {
      version: 'detect',
    },
    'import/resolver': {
      typescript: {
        alwaysTryTypes: true,
        project: './tsconfig.json',
      },
      node: {
        extensions: ['.js', '.jsx', '.ts', '.tsx'],
      },
    },
    'import/parsers': {
      '@typescript-eslint/parser': ['.ts', '.tsx'],
    },
  },
  rules: {
    // React security rules
    'react/no-danger': 'error',
    'react/no-danger-with-children': 'error',
    'react/jsx-no-script-url': 'error',
    'react/jsx-no-target-blank': 'error',
    'react/prop-types': 'off', // We use TypeScript
    'react/react-in-jsx-scope': 'off', // Not needed in React 17+
    'react/display-name': 'off',

    // React Hooks rules
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',

    // General best practices
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-new-func': 'error',
    'no-script-url': 'error',
    'no-console': 'warn',

    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
        ignoreRestSiblings: true,
      },
    ],
    'no-debugger': 'error',
    'no-alert': 'warn',
    'prefer-const': 'warn',
    'no-var': 'error',

    // Security and quality rules - these should be errors
    'no-prototype-builtins': 'error',
    'no-unsafe-finally': 'error',
    'no-cond-assign': 'error',
    'no-func-assign': 'error',
    'no-redeclare': 'error',
    'no-empty': 'error',
    'no-useless-escape': 'error',
    'no-extra-semi': 'error',
    'no-extra-boolean-cast': 'error',
    'no-regex-spaces': 'error',
    'no-sparse-arrays': 'error',
    'no-inner-declarations': 'error',
    'no-case-declarations': 'error',
    'no-fallthrough': 'error',
    'no-undef': 'error',

    // Import organization and sorting rules
    'import/order': [
      'error',
      {
        groups: [
          'builtin', // Node built-in modules
          'external', // npm packages
          'internal', // Internal modules (using path mapping)
          'parent', // Parent directory imports
          'sibling', // Same directory imports
          'index', // Index file imports
        ],
        'newlines-between': 'always',
        alphabetize: {
          order: 'asc',
          caseInsensitive: true,
        },
        pathGroups: [
          {
            pattern: 'react',
            group: 'external',
            position: 'before',
          },
          {
            pattern: 'react-*',
            group: 'external',
            position: 'before',
          },
          {
            pattern: '@/**',
            group: 'internal',
            position: 'before',
          },
        ],
        pathGroupsExcludedImportTypes: ['react'],
      },
    ],
    'import/no-unresolved': 'error',
    'import/no-duplicates': 'error',
    'import/no-unused-modules': 'warn',
    'import/first': 'error',
    'import/newline-after-import': 'error',
    'import/no-absolute-path': 'error',
    'import/no-self-import': 'error',
    'import/no-cycle': 'warn',
  },
  overrides: [
    {
      // Apply different rules to TypeScript files
      files: ['**/*.ts', '**/*.tsx'],
      rules: {
        'no-unused-vars': 'off', // Disable for TypeScript files to avoid false positives with function signatures
      },
    },
    {
      // Apply different rules to test files
      files: [
        '**/__tests__/**/*',
        '**/*.test.*',
        '**/*.spec.*',
        'setupTests.js',
        'teardownTests.js',
      ],
      env: {
        jest: true,
      },
      rules: {
        'no-console': 'off',
        'no-undef': 'off', // Jest globals are available
        'import/no-unresolved': 'off', // Disable for test files due to resolver issues
      },
    },
  ],
};
