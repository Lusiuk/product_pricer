# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::DeliveryRule do
  let(:fixtures_dir) { File.join(__dir__, '..', '..', 'fixtures') }
  let(:config_path) { File.join(fixtures_dir, 'delivery.json') }
  let(:rule) { described_class.new(config_path) }
  let(:product) { OpenStruct.new(price: 100, weight: 2.5) }

  describe '#priority' do
    it 'has priority 10' do
      expect(rule.priority).to eq(10)
    end
  end

  describe '#apply' do
    it 'applies delivery cost based on region' do
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      expect(result.delivery_cost).to be > 0
      expect(result.applied_rules).to include('delivery')
    end

    it 'calculates delivery cost for different regions' do
      us_context = ProductPricer::CalculationContext.new(product:, region: 'US')
      eu_context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      us_result = rule.apply(us_context)
      eu_result = rule.apply(eu_context)

      # Both should have delivery cost
      expect(us_result.delivery_cost).to be > 0
      expect(eu_result.delivery_cost).to be > 0
      # But different values
      expect(us_result.delivery_cost).not_to eq(eu_result.delivery_cost)
    end

    it 'handles unknown region' do
      context = ProductPricer::CalculationContext.new(product:, region: 'UNKNOWN')

      result = rule.apply(context)

      expect(result.delivery_cost).to eq(BigDecimal(0))
    end

    it 'returns context without config' do
      rule_no_config = described_class.new
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule_no_config.apply(context)

      expect(result).to eq(context)
    end
  end
end
