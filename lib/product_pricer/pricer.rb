# frozen_string_literal: true

module ProductPricer
  class Pricer
    def initialize(delivery_config: nil, tax_config: nil, discount_config: nil)
      @delivery_config = delivery_config
      @tax_config = tax_config
      @discount_config = discount_config
      @rules = initialize_rules
    end

    def calculate(product:, region:, promo_code: nil, quantity: 1, user_tier: nil)
      validate_inputs(product, region)

      context = CalculationContext.new(
        product:,
        region:,
        promo_code:,
        quantity:,
        user_tier:
      )

      # Execute rules in priority order
      @rules.sort_by(&:priority).each do |rule|
        context = rule.apply(context)
      end

      context
    end

    private

    def initialize_rules
      [
        Rules::DeliveryRule.new(@delivery_config),
        Rules::TaxRule.new(@tax_config),
        Rules::PromoRule.new(@discount_config),
        Rules::RoundPriceRule.new
      ]
    end

    def validate_inputs(product, region)
      raise ProductPricer::InvalidProductError, 'Product cannot be nil' unless product
      raise ProductPricer::InvalidProductError, 'Product must have a price' unless product.respond_to?(:price)
      raise ProductPricer::InvalidRegionError, 'Region cannot be empty' if region.to_s.strip.empty?
    end
  end
end
