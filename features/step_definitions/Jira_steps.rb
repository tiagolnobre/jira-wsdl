include Test::Unit::Assertions
require File.dirname(__FILE__) + '/../../lib/jira-wsdl'


Given /^I create instantiation of Jira$/ do
  puts 'Creating Jira Object'
  @jira= JiraWsdl.new('jira.mendeley.com', 'tiago.nobre', 'superbock')
end

Then /^I have a login token to access all the functions$/ do
  puts @jira.token
  assert(!@jira.token.nil?, 'Token is empty')
end

Then(/^I can get the versions of the project with the key "([^"]*)"$/) do |key|
  result, error = @jira.get_version key
  assert_equal(true, result, error)
  assert(!@jira.actual_version.nil?, 'Can\'t get actual version')
  puts "Actual version: #{@jira.actual_version}"
  assert(!@jira.actual_version.nil?, 'Can\'t get next version')
  puts "Next version: #{@jira.next_version}"

end

Then(/^I can get the tickets for the "([^"]*)" project, next version with status "([^"]*)"$/) do |project, status|
  @jira.get_version project
  assert(!@jira.next_version.nil?, 'Can\'t get next version')
  puts "Next version: #{@jira.next_version}"

  version = @jira.next_version
  tickets = @jira.get_jira_tickets(status, project, version)

  puts tickets
  assert(!tickets.empty?, 'Tickets are empty')
end

Then(/^I can get all versions for the "([^"]*)" project$/) do |project|
  @jira.get_version project
  assert(!@jira.all_versions.empty?, 'Can\'t get next version')
  puts "All version: #{@jira.all_versions}"
end

Then(/^I check that the project "([^"]*)" existence is "([^"]*)"$/) do |project, boolean|
  result, error = @jira.check_project project
  assert_equal(result.to_s, boolean, error)
end