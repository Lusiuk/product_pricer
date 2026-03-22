# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::Base do
  describe "#initialize" do
    it "loads config from file" do
      config_path = File.join(__dir__, "..", "..", "..", "config", "delivery.json")
      rule = described_class.new(config_path)

      expect(rule.config).to be_a(Hash)
      expect(rule.config.keys).to include("regions")
    end

    it "handles missing config file" do
      expect do
        described_class.new("/nonexistent/path.json")
      end.to raise_error(ProductPricer::ConfigNotFoundError)
    end

    it "handles invalid JSON" do
      temp_file = File.join(__dir__, "temp_invalid.json")
      File.write(temp_file, "{ invalid json")

      begin
        expect do
          described_class.new(temp_file)
        end.to raise_error(ProductPricer::Error)
      ensure
        File.delete(temp_file)
      end
    end
  end

  describe "#priority" do
    it "has default priority 100" do
      rule = described_class.new
      expect(rule.priority).to eq(100)
    end
  end

  describe "#apply" do
    it "raises NotImplementedError" do
      rule = described_class.new
      context = double

      expect do
        rule.apply(context)
      end.to raise_error(NotImplementedError)
    end
  end
end