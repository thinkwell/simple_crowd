module SimpleCrowd
  module Mappers
    class SoapAttributes
      def self.produce hash
        {"int:SOAPAttribute" => hash.inject([]) {|attrs, (key, val)| attrs << {"int:name" => key, "int:values" => {"wsdl:string" => val}}}}
      end
      def self.parse attributes
        soap = attributes[:soap_attribute]
        (soap && soap.inject({}) {|hash, attr| hash[attr[:name].to_sym] = attr[:values][:string]; hash }) || {}
      end
    end
  end
end
