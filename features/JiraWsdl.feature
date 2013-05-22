@jirawsdl
Feature: Test_JiraWsdl

  Scenario: Test_Jira_instantiation
    Given I create instantiation of Jira
    Then I have a login token to access all the functions
    Then I logout from Jira

  Scenario: Test_Jira_get_version_function
    Given I create instantiation of Jira
    Then I can get the versions of the project with the key "PATI"
    Then I logout from Jira

  Scenario: Test_Jira_query_project_function
    Given I create instantiation of Jira
    Then I can get the tickets for the "PATI" project, next version with status "open"
    Then I logout from Jira

  Scenario: Test_Jira_get_all_version_of_a_project
    Given I create instantiation of Jira
    Then I can get all versions for the "PATI" project
    Then I logout from Jira

  Scenario: List_Jira_Operations
    Given I create instantiation of Jira
    Then I get a list of permitted operations
    Then I logout from Jira

  Scenario: List_Jira_Operations
    Given I create instantiation of Jira
    Then I get a list of permitted operations
    Then I logout from Jira

