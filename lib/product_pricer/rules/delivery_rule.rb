# frozen_string_literal: true

require 'bigdecimal'

module ProductPricer
  module Rules
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

        delivery_cost = base_cost + (BigDecimal(context.product.weight.to_s) * weight_multiplier)
        context.delivery_cost = delivery_cost
        context.track_rule('delivery', { base_cost:, weight_multiplier: })

        context
      end
    end
  end
end
