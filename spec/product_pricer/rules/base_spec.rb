# frozen_string_literal: true

require 'ostruct'

RSpec.describe ProductPricer::Rules::Base do
  describe '#initialize' do
    it 'initializes with config from hash' do
      config = { 'key' => 'value' }
      rule = described_class.new(config)

      expect(rule.config).to eq(config)
    end

    it 'initializes with config from file path' do
      fixtures_dir = File.join(__dir__, '../../fixtures')
      config_path = File.join(fixtures_dir, 'delivery.json')

      rule = described_class.new(config_path)

      expect(rule.config).to be_a(Hash)
      expect(rule.config).to have_key('rule')
    end

    it 'initializes with nil config' do
      rule = described_class.new(nil)

      expect(rule.config).to be_nil
    end

    it 'initializes without arguments' do
      rule = described_class.new

      expect(rule.config).to be_nil
    end

    it 'raises error with invalid config type' do
      expect do
        described_class.new(123)
      end.to raise_error(ArgumentError, 'Config must be a String (path) or Hash')
    end

    it 'raises error if config file does not exist' do
      expect do
        described_class.new('/nonexistent/path/config.json')
      end.to raise_error(ProductPricer::ConfigNotFoundError)
    end

    it 'raises error with invalid JSON in config file' do
      invalid_json_file = File.join(__dir__, '../../fixtures', 'invalid.json')

      # Create invalid JSON file for this test
      File.write(invalid_json_file, '{invalid json}')

      expect do
        described_class.new(invalid_json_file)
      end.to raise_error(ProductPricer::Error, /Invalid JSON/)

      # Cleanup
      File.delete(invalid_json_file) if File.exist?(invalid_json_file)
    end
  end

  describe '#priority' do
    it 'returns default priority of 100' do
      rule = described_class.new

      expect(rule.priority).to eq(100)
    end
  end

  describe '#apply' do
    it 'raises NotImplementedError' do
      rule = described_class.new
      context = ProductPricer::CalculationContext.new(
        product: OpenStruct.new(price: 100),
        region: 'US'
      )

      expect do
        rule.apply(context)
      end.to raise_error(NotImplementedError, /must implement #apply method/)
    end
  end

  describe 'config loading' do
    it 'loads config from file correctly' do
      fixtures_dir = File.join(__dir__, '../../fixtures')
      delivery_config = File.join(fixtures_dir, 'delivery.json')

      rule = described_class.new(delivery_config)

      expect(rule.config['rule']).to eq('Rules::DeliveryRule')
      expect(rule.config).to have_key('regions')
      expect(rule.config).to have_key('weight_thresholds')
    end

    it 'stores hash config as-is' do
      config = { 'test' => 'data', 'nested' => { 'value' => 42 } }
      rule = described_class.new(config)

      expect(rule.config).to equal(config)
    end
  end
end