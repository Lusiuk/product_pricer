# frozen_string_literal: true

RSpec.describe ProductPricer::Pricer do
  let(:config_dir) { File.join(__dir__, "..", "..", "config") }
  let(:product) { OpenStruct.new(price: 99.99, category: "electronics", weight: 2.5) }

  let(:pricer) do
    described_class.new(
      delivery_config: File.join(config_dir, "delivery.json"),
      tax_config: File.join(config_dir, "taxes.json"),
      discount_config: File.join(config_dir, "sales.json")
    )
  end

  describe "#calculate" do
    it "calculates price with all rules applied" do
      result = pricer.calculate(
        product: product,
        region: "EU",
        promo_code: "FLAT10",
        quantity: 1,
        user_tier: nil
      )

      expect(result).to be_a(ProductPricer::CalculationContext)
      expect(result.base_price).to eq(BigDecimal("99.99"))
      expect(result.delivery_cost).to be > 0
      expect(result.tax_amount).to be > 0
      expect(result.discount_amount).to eq(BigDecimal("10"))
      expect(result.final_price).to be > 0
    end

    it "applies multiple discounts (promo + loyalty)" do
      result = pricer.calculate(
        product: product,
        region: "EU",
        promo_code: "FLAT10",
        quantity: 1,
        user_tier: "gold"
      )

      expect(result.discount_amount).to be > BigDecimal("10")
      expect(result.applied_rules).to include("promo:FLAT10", "loyalty:gold")
    end

    it "calculates with quantity multiplier" do
      result = pricer.calculate(
        product: product,
        region: "US",
        quantity: 3
      )

      base = BigDecimal("99.99") * 3
      expect(result.base_price).to eq(base)
    end

    it "raises error with invalid product" do
      expect do
        pricer.calculate(product: nil, region: "US")
      end.to raise_error(ProductPricer::InvalidProductError)
    end

    it "raises error with missing price" do
      invalid_product = OpenStruct.new(category: "electronics")

      expect do
        pricer.calculate(product: invalid_product, region: "US")
      end.to raise_error(ProductPricer::InvalidProductError)
    end

    it "raises error with empty region" do
      expect do
        pricer.calculate(product: product, region: "")
      end.to raise_error(ProductPricer::InvalidRegionError)
    end
  end
end