module SimpleCrowd
  class ExtendedProperty < Hashie::Dash
    property :name
    property :default
    property :attribute
    property :immutable
    property :maps, :default => {}
    property :mappers, :default => {}
    def immutable?; @immutable; end
    def is_attribute?; @attribute end
  end
  class CrowdEntity < Hashie::Mash
    def initialize(data = {})
      self.class.properties.each do |prop|
        self.send("#{prop.name}=", self.class.defaults[prop.name.to_sym])
      end
      attrs = data[:attributes].nil? ? [] : data[:attributes].keys
      data.merge! data[:attributes] unless attrs.empty?
      data.delete :attributes
      data.each_pair do |att, value|
        #ruby_att = att_to_ruby att
        ruby_att = att
        real_att = real_key_for ruby_att
        (@attributes ||= []) << real_att if attrs.include?(att)
        prop = self.class.property_by_name(real_att)
        self.send("#{real_att}=", value) unless prop.nil?
        self[real_att] = value if prop.nil?
      end
      # We just initialized the attributes so clear the dirty status
      dirty_properties.clear
    end
    def self.property(property_name, options = {})
      property_name = property_name.to_sym

      maps = options.inject({}) {|map, (key, value)| map[$1.to_sym] = value.to_sym if key.to_s =~ /^map_(.*)$/; map }
      mappers = options.inject({}) {|map, (key, value)| map[$1.to_sym] = value if key.to_s =~ /^mapper_(.*)$/; map }
      options.reject! {|key, val| key.to_s =~ /^map_(.*)$/ || key.to_s =~ /^mapper_(.*)$/ }
      (@properties ||= []) << ExtendedProperty.new({:name => property_name, :maps => maps, :mappers => mappers}.merge(options))
      (@attributes ||= []) << property_name if options[:attribute]

      class_eval <<-RUBY
        def #{property_name}
          self[:#{property_name}]
        end
        def #{property_name}=(val)
          (dirty_properties << :#{property_name}).uniq! unless val == self[:#{property_name}]
          self[:#{property_name}] = val
        end
      RUBY

      maps.each_value do |v|
        alias_method v, property_name
        alias_method :"#{v}=", :"#{property_name}="
      end
    end

    def self.properties
      properties = []
      ancestors.each do |elder|
        if elder.instance_variable_defined?("@properties")
          properties << elder.instance_variable_get("@properties")
        end
      end

      properties.reverse.flatten
    end

    def self.property_by_name(property_name)
      property_name = property_name.to_sym
      properties.detect {|p| p.name == property_name || p.maps.value?(property_name)}
    end

    def self.properties_by_name(property_name)
      property_name = property_name.to_sym
      properties.select {|p| p.name == property_name || p.maps.value?(property_name)}
    end

    def self.property?(prop)
      !property_by_name(prop.to_sym).nil?
    end

    def self.defaults
      properties.inject({}) {|hash, prop| hash[prop.name] = prop.default unless prop.default.nil?; hash }
    end

    def self.attribute_mappers hash = nil
      @attribute_mappers ||= {:soap => SimpleCrowd::Mappers::SoapAttributes}
      unless hash.nil?
        @attribute_mappers.merge! hash if hash.is_a? Hash
      end
      @attribute_mappers
    end

    def self.map_for type
      type = type.to_sym
      properties.inject({}) {|hash, prop| hash[prop.name] = prop.maps[type] unless prop.maps[type].nil?; hash }
    end

    def self.map_to type, entity
      map = map_for type
      attrs = {}
      out = entity.inject({}) do |hash, (key, val)|
        key = key.to_sym
        catch(:skip_prop) do
        unless val.nil?
          mapped_key = map[key].nil? ? key : map[key]
          prop = property_by_name key
          if prop.nil?
            attrs[mapped_key] = val
            throw :skip_prop
          end
          mapper = prop.mappers[type]
          #val = val.inject({}) {|attrs, (k, v)| attrs[property_by_name(k).maps[type]]= v unless v.nil?; attrs} if key == :attributes
          val = mapper.produce val unless mapper.nil?
          if prop.attribute || entity.attributes_keys.include?(key)
            attrs[mapped_key] = val
          else
            hash[mapped_key] = val
          end
        end
        end
        hash
      end
      out[:attributes] = attribute_mappers[type].produce attrs
      out
    end

    def self.parse_from type, entity
      entity[:attributes] = attribute_mappers[type].parse entity[:attributes]
      parsed_entity = entity.inject({}) do |hash, (key, val)|
        prop = property_by_name key
        unless prop.nil?
          mapper = prop.mappers[type]
          val = mapper.parse val unless mapper.nil?
        end
        hash[key] = val
        hash
      end
      self.new(parsed_entity)
    end

    def map_to type
      self.class.map_to type, self
    end

    def attributes_keys
      keys = []
      self.class.ancestors.each do |elder|
        if elder.instance_variable_defined?("@attributes")
          keys << elder.instance_variable_get("@attributes")
        end
      end
      keys << @attributes unless @attributes.nil?
      keys.flatten.uniq
    end

    def attributes
      self.inject({}) {|hash, (k, v)| hash[k] = v if attributes_keys.include?(k.to_sym); hash}
    end

    def dirty_properties
      @dirty_properties ||= Array.new
    end

    def dirty_attributes
      dirty_properties & attributes_keys
    end

    def dirty? prop = nil
      prop.nil? ? !@dirty_properties.empty? : @dirty_properties.include?(prop)
    end

    def update_with attrs
      current_keys = attributes_keys
      attrs.each_pair {|k, v| self.send(:"#{k}=", v) if current_keys.include?(k) && v != self.send(k.to_sym)}
    end

    def []= key, val
      prop = self.class.property_by_name key
      (@attributes ||= []) << key if prop.nil?
      super
    end

    private
    def self.real_key_for att
      p = property_by_name att
      p.nil? ? att : p.name
    end
    def self.att_to_ruby att
      att.to_s =~ /^[a-z]*([A-Z][^A-Z]*)*$/ ? att.to_s.underscore.to_sym : att.to_sym
    end
    def real_key_for att; self.class.real_key_for att; end
    def att_to_ruby att; self.class.att_to_ruby att; end
  end
end