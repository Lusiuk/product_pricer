# ProductPricer

**ProductPricer** — небольшой гем для расчёта цены товара в Ruby‑приложениях. Это учебный проект с фокусом на расширяемую архитектуру правил: каждое правило по очереди изменяет итоговую цену.

---

## Локальная установка

Гем пока не опубликован на RubyGems, поэтому используется локальная сборка.

1. Склонируйте репозиторий и перейдите в корень.
2. Соберите гем:

```bash
gem build product_pricer.gemspec
```

3. Установите:

```bash
gem install product_pricer
```

---

## Как пользоваться

### 1. Создаём `Pricer` и добавляем правила

```ruby
require 'product_pricer'

pricer = ProductPricer::Pricer.new

fixtures_dir = File.join(__dir__, 'config')

pricer.add_rule(ProductPricer::Rules::DeliveryRule.new(
  File.join(fixtures_dir, 'delivery.json')
))
pricer.add_rule(ProductPricer::Rules::TaxRule.new(
  File.join(fixtures_dir, 'taxes.json')
))
pricer.add_rule(ProductPricer::Rules::PromoRule.new(
  File.join(fixtures_dir, 'sales.json')
))
pricer.add_rule(ProductPricer::Rules::RoundPriceRule.new)
```

---

### 2. Считаем цену

```ruby
result = pricer.calculate(
  product: { price: '99.99', category: 'electronics', weight: 2.5 },
  region: 'EU',
  promo_code: 'SUMMER20',
  quantity: 3
)
```

---

### 3. Смотрим результат

```ruby
puts result.final_price
puts result.applied_rules
puts result.breakdown
```

`result` — это `ProductPricer::CalculationContext`, в котором есть:
- `base_price` — цена до правил
- `final_price` — итоговая цена
- `applied_rules` — список применённых правил
- `breakdown` — детализация по правилам

---

### Быстрый вариант

```ruby
ProductPricer.calculate(product: product, region: 'US')
```

---

## Конфигурации правил

Логика правил хранится в JSON и не захардкожена в коде.

### Пример налогов (`taxes.json`)

```json
{
  "categories": {
    "electronics": {
      "US": 0.00,
      "EU": 0.20,
      "RU": 0.20
    }
  },
  "rules": {
    "compound_tax": false
  }
}
```

---

### Пример скидок (`sales.json`)

```json
{
  "promo_codes": {
    "SUMMER20": {
      "type": "percentage",
      "value": 0.20,
      "min_purchase": 50.00,
      "max_discount": 100.00,
      "valid_from": "2024-06-01",
      "valid_until": "2024-08-31"
    },
    "FLAT10": {
      "type": "fixed",
      "value": 10.00
    }
  }
}
```

---

## Использование через `rules_config`

Можно передать конфиг напрямую:

### 1) Один файл:

```ruby
ProductPricer.calculate(
  product: product,
  region: 'EU',
  rules_config: 'config/taxes.json'
)
```

### 2) Несколько файлов:

```ruby
ProductPricer.calculate(
  product: product,
  region: 'EU',
  rules_config: ['config/delivery.json', 'config/taxes.json']
)
```

### 3) Хэш-конфиг:

```ruby
config = {
  'rule' => 'Rules::TaxRule',
  'categories' => {
    'electronics' => { 'US' => '0.10', 'EU' => '0.20' }
  },
  'rules' => { 'compound_tax' => false }
}

ProductPricer.calculate(product: product, region: 'US', rules_config: config)
```

---

## Как добавить своё правило

```ruby
module ProductPricer
  module Rules
    class BlackFridayRule < Base
      def priority
        45
      end

      def apply(context)
        return context unless black_friday?

        discount = context.base_price * 0.30
        context.final_price -= discount
        context.track_rule('black_friday', { discount: discount })
        context
      end

      private

      def black_friday?
        Date.today.month == 11 && Date.today.friday?
      end
    end
  end
end
```

---

## Тесты

```bash
bundle exec rspec
```

Отдельный тест:

```bash
bundle exec rspec spec/product_pricer/rules/promo_rule_spec.rb
```

---

## Лицензия

MIT — делайте с этим что хотите :)
