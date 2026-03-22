# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::RoundPriceRule do
  let(:rule) { described_class.new }

  describe "#priority" do
    it "has priority 999 (last)" do
      expect(rule.priority).to eq(999)
    end
  end

  describe "#apply" do
    it "calculates and rounds final price" do
      product = OpenStruct.new(price: 99.99, category: "electronics", weight: 1)
      context = ProductPricer::CalculationContext.new(product: product, region: "EU")

      context.delivery_cost = BigDecimal("8.99")
      context.tax_amount = BigDecimal("22.55")
      context.discount_amount = BigDecimal("10")

      result = rule.apply(context)

      # 99.99 + 8.99 + 22.55 - 10 = 121.53
      expected = BigDecimal("121.53")
      expect(result.final_price).to eq(expected)
    end

    it "rounds to 2 decimal places" do
      product = OpenStruct.new(price: 100, category: "food", weight: 1)
      context = ProductPricer::CalculationContext.new(product: product, region: "EU")

      context.delivery_cost = BigDecimal("5.555")
      context.tax_amount = BigDecimal("15.333")
      context.discount_amount = BigDecimal("0")

      result = rule.apply(context)

      # Should be rounded to 2 decimals
      expect(result.final_price.to_s.split(".")[1].length).to be <= 2
    end

    it "tracks round rule" do
      product = OpenStruct.new(price: 100, category: "electronics", weight: 1)
      context = ProductPricer::CalculationContext.new(product: product, region: "EU")

      result = rule.apply(context)

      expect(result.applied_rules).to include("round")
    end
  end
end