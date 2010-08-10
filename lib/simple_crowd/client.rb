module SimpleCrowd
  class Client
    def initialize options = {}
      @options = SimpleCrowd.soap_options SimpleCrowd.options.merge(options)

      # TODO: Fix error handling
      # Errors do not contained Exception info so we'll handle the errors ourselves
      # Savon::Response.raise_errors = false
      # @client = Savon::Client.new @options[:service_url]
      yield(@options) if block_given?
    end
    def app_token
      @app_token ||= authenticate_application
    end
    attr_writer :app_token

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

    def find_group_by_name name
      group = simple_soap_call :find_group_by_name, name
      map_group_hash group
    end

    def find_all_group_names
      (simple_soap_call :find_all_group_names)[:string]
    end

    def update_group group, description, active
      simple_soap_call :update_group, group, description, active  do |res|
        !res.soap_fault? && res.to_hash.key?(:update_group_response)
      end
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

    def find_all_user_names
      (simple_soap_call :find_all_principal_names)[:string]
    end

    def find_user_by_name name
      map_user_hash simple_soap_call :find_principal_by_name, name rescue nil
    end

    def find_user_by_token token
      map_user_hash simple_soap_call :find_principal_by_token, token rescue nil
    end

    def find_username_by_token token
      user = find_user_by_token token
      user && user[:username]
    end

    def update_user_credential user, credential, encrypted = false
      simple_soap_call :update_principal_credential, user,
                       {'auth:credential' => credential, 'auth:encryptedCredential' => encrypted} do |res|
        !res.soap_fault? && res.to_hash.key?(:update_principal_credential_response)
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

    # Take Crowd SOAP attribute format and return a simple ruby hash
    # @param attributes the soap attributes array
    def process_soap_attributes attributes
      soap = attributes[:soap_attribute]
      (soap && soap.inject({}) {|hash, attr| hash[attr[:name].to_sym] = attr[:values][:string]; hash }) || {}
    end

    # Takes a SOAP user hash returned from the API and maps it into a User object
    # @param user (soap hash) to map to object
    def map_user_hash user
      attributes = process_soap_attributes user[:attributes]
      supported_keys = attributes.keys & SimpleCrowd::User.mapped_properties(:soap)
      user = user.merge attributes.inject({}) {|map, (k, v)| map[k] = v if supported_keys.include? k; map}
      user[:attributes] = attributes.inject({}) {|map, (k, v)| map[k] = v unless supported_keys.include? k; map}
      user.delete :attributes if user[:attributes].empty?
      SimpleCrowd::User.new user
    end

    def map_group_hash group
      attributes = process_soap_attributes group[:attributes]
      supported_keys = attributes.keys & SimpleCrowd::Group.mapped_properties(:soap)
      group = group.merge attributes.inject({}) {|map, (k, v)| map[k] = v if supported_keys.include? k; map}
      group[:attributes] = attributes.inject({}) {|map, (k, v)| map[k] = v unless supported_keys.include? k; map}
      group.delete :attributes if group[:attributes].empty?
      SimpleCrowd::Group.new group
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