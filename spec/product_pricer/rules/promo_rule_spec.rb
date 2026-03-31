# frozen_string_literal: true

require 'ostruct'

RSpec.describe ProductPricer::Rules::PromoRule do
  let(:fixtures_dir) { File.join(__dir__, '../../fixtures') }
  let(:config_path) { File.join(fixtures_dir, 'sales.json') }
  let(:product) { OpenStruct.new(price: 100, category: 'electronics', weight: 1) }

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

      expect(result.final_price).to eq(BigDecimal(90))
      expect(result.applied_rules).to include('promo:FLAT10')
    end

    it 'skips without promo code' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
      expect(result.applied_rules).to be_empty
    end

    it 'skips for invalid promo code' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'US', promo_code: 'INVALID')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'skips for non-applicable category' do
      rule = described_class.new(config_path)
      food_product = OpenStruct.new(price: 100, category: 'food', weight: 1)
      context = ProductPricer::CalculationContext.new(product: food_product, region: 'US', promo_code: 'SUMMER20')

      result = rule.apply(context)

      # SUMMER20 only applies to electronics and clothing
      expect(result.final_price).to eq(BigDecimal(100))
    end

    it 'applies percentage discount correctly' do
      rule = described_class.new(config_path)
      expensive_product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product: expensive_product, region: 'US', promo_code: 'SUMMER20')

      result = rule.apply(context)

      # 20% of 100 = 20 discount
      expect(result.final_price).to eq(BigDecimal(80))
    end

    it 'respects max discount limit for percentage' do
      rule = described_class.new(config_path)
      very_expensive = OpenStruct.new(price: 1000, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product: very_expensive, region: 'US', promo_code: 'SUMMER20')

      result = rule.apply(context)

      # 20% of 1000 = 200, but max_discount is 100
      expect(result.final_price).to eq(BigDecimal(900))
    end
  end
end
