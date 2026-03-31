# frozen_string_literal: true

require 'ostruct'

RSpec.describe ProductPricer::Rules::DeliveryRule do
  let(:fixtures_dir) { File.join(__dir__, '../../fixtures') }
  let(:config_path) { File.join(fixtures_dir, 'delivery.json') }
  let(:product) { OpenStruct.new(price: 100, category: 'electronics', weight: 2.5) }

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
      product_no_weight = OpenStruct.new(price: 100, category: 'electronics')
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
      # Product with 5kg should get different surcharge than 2.5kg
      heavy_product = OpenStruct.new(price: 100, category: 'electronics', weight: 5)
      light_context = ProductPricer::CalculationContext.new(product:, region: 'EU')
      heavy_context = ProductPricer::CalculationContext.new(product: heavy_product, region: 'EU')

      light_result = rule.apply(light_context)
      heavy_result = rule.apply(heavy_context)

      # Heavy product should have higher delivery cost
      expect(heavy_result.final_price - heavy_context.base_price)
        .to be > (light_result.final_price - light_context.base_price)
    end
  end
end
