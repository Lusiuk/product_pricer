# frozen_string_literal: true

RSpec.describe ProductPricer::CalculationContext do
  before do
    stub_const('Product', Struct.new(:price, :category, :weight))
  end

  let(:product) { instance_double(Product, price: 99.99, category: 'electronics', weight: 2.5) }

  describe '#initialize' do
    it 'initializes context with product and region' do
      context = described_class.new(product:, region: 'EU', quantity: 3)

      expect(context.product.price).to eq(99.99)
    end

    it 'sets region correctly' do
      context = described_class.new(product:, region: 'EU', quantity: 3)

      expect(context.region).to eq('EU')
    end

    it 'sets quantity correctly' do
      context = described_class.new(product:, region: 'EU', quantity: 3)

      expect(context.quantity).to eq(3)
    end

    it 'calculates base price with quantity' do
      context = described_class.new(product:, region: 'EU', quantity: 3)

      expect(context.base_price).to eq(BigDecimal('299.97'))
    end

    it 'normalizes hash products to Struct-like object' do
      product_hash = { price: 50, category: 'food', weight: 1 }
      context = described_class.new(product: product_hash, region: 'US')

      expect(context.product.price).to eq(50)
    end

    it 'initializes with default quantity of 1' do
      context = described_class.new(product:, region: 'EU')

      expect(context.quantity).to eq(1)
    end

    it 'sets base price to product price when quantity is 1' do
      context = described_class.new(product:, region: 'EU')

      expect(context.base_price).to eq(BigDecimal('99.99'))
    end
  end

  describe '#track_rule' do
    it 'tracks applied rules with details' do
      context = described_class.new(product:, region: 'EU')

      context.track_rule('delivery', { cost: 8.99 })
      context.track_rule('tax', { rate: 0.20 })

      expect(context.applied_rules).to eq(%w[delivery tax])
    end

    it 'stores breakdown details correctly' do
      context = described_class.new(product:, region: 'EU')

      context.track_rule('delivery', { cost: 8.99 })

      expect(context.breakdown['delivery']).to eq({ cost: 8.99 })
    end
  end

  describe '#to_h' do
    it 'returns hash representation of context' do
      context = described_class.new(product:, region: 'EU')
      context.final_price = BigDecimal('120.50')
      context.track_rule('delivery', { cost: 8.99 })

      result = context.to_h

      expect(result).to be_a(Hash)
    end

    it 'includes base_price in hash' do
      context = described_class.new(product:, region: 'EU')
      context.final_price = BigDecimal('120.50')

      result = context.to_h

      expect(result[:base_price]).to eq(BigDecimal('99.99'))
    end

    it 'includes final_price in hash' do
      context = described_class.new(product:, region: 'EU')
      context.final_price = BigDecimal('120.50')

      result = context.to_h

      expect(result[:final_price]).to eq(BigDecimal('120.50'))
    end

    it 'includes applied_rules in hash' do
      context = described_class.new(product:, region: 'EU')
      context.track_rule('delivery', { cost: 8.99 })

      result = context.to_h

      expect(result[:applied_rules]).to eq(['delivery'])
    end

    it 'includes breakdown in hash' do
      context = described_class.new(product:, region: 'EU')
      context.track_rule('delivery', { cost: 8.99 })

      result = context.to_h

      expect(result[:breakdown]).to include('delivery' => { cost: 8.99 })
    end
  end

  describe 'attribute accessors' do
    it 'has readable product attribute' do
      context = described_class.new(product:, region: 'EU')

      expect(context.product).not_to be_nil
    end

    it 'has readable region attribute' do
      context = described_class.new(product:, region: 'EU', promo_code: 'FLAT10')

      expect(context.region).to eq('EU')
    end

    it 'allows setting base_price' do
      context = described_class.new(product:, region: 'EU')

      context.base_price = BigDecimal(100)

      expect(context.base_price).to eq(BigDecimal(100))
    end

    it 'allows setting final_price' do
      context = described_class.new(product:, region: 'EU')

      context.final_price = BigDecimal(120)

      expect(context.final_price).to eq(BigDecimal(120))
    end
  end
end
