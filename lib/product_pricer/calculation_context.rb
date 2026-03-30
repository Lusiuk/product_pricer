# frozen_string_literal: true

module ProductPricer
  # Holds all pricing data and tracks applied rules throughout the calculation pipeline
  class CalculationContext
    attr_reader :product, :region, :promo_code, :quantity, :applied_rules, :breakdown
    attr_accessor :base_price, :final_price

    def initialize(product:, region:, promo_code: nil, quantity: 1)
      @product = normalize_product(product)
      @region = region
      @promo_code = promo_code
      @quantity = quantity

      @base_price = BigDecimal(@product.price.to_s) * quantity
      @final_price = @base_price

      @applied_rules = []
      @breakdown = {}
    end

    def track_rule(rule_name, details = {})
      @applied_rules << rule_name
      @breakdown[rule_name] = details
    end

    def to_h
      {
        base_price: @base_price,
        final_price: @final_price,
        applied_rules: @applied_rules,
        breakdown: @breakdown
      }
    end

    private

    def normalize_product(product)
      # Если пришел Hash, превращаем его в Struct
      if product.is_a?(Hash)
        # Создаем класс структуры с ключами хеша в качестве полей
        product_class = Struct.new(*product.keys.map(&:to_sym))
        # Создаем экземпляр со значениями хеша
        return product_class.new(*product.values)
      end

      # Если объект уже имеет метод price, возвращаем его
      return product if product.respond_to?(:price)

      # Защита от некорректных данных
      raise ArgumentError, 'Product must be a Hash or respond to :price'
    end
  end
end
