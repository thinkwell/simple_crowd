module SimpleCrowd
  class CrowdError < StandardError
    attr_reader :response
    attr_reader :type
    attr_reader :original

    def initialize(string, original)
      super string
      @original = original

      if original.is_a?(Savon::SOAP::Fault)
        @response = original.http
        @type = original.to_hash[:fault][:detail].keys.first rescue nil
      elsif original.is_a?(Savon::HTTP::Error)
        @response = original.http
        @type = :http
      end
    end

    def type? type
      @type == type.to_sym
    end
  end
end
