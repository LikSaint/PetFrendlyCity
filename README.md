# Pet-Friendly City

Монорепозиторий платформы для поиска мест с точными и проверяемыми правилами
посещения с собакой. Первый рынок — Баку, Азербайджан.

Основной продуктовый и технический документ: [GDD v0.1](docs/GDD-v0.1.md).

## Статус

Работа начата с **Phase 0 — Technical Prototypes** из GDD:

- зафиксирован контракт `Google Place ID → наш Place lookup`;
- добавлен общий KMP domain slice и Swift-friendly presenter;
- добавлен первый PostGIS migration с radius query;
- добавлен SQL smoke test для географического запроса;
- подготовлены критерии ручной проверки Google Maps / Places UI Kit.

Текущий прогресс и внешние prerequisites описаны в
[Phase 0](docs/phase-0/README.md).

## Структура

```text
mobile/     KMP shared core, Android и iOS клиенты
web/        public site и Admin / CRM
supabase/   migrations, Edge Functions, seed и SQL tests
docs/       GDD, решения и отчёты по фазам
infra/      инфраструктурная конфигурация
```

## Быстрый старт Phase 0

Supabase CLI закреплён как локальная npm dev-зависимость. Для PostGIS smoke test
нужен работающий Docker:

```bash
npm install
npm run db:start
npm run db:lint
npm run db:test
npm run db:stop
```

Shared KMP contract проверяется командой `npm run test:kmp`. Линковка iOS
framework также выполняется в GitHub Actions на macOS runner с полным Xcode.

Google spikes требуют отдельного debug API key. Ключи и локальные secret-файлы
не коммитятся.
