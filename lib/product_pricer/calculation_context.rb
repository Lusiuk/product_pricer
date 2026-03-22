# frozen_string_literal: true

require "bigdecimal"
require "ostruct"

module ProductPricer
  class CalculationContext
    attr_reader :product, :region, :promo_code, :quantity, :user_tier
    attr_accessor :base_price, :delivery_cost, :weight_surcharge, :tax_amount, :discount_amount, :final_price
    attr_reader :applied_rules, :breakdown

    def initialize(product:, region:, promo_code: nil, quantity: 1, user_tier: nil)
      @product = normalize_product(product)
      @region = region
      @promo_code = promo_code
      @quantity = quantity
      @user_tier = user_tier

      @base_price = BigDecimal(@product.price.to_s) * quantity
      @delivery_cost = BigDecimal("0")
      @weight_surcharge = BigDecimal("0")
      @tax_amount = BigDecimal("0")
      @discount_amount = BigDecimal("0")
      @final_price = @base_price

      @applied_rules = []
      @breakdown = {}
    end

    def track_rule(rule_name, details = {})
      @applied_rules << rule_name
      @breakdown[rule_name] = details
    end

    def to_h
      {
        base_price: @base_price,
        delivery_cost: @delivery_cost,
        weight_surcharge: @weight_surcharge,
        tax_amount: @tax_amount,
        discount_amount: @discount_amount,
        final_price: @final_price,
        applied_rules: @applied_rules,
        breakdown: @breakdown
      }
    end

    private

    def normalize_product(product)
      if product.is_a?(Hash)
        OpenStruct.new(product)
      else
        product
      end
    end
  end
end