# frozen_string_literal: true

module ProductPricer
  class Error < StandardError; end
  class ConfigNotFoundError < Error; end
  class InvalidProductError < Error; end
  class InvalidRegionError < Error; end
  class CalculationError < Error; end
end