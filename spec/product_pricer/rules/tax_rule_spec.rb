# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::TaxRule do
  let(:fixtures_dir) { File.join(__dir__, '../../fixtures') }
  let(:product) { instance_double(Product, price: 100, category: 'electronics', weight: 1) }
  let(:config_path) { File.join(fixtures_dir, 'taxes.json') }

  before do
    stub_const('Product', Struct.new(:price, :category, :weight))
  end

  describe '#priority' do
    it 'returns higher priority for tax calculation' do
      rule = described_class.new(config_path)
      expect(rule.priority).to eq(100)
    end
  end

  describe '#apply' do
    it 'adds tax to final price' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      # EU tax on electronics is 20% = 20
      expect(result.final_price).to eq(BigDecimal(120))
      expect(result.applied_rules).to include('tax')
    end

    it 'calculates different tax for different regions' do
      rule = described_class.new(config_path)
      eu_context = ProductPricer::CalculationContext.new(product:, region: 'EU')
      us_context = ProductPricer::CalculationContext.new(product:, region: 'US')

      eu_result = rule.apply(eu_context)
      us_result = rule.apply(us_context)

      expect(eu_result.final_price).to eq(BigDecimal(120))
      expect(us_result.final_price).to eq(BigDecimal(100))
    end

    it 'skips calculation without category' do
      rule = described_class.new(config_path)
      product_no_category = instance_double(Product, price: 100, category: nil, weight: 1)
      context = ProductPricer::CalculationContext.new(product: product_no_category, region: 'EU')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'skips calculation for unknown category' do
      rule = described_class.new(config_path)
      product_unknown = instance_double(Product, price: 100, category: 'unknown_category', weight: 1)
      context = ProductPricer::CalculationContext.new(product: product_unknown, region: 'EU')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'applies different tax rates for different categories' do
      rule = described_class.new(config_path)
      electronics = instance_double(Product, price: 100, category: 'electronics', weight: 1)
      food = instance_double(Product, price: 100, category: 'food', weight: 1)

      elec_context = ProductPricer::CalculationContext.new(product: electronics, region: 'EU')
      food_context = ProductPricer::CalculationContext.new(product: food, region: 'EU')

      elec_result = rule.apply(elec_context)
      food_result = rule.apply(food_context)

      expect(elec_result.final_price).to eq(BigDecimal(120))
      expect(food_result.final_price).to eq(BigDecimal(105))
    end
  end
end
