# Phase 0 — Technical Prototypes

Цель фазы — снять четыре главных технических риска до разработки полного MVP.
Артефакты здесь являются spike-кодом и контрактами, а не готовым UI.

## Статус

| Spike | Статус | Артефакт | Gate для завершения |
|---|---|---|---|
| Google POI → Place ID | prepared | `GooglePlaceSelectionHandler.kt` | Нужны Android SDK и debug API key |
| Places UI Kit Compact | blocked externally | checklist ниже | Нужны Android SDK, Google Cloud project и API key |
| KMP ↔ SwiftUI | compiled, link pending | shared presenter + Swift ViewModel | JVM test проходит; Kotlin/Native компилируется; framework link требует full Xcode |
| Supabase + PostGIS | implemented, test pending | migration + SQL test | Локальный Docker не запускает новые контейнеры; тест вынесен в CI |

`blocked externally` означает, что репозиторий готов к проверке, но результат
нельзя честно подтвердить без Google Cloud project, API key и native SDK.

Автоматические проверки находятся в `.github/workflows/phase-0.yml`. KMP job
использует macOS runner с Xcode, PostGIS job — отдельный database-only Supabase
container и pgTAP. Локально JVM-тест подтверждён. Попытка запуска PostGIS была
остановлена, потому что Docker Engine зависает даже на новом `hello-world`, при
этом уже работающий пользовательский контейнер не перезапускался.

## Google spike checklist

1. Ограничить debug key package/bundle identifiers и SHA fingerprint.
2. Открыть карту Баку и нажать обычный Google POI.
3. Передать стабильный Google Place ID в `GooglePlaceSelectionHandler`.
4. Убедиться, что неизвестный ID создаёт/находит ровно один внутренний Place.
5. Показать Compact Place Details рядом с нашей pet-секцией.
6. Проверить, что Google-контент не сохраняется как наш долговременный dataset.
7. Проверить переход строки рейтинга на конкретное место в Google Maps.

## KMP interop contract

На границе Swift/Kotlin не экспортируются Android/iOS SDK types. Swift получает
immutable snapshot и callback-driven presenter. После успешной сборки этот spike
нужно расширить проверкой `Flow`, cancellation, nullable fields и typed errors —
это отдельный gate из GDD, а не молчаливое предположение.

## Решение о переходе к Phase 1

Phase 1 начинается после зелёного результата всех четырёх gate. Допустимо вести
минимальную схему `places` внутри PostGIS spike, но CRM, reviews и полную policy
schema до закрытия Phase 0 не наращиваем.
