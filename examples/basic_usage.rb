# frozen_string_literal: true

require_relative '../lib/product_pricer'

# Пример 1: Простой расчет с конфигами
puts '=' * 60
puts 'Example 1: Calculate price for electronics in EU'
puts '=' * 60

product = Struct.new(:price, :category, :weight).new(99.99, 'electronics', 2.5)
pricer = ProductPricer::Pricer.new

# Правильно инициализируем правила из файлов конфигурации
config_dir = File.join(__dir__, '..', 'config')
pricer.add_rule(ProductPricer::Rules::DeliveryRule.new(File.join(config_dir, 'delivery.json')))
pricer.add_rule(ProductPricer::Rules::PromoRule.new(File.join(config_dir, 'sales.json')))
pricer.add_rule(ProductPricer::Rules::TaxRule.new(File.join(config_dir, 'taxes.json')))
pricer.add_rule(ProductPricer::Rules::RoundPriceRule.new)

result = pricer.calculate(
  product:,
  region: 'EU',
  promo_code: 'FLAT20',
  quantity: 1
)

puts "Base Price:        #{format('%.2f', result.base_price)}"
puts "Final Price:       #{format('%.2f', result.final_price)}"
puts "Applied Rules:     #{result.applied_rules.join(', ')}"
puts 'Breakdown:'
result.breakdown.each do |rule, details|
  puts "  #{rule}: #{details}"
end

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
puts "Final Price:       #{format('%.2f', result.final_price)}"
puts "Applied Rules:     #{result.applied_rules.join(', ')}"
puts 'Breakdown:'
result.breakdown.each do |rule, details|
  puts "  #{rule}: #{details}"
end
