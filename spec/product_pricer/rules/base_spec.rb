# frozen_string_literal: true

require 'fileutils'

RSpec.describe ProductPricer::Rules::Base do
  before do
    stub_const('Product', Struct.new(:price, :category, :weight))
  end

  describe '#initialize' do
    it 'initializes with config from hash' do
      config = { 'key' => 'value' }
      rule = described_class.new(config)

      expect(rule.config).to eq(config)
    end

    it 'initializes with config from file path' do
      fixtures_dir = File.join(__dir__, '..', '..', 'fixtures')
      config_path = File.join(fixtures_dir, 'delivery.json')

      rule = described_class.new(config_path)

      expect(rule.config).to be_a(Hash)
    end

    it 'has rule key in config' do
      fixtures_dir = File.join(__dir__, '..', '..', 'fixtures')
      config_path = File.join(fixtures_dir, 'delivery.json')

      rule = described_class.new(config_path)

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
      fixtures_dir = File.join(__dir__, '..', '..', 'fixtures')
      invalid_json_file = File.join(fixtures_dir, 'invalid.json')

      FileUtils.mkdir_p(fixtures_dir)
      File.write(invalid_json_file, '{invalid json}')

      expect do
        described_class.new(invalid_json_file)
      end.to raise_error(ProductPricer::Error, /Invalid JSON/)

      FileUtils.rm_f(invalid_json_file)
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
      product = instance_double(Product, price: 100)
      context = ProductPricer::CalculationContext.new(
        product:,
        region: 'US'
      )

      expect do
        rule.apply(context)
      end.to raise_error(NotImplementedError, /must implement #apply method/)
    end
  end

  describe 'config loading' do
    it 'loads config from file correctly' do
      fixtures_dir = File.join(__dir__, '..', '..', 'fixtures')
      delivery_config = File.join(fixtures_dir, 'delivery.json')

      rule = described_class.new(delivery_config)

      expect(rule.config['rule']).to eq('Rules::DeliveryRule')
    end

    it 'has regions key in delivery config' do
      fixtures_dir = File.join(__dir__, '..', '..', 'fixtures')
      delivery_config = File.join(fixtures_dir, 'delivery.json')

      rule = described_class.new(delivery_config)

      expect(rule.config).to have_key('regions')
    end

    it 'stores hash config as-is' do
      config = { 'test' => 'data', 'nested' => { 'value' => 42 } }
      rule = described_class.new(config)

      expect(rule.config).to equal(config)
    end
  end
end
