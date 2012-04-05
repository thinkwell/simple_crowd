require 'savon'
require 'hashie'
require 'yaml'
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

    def options app_options = {}
      c = soap_options.merge(default_crowd_options).merge(app_options) and
          c.merge(:service_url => c[:service_url] + 'services/SecurityServer')
    end
    def soap_options
      @soap_options ||= {
        :service_ns => "urn:SecurityServer",
        :service_namespaces => {
          'xmlns:auth' => 'http://authentication.integration.crowd.atlassian.com',
          'xmlns:ex' => 'http://exception.integration.crowd.atlassian.com',
          'xmlns:int' => 'http://soap.integration.crowd.atlassian.com',
          'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
        }
      }
    end
    def default_crowd_options
      @default_crowd_options ||= {
        :service_url => "http://localhost:8095/crowd/",
        :app_name => "crowd",
        :app_password => ""
      }
      defined?(IRB) ? @default_crowd_options.merge(config_file_options) : @default_crowd_options
    end
    def config_file_options
      @config_file_options ||= begin
        (File.exists?('config/crowd.yml') &&
            yml = (YAML.load_file('config/crowd.yml')[ENV["RAILS_ENV"] || "development"] || {}) and
            yml.symbolize_keys!) || {}
      end
    end
  end
end