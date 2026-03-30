# frozen_string_literal: true

module ProductPricer
  module Rules
    # Interface for product pricer rules
    class Base
      attr_reader :config

      def initialize(config = nil)
        @config = case config
                  when String
                    load_config_file(config)
                  when Hash
                    config
                  when nil
                    nil
                  else
                    raise ArgumentError, 'Config must be a String (path) or Hash'
                  end
      end

      def priority
        100
      end

      def apply(context)
        raise NotImplementedError, "#{self.class} must implement #apply method"
      end

      protected

      def load_config_file(path)
        raise ProductPricer::ConfigNotFoundError, "Config file not found: #{path}" unless File.exist?(path)

        JSON.parse(File.read(path))
      rescue JSON::ParserError => e
        raise ProductPricer::Error, "Invalid JSON in config #{path}: #{e.message}"
      end
    end
  end
end
