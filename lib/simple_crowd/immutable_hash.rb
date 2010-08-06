module SimpleCrowd
  module ImmutableHash
    def initialize *args
      super *args
      self.freeze
    end
  end
end