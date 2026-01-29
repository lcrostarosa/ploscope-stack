---
name: 🧪 Test Issue
about: Report test failures, flaky tests, or suggest test improvements
title: '[TEST] '
labels: 'testing, needs-triage'
assignees: ''
---

# 🧪 Test Issue

## 📋 **Test Issue Type**

<!-- Mark the relevant option with an "x" -->
- [ ] ❌ Test Failure - Existing test is failing
- [ ] 🔄 Flaky Test - Test passes/fails inconsistently
- [ ] 📈 Test Coverage - Missing test coverage
- [ ] ⚡ Test Performance - Tests are running slowly
- [ ] 🔧 Test Infrastructure - Testing framework issues
- [ ] ✨ Test Enhancement - Improve existing tests

---

## 🎯 **Test Details**

### Test Location
- **Test File**: `path/to/test/file.test.js` or `path/to/test/file.py`
- **Test Name**: `describe/test block name`
- **Test Type**: [Unit/Integration/E2E]
- **Component**: [Frontend/Backend]

### Current Test Status
- [ ] Test currently failing
- [ ] Test sometimes fails (flaky)
- [ ] Test missing entirely
- [ ] Test exists but insufficient
- [ ] Test performance issue

---

## 🐛 **Failure Information** (if applicable)

### Error Message
```
Paste the error message here
```

### Stack Trace
```
Paste the full stack trace here
```

### Failure Frequency
- [ ] Fails every time
- [ ] Fails intermittently (~25% of runs)
- [ ] Fails occasionally (~10% of runs)
- [ ] Fails rarely (<5% of runs)

---

## 🔍 **Reproduction Information**

### Steps to Reproduce
1. Run test with: `command here`
2. Observe failure at: `specific step`
3. Error occurs: `description`

### Environment
- **OS**: [macOS/Windows/Linux]
- **Node.js Version**: [if frontend test]
- **Python Version**: [if backend test]
- **Test Runner**: [Jest/pytest/other]
- **CI/Local**: [Where does it fail?]

---

## 📊 **Test Coverage Analysis**

### Current Coverage
- **File/Function**: `path/to/file.js:functionName`
- **Coverage %**: [Current coverage percentage]
- **Lines Covered**: [X/Y lines covered]

### Missing Coverage Areas
- [ ] Edge cases not tested
- [ ] Error conditions not covered
- [ ] Integration paths missing
- [ ] Performance scenarios
- [ ] Security scenarios

---

## 💡 **Proposed Solution**

### Test Improvement Strategy
<!-- Describe how you think the test should be improved -->

### Test Cases to Add
1. Test case 1: `description`
2. Test case 2: `description`
3. Test case 3: `description`

### Mock/Fixture Requirements
<!-- Any new mocks or test fixtures needed -->

---

## 🔧 **Technical Context**

### Related Code Changes
<!-- Any recent code changes that might have affected tests -->
- [ ] Recent feature additions
- [ ] Recent refactoring
- [ ] Dependency updates
- [ ] Configuration changes

### Test Dependencies
<!-- List any external dependencies the test relies on -->
- Database setup
- External services
- File system state
- Environment variables

---

## 🎯 **Testing Standards Compliance**

### PLOSolver Test Requirements
- [ ] Test follows project testing patterns
- [ ] Test is isolated and independent
- [ ] Test has clear assertions
- [ ] Test includes error scenarios
- [ ] Test is performant (<5 seconds)

### Quality Checklist
- [ ] Test name clearly describes what is being tested
- [ ] Test setup and teardown are proper
- [ ] Test uses appropriate mocking
- [ ] Test covers both happy path and edge cases
- [ ] Test mastertains 100% pass rate goal

---

## 📈 **Impact Assessment**

### Test Suite Impact
- [ ] Affects overall test reliability
- [ ] Impacts CI/CD pipeline
- [ ] Blocks development workflow
- [ ] Reduces confidence in deployments

### Priority Level
- [ ] 🔴 Critical - Blocks releases
- [ ] 🟠 High - Affects team productivity
- [ ] 🟡 Medium - Should be fixed soon
- [ ] 🟢 Low - Nice to have improvement

---

## 🔗 **Related Information**

### Related Issues
- Related to #(issue)
- Caused by #(issue)
- Blocks #(issue)

### Test Documentation
<!-- Links to relevant test documentation or standards -->

---

## ✅ **Acceptance Criteria**

<!-- Define when this test issue is considered resolved -->
- [ ] Test passes consistently (100% reliability)
- [ ] Test covers all required scenarios
- [ ] Test performance is acceptable
- [ ] Test follows project standards
- [ ] Test is properly documented

---

**Checklist before submitting:**
- [ ] I have run the test locally
- [ ] I have checked for existing test issues
- [ ] I have provided complete error information
- [ ] I have identified the scope of the problem
- [ ] I have considered the impact on the test suite 