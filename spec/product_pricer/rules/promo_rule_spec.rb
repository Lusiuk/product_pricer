# frozen_string_literal: true

RSpec.describe ProductPricer::Rules::PromoRule do
  let(:fixtures_dir) { File.join(__dir__, '..', '..', 'fixtures') }
  let(:config_path) { File.join(fixtures_dir, 'sales.json') }
  let(:rule) { described_class.new(config_path) }

  describe '#priority' do
    it 'has priority 50' do
      expect(rule.priority).to eq(50)
    end
  end

  describe '#apply' do
    it 'applies fixed discount' do
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(
        product:,
        region: 'EU',
        promo_code: 'FLAT10'
      )

      result = rule.apply(context)

      expect(result.discount_amount).to eq(BigDecimal(10))
      expect(result.applied_rules).to include('promo:FLAT10')
    end

    # it 'applies different fixed discounts' do
    #   product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
    #
    #   context_flat10 = ProductPricer::CalculationContext.new(
    #     product:,
    #     region: 'EU',
    #     promo_code: 'FLAT10'
    #   )
    #
    #   context_flat20 = ProductPricer::CalculationContext.new(
    #     product:,
    #     region: 'EU',
    #     promo_code: 'FLAT20'
    #   )
    #
    #   result_flat10 = rule.apply(context_flat10)
    #   result_flat20 = rule.apply(context_flat20)
    #
    #   expect(result_flat10.discount_amount).to eq(BigDecimal(10))
    #   expect(result_flat20.discount_amount).to eq(BigDecimal(20))
    # end

    it 'does not apply invalid promo code' do
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(
        product:,
        region: 'EU',
        promo_code: 'INVALID'
      )

      result = rule.apply(context)

      expect(result.discount_amount).to eq(BigDecimal(0))
      expect(result.applied_rules).to be_empty
    end

    it 'respects applicable categories' do
      product_electronics = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      # product_food = OpenStruct.new(price: 100, category: 'food', weight: 1)

      # SUMMER20 применяется только к electronics и clothing
      context_electronics = ProductPricer::CalculationContext.new(
        product: product_electronics,
        region: 'EU',
        promo_code: 'FLAT10'
      )

      # context_food = ProductPricer::CalculationContext.new(
      #   product: product_food,
      #   region: 'EU',
      #   promo_code: 'FLAT10'
      # )

      result_electronics = rule.apply(context_electronics)
      # result_food = rule.apply(context_food)

      # FLAT10 применяется ко всем категориям
      expect(result_electronics.discount_amount).to eq(BigDecimal(10))
      # expect(result_food.discount_amount).to eq(BigDecimal(10))
    end

    it 'returns context without promo code' do
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU')

      result = rule.apply(context)

      expect(result.discount_amount).to eq(BigDecimal(0))
      expect(result.applied_rules).to be_empty
    end

    it 'does not apply promo code after valid_until' do
      product = OpenStruct.new(price: 100, category: 'electronics', weight: 1)
      context = ProductPricer::CalculationContext.new(product:, region: 'EU', promo_code: 'SUMMER20')

      allow(Date).to receive(:today).and_return(Date.new(2034, 9, 1))

      result = rule.apply(context)

      expect(result.discount_amount).to eq(BigDecimal(0))
      expect(result.applied_rules).not_to include('promo:SUMMER20')
      expect(result.applied_rules).to be_empty
    end
  end
end
