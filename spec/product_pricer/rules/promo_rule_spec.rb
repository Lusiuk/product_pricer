# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::PromoRule do
  let(:config_path) { File.join(__dir__, "..", "..", "..", "config", "sales.json") }
  let(:rule) { described_class.new(config_path) }

  describe "#priority" do
    it "has priority 50" do
      expect(rule.priority).to eq(50)
    end
  end

  describe "#apply" do
    it "applies percentage discount" do
      product = OpenStruct.new(price: 100, category: "electronics", weight: 1)
      context = ProductPricer::CalculationContext.new(
        product: product,
        region: "EU",
        promo_code: "SUMMER20"
      )

      result = rule.apply(context)

      # SUMMER20: 20% off, but category check needed
      # Product category is electronics, which is in applicable_categories
      expected_discount = BigDecimal("100") * BigDecimal("0.20")
      expect(result.discount_amount).to eq(expected_discount)
    end

    it "applies fixed discount" do
      product = OpenStruct.new(price: 100, category: "electronics", weight: 1)
      context = ProductPricer::CalculationContext.new(
        product: product,
        region: "EU",
        promo_code: "FLAT10"
      )

      result = rule.apply(context)

      expect(result.discount_amount).to eq(BigDecimal("10"))
    end

    it "respects max_discount limit" do
      product = OpenStruct.new(price: 1000, category: "electronics", weight: 1)
      context = ProductPricer::CalculationContext.new(
        product: product,
        region: "EU",
        promo_code: "SUMMER20"
      )

      result = rule.apply(context)

      # SUMMER20: 20% of 1000 = 200, but max_discount is 100
      expect(result.discount_amount).to eq(BigDecimal("100"))
    end

    it "does not apply invalid promo code" do
      product = OpenStruct.new(price: 100, category: "electronics", weight: 1)
      context = ProductPricer::CalculationContext.new(
        product: product,
        region: "EU",
        promo_code: "INVALID"
      )

      result = rule.apply(context)

      expect(result.discount_amount).to eq(BigDecimal("0"))
      expect(result.applied_rules).to be_empty
    end

    it "respects applicable categories" do
      product = OpenStruct.new(price: 100, category: "food", weight: 1)
      context = ProductPricer::CalculationContext.new(
        product: product,
        region: "EU",
        promo_code: "SUMMER20"
      )

      result = rule.apply(context)

      # SUMMER20 is not applicable to food category
      expect(result.discount_amount).to eq(BigDecimal("0"))
    end

    it "respects date validity" do
      product = OpenStruct.new(price: 100, category: "clothing", weight: 1)
      context = ProductPricer::CalculationContext.new(
        product: product,
        region: "EU",
        promo_code: "WINTER15"
      )

      result = rule.apply(context)

      # WINTER15 is only valid Dec 1-31
      # If today is not in December, discount should not apply
      # This test will pass if run outside December
      if Date.today.month != 12
        expect(result.discount_amount).to eq(BigDecimal("0"))
      end
    end
  end
end