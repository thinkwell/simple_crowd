module SimpleCrowd
  class CrowdError < StandardError
    attr_accessor :response
    attr_reader :type
    def initialize string, data = nil
      super string
      self.response = data unless data.nil?
      @type = data[:detail].keys.first unless data.nil?
    end

    def type? type
      @type == type.to_sym
    end
  end
end