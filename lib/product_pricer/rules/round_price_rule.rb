# frozen_string_literal: true

module ProductPricer
  module Rules
    # Applies final rounding to 2 decimal places as the last rule in the chain
    class RoundPriceRule < Base
      def priority
        999
      end

      def apply(context)
        context.final_price = context.round(2)
        context.track_rule('round', { final_price: context.final_price })
        context
      end
    end
  end
end
