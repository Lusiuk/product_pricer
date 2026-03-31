# frozen_string_literal: true

require 'ostruct'

RSpec.describe ProductPricer do
  it 'has a version number' do
    expect(ProductPricer::VERSION).not_to be nil
  end

  describe '.calculate' do
    let(:product) { OpenStruct.new(price: 100, category: 'electronics', weight: 1) }

    context 'without rules' do
      it 'returns context with base price as final price' do
        result = described_class.calculate(product:, region: 'US')

        expect(result).to be_a(ProductPricer::CalculationContext)
        expect(result.base_price).to eq(BigDecimal('100'))
        expect(result.final_price).to eq(BigDecimal('100'))
      end

      it 'applies quantity multiplier' do
        result = described_class.calculate(product:, region: 'US', quantity: 3)

        expect(result.base_price).to eq(BigDecimal('300'))
        expect(result.final_price).to eq(BigDecimal('300'))
      end

      it 'accepts OpenStruct product' do
        openstruct_product = OpenStruct.new(price: 50, category: 'food')
        result = described_class.calculate(product: openstruct_product, region: 'US')

        expect(result.base_price).to eq(BigDecimal('50'))
      end
    end

    context 'with single rule config (file path)' do
      let(:fixtures_dir) { File.join(__dir__, 'fixtures') }

      it 'applies delivery rule' do
        delivery_config = File.join(fixtures_dir, 'delivery.json')
        product_with_weight = OpenStruct.new(price: 100, category: 'electronics', weight: 2.5)

        result = described_class.calculate(
          product: product_with_weight,
          region: 'EU',
          rules_config: delivery_config
        )

        expect(result.applied_rules).to include('delivery')
        expect(result.final_price).to be > BigDecimal('100')
      end

      it 'applies tax rule' do
        tax_config = File.join(fixtures_dir, 'taxes.json')
        result = described_class.calculate(product:, region: 'EU', rules_config: tax_config)

        # EU tax on electronics is 20%
        expect(result.applied_rules).to include('tax')
        expect(result.final_price).to eq(BigDecimal('120'))
      end

      it 'applies promo rule' do
        promo_config = File.join(fixtures_dir, 'sales.json')
        result = described_class.calculate(
          product:,
          region: 'US',
          promo_code: 'FLAT10',
          rules_config: promo_config
        )

        expect(result.applied_rules).to include('promo:FLAT10')
        expect(result.final_price).to eq(BigDecimal('90'))
      end
    end

    context 'with multiple rule configs (array)' do
      let(:fixtures_dir) { File.join(__dir__, 'fixtures') }

      it 'applies all rules in priority order' do
        product_full = OpenStruct.new(price: 100, category: 'electronics', weight: 2.5)
        delivery_config = File.join(fixtures_dir, 'delivery.json')
        tax_config = File.join(fixtures_dir, 'taxes.json')

        result = described_class.calculate(
          product: product_full,
          region: 'EU',
          rules_config: [delivery_config, tax_config]
        )

        expect(result.applied_rules).to include('delivery', 'tax')
        # Base 100 + delivery ~10.87 + tax on 110.87 ~22.17 = ~133.04
        expect(result.final_price).to be > BigDecimal('130')
      end

      it 'applies promo, delivery and tax together' do
        product_full = OpenStruct.new(price: 100, category: 'electronics', weight: 2.5)
        delivery_config = File.join(fixtures_dir, 'delivery.json')
        tax_config = File.join(fixtures_dir, 'taxes.json')
        promo_config = File.join(fixtures_dir, 'sales.json')

        result = described_class.calculate(
          product: product_full,
          region: 'EU',
          promo_code: 'FLAT10',
          rules_config: [delivery_config, tax_config, promo_config]
        )

        expect(result.applied_rules).to include('delivery', 'tax', 'promo:FLAT10')
      end
    end

    context 'with hash config' do
      it 'applies rule from hash configuration' do
        config = {
          'rule' => 'Rules::TaxRule',
          'categories' => {
            'electronics' => { 'US' => '0.10', 'EU' => '0.20' }
          },
          'rules' => { 'compound_tax' => false }
        }

        result = described_class.calculate(product:, region: 'US', rules_config: config)

        expect(result.applied_rules).to include('tax')
        expect(result.final_price).to eq(BigDecimal('110'))
      end
    end

    context 'error handling' do
      it 'raises InvalidProductError if product is nil' do
        expect do
          described_class.calculate(product: nil, region: 'US')
        end.to raise_error(ProductPricer::InvalidProductError)
      end

      it 'raises InvalidProductPriceError if product has no price' do
        invalid_product = OpenStruct.new(category: 'electronics')
        expect do
          described_class.calculate(product: invalid_product, region: 'US')
        end.to raise_error(ProductPricer::InvalidProductPriceError)
      end

      it 'raises InvalidRegionError if region is empty' do
        expect do
          described_class.calculate(product:, region: '')
        end.to raise_error(ProductPricer::InvalidRegionError)
      end

      it 'raises InvalidQuantityError if quantity is zero' do
        expect do
          described_class.calculate(product:, region: 'US', quantity: 0)
        end.to raise_error(ProductPricer::InvalidQuantityError)
      end

      it 'raises InvalidQuantityError if quantity is negative' do
        expect do
          described_class.calculate(product:, region: 'US', quantity: -1)
        end.to raise_error(ProductPricer::InvalidQuantityError)
      end

      it 'raises ConfigNotFoundError if config file does not exist' do
        expect do
          described_class.calculate(
            product:,
            region: 'US',
            rules_config: '/nonexistent/path.json'
          )
        end.to raise_error(ProductPricer::ConfigNotFoundError)
      end

      it 'raises InvalidConfigError if JSON is invalid' do
        # Create temp directory if it doesn't exist
        fixtures_dir = File.join(__dir__, 'fixtures')
        Dir.mkdir(fixtures_dir) unless Dir.exist?(fixtures_dir)

        invalid_file = File.join(fixtures_dir, 'invalid_temp.json')
        File.write(invalid_file, '{invalid json}')

        expect do
          described_class.calculate(
            product:,
            region: 'US',
            rules_config: invalid_file
          )
        end.to raise_error(ProductPricer::InvalidConfigError)

        File.delete(invalid_file) if File.exist?(invalid_file)
      end

      it 'raises InvalidRuleError if rule name is unknown' do
        config = { 'rule' => 'Rules::UnknownRule', 'data' => {} }

        expect do
          described_class.calculate(product:, region: 'US', rules_config: config)
        end.to raise_error(ProductPricer::InvalidRuleError)
      end

      it 'raises InvalidConfigError if rule name is missing' do
        config = { 'data' => {} }

        expect do
          described_class.calculate(product:, region: 'US', rules_config: config)
        end.to raise_error(ProductPricer::InvalidConfigError)
      end
    end
  end
end