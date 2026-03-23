# frozen_string_literal: true

require 'bigdecimal'

module ProductPricer
  module Rules
    # Delivery rule class, applying delivery price info to context
    class DeliveryRule < Base
      def priority
        10
      end

      def apply(context)
        return context unless @config

        region_config = @config.dig('regions', context.region)
        return context unless region_config

        base_cost = BigDecimal(region_config['base_cost'].to_s)
        weight_multiplier = BigDecimal(region_config['weight_multiplier'].to_s || '0')

        context.delivery_cost = calculate_cost(context.product.weight, base_cost, weight_multiplier)
        context.track_rule('delivery', { base_cost:, weight_multiplier: })

        context
      end

      private

      def calculate_cost(weight, base, multiplier)
        base + (BigDecimal(weight.to_s) * multiplier)
      end
    end
  end
end
