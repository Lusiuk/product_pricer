# ProductPricer

**ProductPricer** — это гибкий, расширяемый калькулятор цен для Ruby-приложений. Он вычисляет итоговую стоимость товара на основе настраиваемых бизнес-правил, используя паттерн «Конвейер правил» (Pipeline Pattern).

---

## 📖 Оглавление

- [Установка](#-установка)
- [Быстрый старт](#-быстрый-старт)
- [Ключевые особенности](#-ключевые-особенности)
- [Создание своих правил](#-создание-своих-правил)
- [Тестирование](#-тестирование)
- [Лицензия](#-лицензия)

---

## 📦 Установка

Добавьте эту строку в `Gemfile` вашего приложения:

```ruby
gem 'product-pricer', '~> 0.1'
```

Затем выполните:

```bash
$ bundle install
```

Или установите его самостоятельно:

```bash
$ gem install product-pricer
```

**Зависимости:**
- `bigdecimal` (встроен в Ruby ≥ 3.1)
- `json` (встроен)
- *(опционально)* `money` — для работы с валютами

**Требования:** Ruby 3.0+

---

## 🚀 Быстрый старт

### 1. Инициализация
Загрузите конфигурационные файлы с правилами (делается один раз при старте приложения):

```ruby
require 'product_pricer'

pricer = ProductPricer::Pricer.new(
  delivery_rules: 'config/delivery.json',
  tax_rules: 'config/taxes.json',
  discount_rules: 'config/sales.json'
)
```

### 2. Расчёт цены
Передайте данные о товаре и контексте покупки:

```ruby
result = pricer.calculate(
  product: { price: '99.99', category: 'electronics', weight: 2.5 },
  region: 'EU',
  promo_code: 'SUMMER20',
  quantity: 3,
  user_tier: 'gold'
)
```

### 3. Получение результата
Гем возвращает детализированный объект расчёта:

```ruby
puts "Итоговая цена: #{result.final_price}" 
# => Итоговая цена: 110.28

puts "Скидки: #{result.discount_amount}"
# => Скидки: 25.00

puts "Применённые правила: #{result.applied_rules.join(', ')}"
# => Применённые правила: delivery, weight, tax, promo:SUMMER20, loyalty:gold
```

### Глобальный метод
Для простых случаев можно использовать метод уровня класса:

```ruby
ProductPricer.calculate(product: product, region: 'US')
```

---

## ✨ Ключевые особенности

| Особенность | Описание |
|-------------|----------|
| **Точность** | Все денежные операции используют `BigDecimal`. Округление только в конце. |
| **Расширяемость** | Новое правило = новый класс. Не нужно менять ядро гема. |
| **Прозрачность** | Поле `applied_rules` показывает, какие правила сработали и почему. |
| **Гибкость** | Порядок выполнения правил настраивается через приоритеты (`priority`). |
| **Безопасность** | Валидация входных данных, понятные исключения, иммутабельность контекста. |
| **Конфигурация** | Бизнес-логика (налоги, скидки) вынесена в JSON-файлы. |

---

## ⚙️ Конфигурация

Гем не хранит бизнес-логику в коде — она вынесена в читаемые JSON-файлы. Это позволяет менеджерам править цены без участия разработчиков.

### Пример: `taxes-per-category.json`
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

### Пример: `sales-per-category.json`
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

## 🛠 Создание своих правил

Вы можете легко добавить собственную логику ценообразования, наследуясь от базового класса.

### 1. Создайте класс правила
```ruby
module ProductPricer
  module Rules
    class BlackFridayRule < Base
      def priority
        45 # Выполнится перед обычными промокодами
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

### 2. Зарегистрируйте правило
При инициализации `Pricer` передайте путь к вашему правилу или подключите его через конфигурацию гема.

---

## 🧪 Тестирование

Гем поставляется с полным покрытием тестами (>95%).

```bash
# Запустить все тесты
bundle exec rspec

# Запустить тесты с отчётом о покрытии
bundle exec rspec --format documentation --require simplecov

# Запустить тесты только для одного правила
bundle exec rspec spec/product_pricer/rules/promo_rule_spec.rb
```

## 📄 Лицензия

Гем распространяется под лицензией **MIT** — используйте в коммерческих проектах без ограничений. См. файл [LICENSE](LICENSE) для деталей.

---
