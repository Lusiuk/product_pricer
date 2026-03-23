# frozen_string_literal: true

RSpec.describe ProductPricer::CalculationContext do
  let(:product) { OpenStruct.new(price: 99.99, category: 'electronics', weight: 2.5) }

  describe '#initialize' do
    it 'initializes context with product and region' do
      context = described_class.new(product:, region: 'EU', quantity: 3)

      expect(context.product.price).to eq(99.99)
      expect(context.region).to eq('EU')
      expect(context.quantity).to eq(3)
      expect(context.base_price).to eq(BigDecimal('299.97'))
    end

    it 'normalizes hash products to OpenStruct' do
      product_hash = { price: 50, category: 'food', weight: 1 }
      context = described_class.new(product: product_hash, region: 'US')

      expect(context.product).to be_a(OpenStruct)
      expect(context.product.price).to eq(50)
    end

    it 'initializes with default quantity of 1' do
      context = described_class.new(product:, region: 'EU')

      expect(context.quantity).to eq(1)
      expect(context.base_price).to eq(BigDecimal('99.99'))
    end
  end

  describe '#track_rule' do
    it 'tracks applied rules' do
      context = described_class.new(product:, region: 'EU')

      context.track_rule('delivery', { cost: 8.99 })
      context.track_rule('tax', { rate: 0.20 })

      expect(context.applied_rules).to eq(%w[delivery tax])
      expect(context.breakdown['delivery']).to eq({ cost: 8.99 })
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      context = described_class.new(product:, region: 'EU')
      context.delivery_cost = BigDecimal('8.99')

      result = context.to_h

      expect(result).to include(
        :base_price,
        :delivery_cost,
        :final_price,
        :applied_rules
      )
    end
  end
end
