# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::RoundPriceRule do
  before do
    stub_const('Product', Struct.new(:price, :category, :weight))
  end

  let(:product) { instance_double(Product, price: 100, category: 'electronics', weight: 1) }

  describe '#priority' do
    it 'returns highest priority (executed last)' do
      rule = described_class.new
      expect(rule.priority).to eq(999)
    end
  end

  describe '#apply' do
    it 'rounds final price to 2 decimal places' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      context.final_price = BigDecimal('99.999')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal('100.00'))
    end

    it 'rounds down correctly' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      context.final_price = BigDecimal('99.991')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal('99.99'))
    end

    it 'rounds up correctly' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      context.final_price = BigDecimal('99.996')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal('100.00'))
    end

    it 'tracks the rounding rule' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      context.final_price = BigDecimal('99.999')

      result = rule.apply(context)

      expect(result.applied_rules).to include('round')
      expect(result.breakdown['round']).to eq({ final_price: BigDecimal('100.00') })
    end

    it 'returns the context unchanged when price already rounded' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      original_price = BigDecimal('99.99')
      context.final_price = original_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'handles very small prices' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      context.final_price = BigDecimal('0.001')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal('0.00'))
    end

    it 'handles large prices' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US')
      context.final_price = BigDecimal('9999999.999')

      result = rule.apply(context)

      expect(result.final_price).to eq(BigDecimal('10000000.00'))
    end

    it 'preserves context object' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'US', promo_code: 'TEST')
      context.final_price = BigDecimal('99.999')

      result = rule.apply(context)

      expect(result).to be(context)
      expect(result.promo_code).to eq('TEST')
    end

    it 'is typically the last rule in execution chain' do
      rule = described_class.new
      expect(rule.priority).to be > 100
    end
  end

  describe 'integration with calculation flow' do
    it 'rounds the final result after all other rules' do
      product = instance_double(Product, price: 99.99, category: 'electronics', weight: 2.5)
      pricer = ProductPricer::Pricer.new

      fixtures_dir = File.join(__dir__, '../../fixtures')
      pricer.add_rule(ProductPricer::Rules::DeliveryRule.new(
                        File.join(fixtures_dir, 'delivery.json')
                      ))
      pricer.add_rule(ProductPricer::Rules::TaxRule.new(
                        File.join(fixtures_dir, 'taxes.json')
                      ))
      pricer.add_rule(described_class.new)

      result = pricer.calculate(product:, region: 'EU')

      shifted_price = result.final_price * 100
      expect(shifted_price % 1).to eq(0)
      expect(result.final_price).to be > 0
      expect(result.applied_rules.last).to eq('round')
    end
  end
end
