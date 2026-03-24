# ProductPricer

**ProductPricer** — это небольшой гем для расчёта цены товара в Ruby-приложениях. Мы делали его как учебный проект, чтобы разобраться с паттернами и заодно решить практическую задачу: гибко считать цену с учётом налогов, доставки и скидок.

Внутри используется что-то вроде конвейера правил (Pipeline), где каждое правило по очереди изменяет итоговую цену.

---
## Локальная установка
На текущий момент гем не опубликован на RubyGems, так как мы не хотим перегружать его учебными проектами.
Чтобы использовать библиотеку сейчас, вам необходимо собрать её локально из нашего репозитория:

### 1. Склонируйте репозиторий и перейдите в его корень.
### 2. Соберите гем командой:

```bash
gem build product_pricer.gemspec
```
### 3.Установите собранный файл
```bash
gem install product_pricer
```


## Как пользоваться

### 1. Создаём pricer

При старте приложения подгружаем конфиги с правилами:

```ruby
require 'product_pricer'

pricer = ProductPricer::Pricer.new(
  delivery_rules: 'config/delivery.json',
  tax_rules: 'config/taxes.json',
  discount_rules: 'config/sales.json'
)
```

---

### 2. Считаем цену

```ruby
result = pricer.calculate(
  product: { price: '99.99', category: 'electronics' },
  region: 'EU',
  promo_code: 'SUMMER20',
  quantity: 3
)
```

---

### 3. Смотрим результат

```ruby
puts result.final_price
puts result.discount_amount
puts result.applied_rules
```

Можно увидеть не только итоговую цену, но и какие правила вообще сработали — это удобно для дебага.

---

### Быстрый вариант

Если не хочется создавать объект:

```ruby
ProductPricer.calculate(product: product, region: 'US')
```

---

## Что умеет

Если коротко:

* считает деньги нормально (через `BigDecimal`, без сюрпризов с float)
* легко расширяется (новое правило = новый класс)
* можно понять, что произошло (есть список применённых правил)
* порядок правил можно менять через `priority`
* вся бизнес-логика лежит в JSON, а не захардкожена

---

## Конфигурация

Мы специально вынесли всю логику в JSON, чтобы можно было менять правила без переписывания кода.

### Пример налогов

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
    "tax_shipping": false,
    "compound_tax": false
  }
}
```

---

### Пример скидок

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
    }
  }
}
```

---

## Как добавить своё правило

Если стандартных правил не хватает — можно написать своё.

### Пример

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
        context.discount_amount += discount
        context.track_rule('black_friday')
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

Дальше просто подключаете это правило — и оно начинает участвовать в расчёте.

---

## Тесты

Мы постарались нормально покрыть код тестами.

```bash
bundle exec rspec
```

Если нужен отчёт:

```bash
bundle exec rspec --format documentation --require simplecov
```

Отдельный тест:

```bash
bundle exec rspec spec/product_pricer/rules/promo_rule_spec.rb
```

---

## Лицензия

MIT — делайте с этим что хотите :)
