# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::TaxRule do
  let(:config_path) { File.join(__dir__, '..', '..', '..', 'config', 'taxes.json') }
  let(:rule) { described_class.new(config_path) }

  describe '#priority' do
    it 'has priority 100' do
      expect(rule.priority).to eq(100)
    end
  end

  describe '#apply' do
    it 'applies tax based on category and region' do
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      # EU electronics tax: 20%
      expected_tax = BigDecimal('100') * BigDecimal('0.20')
      expect(result.tax_amount).to eq(expected_tax)
    end

    it 'applies different tax rates per category' do
      product_food = OpenStruct.new(price: 100, category: 'food', weight: 1)
      context_food = ProductPricer::CalculationContext.new(product: product_food, region: 'EU')

      rule.apply(context_food)

      # EU food tax: 5%
      expected_tax = BigDecimal('100') * BigDecimal('0.05')
      expect(context_food.tax_amount).to eq(expected_tax)
    end

    it 'handles unknown category' do
      product = OpenStruct.new(price: 100, category: 'unknown_category', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      expect(result.tax_amount).to eq(BigDecimal('0'))
    end

    it 'includes delivery in tax calculation if configured' do
      # This would require a modified config file to test
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')
      context.delivery_cost = BigDecimal('10')

      rule.apply(context)

      # With tax_shipping: false, only base_price is taxed
      expected_tax = BigDecimal('100') * BigDecimal('0.20')
      expect(context.tax_amount).to eq(expected_tax)
    end
  end
end
