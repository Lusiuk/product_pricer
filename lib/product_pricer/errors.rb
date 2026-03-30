# frozen_string_literal: true

module ProductPricer
  class Error < StandardError; end

  class InvalidConfigError < Error; end

  class ConfigNotFoundError < Error; end

  class InvalidProductError < Error; end

  class InvalidProductPriceError < Error; end

  class InvalidRegionError < Error; end

  class CalculationError < Error; end

  class InvalidQuantityError < Error; end

  class InvalidRuleError < Error; end
end
