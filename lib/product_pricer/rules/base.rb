# frozen_string_literal: true

require 'json'

module ProductPricer
  module Rules
    class Base
      attr_reader :config

      def initialize(config_path = nil)
        @config_path = config_path
        @config = load_config if config_path && File.exist?(config_path)
      end

      def priority
        100
      end

      def apply(context)
        raise NotImplementedError, "#{self.class} must implement #apply method"
      end

      protected

      def load_config
        JSON.parse(File.read(@config_path))
      rescue JSON::ParserError => e
        raise ProductPricer::Error, "Invalid JSON in config #{@config_path}: #{e.message}"
      rescue Errno::ENOENT => e
        raise ProductPricer::ConfigNotFoundError, "Config file not found: #{@config_path}"
      end
    end
  end
end
