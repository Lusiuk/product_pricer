# frozen_string_literal: true

RSpec.describe ProductPricer::Pricer do
  let(:fixtures_dir) { File.join(__dir__, '..', 'fixtures') }
  let(:product) { OpenStruct.new(price: 99.99, category: 'electronics') }

  let(:pricer) do
    described_class.new(
      delivery_config: File.join(fixtures_dir, 'delivery.json'),
      tax_config: File.join(fixtures_dir, 'taxes.json'),
      discount_config: File.join(fixtures_dir, 'sales.json')
    )
  end

  describe '#calculate' do
    it 'calculates price with delivery and tax rules applied' do
      result = pricer.calculate(
        product:,
        region: 'EU',
        promo_code: 'FLAT10',
        quantity: 1
      )

      expect(result).to be_a(ProductPricer::CalculationContext)
      expect(result.base_price).to eq(BigDecimal('99.99'))
      expect(result.delivery_cost).to be > 0
      expect(result.tax_amount).to be > 0
      expect(result.discount_amount).to eq(BigDecimal('10'))
      expect(result.final_price).to be > 0
    end

    it 'applies promo discount' do
      result = pricer.calculate(
        product:,
        region: 'EU',
        promo_code: 'FLAT20',
        quantity: 1
      )

      expect(result.discount_amount).to eq(BigDecimal('20'))
      expect(result.applied_rules).to include('promo:FLAT20')
    end

    it 'calculates with quantity multiplier' do
      result = pricer.calculate(
        product:,
        region: 'US',
        quantity: 3
      )

      base = BigDecimal('99.99') * 3
      expect(result.base_price).to eq(base)
    end

    it 'raises error with invalid product' do
      expect do
        pricer.calculate(product: nil, region: 'US')
      end.to raise_error(ProductPricer::InvalidProductError)
    end

    it 'raises error with missing price' do
      invalid_product = OpenStruct.new(category: 'electronics')

      expect do
        pricer.calculate(product: invalid_product, region: 'US')
      end.to raise_error(ProductPricer::InvalidProductError)
    end

    it 'raises error with empty region' do
      expect do
        pricer.calculate(product:, region: '')
      end.to raise_error(ProductPricer::InvalidRegionError)
    end
  end
end
