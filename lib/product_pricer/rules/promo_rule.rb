# frozen_string_literal: true

require 'bigdecimal'
require 'date'

module ProductPricer
  module Rules
    # Applies promotional discounts based on promo code, validity dates, and category restrictions
    class PromoRule < Base
      def priority
        50
      end

      def apply(context)
        return context unless @config
        return context unless context.promo_code

        promo = @config.dig('promo_codes', context.promo_code)
        return context unless promo

        # Отладка: выводим ключевые данные
        puts '=== DEBUG PromoRule#apply ==='
        puts "Current date: #{Date.today}"
        puts "Promo config: #{promo}"
        puts "Is promo valid? #{promo_valid?(promo)}"
        puts "Base price: #{context.base_price}"

        return context unless promo_valid?(promo)
        return context unless applicable_category?(promo, context)

        discount = calculate_discount(context.base_price, promo)
        context.discount_amount += discount
        context.track_rule("promo:#{context.promo_code}", { discount:, type: promo['type'] })

        context
      end

      private

      def promo_valid?(promo)
        return true unless promo['valid_from'] || promo['valid_until']

        now = Date.today
        valid_from = Date.parse(promo['valid_from']) if promo['valid_from']
        valid_until = Date.parse(promo['valid_until']) if promo['valid_until']

        valid_from ||= Date.new(1900, 1, 1)
        valid_until ||= Date.new(2100, 12, 31)

        now.between?(valid_from, valid_until)
      end

      def applicable_category?(promo, context)
        return true unless promo['applicable_categories']

        promo['applicable_categories'].include?(context.product.category)
      end

      def calculate_discount(price, promo)
        case promo['type']
        when 'percentage'
          discount = price * BigDecimal(promo['value'].to_s)
          max_discount = BigDecimal(promo['max_discount'].to_s || Float::INFINITY.to_s)
          [discount, max_discount].min
        when 'fixed'
          BigDecimal(promo['value'].to_s)
        else
          BigDecimal(0)
        end
      end
    end
  end
end
