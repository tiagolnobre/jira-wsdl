# jira-wsdl
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Ftiagolnobre%2Fjira-wsdl.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Ftiagolnobre%2Fjira-wsdl?ref=badge_shield)


 ruby interaction with JIRA

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
   
   or (jql query as a string)
   
     tickets = jira.jqlquery(string)
   
   or (jql query as a hash parameters)
   
     tickets = jira.query_by_hash(query)
  
  
  
  Close session:

    jira.logout token 
    


___________________________________________________________________________________________

New features?  Tell us what you need that we will see what we can do. :)




## License
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Ftiagolnobre%2Fjira-wsdl.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Ftiagolnobre%2Fjira-wsdl?ref=badge_large)