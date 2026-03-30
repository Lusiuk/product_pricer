# frozen_string_literal: true

module ProductPricer
  module Rules
    class DeliveryRule < Base
      def priority
        10
      end

      def apply(context)
        return context unless @config
        return context unless context.product&.weight

        region_config = @config.dig('regions', context.region)
        return context unless region_config

        weight = BigDecimal(context.product.weight.to_s)

        base_delivery_cost = BigDecimal(region_config['base_cost'] || '0')
        weight_multiplier = BigDecimal(region_config['weight_multiplier'] || '0')

        delivery_cost = calculate_delivery_cost(base_delivery_cost, weight, weight_multiplier)
        threshold_surcharge = calculate_threshold_surcharge(weight)
        delivery_cost += threshold_surcharge

        context.final_price += delivery_cost

        # 4. Используем готовую переменную threshold_surcharge для лога
        context.track_rule('delivery', {
                             base_delivery_cost:,
                             weight_multiplier:,
                             weight:,
                             threshold_surcharge:,
                             delivery_cost:
                           })
        context
      end

      private

      def calculate_delivery_cost(base_delivery_cost, weight, multiplier)
        base_delivery_cost + (weight * multiplier)
      end

      def calculate_threshold_surcharge(weight)
        thresholds = @config['weight_thresholds']
        return BigDecimal(0) unless thresholds.is_a?(Array)

        applicable_threshold = thresholds.reverse.find do |t|
          weight >= BigDecimal(t['min_weight'] || '0')
        end

        return BigDecimal(0) unless applicable_threshold

        rate = BigDecimal(applicable_threshold['surcharge_per_kg'] || '0')
        weight * rate
      end
    end
  end
end
