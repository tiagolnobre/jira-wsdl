# jira-wsdl

gem for internal use of qa team projects

## Installation

Add this line to your application's Gemfile:

    gem 'jira-wsdl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jira-wsdl

## Usage



    jira= JiraWsdl.new('jira.atlassian.com', 'tiago.l.nobre+test', '123qwe')

  Get login token:
  
    jira.token

  Get version of the project
  
    jira.get_version project_key
 
  Actual version: 
  
    jira.actual_version

  Next version: 
  
    jira.next_version

  All version:
  
    jira.all_versions

  Get tickets:
   
    tickets = jira.get_jira_tickets(status, project, version)
    
  Close session
    jira.logout token 
    
