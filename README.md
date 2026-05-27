# Hash Sum & Replication Mechanism & Tests

Проект реализует два механизма для PostgreSQL:
1. **Функция расчета хеш-суммы таблицы**: Генерирует уникальный хеш на основе содержимого всех строк и типов данных.
2. **Механизм репликации на триггерах**: Логирует операции INSERT, UPDATE, DELETE в служебные таблицы.

## Требования
- PostgreSQL 10+ (рекомендуется 13+ для поддержки `pg_current_xact_id`)

## Установка и запуск

1. Подключитесь к вашей базе данных PostgreSQL.
2. Выполните скрипты в этом порядке:

```bash
psql -U your_user -d your_database -f hash_table.sql.sql
psql -U your_user -d your_database -f replication.sql
psql -U your_user -d your_database -f tests.sql
