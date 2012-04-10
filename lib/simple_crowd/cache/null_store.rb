module SimpleCrowd
  module Cache

    # A cache store implementation which doesn't actually store anything.
    #
    # Implements ActiveSupport::Cache::Store interface without depending on
    # the active_support gem.
    class NullStore
      attr_reader :silence, :options
      alias :silence? :silence

      def initialize(options = nil)
      end

      def mute
        yield
      end

      def silence!
      end

      def synchronize
        yield
      end

      def fetch(name, options = nil)
        if block_given?
          yield
        else
          read(name, options)
        end
      end

      def read(name, options = nil)
        nil
      end

      def write(name, vaue, options = nil)
        true
      end

      def delete(name, options = nil)
        false
      end

      def exist?(name, options = nil)
        false
      end

      def clear(options = nil)
      end

      def cleanup(options = nil)
      end

      def increment(name, amount = 1, options = nil)
      end

      def decrement(name, amount = 1, options = nil)
      end

      def delete_matched(matcher, options = nil)
      end

      def self.logger
        nil
      end

      def self.logger=(logger)
      end

      protected

      def read_entry(key, options) # :nodoc:
      end

      def write_entry(key, entry, options) # :nodoc:
        true
      end

      def delete_entry(key, options) # :nodoc:
        false
      end
    end
  end
end
