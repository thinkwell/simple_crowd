module SimpleCrowd
  class Client
    def initialize options = {}
      @options = SimpleCrowd.options.merge options
      # Errors do not contained Exception info so we'll handle the errors ourselves
      # Savon::Response.raise_errors = false
      # @client = Savon::Client.new @options[:service_url]
    end
    def app_token
      @app_token ||= authenticate_application
    end

    def get_cookie_info
      response = client.get_cookie_info! do |soap|
        prepare soap
        soap.body = { :in0 => hash_authenticated_token }
      end
      response.to_hash[:get_cookie_info_response][:out]
    end
    
    def authenticate_application(name = @options[:app_name], password = @options[:app_password])
      response = client.authenticate_application! do |soap|
        prepare soap
        soap.body = {:in0 => {
          'auth:name' => name,
          'auth:credential' => {'auth:credential' => password}
        }.merge(no_validation_factors)}
      end
      response.to_hash[:authenticate_application_response][:out][:token]
    end

    # Authenticate user by name/pass and retrieve login token
    # @return [String] user token
    def authenticate_user name, password 
      response = client.authenticate_principal! do |soap|
        prepare soap
        soap.body = {:in0 => hash_authenticated_token, :in1 => {
          'auth:application' => @options[:app_name],
          'auth:name' => name,
          'auth:credential' => {'auth:credential' => password}
        }, :order! => [:in0, :in1]}
      end
      response.to_hash[:authenticate_principal_response][:out]
    end

    def create_user_token name
      response = client.create_principal_token! do |soap|
        prepare soap
        soap.body = {:in0 => hash_authenticated_token, :in1 => name, :in2 => nil, :order! => [:in0, :in1, :in2]}
      end
      response.to_hash[:create_principal_token_response][:out]
    end

    # Invalidate an existing user token (log out)
    # NOTE: call will return true even if token is invalid
    # @return [Boolean] success (does not guarantee valid token)
    def invalidate_user_token token
      response = client.invalidate_principal_token! do |soap|
        prepare soap
        soap.body = {:in0 => hash_authenticated_token, :in1 => token, :order! => [:in0, :in1]}
      end
      !response.soap_fault? && response.to_hash.key?(:invalidate_principal_token_response)
    end

    def is_valid_user_token? token
      response = client.is_valid_principal_token! do |soap|
        prepare soap
        soap.body = {:in0 => hash_authenticated_token, :in1 => token, :in2 => nil, :order! => [:in0, :in1, :in2]}
      end
      response.to_hash[:is_valid_principal_token_response][:out]
    end

    def find_user_by_name name
      response = client.find_principal_by_name! do |soap|
        prepare soap
        soap.body = {:in0 => hash_authenticated_token, :in1 => name, :order! => [:in0, :in1]}
      end
      response.to_hash[:find_principal_by_name_response][:out]
    end

    def reset_user_password name
      response = client.reset_principal_credential! do |soap|
        prepare soap
        soap.body = {:in0 => hash_authenticated_token, :in1 => name, :order! => [:in0, :in1]}
      end
      !response.soap_fault? && response.to_hash.key?(:reset_principal_credential_response)
    end

    private
    # Generate new client on every request (Savon bug?)
    def client
      Savon::Client.new @options[:service_url]
    end
    # Setup soap object for request
    def prepare soap
      soap.namespace = @options[:service_ns]
      soap.namespaces.merge! @options[:service_namespaces]
    end
    def hash_authenticated_token name = @options[:app_name], token = nil
      token ||= app_token
      {'auth:name' => name, 'auth:token' => token}
    end
    def no_validation_factors
      {'auth:validationFactors' => {}, :attributes! => {'auth:validationFactors' => {'xsi:nil' => true}}}
    end
  end
end