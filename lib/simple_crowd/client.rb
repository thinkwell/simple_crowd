module SimpleCrowd
  class Client
    def initialize options = {}
      @options = SimpleCrowd.options.merge options
      # TODO: Fix error handling
      # Errors do not contained Exception info so we'll handle the errors ourselves
      # Savon::Response.raise_errors = false
      # @client = Savon::Client.new @options[:service_url]
    end
    def app_token
      @app_token ||= authenticate_application
    end

    def get_cookie_info
      simple_soap_call :get_cookie_info
    end

    def get_granted_authorities
      groups = simple_soap_call :get_granted_authorities
      groups[:string] unless groups.nil?
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
    def authenticate_user name, password, factors = nil
      if factors
        factors = prepare_validation_factors(factors)
        simple_soap_call :authenticate_principal, {'auth:application' => @options[:app_name], 'auth:name' => name,
            'auth:credential' => {'auth:credential' => password},
            'auth:validationFactors' => factors}
      else
        simple_soap_call :authenticate_principal_simple, name, password
      end
    end

    def create_user_token name
      simple_soap_call :create_principal_token, name, nil
    end

    # Invalidate an existing user token (log out)
    # NOTE: call will return true even if token is invalid
    # @return [Boolean] success (does not guarantee valid token)
    def invalidate_user_token token
      simple_soap_call :invalidate_principal_token, token do |res|
        !res.soap_fault? && res.to_hash.key?(:invalidate_principal_token_response)
      end
    end

    def is_valid_user_token? token, factors = nil
      factors = prepare_validation_factors(factors) unless factors.nil?
      simple_soap_call :is_valid_principal_token, token, factors
    end

    def is_cache_enabled?
      simple_soap_call :is_cache_enabled
    end

    def is_group_member? group, user
      simple_soap_call :is_group_member, group, user
    end

    def find_user_by_name name
      simple_soap_call :find_principal_by_name, name
    end

    def add_user_to_group user, group
      simple_soap_call :add_principal_to_group, user, group do |res|
        !res.soap_fault? && res.to_hash.key?(:add_principal_to_group_response)
      end
    end

    def remove_user_from_group user, group
      simple_soap_call :remove_principal_from_group, user, group do |res|
        !res.soap_fault? && res.to_hash.key?(:remove_principal_from_group_response)
      end
    end

    def reset_user_password name
      simple_soap_call :reset_principal_credential, name do |res|
        !res.soap_fault? && res.to_hash.key?(:reset_principal_credential_response)
      end
    end

    private
    
    # Simplify the duplicated soap calls across methods
    # @param [Symbol] action the soap action to call
    # @param data the list of args to pass to the server as "in" args (in1, in2, etc.)
    def simple_soap_call action, *data
      # Take each arg and assign it to "in" keys for SOAP call
      soap_args = data.inject({}){|hash, arg| hash[:"in#{hash.length + 1}"] = arg; hash }
      # Ordered "in" keys ex. in1, in2, etc. for SOAP ordering
      in_keys = soap_args.length ? (1..soap_args.length).collect {|v| :"in#{v}" } : []
      # Make the SOAP call to the dynamic action
      response = client.send :"#{action}!" do |soap|
        prepare soap
        # Pass in all the args as "in" vars
        soap.body = {:in0 => hash_authenticated_token}.merge(soap_args).merge({:order! => [:in0, *in_keys]})
      end
      # If a block is given then call it and pass in the response object, otherwise get the default out value
      block_given? ? yield(response) : response.to_hash[:"#{action}_response"][:out]
    end

    # Generate new client on every request (Savon bug?)
    def client
      Savon::Client.new @options[:service_url]
    end

    # Setup soap object for request
    def prepare soap
      soap.namespace = @options[:service_ns]
      soap.namespaces.merge! @options[:service_namespaces]
    end

    def prepare_validation_factors factors
      {'auth:validationFactor' =>
              factors.inject([]) {|arr, factor| arr << {'auth:name' => factor[0], 'auth:value' => factor[1]} }
      }
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