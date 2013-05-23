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

    #create login token
    @token ||= self.get_token
  end

  def list_operations
    #operation list permited by JIRA soap
    @operations_available = @client.operations.sort
  end

  #get token login
  #
  # @return [String] token
  def get_token
    response = self.login @username, @password
    response.to_hash[:login_response][:login_return] if response.nil? ==false and response.success?
  rescue Savon::SOAPFault => error
    LOG.error error.to_hash[:fault][:faultstring]
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
    response if response.success?
  rescue Savon::SOAPFault => error
    puts error.to_hash[:fault][:faultstring]
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

  #checks if a project exist
  #
  # @param [String] project
  # @return [Boolean]
  def check_project project
    @client.call(:get_project_by_key, message: {:token => @token, :key => project.upcase})
    true
  rescue Savon::SOAPFault => error
    error = error.to_hash[:fault][:faultstring]
    return false, error
  end

  #get teh actual version and the next version of a project
  # @param [String] project_name
  def get_version(project_name)
    tries ||= 5
    all_versions = []
    result, error = (self.check_project project_name)

    unless result == false
      #get all versions xml
      response = @client.call(:get_versions, message: {:token => @token, :key => project_name.upcase})

    #get next version from hash
    next_version_id = response.to_hash[:get_versions_response][:get_versions_return][:'@soapenc:array_type']
    next_version_id = next_version_id.match(/RemoteVersion\[(\d+)\]/)[1]

    #get actual version from the array of version id's
    actual_version_id = (self.get_all_version_ids response.to_hash).sort.last - 1

    response.to_hash[:multi_ref].each do |version|
      all_versions << version[:name]
      @next_version = version[:name] if next_version_id.to_i == version[:sequence].to_i
      @actual_version = version[:name] if actual_version_id.to_i == version[:sequence].to_i
    end

    @all_versions = all_versions.sort_by { |x| x.split('.').map &:to_i }
    raise Exceptions::CouldNotGetNextVersion, 'Problem getting Next Version number' if @next_version.nil?
    raise Exceptions::CouldNotGetActualVersion, 'Problem getting Actual Version number' if @actual_version.nil?
    return true
      response.to_hash[:multi_ref].each do |version|
        all_versions << version[:name]
        @next_version = version[:name] if next_version_id.to_i == version[:sequence].to_i
        @actual_version = version[:name] if actual_version_id.to_i == version[:sequence].to_i
      end

      @all_versions = all_versions.sort_by { |x| x.split('.').map &:to_i }
      all_versions = []
      raise Exceptions::CouldNotGetNextVersion, 'Problem getting Next Version number' if @next_version.nil?
      raise Exceptions::CouldNotGetActualVersion, 'Problem getting Actual Version number' if @actual_version.nil?
      return true
    end
    return false, error.to_s
  rescue Savon::SOAPFault => e
    tries = tries -= 1
    if (tries).zero?
      return false
    else
      sleep 5
      self.token
      puts "Jira connection failed. Trying to connect again. (Num tries: #{tries})"
      retry
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
  end

  #get jira tickets from a project
  #
  # @param status - verify,in progress, open, reopened, closed
  # @param project key or name
  # @param version project version
  # @param max_num_results max number of results
  # @return nil, jira_tickets, (false, error_msg)
  def get_jira_tickets(status, project, version, max_num_results=300)

    response = @client.call(:get_issues_from_jql_search,
                            message: {:token => @token,
                                      :jqlSearch => 'status in (' + status + ') and project=' + project + ' and fixVersion in (' + version + ')',
                                      :maxNumResults => max_num_results})
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
      jira_tickets
    end
  rescue Savon::SOAPFault => error
    return false, error.to_hash[:fault][:faultstring].match(/.*?:(.*)/)[1]
  end

end

module Exceptions
  #exceptions
  class CouldNotGetNextVersion < StandardError;
  end
  class CouldNotGetActualVersion < StandardError;
  end
  class TokenNotCreated < StandardError;
  end
end
