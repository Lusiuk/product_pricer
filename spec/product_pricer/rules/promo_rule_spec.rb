# frozen_string_literal: true

require 'date'

RSpec.describe ProductPricer::Rules::PromoRule do
  let(:fixtures_dir) { File.join(__dir__, '..', '..', 'fixtures') }
  let(:product) { instance_double(Product, price: 99.99, category: 'electronics', weight: 1) }
  let(:config_path) { File.join(fixtures_dir, 'sales.json') }

  before do
    stub_const('Product', Struct.new(:price, :category, :weight))
  end

  describe '#priority' do
    it 'returns medium priority' do
      rule = described_class.new(config_path)

      expect(rule.priority).to eq(50)
    end
  end

  describe '#apply' do
    it 'applies fixed discount' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'US', promo_code: 'FLAT10')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal('89.99'))
    end

    it 'skips without promo code' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'skips for invalid promo code' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'US', promo_code: 'INVALID')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'skips expired promo code' do
      rule = described_class.new(config_path)
      expired_product = instance_double(Product, price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product: expired_product, region: 'EU', promo_code: 'SUMMER20')

      allow(Date).to receive(:today).and_return(Date.new(2034, 9, 1))

      result = rule.apply(context)
      expect(result.applied_rules).not_to include('promo:SUMMER20')
      expect(result.applied_rules).to be_empty
    end

    it 'skips for non-applicable category' do
      rule = described_class.new(config_path)
      food_product = instance_double(Product, price: 100, category: 'food', weight: 1)
      context = ProductPricer::CalculationContext.new(product: food_product, region: 'US', promo_code: 'SUMMER20')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal(100))
    end

    it 'applies percentage discount correctly' do
      rule = described_class.new(config_path)
      expensive_product = instance_double(Product, price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product: expensive_product, region: 'US', promo_code: 'SUMMER20')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal(80))
    end

    it 'respects max discount limit for percentage' do
      rule = described_class.new(config_path)
      very_expensive = instance_double(Product, price: 1000, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product: very_expensive, region: 'US', promo_code: 'SUMMER20')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal(900))
    end
  end
end
