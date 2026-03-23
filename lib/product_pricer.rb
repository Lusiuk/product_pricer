# frozen_string_literal: true

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
  # Base class of errors
  class Error < StandardError; end

  def self.calculate(product:, region:, promo_code: nil, quantity: 1, config_dir: nil)
    config_dir ||= File.join(File.dirname(__FILE__), '..', 'config')

    pricer = Pricer.new(
      delivery_config: File.join(config_dir, 'delivery.json'),
      tax_config: File.join(config_dir, 'taxes.json'),
      discount_config: File.join(config_dir, 'sales.json')
    )

    pricer.calculate(
      product:,
      region:,
      promo_code:,
      quantity:
    )
  end
end
