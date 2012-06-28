module SimpleCrowd
  class CrowdError < StandardError
    attr_reader :response
    attr_reader :type
    attr_reader :original

    def initialize(original, message=nil)
      @original = original

      if original.is_a?(Savon::SOAP::Fault)
        fault = original.to_hash[:fault] || {}
        @response = original.http
        @type = fault[:detail].keys.first rescue :fault
        message = fault[:faultstring] if message.blank?
      elsif original.is_a?(Savon::HTTP::Error)
        @response = original.http
        @type = :http
      end

      message = original.to_s if message.blank?
      super message
    end

    def type? type
      @type == type.to_sym
    end
  end
end
