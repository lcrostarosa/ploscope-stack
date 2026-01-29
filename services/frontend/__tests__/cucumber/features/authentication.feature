@authentication
Feature: Authentication
  As a user
  I want to authenticate with the application
  So that I can access protected features

  Background:
    Given the application is running
    And I am on the home page

  Scenario: Dismiss the Cookie Consent Modal
    Given I validate the cookie consent modal is visible
    When I click the "Accept All" button
    Then the cookie consent modal should be dismissed

  Scenario: User can open the authentication modal
    When I click the "Sign In" button
    Then I should see the authentication modal
    And the modal should contain login options

  Scenario: User can close the authentication modal
    Given the authentication modal is open
    When I click the close button
    Then the authentication modal should be closed

  Scenario: User can register with a random email and password
    # Generate a random email and password and save them for later steps
    Given I generate a random email and password and save them as "testEmail" and "testPassword"
    When I click the "Sign Up" button
    Then I should see the authentication modal
    When I fill in the email field with "<testEmail>"
    And I fill in the password field with "<testPassword>"
    And I click the "Register" button
    Then I should be registered and logged in
    And I should see my user profile or dashboard

    # The credentials <testEmail> and <testPassword> should be available for use in subsequent scenarios or steps

  Scenario: User can login with the registered credentials
    Given I am on the home page
    When I click the "Sign In" button
    Then I should see the authentication modal
    When I fill in the email field with "<testEmail>"
    And I fill in the password field with "<testPassword>"
    And I click the "Sign In" button
    Then I should be logged in
    And I should see my user profile or dashboard