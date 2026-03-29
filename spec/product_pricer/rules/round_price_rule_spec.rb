# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::RoundPriceRule do
  let(:rule) { described_class.new }

  describe '#priority' do
    it 'has priority 999 (last)' do
      expect(rule.priority).to eq(999)
    end
  end

  describe '#apply' do
    it 'calculates and rounds final price' do
      product = OpenStruct.new(price: 99.99, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      context.delivery_cost = BigDecimal('8.99')
      context.tax_amount = BigDecimal('22.55')
      context.discount_amount = BigDecimal(10)

      result = rule.apply(context)

      # 99.99 + 8.99 + 22.55 - 10 = 121.53
      expected = BigDecimal('121.53')
      expect(result.final_price).to eq(expected)
    end

    it 'rounds to 2 decimal places' do
      product = OpenStruct.new(price: 100, category: 'food', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      context.delivery_cost = BigDecimal('5.555')
      context.tax_amount = BigDecimal('15.333')
      context.discount_amount = BigDecimal(0)

      result = rule.apply(context)

      # Проверяем что значение округлено до 2 знаков после запятой
      # 100 + 5.555 + 15.333 = 120.888 -> 120.89
      expect(result.final_price).to eq(BigDecimal('120.89'))
    end

    it 'tracks round rule in applied_rules' do
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      expect(result.applied_rules).to include('round')
      expect(result.breakdown).to have_key('round')
    end
  end
end
