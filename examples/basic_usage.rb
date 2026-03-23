# frozen_string_literal: true

require_relative '../lib/product_pricer'

# Пример 1: Простой расчет с конфигами
puts '=' * 60
puts 'Example 1: Calculate price for electronics in EU'
puts '=' * 60

product = OpenStruct.new(
  price: 99.99,
  category: 'electronics',
  weight: 2.5
)

pricer = ProductPricer::Pricer.new(
  delivery_config: File.join(__dir__, '..', 'config', 'delivery.json'),
  tax_config: File.join(__dir__, '..', 'config', 'taxes.json'),
  discount_config: File.join(__dir__, '..', 'config', 'sales.json')
)

result = pricer.calculate(
  product:,
  region: 'EU',
  promo_code: 'FLAT10',
  quantity: 1,
  user_tier: nil
)

puts "Base Price:        #{format('%.2f', result.base_price)}"
puts "Delivery Cost:     #{format('%.2f', result.delivery_cost)}"
puts "Weight Surcharge:  #{format('%.2f', result.weight_surcharge)}"
puts "Tax Amount:        #{format('%.2f', result.tax_amount)}"
puts "Discount Amount:   #{format('%.2f', result.discount_amount)}"
puts "Final Price:       #{format('%.2f', result.final_price)}"
puts "Applied Rules:     #{result.applied_rules.join(', ')}"
puts

# Пример 2: Расчет с промокодом
puts '=' * 60
puts 'Example 2: Calculate with promo'
puts '=' * 60

result = pricer.calculate(
  product:,
  region: 'US',
  promo_code: 'FLAT10',
  quantity: 3
)

puts "Base Price (x3):   #{format('%.2f', result.base_price)}"
puts "Delivery Cost:     #{format('%.2f', result.delivery_cost)}"
puts "Weight Surcharge:  #{format('%.2f', result.weight_surcharge)}"
puts "Tax Amount:        #{format('%.2f', result.tax_amount)}"
puts "Discount Amount:   #{format('%.2f', result.discount_amount)}"
puts "Final Price:       #{format('%.2f', result.final_price)}"
puts "Applied Rules:     #{result.applied_rules.join(', ')}"
puts 'Breakdown:'
result.breakdown.each do |rule, details|
  puts "  #{rule}: #{details}"
end
