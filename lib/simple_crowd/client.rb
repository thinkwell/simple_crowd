module SimpleCrowd
  class Client

    attr_reader :options
    attr_accessor :app_token, :cache_store

    def initialize options = {}
      @options = SimpleCrowd.options options
      yield(@options) if block_given?
      self.cache_store = @options.delete(:cache_store)
    end

    def get_cookie_info
      @cookie_info ||= cache.fetch(cache_key(:cookie_info)) do
        # Remove custom SOAP attributes from the strings
        simple_soap_call(:get_cookie_info).inject({}) do |cookie_info, (key, val)|
          cookie_info[key] = val ? val.to_s : val
          cookie_info
        end
      end
    end

    def get_granted_authorities
      groups = simple_soap_call :get_granted_authorities
      groups[:string] unless groups.nil?
    end

    def authenticate_application(name = @options[:app_name], password = @options[:app_password])
      response = convert_soap_errors do
        client.request :authenticate_application do |soap|
          prepare soap
          soap.body = {:in0 => {
            'auth:name' => name,
            'auth:credential' => {'auth:credential' => password}
          }.merge(no_validation_factors)}
        end
      end
      clean_response(response.to_hash[:authenticate_application_response][:out])[:token].to_s.dup
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
      simple_soap_call :invalidate_principal_token, token
      true
    end

    def is_valid_user_token? token, factors = nil
      factors = prepare_validation_factors(factors)
      simple_soap_call :is_valid_principal_token, token, factors
    end

    def is_cache_enabled?
      simple_soap_call :is_cache_enabled
    end

    def is_group_member? group, user
      simple_soap_call :is_group_member, group, user
    end

    def find_group_memberships user
      groups = simple_soap_call :find_group_memberships, user
      groups[:string] unless groups.nil?
    end

    def find_group_by_name name
      SimpleCrowd::Group.from_soap simple_soap_call(:find_group_by_name, name)
    end

    def find_all_group_names
      (simple_soap_call :find_all_group_names)[:string]
    end

    def update_group group, description, active
      simple_soap_call :update_group, group, description, active
      true
    end

    def add_user_to_group user, group
      simple_soap_call :add_principal_to_group, user, group
      true
    end

    def remove_user_from_group user, group
      simple_soap_call :remove_principal_from_group, user, group
      true
    end

    def reset_user_password name
      simple_soap_call :reset_principal_credential, name
      true
    end

    def find_all_user_names
      (simple_soap_call :find_all_principal_names)[:string]
    end

    def find_user_by_name name
      SimpleCrowd::User.from_soap simple_soap_call(:find_principal_by_name, name) rescue nil
    end

    def find_user_with_attributes_by_name name
      SimpleCrowd::User.from_soap simple_soap_call(:find_principal_with_attributes_by_name, name) rescue nil
    end

    def find_user_by_token token
      SimpleCrowd::User.from_soap simple_soap_call(:find_principal_by_token, token) rescue nil
    end

    def find_username_by_token token
      user = find_user_by_token token
      user && user[:username]
    end

    # Exact email match
    def find_user_by_email email
      search_users_by_email(email).find{|u| u.email == email}
    end

    # Partial email match
    def search_users_by_email email
      search_users({'email' => email})
    end

    # Search Crowd users using the given criteria.
    #
    # critieria should be a hash of SimpleCrowd::User properties or attributes.
    # Not all properties are supported, see (https://developer.atlassian.com/display/CROWDDEV/Using+the+Search+API)
    #
    # NOTE: Atlassian Crowd contains a bug that ignores the limit and start
    # parameters
    #
    # For example:
    #   client.search_users(:email => 'foo', :display_name => 'bar')
    def search_users criteria, limit=0, start=0
      # Convert search criteria to Crowd search restrictions
      restrictions = criteria.inject({}) do |h, (key, val)|
        key = User.search_restriction_for(key).to_s
        h[key] = val
        h
      end
      soap_restrictions = add_soap_namespace(prepare_search_restrictions(restrictions, limit, start))
      users = simple_soap_call :search_principals, soap_restrictions rescue []
      return [] if users.nil? || users[:soap_principal].nil?
      users = users[:soap_principal].is_a?(Array) ? users[:soap_principal] : [users[:soap_principal]]
      users.map{|u| SimpleCrowd::User.from_soap u}
    end

    def add_user user, credential
      return if user.nil? || credential.nil?
      [:email, :first_name, :last_name].each do |k|
        user.send(:"#{k}=", "") if user.send(k).nil?
      end
      soap_user = user.to_soap
      # We don't use these attributes when creating
      soap_user.delete(:id)
      soap_user.delete(:directory_id)
      # Add blank attributes if missing

      # Declare require namespaces
      soap_user = add_soap_namespace(soap_user)

      SimpleCrowd::User.from_soap simple_soap_call(:add_principal, soap_user, {'auth:credential' => credential, 'auth:encryptedCredential' => false})
    end

    def remove_user name
      simple_soap_call :remove_principal, name
      true
    end

    def update_user_credential user, credential, encrypted = false
      simple_soap_call :update_principal_credential, user,
                       {'auth:credential' => credential, 'auth:encryptedCredential' => encrypted}
      true
    end

    # Only supports single value attributes
    # TODO: Allow value arrays
    # @param user [String] name of user to update
    # @param name [String] of attribute to update
    # @param value [String] of attribute to update
    def update_user_attribute user, name, value
      return unless (name.is_a?(String) || name.is_a?(Symbol)) && (value.is_a?(String) || value.is_a?(Array))
      soap_attr = add_soap_namespace({:name => name, :values => {:string => value}})
      simple_soap_call :update_principal_attribute, user, soap_attr
      true
    end
    alias_method :add_user_attribute, :update_user_attribute

    # @param user [SimpleCrowd::User] dirty user to update
    def update_user user
      return unless user.dirty?
      # Exclude non-attribute properties (only attributes can be updated in crowd)
      attrs_to_update = user.dirty_attributes
      return if attrs_to_update.empty?

      attrs_to_update.each do |a|
        key = SimpleCrowd::User.soap_key_for(a)
        self.update_user_attribute user.username, key, user.send(a)
      end
    end

    def app_token
      @app_token ||= cache.read(cache_key(:app_token))
    end

    def app_token=(token)
      cache.write(cache_key(:app_token), token)
      @app_token = token
    end

    def cache_store=(store)
      @cache_store = store || Cache::NullStore.new
    end
    alias_method :cache, :cache_store

    def reset_cache
      [:app_token, :cookie_info].each do |key|
        cache.delete(cache_key(key))
      end
    end

    private

    # Simplify the duplicated soap calls across methods
    # @param [Symbol] action the soap action to call
    # @param data the list of args to pass to the server as "in" args (in1, in2, etc.)
    def simple_soap_call action, *data
      # Take each arg and assign it to "in" keys for SOAP call starting with in1 (in0 is app token)
      soap_args = data.inject({}){|hash, arg| hash[:"in#{hash.length + 1}"] = arg; hash }
      # Ordered "in" keys ex. in1, in2, etc. for SOAP ordering
      in_keys = soap_args.length ? (1..soap_args.length).collect {|v| :"in#{v}" } : []
      # Make the SOAP call to the dynamic action
      response = client_with_app_token do |client|
        convert_soap_errors do
          client.request :"#{action}" do |soap|
            prepare soap
            # Pass in all the args as "in" vars
            soap.body = {:in0 => hash_authenticated_token}.merge(soap_args).merge({:order! => [:in0, *in_keys]})
          end
        end
      end
      response_hash = clean_response response.to_hash[:"#{action}_response"][:out]
      # If a block is given then call it and pass in the response, otherwise get the default out value
      block_given? ? yield(response_hash) : response_hash
    end

    # Savon returns strings with embedded SOAP/XML attributes.  These don't serialize
    # well and users shouldn't care that we use SOAP.  Remove these attributes.
    def clean_response(r)
      case r
      when Hash
        r.each {|k,v| r[k] = clean_response(v)}
      when Array
        r = r.map {|v| clean_response(v)}
      when Nori::StringWithAttributes
        r = r.to_s
      end
      r
    end

    def convert_soap_errors
      begin
        old_raise_errors = client.config.raise_errors
        client.config.raise_errors = true
        yield
      rescue Savon::SOAP::Fault => fault
        raise CrowdError.new(fault.to_s, fault)
      rescue Savon::HTTP::Error => e
        raise CrowdError.new(e.to_s)
      ensure
        client.config.raise_errors = old_raise_errors
      end
    end

    def client
      @client ||= Savon::Client.new do
        wsdl.endpoint = options[:service_url]
        wsdl.namespace = options[:service_ns]
      end
    end

    def client_with_app_token retries = 1
      self.app_token = authenticate_application unless self.app_token
      begin
        yield client
      rescue CrowdError => e
        if retries > 0 && e.type?(:invalid_authorization_token_exception)
          # Refresh the app token
          self.app_token = authenticate_application
          retries -= 1
          retry
        end
        raise
      end
    end

    # Setup soap object for request
    def prepare soap
      soap.namespaces.merge! options[:service_namespaces]
    end

    # Take Crowd SOAP attribute format and return a simple ruby hash
    # @param attributes the soap attributes array
    def process_soap_attributes attributes
      soap = attributes[:soap_attribute]
      (soap && soap.inject({}) {|hash, attr| hash[attr[:name].to_sym] = attr[:values][:string]; hash }) || {}
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
              (factors || []).inject([]) {|arr, factor| arr << {'auth:name' => factor[0], 'auth:value' => factor[1]} }
      }
    end

    def prepare_search_restrictions restrictions, limit=0, start=0
      restrictions = restrictions.inject([]) do |arr, (key, val)|
        arr << {'name' => key, 'value' => val}
      end
      restrictions << {'name' => 'search.max.results', 'value' => limit.to_i} if limit.to_i > 0
      restrictions << {'name' => 'search.index.start', 'value' => start.to_i} if start.to_i > 0
      {'searchRestriction' => restrictions}
    end

    def hash_authenticated_token name = @options[:app_name], token = nil
      token ||= app_token
      {'auth:name' => name, 'auth:token' => token}
    end

    def no_validation_factors
      {'auth:validationFactors' => {}, :attributes! => {'auth:validationFactors' => {'xsi:nil' => true}}}
    end

    def cache_key(key)
      "#{@options[:cache_prefix]}#{key}"
    end

    def add_soap_namespace(enum)
      if enum.is_a?(Hash)
        enum.inject({}) do |h, (k, v)|
          k = k == :string ? "wsdl:#{k}" : "int:#{k}"
          h[k] = v.is_a?(Enumerable) ? add_soap_namespace(v) : v
          h
        end
      else
        enum.map do |v|
          v.is_a?(Enumerable) ? add_soap_namespace(v) : v
        end
      end
    end
  end
end
