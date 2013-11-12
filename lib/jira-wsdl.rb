require 'savon'
require 'timeout'
#Class to handle Jira soap api
class JiraWsdl

  attr_reader :next_version, :actual_version, :token, :client, :all_versions #, :operations_available

  def initialize(jira_host, username, password)

    @username = username
    @password = password
    @wsdl_url = "https://#{jira_host}/rpc/soap/jirasoapservice-v2?wsdl"
    @jira_host = jira_host

    #create Savon.client
    @client = Savon.client(wsdl: @wsdl_url, log: false)

    #operation list permited by JIRA soap
    #@operations_available = @client.operations.sort

    #create login token
    @token ||= self.get_token
  end


  class Response
    attr_reader :success, :tickets, :optional

    def initialize(success, tickets, error_msg, optional=nil)
      @success = success
      @tickets = tickets
      @error_msg = error_msg
      @optional = optional
    end
  end

  #get token login
  #
  # @return [String] token
  def get_token
    response = self.login @username, @password
    response.to_hash[:login_response][:login_return] if response
  rescue Savon::SOAPFault => error
    puts error.to_hash[:fault][:faultstring]
    return false
  end

  #login to jira
  #
  # @param [Stirng] username
  # @param [String] password
  # @return [Savon::Response] response
  def login(username, password)
    response=nil
    Timeout::timeout(60) {
      response = @client.call(:login, message: {:username => username, :password => password})
    }
    response if response.success? if response
  rescue Savon::SOAPFault => error
    puts error.to_hash[:fault][:faultstring]
    return false
  end

  #logout of jira
  #
  # @param [String] token
  # @return [Boolean]
  def logout(token = @token)
    response=nil
    Timeout::timeout(60) {
      response = @client.call(:logout, message: {:token => token})
    }
    response.to_hash[:logout_response][:logout_return]
  end


  #get the actual version and the next version of a project
  # @param [String] project_name
  def get_version(project_name)
    tries ||= 5
    all_versions = []
    version_name =[]
    hash_versions = {}

    #get all versions xml
    response = @client.call(:get_versions, message: {:token => @token, :key => project_name.upcase})
    response.to_hash[:multi_ref].each do |version|

      begin
        #get version with release date greater than todays date
        version_name << version[:name] if Time.now.strftime("%F") <= Time.parse(version[:release_date]).strftime("%F")
        #case the below option is without any date will get all version with release data 
        # and the start will be the nearest one to the today date
        hash_versions.store(version[:name], version[:release_date])
      rescue NoMethodError, TypeError
        puts 'There were versions without release version.'
      end
      all_versions << version[:name]
    end

    @all_versions = all_versions.sort_by { |a| a.split('.').map &:to_i }
    @actual_version = version_name.empty? ? @all_versions[@all_versions.index(hash_versions.sort_by { |k, v| v }.last[0]) + 1] : version_name.sort_by { |a| a.split('.').map &:to_i }.first

    # in case there is no next_version put the last two version of the array of versions
    if @actual_version.nil?
      @next_version = @all_versions[-1]
      @actual_version = @all_versions[-2]
    else
      @next_version = @all_versions[@all_versions.index(@actual_version) + 1]
      # if there is no next version put the last two versions
      if @next_version.nil?
        @next_version = @all_versions[-1]
        @actual_version = @all_versions[-2]
      end
    end

    #all_versions = []
    raise Exceptions::CouldNotGetNextVersion, 'Problem getting Next Version number' if @next_version.nil?
    raise Exceptions::CouldNotGetActualVersion, 'Problem getting Actual Version number' if @actual_version.nil?
    return true
  rescue Savon::SOAPFault => error
    tries = tries -= 1
    unless (tries).zero?
      sleep 5
      logout
      @token = self.get_token
      puts "Jira connection failed. Trying to connect again. (Num tries: #{tries})"
      retry
    else
      return false
    end
  end

  #get all version id's of the project
  #
  # @param [Has] response
  # @return [Array] @version_id_array
  def get_all_version_ids(response)
    version_id_array = []
    response.to_hash[:multi_ref].each do |version|
      version_id_array << version[:sequence].to_i
    end
    return version_id_array
  rescue Savon::SOAPFault => error
    puts error.to_hash[:fault][:faultstring]
    return false
  end

  #Should be used the query_by_hash or jqlquery function instead of this one
  #
  #get jira tickets from a project
  #
  # @param status - verify,in progress, open, reopened, closed
  # @param project key or name
  # @param version project version
  # @param maxnumresults max number of results
  # @return nil, jira_tickets, (false, error_msg)
  def get_jira_tickets(status, project, version, maxnumresults=300)
    puts 'Should be used the query_by_hash or jqlquery function instead of this one'
    response = @client.call(:get_issues_from_jql_search, message: {:token => @token,
                                                                   :jqlSearch => 'status in (' + status + ') and project=' + project + ' and fixVersion in (' + version + ')',
                                                                   :maxNumResults => maxnumresults})
    #if response is empty
    if response.to_hash.has_key? :multi_ref
      jira_tickets = []
      response.to_hash[:multi_ref].each do |tickets|
        jira_tickets << [tickets[:key], tickets[:summary], 'http://'+@jira_host+'/browse/'+tickets[:key].to_s] if !tickets[:key].nil? and !tickets[:summary].nil?
      end
    end
    return JiraWsdl::Response.new(true, jira_tickets, nil)
  rescue Savon::SOAPFault => error
    return JiraWsdl::Response.new(false, nil, error.to_hash[:fault][:faultstring].match(/.*?:(.*)/)[1])
  rescue StandardError => error
    puts error
    return JiraWsdl::Response.new(false, nil, error)
  end


  #get jira tickets by hash
  #
  # @param hash - verify,in progress, open, reopened, closed
  # @param maxnumresults max number of results
  # @return nil, jira_tickets, (false, error_msg)
  def query_by_hash(hash, maxnumresults=300)
    begin
      jql_string = hash.map { |k, v| "#{k} in (#{v})" }.join(' AND ')
      puts "Query: #{jql_string}"
      response = @client.call(:get_issues_from_jql_search, message: {:token => @token,
                                                                     :jqlSearch => "#{jql_string}",
                                                                     :maxNumResults => maxnumresults})
      jira_tickets = []
      if response.to_hash.has_key? :multi_ref
        response.to_hash[:multi_ref].each do |tickets|
          if !tickets[:key].nil? and !tickets[:summary].nil?
            jira_tickets << [tickets[:key], tickets[:summary], 'http://'+@jira_host+'/browse/'+tickets[:key].to_s]
          end
        end
      end
      return JiraWsdl::Response.new(true, jira_tickets, nil)
    rescue Savon::SOAPFault => error
      return JiraWsdl::Response.new(false, nil, error.to_hash[:fault][:faultstring].match(/.*?:(.*)/)[1])
    end
  end

  #get jira tickets from a project
  #
  # @param jql_string - jql string
  # @param maxnumresults max number of results
  # @return nil, jira_tickets, (false, error_msg)
  def jqlquery(jql_string, maxnumresults=300)

    puts "Query: #{jql_string}"
    response = @client.call(:get_issues_from_jql_search, message: {:token => @token,
                                                                   :jqlSearch => "#{jql_string}",
                                                                   :maxNumResults => maxnumresults})
    #if response is empty
    if response.to_hash[:multi_ref].nil?
      nil
    else
      jira_tickets = []
      response.to_hash[:multi_ref].each do |tickets|
        if !tickets[:key].nil? and !tickets[:summary].nil?
          jira_tickets << [tickets[:key], tickets[:summary], 'http://'+@jira_host+'/browse/'+tickets[:key].to_s]
        end
      end
      #return true, jira_tickets
      return JiraWsdl::Response.new(true, jira_tickets, nil)
    end
  rescue Savon::SOAPFault => error
    #return false, error.to_hash[:fault][:faultstring].match(/.*?:(.*)/)[1]
    return JiraWsdl::Response.new(false, nil, error.to_hash[:fault][:faultstring].match(/.*?:(.*)/)[1])
  rescue StandardError => error
    puts error
    return JiraWsdl::Response.new(false, nil, error)
  end

end

module Exceptions
  #exceptions
  class CouldNotGetNextVersion < StandardError;
  end
  class CouldNotGetActualVersion < StandardError;
  end
end