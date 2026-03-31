# frozen_string_literal: true

require 'ostruct'

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

    it 'normalizes hash products to Struct-like object' do
      product_hash = { price: 50, category: 'food', weight: 1 }
      context = described_class.new(product: product_hash, region: 'US')

      expect(context.product.price).to eq(50)
      expect(context.product.category).to eq('food')
    end

    it 'initializes with default quantity of 1' do
      context = described_class.new(product:, region: 'EU')

      expect(context.quantity).to eq(1)
      expect(context.base_price).to eq(BigDecimal('99.99'))
    end

    it 'raises error if product does not respond to price' do
      invalid_product = 'not_a_product'

      expect do
        described_class.new(product: invalid_product, region: 'US')
      end.to raise_error(ArgumentError)
    end
  end

  describe '#track_rule' do
    it 'tracks applied rules with details' do
      context = described_class.new(product:, region: 'EU')

      context.track_rule('delivery', { cost: 8.99 })
      context.track_rule('tax', { rate: 0.20 })

      expect(context.applied_rules).to eq(%w[delivery tax])
      expect(context.breakdown['delivery']).to eq({ cost: 8.99 })
      expect(context.breakdown['tax']).to eq({ rate: 0.20 })
    end
  end

  describe '#to_h' do
    it 'returns hash representation of context' do
      context = described_class.new(product:, region: 'EU')
      context.final_price = BigDecimal('120.50')
      context.track_rule('delivery', { cost: 8.99 })

      result = context.to_h

      expect(result).to be_a(Hash)
      expect(result[:base_price]).to eq(BigDecimal('99.99'))
      expect(result[:final_price]).to eq(BigDecimal('120.50'))
      expect(result[:applied_rules]).to eq(['delivery'])
      expect(result[:breakdown]).to include('delivery' => { cost: 8.99 })
    end
  end

  describe 'attribute accessors' do
    it 'has readable attributes' do
      context = described_class.new(product:, region: 'EU', promo_code: 'FLAT10')

      expect(context.product).to be_a(OpenStruct)
      expect(context.region).to eq('EU')
      expect(context.promo_code).to eq('FLAT10')
      expect(context.quantity).to eq(1)
      expect(context.applied_rules).to be_a(Array)
      expect(context.breakdown).to be_a(Hash)
    end

    it 'allows setting base_price and final_price' do
      context = described_class.new(product:, region: 'EU')

      context.base_price = BigDecimal(100)
      context.final_price = BigDecimal(120)

      expect(context.base_price).to eq(BigDecimal(100))
      expect(context.final_price).to eq(BigDecimal(120))
    end
  end
end
