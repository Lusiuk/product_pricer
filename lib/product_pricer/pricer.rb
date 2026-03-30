# frozen_string_literal: true

module ProductPricer
  class Pricer
    def initialize
      @rules = []
    end

    def add_rule(rule)
      raise ArgumentError, 'Rule must be a Rules::Base instance' unless rule.is_a?(Rules::Base)

      @rules << rule
    end

    def add_rules(rules)
      raise ArgumentError, 'Rules must be an Array' unless rules.is_a?(Array)

      rules.each { |rule| add_rule(rule) } unless rules.empty?
    end

    def remove_rule(rule_class)
      @rules.reject! { |rule| rule.is_a?(rule_class) }
    end

    def remove_rules(rule_classes)
      rule_classes.each { |rule_class| remove_rule(rule_class) }
    end

    def calculate(product:, region:, promo_code: nil, quantity: 1)
      validate_inputs(product, region, quantity)

      context = CalculationContext.new(
        product:,
        region:,
        promo_code:,
        quantity:
      )

      @rules.sort_by(&:priority).each do |rule|
        context = rule.apply(context)
      end

      context
    end

    private

    def validate_inputs(product, region, quantity)
      raise ProductPricer::InvalidProductError, 'Product cannot be nil' unless product
      raise ProductPricer::InvalidProductPriceError, 'Product must have a price' unless product.respond_to?(:price)
      raise ProductPricer::InvalidRegionError, 'Region cannot be empty' if region.to_s.strip.empty?
      raise ProductPricer::InvalidQuantityError, 'Quantity must be positive' if quantity.to_i <= 0
    end
  end
end
