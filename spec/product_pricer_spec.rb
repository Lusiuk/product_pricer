# frozen_string_literal: true

RSpec.describe ProductPricer do
  it 'has a version number' do
    expect(ProductPricer::VERSION).not_to be nil
  end

  describe '.calculate' do
    it 'calculates simple price without configs' do
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)

      result = described_class.calculate(
        product:,
        region: 'US'
      )

      expect(result).to be_a(ProductPricer::CalculationContext)
      expect(result.base_price).to eq(BigDecimal(100))
    end
  end
end
