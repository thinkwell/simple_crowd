require 'savon'
require 'simple_crowd/client'

module SimpleCrowd
  class << self
    # SimpleCrowd default options
    def options
      @options ||= {
        :service_url => "http://localhost:8095/crowd/services/SecurityServer",
        :service_ns => "urn:SecurityServer",
        :service_namespaces => {
          'xmlns:auth' => 'http://authentication.integration.crowd.atlassian.com',
          'xmlns:ex' => 'http://exception.integration.crowd.atlassian.com',
          'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
        },
        :app_name => "crowd",
        :app_password => ""
      }
    end
  end
end


