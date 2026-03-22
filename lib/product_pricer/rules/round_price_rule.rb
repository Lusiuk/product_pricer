# frozen_string_literal: true

require "bigdecimal"

module ProductPricer
  module Rules
    class RoundPriceRule < Base
      def priority
        999
      end

      def apply(context)
        # Calculate final price
        final = context.base_price
        final += context.delivery_cost
        final += context.tax_amount
        final -= context.discount_amount

        # Round to 2 decimal places
        context.final_price = final.round(2)
        context.track_rule("round", { final_price: context.final_price })

        context
      end
    end
  end
end