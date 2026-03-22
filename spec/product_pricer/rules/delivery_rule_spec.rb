# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::DeliveryRule do
  let(:config_path) { File.join(__dir__, "..", "..", "..", "config", "delivery.json") }
  let(:rule) { described_class.new(config_path) }
  let(:product) { OpenStruct.new(price: 100, weight: 2.5) }

  describe "#priority" do
    it "has priority 10" do
      expect(rule.priority).to eq(10)
    end
  end

  describe "#apply" do
    it "applies delivery cost based on region" do
      context = ProductPricer::CalculationContext.new(product: product, region: "EU")

      result = rule.apply(context)

      expect(result.delivery_cost).to be > 0
      expect(result.applied_rules).to include("delivery")
    end

    it "applies weight multiplier" do
      context = ProductPricer::CalculationContext.new(product: product, region: "US")

      result = rule.apply(context)

      # US: base_cost 5.99, weight_multiplier 0.5
      # Expected: 5.99 + (2.5 * 0.5) = 7.24
      expected = BigDecimal("5.99") + (BigDecimal("2.5") * BigDecimal("0.5"))
      expect(result.delivery_cost).to eq(expected)
    end

    it "handles unknown region" do
      context = ProductPricer::CalculationContext.new(product: product, region: "UNKNOWN")

      result = rule.apply(context)

      expect(result.delivery_cost).to eq(BigDecimal("0"))
    end

    it "returns context without config" do
      rule_no_config = described_class.new
      context = ProductPricer::CalculationContext.new(product: product, region: "EU")

      result = rule_no_config.apply(context)

      expect(result).to eq(context)
    end
  end
end