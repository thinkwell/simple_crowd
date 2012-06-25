module SimpleCrowd
  class CrowdEntity

    def initialize(attrs={})
      self.class.defaults.each do |key, val|
        send(:"#{key.to_s}=", val)
      end

      attrs.each do |key, val|
        send(:"#{key.to_s}=", val) if self.respond_to?("#{key.to_s}=", true)
      end
      dirty_properties.clear
    end

    def self.property(property_name, opts={})
      property_name = property_name.to_sym

      @properties ||= []
      @properties << property_name unless @properties.include?(property_name)

      class_eval <<-PROPERTY, __FILE__, __LINE__ + 1
        def #{property_name}
          @#{property_name}
        end
        def #{property_name}=(val)
          (dirty_properties << :#{property_name}).uniq! unless val == @#{property_name}
          @#{property_name} = val
        end
      PROPERTY

      if opts[:immutable]
        private :"#{property_name}="
      end

      if opts[:map_soap]
        v = :"#{opts[:map_soap]}"
        @soap_to_property_map ||= {}
        @property_to_soap_map ||= {}
        @soap_to_property_map[v] = property_name
        @property_to_soap_map[property_name] = v
      end

      if opts[:default]
        @defaults ||= {}
        @defaults[property_name] = opts[:default]
      end
    end

    def self.attribute(attr_name, opts={})
      attr_name = attr_name.to_sym
      @attributes ||= []
      @attributes << attr_name
      self.property(attr_name, opts)
    end

    def self.properties
      @properties.freeze
    end

    def self.attributes
      @attributes.freeze
    end

    def self.defaults
      @defaults.freeze
    end

    def dirty_properties
      @dirty_properties ||= Array.new
    end

    def dirty_attributes
      dirty_properties & self.class.attributes
    end

    def dirty?(prop=nil)
      prop.nil? ? !@dirty_properties.empty? : @dirty_properties.include?(prop)
    end

    def clean
      @dirty_properties.clear
    end

    def [](key)
      respond_to?(:"#{key}") ? send(:"#{key}") : nil
    end

    def to_hash
      (self.class.properties || []).inject({}) do |hash, key|
        hash[key] = send(key) if respond_to?(key)
        hash
      end
    end

    def inspect
      ret = "#<#{self.class.to_s}"
      self.class.properties.each do |key|
        ret << " #{key}=#{self.instance_variable_get("@#{key}").inspect}"
      end
      ret << ">"
      ret
    end

    def self.from_soap(data)
      data = data.dup if data

      # Merge attributes into the main hash
      if data && data[:attributes] && data[:attributes][:soap_attribute]
        attrs = {}
        attrs = data[:attributes][:soap_attribute].inject({}) do |hash, attr|
          hash[attr[:name]] = attr[:values][:string]
          hash
        end
        data.delete :attributes
        data.merge! attrs
      end

      # Clean soap values
      data.each do |(key, val)|
        if val.is_a?(Hash) && val[:"@xmlns"]
          val.delete(:"@xmlns")
          data[key] = nil if val.empty?
        end
      end

      # Map soap values to property values
      if @soap_to_property_map
        data = data.inject({}) do |hash, (key, val)|
          key = :"#{key}"
          if @soap_to_property_map.has_key?(key)
            hash[@soap_to_property_map[key]] = val
          else
            hash[key] = val
          end
          hash
        end
      end

      self.new data
    end

    def to_soap
      properties = self.class.properties || []
      attributes = self.class.attributes || []

      data = {}
      data[:attributes] = {:SOAPAttribute => []} unless attributes.empty?
      properties.each do |prop|
        key = self.class.soap_key_for(prop)
        val = send(prop)

        if attributes.include?(prop)
          data[:attributes][:SOAPAttribute] << {:name => key, :values => {:string => val}}
        else
          data[key] = val
        end
      end

      data
    end

    def self.soap_key_for(property_key)
      property_key = :"#{property_key}"
      if @property_to_soap_map && @property_to_soap_map.has_key?(property_key)
        return @property_to_soap_map[property_key]
      end
      property_key
    end
  end
end
