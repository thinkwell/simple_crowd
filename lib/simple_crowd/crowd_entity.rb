require 'simple_crowd/mappers/soap_attributes'
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
  class CrowdEntity < Hashie::Dash

    def initialize(attributes = {})
      # Hack to allow first assignment of immutable properties
      @initializing = true
      self.class.properties.each do |prop|
        self.send("#{prop.name}=", self.class.defaults[prop.name.to_sym])
      end
      attributes.merge! attributes[:attributes] unless attributes[:attributes].nil?
      attributes.delete(:attributes)
      attributes.each_pair do |att, value|
        prop = self.class.property_by_name(att)
        next if prop.nil?
        self.send("#{att}=", value)
      end
      @initializing = false
    end

    def self.property(property_name, options = {})
      property_name = property_name.to_sym

      maps = options.inject({}) {|map, (key, value)| map[$1.to_sym] = value.to_sym if key.to_s =~ /^map_(.*)$/; map }
      mappers = options.inject({}) {|map, (key, value)| map[$1.to_sym] = value if key.to_s =~ /^mapper_(.*)$/; map }
      options.reject! {|key, val| key.to_s =~ /^map_(.*)$/ || key.to_s =~ /^mapper_(.*)$/ }
      (@properties ||= []) << ExtendedProperty.new({:name => property_name, :maps => maps, :mappers => mappers}.merge(options))

      if options[:attribute]
        class_eval <<-RUBY
          def #{property_name}
            self[:attributes][:#{property_name}]
          end
          def #{property_name}=(val)
            self[:attributes][:#{property_name}] = val
          end
        RUBY
      else
        class_eval <<-RUBY
          def #{property_name}
            self[:#{property_name}]
          end

          def #{property_name}=(val)
            self[:#{property_name}] = val
          end
        RUBY
      end

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

    def self.defaults
      properties.inject({}) {|hash, prop| hash[prop.name] = prop.default unless prop.default.nil?; hash }
    end

    def self.map_for type
      type = type.to_sym
      properties.inject({}) {|hash, prop| hash[prop.name] = prop.maps[type] unless prop.maps[type].nil?; hash }
    end

    def self.property?(prop)
      !property_by_name(prop.to_sym).nil?
    end

    def self.property_immutable?(prop)
      property_by_name(prop).immutable
    end

    def self.property_by_name(property_name)
      prop = properties_by_name(property_name)
      prop.first unless prop.empty?
    end

    def self.properties_by_name(property_name)
      properties.select {|p| p.name == property_name || p.maps.value?(property_name)}
    end

    def [](property)
      super || self[:attributes][property]
    end

    def key?(property)
      super || self[:attributes].key?(property)
    end

    def []=(property, value)
      super if property_mutable?(property)
    end

    def self.map_to type, entity
      map = map_for type
      entity.inject({}) do |hash, (key, val)|
        unless val.nil?
          mapped_key = map[key].nil? ? key : map[key]
          prop = property_by_name key
          mapper = prop.mappers[type]
          val = val.inject({}) {|attrs, (k, v)| attrs[property_by_name(k).maps[type]]= v unless v.nil?; attrs} if key == :attributes
          val = mapper.produce val unless mapper.nil?
          hash[mapped_key] = val
        end
        hash
      end
    end

    def map_to type
      self.class.map_to type, self
    end

    def self.parse_from type, entity
      parsed_entity = entity.inject({}) do |hash, (key, val)|
        prop = property_by_name key
        mapper = prop.mappers[type]
        val = mapper.parse val unless mapper.nil?
        hash[key] = val
        hash
      end
      self.new(parsed_entity)
    end
    
    property :attributes, :default => {}, :mapper_soap => SimpleCrowd::Mappers::SoapAttributes

    private
    def property_mutable?(property)
      if !@initializing && self.class.property_immutable?(property.to_sym)
        #raise NoMethodError, "The property '#{property}' is immutable for this Dash."
      end
      true
    end
    
  end
end