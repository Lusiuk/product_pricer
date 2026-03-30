# frozen_string_literal: true

module ProductPricer
  module Rules
    # Tax calculation rule based on product category and region
    class TaxRule < Base
      def priority
        100
      end

      def apply(context)
        return context unless @config
        return context unless context.product.category

        category = context.product.category
        region = context.region

        tax_rate = @config.dig('categories', category, region)
        return context unless tax_rate

        tax_rate = BigDecimal(tax_rate.to_s)
        compound_tax = @config.dig('rules', 'compound_tax') || false
        taxable_amount = compound_tax ? context.final_price : context.base_price
        tax_amount = taxable_amount * tax_rate
        context.final_price += tax_amount
        context.track_rule('tax', {
                             tax_rate:,
                             taxable_amount:,
                             compound_tax:,
                             tax_amount:
                           })
        context
      end
    end
  end
end
