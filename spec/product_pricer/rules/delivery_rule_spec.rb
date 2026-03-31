# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::DeliveryRule do
  let(:fixtures_dir) { File.join(__dir__, '..', '..', 'fixtures') }
  let(:config_path) { File.join(fixtures_dir, 'delivery.json') }
  let(:product) { double(price: 100, category: 'electronics', weight: 2.5) }

  describe '#priority' do
    it 'returns lower priority number' do
      rule = described_class.new(config_path)

      expect(rule.priority).to eq(10)
    end
  end

  describe '#apply' do
    it 'adds delivery cost to final price' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      expect(result.final_price).to be > context.base_price
    end

    it 'tracks delivery rule' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      expect(result.applied_rules).to include('delivery')
    end

    it 'skips calculation without config' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'skips calculation without product weight' do
      rule = described_class.new(config_path)
      product_no_weight = double(price: 100, category: 'electronics')
      allow(product_no_weight).to receive(:weight).and_return(nil)
      context = ProductPricer::CalculationContext.new(product: product_no_weight, region: 'EU')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'skips calculation for unknown region' do
      rule = described_class.new(config_path)
      context = ProductPricer::CalculationContext.new(product:, region: 'UNKNOWN')
      original_price = context.final_price

      result = rule.apply(context)

      expect(result.final_price).to eq(original_price)
    end

    it 'calculates delivery with weight surcharge' do
      rule = described_class.new(config_path)
      heavy_product = double(price: 100, category: 'electronics', weight: 5)
      light_context = ProductPricer::CalculationContext.new(product:, region: 'EU')
      heavy_context = ProductPricer::CalculationContext.new(product: heavy_product, region: 'EU')

      light_result = rule.apply(light_context)
      heavy_result = rule.apply(heavy_context)

      light_delivery = light_result.final_price - light_context.base_price
      heavy_delivery = heavy_result.final_price - heavy_context.base_price
      expect(heavy_delivery).to be > light_delivery
    end
  end
end