const { Given, When, Then } = require('@cucumber/cucumber');
const { expect } = require('chai');

function resolveValue(world, value) {
  if (typeof value === 'string' && value.startsWith('<') && value.endsWith('>')) {
    const key = value.slice(1, -1);
    if (world.getTestData) {
      const stored = world.getTestData(key);
      return stored ?? value;
    }
  }
  return value;
}

function generateRandomEmail() {
  const ts = Date.now();
  const rand = Math.random().toString(36).slice(2, 8);
  return `test_${rand}_${ts}@example.com`;
}

function generateStrongPassword() {
  const base = Math.random().toString(36).slice(2) + Math.random().toString(36).toUpperCase().slice(2);
  return `Aa1!${base.slice(0, 12)}`;
}

Given('I generate a random email and password and save them as {string} and {string}', function (emailKey, passwordKey) {
  const email = generateRandomEmail();
  const password = generateStrongPassword();
  if (this.setTestData) {
    this.setTestData(emailKey, email);
    this.setTestData(passwordKey, password);
  } else {
    this.testData = this.testData || {};
    this.testData[emailKey] = email;
    this.testData[passwordKey] = password;
  }
});

When('I fill in the email field with {string}', async function (value) {
  const email = resolveValue(this, value);
  const selectors = ['#email', 'input[name="email"]', 'input[type="email"]', 'input[id*="email"]'];
  for (const selector of selectors) {
    const el = await this.page.$(selector);
    if (el) {
      await this.page.fill(selector, String(email));
      return;
    }
  }
  throw new Error('Email input not found');
});

When('I fill in the password field with {string}', async function (value) {
  const password = resolveValue(this, value);
  const pwdSelectors = ['#password', 'input[name="password"]', 'input[type="password"]', 'input[id*="password"]'];
  let filled = false;
  for (const selector of pwdSelectors) {
    const el = await this.page.$(selector);
    if (el) {
      await this.page.fill(selector, String(password));
      filled = true;
      break;
    }
  }
  if (!filled) throw new Error('Password input not found');

  // If confirm password exists, mirror it
  const confirmSelectors = ['#confirmPassword', 'input[name="confirmPassword"]', 'input[id*="confirm"]'];
  for (const selector of confirmSelectors) {
    const el = await this.page.$(selector);
    if (el) {
      await this.page.fill(selector, String(password));
      break;
    }
  }

  // Accept terms if present (for registration)
  const terms = await this.page.$('#accept_terms');
  if (terms) {
    const checked = await this.page.isChecked('#accept_terms');
    if (!checked) {
      await this.page.click('#accept_terms');
    }
  }
});

Then('I should be registered and logged in', async function () {
  // Consider logged in if access token exists
  const hasToken = await this.page.evaluate(() => !!localStorage.getItem('access_token'));
  expect(hasToken).to.be.true;
});

Then('I should be logged in', async function () {
  const hasToken = await this.page.evaluate(() => !!localStorage.getItem('access_token'));
  expect(hasToken).to.be.true;
});

Then('I should see my user profile or dashboard', async function () {
  const url = this.page.url();
  const token = await this.page.evaluate(() => localStorage.getItem('access_token'));
  const onDashboard = /\/app|dashboard|profile/.test(url);
  expect(!!token || onDashboard).to.be.true;
});


