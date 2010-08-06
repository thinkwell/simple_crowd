module SimpleCrowd
  class ExtendedDash < Hashie::Dash
    #include SimpleCrowd::ImmutableHash

    def self.maps; @maps ||= {}; end

    def self.property(property_name, options = {})
      property_name = property_name.to_sym

      (@properties ||= []) << property_name
      (@defaults ||= {})[property_name] = options.delete(:default)

      class_eval <<-RUBY
        def #{property_name}
          self[:#{property_name}]
        end

        def #{property_name}=(val)
          self[:#{property_name}] = val
        end
      RUBY

      options.inject({}) {|map, (key, value)| map[$1.to_sym] = value if key.to_s =~ /^map_(.*)$/; map }.each_pair do |map_type, name|
        (maps[map_type] ||= {})[property_name] = name
        class_eval <<-RUBY
          alias_method :#{name.to_s}, :#{property_name.to_s}
          alias_method :#{name.to_s}=, :#{property_name.to_s}=
        RUBY
      end
    end

    def [](property)
      self.class.maps.each_value do |val|
        mapped_prop = val.index property
        if mapped_prop
          property = mapped_prop
          break
        end
      end
      super
    end

    def []=(property, value)
      self.class.maps.each_value do |val|
        mapped_prop = val.index property
        if mapped_prop
          property = mapped_prop
          break
        end
      end
      super
    end

    def self.properties_by attribute
      properties = []
      ancestors.each do |elder|
        if elder.instance_variable_defined?("@#{attribute.to_s}")
          properties << elder.instance_variable_get("@#{attribute.to_s}")
        end
      end

      properties.flatten
    end

    def self.mapped_properties map_type
      properties + ((maps[map_type] && maps[map_type].values) || [])
    end
  end
end