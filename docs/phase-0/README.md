# Phase 0 — Technical Prototypes

Цель фазы — снять четыре главных технических риска до разработки полного MVP.
Артефакты здесь являются spike-кодом и контрактами, а не готовым UI.

## Статус

| Spike | Статус | Артефакт | Gate для завершения |
|---|---|---|---|
| Google POI → Place ID | prepared | `GooglePlaceSelectionHandler.kt` | Прогон на физическом Android-устройстве с debug API key |
| Places UI Kit Compact | blocked externally | checklist ниже | Подтвердить компактную строку rating/review count и переход в Google Maps |
| KMP ↔ SwiftUI | prepared | shared presenter + Swift ViewModel | Собрать Android/iOS targets с установленными JDK и Xcode toolchain |
| Supabase + PostGIS | implemented locally | migration + SQL test | Выполнить тест через локальный Supabase stack |

`blocked externally` означает, что репозиторий готов к проверке, но результат
нельзя честно подтвердить без Google Cloud project, API key и native SDK.

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
