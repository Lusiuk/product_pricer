# frozen_string_literal: true

RSpec.describe ProductPricer::Pricer do
  let(:fixtures_dir) { File.join(__dir__, '..', 'fixtures') }
  let(:product) { instance_double(Product, price: 99.99, category: 'electronics', weight: 2.5) }

  before do
    stub_const('Product', Struct.new(:price, :category, :weight))
  end

  describe '#initialize' do
    it 'creates pricer with empty rules' do
      pricer = described_class.new

      expect(pricer).to be_a(described_class)
    end
  end

  describe '#add_rule' do
    it 'adds a single rule' do
      pricer = described_class.new
      delivery_rule = ProductPricer::Rules::DeliveryRule.new(
        File.join(fixtures_dir, 'delivery.json')
      )

      pricer.add_rule(delivery_rule)
      result = pricer.calculate(product:, region: 'EU')

      expect(result.applied_rules).to include('delivery')
    end

    it 'raises error if rule is not Rules::Base instance' do
      pricer = described_class.new

      expect do
        pricer.add_rule('not_a_rule')
      end.to raise_error(ArgumentError)
    end
  end

  describe '#add_rules' do
    it 'adds multiple rules at once' do
      pricer = described_class.new
      rules = [
        ProductPricer::Rules::DeliveryRule.new(File.join(fixtures_dir, 'delivery.json')),
        ProductPricer::Rules::TaxRule.new(File.join(fixtures_dir, 'taxes.json'))
      ]

      pricer.add_rules(rules)
      result = pricer.calculate(product:, region: 'EU')

      expect(result.applied_rules).to include('delivery', 'tax')
    end

    it 'raises error if argument is not array' do
      pricer = described_class.new

      expect do
        pricer.add_rules('not_an_array')
      end.to raise_error(ArgumentError)
    end
  end

  describe '#remove_rule' do
    it 'removes rule by class' do
      pricer = described_class.new
      pricer.add_rule(ProductPricer::Rules::DeliveryRule.new(
                        File.join(fixtures_dir, 'delivery.json')
                      ))

      pricer.remove_rule(ProductPricer::Rules::DeliveryRule)
      result = pricer.calculate(product:, region: 'EU')

      expect(result.applied_rules).not_to include('delivery')
    end
  end

  describe '#calculate' do
    let(:pricer) do
      p = described_class.new
      p.add_rule(ProductPricer::Rules::DeliveryRule.new(
                   File.join(fixtures_dir, 'delivery.json')
                 ))
      p.add_rule(ProductPricer::Rules::TaxRule.new(
                   File.join(fixtures_dir, 'taxes.json')
                 ))
      p.add_rule(ProductPricer::Rules::PromoRule.new(
                   File.join(fixtures_dir, 'sales.json')
                 ))
      p.add_rule(ProductPricer::Rules::RoundPriceRule.new)
      p
    end

    it 'calculates price with all rules applied' do
      result = pricer.calculate(
        product:,
        region: 'EU',
        promo_code: 'FLAT10',
        quantity: 1
      )

      expect(result).to be_a(ProductPricer::CalculationContext)
    end

    it 'includes all applied rules' do
      result = pricer.calculate(
        product:,
        region: 'EU',
        promo_code: 'FLAT10',
        quantity: 1
      )

      expect(result.applied_rules).to include('delivery', 'tax', 'promo:FLAT10', 'round')
    end

    it 'returns positive final price' do
      result = pricer.calculate(
        product:,
        region: 'EU',
        promo_code: 'FLAT10',
        quantity: 1
      )

      expect(result.final_price).to be > 0
    end

    it 'applies promo discount correctly' do
      result = pricer.calculate(
        product:,
        region: 'EU',
        promo_code: 'FLAT20',
        quantity: 1
      )

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

    it 'applies rules in correct priority order' do
      result = pricer.calculate(product:, region: 'EU')

      expect(result.applied_rules[0]).to eq('delivery')
    end

    it 'raises error with invalid product' do
      expect do
        pricer.calculate(product: nil, region: 'US')
      end.to raise_error(ProductPricer::InvalidProductError)
    end

    it 'raises error with missing price' do
      invalid_product = instance_double(Product, category: 'electronics')
      allow(invalid_product).to receive(:respond_to?).with(:price).and_return(false)

      expect do
        pricer.calculate(product: invalid_product, region: 'US')
      end.to raise_error(ProductPricer::InvalidProductPriceError)
    end

    it 'raises error with empty region' do
      expect do
        pricer.calculate(product:, region: '')
      end.to raise_error(ProductPricer::InvalidRegionError)
    end

    it 'raises error with non-positive quantity' do
      expect do
        pricer.calculate(product:, region: 'US', quantity: 0)
      end.to raise_error(ProductPricer::InvalidQuantityError)
    end
  end
end
