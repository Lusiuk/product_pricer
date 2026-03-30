# frozen_string_literal: true
require 'json'
require 'bigdecimal'
require 'date'

require_relative 'product_pricer/version'
require_relative 'product_pricer/errors'
require_relative 'product_pricer/calculation_context'
require_relative 'product_pricer/rules/base'
require_relative 'product_pricer/rules/delivery_rule'
require_relative 'product_pricer/rules/tax_rule'
require_relative 'product_pricer/rules/promo_rule'
require_relative 'product_pricer/rules/round_price_rule'
require_relative 'product_pricer/pricer'

# The main module of the ProductPricer library
module ProductPricer
  class Error < StandardError; end

  def self.calculate(product:, region:, promo_code: nil, quantity: 1, rules_config: nil)
    pricer = Pricer.new

    if rules_config
      rules = initialize_rules_from_config(rules_config)
      pricer.add_rules(rules)
    end

    pricer.calculate(
      product:,
      region:,
      promo_code:,
      quantity:
    )
  end

  def self.initialize_rules_from_config(rules_config)
    configs = normalize_configs(rules_config)

    configs.map do |config|
      rule_class = config['rule']
      raise ProductPricer::InvalidConfigError, 'Rule name missing in config' unless rule_class
      raise ProductPricer::InvalidRuleError, "Unknown rule: #{rule_class}" unless rule_class.is_a?(Rules::Base)

      rule_class.new(config)
    end
  end

  # Загружает конфиг из файла
  def self.load_config_file(path)
    raise ProductPricer::ConfigNotFoundError, "Config file not found: #{path}" unless File.exist?(path)

    JSON.parse(File.read(path))
  rescue JSON::ParserError => e
    raise ProductPricer::InvalidConfigError, "Invalid JSON in config #{path}: #{e.message}"
  end

  def self.normalize_configs(rules_config)
    case rules_config
    when String
      load_config_file(rules_config)
    when Array
      rules_config.map { |config| config.is_a?(String) ? load_config_file(config) : config }
    when Hash
      [rules_config]
    else
      raise ProductPricer::InvalidConfigError, 'rules_config must be a String, Array, or Hash'
    end
  end
end
