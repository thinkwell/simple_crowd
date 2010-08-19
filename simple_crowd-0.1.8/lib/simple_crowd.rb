require 'savon'
require 'hashie'
require 'forwardable'
require 'simple_crowd/crowd_entity'
require 'simple_crowd/crowd_error'
require 'simple_crowd/user'
require 'simple_crowd/group'
require 'simple_crowd/client'
require 'simple_crowd/mappers/soap_attributes'
Dir['simple_crowd/mappers/*.rb'].each {|file| require File.basename(file, File.extname(file)) }

module SimpleCrowd
  class << self
    def config &config_block
      config_block.call(options)
    end
    # SimpleCrowd default options
    def options
      @options ||= {
        :service_url => "http://localhost:8095/crowd/",
        :app_name => "crowd",
        :app_password => ""
      }
    end
    def soap_options base_options = self.options
      @soap_options ||= base_options.merge({
        :service_ns => "urn:SecurityServer",
        :service_namespaces => {
          'xmlns:auth' => 'http://authentication.integration.crowd.atlassian.com',
          'xmlns:ex' => 'http://exception.integration.crowd.atlassian.com',
          'xmlns:int' => 'http://soap.integration.crowd.atlassian.com',
          'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
        }
      })
      @soap_options.merge!({:service_url => base_options[:service_url] + 'services/SecurityServer'})
    end
  end
end


