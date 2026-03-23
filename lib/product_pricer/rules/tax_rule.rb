# frozen_string_literal: true

require 'bigdecimal'

module ProductPricer
  module Rules
    # Tax calculation rule based on product category and region
    class TaxRule < Base
      def priority
        100
      end

      def apply(context)
        return context unless @config

        category = context.product.category
        region = context.region

        tax_rate = @config.dig('categories', category, region)
        return context unless tax_rate

        tax_rate = BigDecimal(tax_rate.to_s)

        # Decide what to tax: base price, delivery, or both
        tax_shipping = @config.dig('rules', 'tax_shipping') || false
        taxable_amount = context.base_price
        taxable_amount += context.delivery_cost if tax_shipping

        tax_amount = taxable_amount * tax_rate
        context.tax_amount = tax_amount
        context.track_rule('tax', { tax_rate:, taxable_amount: })

        context
      end
    end
  end
end
