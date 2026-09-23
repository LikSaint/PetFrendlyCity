# Pet-Friendly Platform
## Master Product & Technical Specification

Версия: 0.1  
Первый рынок: Баку, Азербайджан

---

# 1. Концепция

Продукт для владельцев собак, который отвечает на основной вопрос:

**«Куда я могу пойти со своей собакой и какие именно правила действуют в этом месте?»**

Это не конкурент Google Maps как универсальной карты.

Google отвечает:

**«Что это за место?»**

Наш продукт отвечает:

**«Можно ли мне туда с собакой, какого размера, куда именно можно пройти и какие действуют ограничения?»**

Главный собственный актив проекта — постоянно обновляемая структурированная база pet-policy заведений.

---

# 2. Основные платформы

Продукт состоит из четырёх частей:

1. Android-приложение.
2. iOS-приложение.
3. Публичный Web.
4. Admin + CRM.

---

# 3. Технологический стек

## Android

- Kotlin
- Jetpack Compose
- Google Maps SDK for Android

## iOS

- Swift
- SwiftUI
- Google Maps SDK for iOS
- при необходимости отдельные системные интеграции через MapKit

## Общая мобильная логика

**Kotlin Multiplatform — KMP**

Через KMP шарим:

- API client;
- repositories;
- domain models;
- filters;
- caching;
- analytics interface;
- navigation logic;
- events;
- place logic;
- business rules;
- use cases.

UI остаётся нативным:

```text
Android → Jetpack Compose
iOS     → SwiftUI
```

---

# 4. Web

Публичный сайт:

**Angular + SSR**

Задачи Web:

- полноценная web-версия карты;
- SEO;
- страницы заведений;
- страницы событий;
- landing pages;
- индексируемые подборки.

Примеры URL:

```text
/baku
/baku/restaurants
/baku/pet-friendly-restaurants
/baku/parks
/baku/events

/place/paul-port-baku
/event/dogfest
```

---

# 5. Admin / CRM

Отдельное Angular-приложение:

```text
admin.domain.com
```

Используется внутренней командой для:

- ведения заведений;
- обзвона заведений;
- проверки pet-policy;
- re-verification;
- обработки пользовательских запросов;
- обработки пользовательских жалоб;
- событий;
- CRM;
- аналитики;
- управления контентом.

---

# 6. Общая архитектура

```text
                    Backend
            PostgreSQL + PostGIS
                  Supabase
                     │
        ┌────────────┼─────────────┐
        │            │             │
     Android        iOS           Web
     Kotlin         Swift        Angular
     Compose        SwiftUI      SSR
        │            │
        └────── KMP Shared ──────┘

                     │
                     │
                Admin / CRM
                   Angular
```

---

# 7. Backend

На старте:

**Supabase Free**

Используем:

- PostgreSQL;
- PostGIS;
- Auth;
- API;
- Edge Functions;
- Storage при необходимости.

Причина выбора PostgreSQL:

данные сильно реляционные и географические.

Нам постоянно понадобятся запросы:

```text
все места в bounding box карты
все места в радиусе 3 км
все места поблизости
pet-friendly места в радиусе N км
сортировка по расстоянию
```

PostGIS для этого подходит значительно лучше NoSQL.

---

# 8. Возможность миграции

Нельзя архитектурно привязывать core-бизнес-логику к Supabase.

Supabase рассматривается как удобный managed PostgreSQL.

При росте можно переехать на:

```text
собственный PostgreSQL + PostGIS
Neon
AWS RDS
другой managed PostgreSQL
```

без полной переработки приложения.

---

# 9. Storage

На MVP:

```text
Supabase Storage
```

При росте фотографий:

```text
Cloudflare R2
```

Изображения не должны храниться непосредственно в PostgreSQL.

---

# 10. Email

Регистрация не является core-сценарием, поэтому объём email будет маленьким.

Используем:

**Resend Free**

Email:

- verification;
- password reset;
- технические уведомления.

Обязательно сделать abstraction:

```text
MailService
```

Например:

```text
MailService
    ↓
ResendMailService
```

В будущем:

```text
MailService
    ↓
AmazonSesMailService
```

или:

```text
SMTPMailService
```

HTML templates храним у себя, чтобы не создавать vendor lock-in.

---

# 11. Регистрация

## Главное правило

**Для основной функциональности регистрация НЕ требуется.**

Пользователь:

```text
устанавливает приложение
        ↓
открывает приложение
        ↓
сразу видит карту
```

Нет обязательного:

- email;
- имени;
- профиля собаки;
- onboarding-анкеты.

---

# 12. Что доступно без аккаунта

Без регистрации:

- карта;
- поиск;
- фильтры;
- карточки мест;
- pet-policy;
- Google rating;
- Google review link;
- события;
- навигация;
- Request Information;
- pet-review;
- сообщение об изменившихся правилах.

Некоторые настройки можно хранить локально:

- последние фильтры;
- preferred navigator;
- local favorites;
- notification preferences.

---

# 13. Когда нужен аккаунт

Регистрация предлагается только при необходимости:

- синхронизация Favorites;
- Dog Profile;
- несколько собак;
- cross-device sync;
- история;
- персонализация.

Позже желательно:

```text
Sign in with Google
Sign in with Apple
```

Email/password оставить дополнительным способом.

---

# 14. Anonymous user

При первом запуске генерируется:

```text
anonymousId = UUID
```

Он хранится локально.

Например:

```text
anonymousId = 82eae...
```

Мы можем понимать поведение одного анонимного устройства без получения:

- имени;
- email;
- номера телефона.

---

# 15. Карта — главный экран

После запуска:

```text
┌────────────────────────────────┐
│ Search                     ⚙   │
│                                │
│ [Indoor] [Large dogs] [More]  │
│                                │
│             MAP                │
│                                │
│     🐾               🐾       │
│                                │
│           ● Google POI         │
│                                │
└────────────────────────────────┘
```

Карта является core-продуктом.

---

# 16. Google Maps

Используем native Google Maps SDK:

```text
Android → Google Maps SDK
iOS     → Google Maps SDK
```

На карте уже существуют обычные Google POI:

- рестораны;
- кафе;
- отели;
- магазины;
- парки;
- другие места.

Это позволяет избежать пустой карты при старте.

---

# 17. Два слоя карты

## Google layer

Обычные Google POI.

## Наш Pet Layer

Наши собственные маркеры.

Например:

```text
🐾 зелёный
Verified pet-friendly

🐾 серый
Community information

обычный Google POI
pet-data отсутствует
```

---

# 18. Google как каталог заведений

Мы не собираемся создавать полный каталог ресторанов Баку самостоятельно.

Используем Google как discovery layer.

Google предоставляет:

- существование места;
- название;
- фотографии;
- Google rating;
- review count;
- обычные данные POI.

Мы предоставляем:

- pet-policy;
- pet-rating;
- verified information;
- pet-reviews;
- community reports;
- events;
- Request Information.

---

# 19. Google Places UI Kit

Для отображения Google-информации используем:

**Google Places UI Kit / Compact Place Details**

Design target:

```text
Google Maps     ★ 4.6 (1 284)  ›
```

Вся строка кликабельная.

По нажатию:

```text
→ Google Maps
→ конкретное заведение
→ Google reviews
```

Google reviews мы к себе не копируем.

---

# 20. Google Content

Google отвечает за:

```text
Название
Фото
Google rating
Google review count
Google reviews
Opening hours
Website
Phone
```

Наше приложение не должно пытаться копировать эти данные в собственный постоянный dataset.

Главная долговременная связь:

```text
googlePlaceId
```

---

# 21. Карточка места

Пример:

```text
Paul Port Baku
Restaurant

[ PHOTO ]

Google Maps       ★ 4.6 (1 284) ›


🐾 PET INFORMATION

✓ Dogs allowed inside
✓ Terrace available
Inside: up to 10 kg
Terrace: any size

✓ Water bowl
Leash required

Verified by venue
23 Sep 2026


🐾 Pet rating
4.8 / 5
37 ratings


[ Navigate ]
[ Leave pet review ]
```

---

# 22. Неизвестное заведение

Если пользователь нажимает Google POI, которого у нас нет:

```text
Paul

Google Maps ★ 4.6 (1 284) ›


🐾 Pet information

No verified information yet.

[ Request information ]

Know the rules?
[ Tell us ]
```

---

# 23. Автоматическое создание Place stub

При первом открытии неизвестного Google Place:

backend получает:

```text
googlePlaceId
```

Если записи нет:

создаём минимальную собственную запись:

```text
Place

id
google_place_id

status = DISCOVERED
pet_policy_status = UNKNOWN

first_seen_at
last_seen_at
```

Google-контент туда не копируется.

---

# 24. Analytics при открытии неизвестного Place

Сразу начинаем считать:

```text
views_count
unique_views_count
navigation_count
request_information_count
review_attempt_count
```

Это используется CRM.

---

# 25. Demand-driven Verification

Мы НЕ обзваниваем весь Google Maps подряд.

Заведения проверяются исходя из пользовательского спроса.

Цикл:

```text
Google POI
   ↓
user opens
   ↓
analytics
   ↓
demand score
   ↓
CRM priority
   ↓
operator calls
   ↓
verified pet-policy
```

---

# 26. Request Information

Это одна из core-функций продукта.

Если pet-policy неизвестна:

```text
[ Request information ]
```

Смысл:

**«Я хочу узнать правила именно этого места. Пожалуйста, свяжитесь с заведением».**

Регистрация НЕ требуется.

---

# 27. Request Information UX

До запроса:

```text
🐾 Pet information

No verified information yet.

[ Request information ]
```

После:

```text
✓ Information requested

We'll try to verify this place.
```

Повторное нажатие с того же anonymousId не создаёт новый уникальный request.

---

# 28. Request Information — высший user intent

Сигналы по силе:

```text
Impression
     ↓
Place Open
     ↓
Favorite
     ↓
Navigate
     ↓
Request Information
```

`REQUEST_INFORMATION` — самый сильный пользовательский сигнал для CRM.

---

# 29. Demand Score

Пример начальной формулы:

```text
uniquePlaceOpen       × 1
detailView            × 2
favorite              × 3
navigationClick       × 5
petReviewStart        × 5
policyReport          × 8
requestInformation    × 15
```

Вес позже корректируется по реальным данным.

---

# 30. CRM Priority

Например:

```text
MADO Nizami

Unique opens:          93
Navigation clicks:     18
Information requests:   7

Priority: URGENT
```

---

# 31. CRM — User Requested

Отдельная очередь:

```text
🔥 USERS REQUESTED

1. MADO Nizami
   7 requests

2. Paul Port Baku
   5 requests

3. Chinar
   4 requests
```

Эта очередь имеет максимальный приоритет.

---

# 32. CRM задачи

Причины:

```text
SEED_LEAD
DISCOVERY
HIGH_DEMAND
USER_INFORMATION_REQUEST
USER_POLICY_REPORT
SCHEDULED_REVERIFICATION
```

---

# 33. Seed Leads

До появления реальной аналитики можно собрать стартовый список известных pet-friendly кандидатов:

- свежие статьи;
- локальные обзоры;
- списки заведений;
- известные pet-friendly places.

НО:

эти данные НЕ показываем пользователю как наши pet-policy.

Используем только для CRM.

---

# 34. Seed Lead

Например:

```text
Nomad Bakery

Google Place ID: ...
Source: 1news
Source date: May 2026
External claim: pet-friendly

Status: TO_CALL
Priority: HIGH
```

После нашего звонка:

```text
VERIFIED
```

И только тогда правила попадают в публичный pet-layer.

---

# 35. Внешние списки

Внешние статьи / приложения / каталоги:

НЕ становятся частью публичной базы автоматически.

Используются исключительно как:

```text
внутренние лиды для обзвона
```

Приоритет:

```text
1. Request Information
2. High real user demand
3. Fresh seed leads
4. Other discovered places
```

---

# 36. Статусы Place

Основные:

```text
DISCOVERED
COMMUNITY_DATA
VERIFIED
NEEDS_REVERIFICATION
NOT_PET_FRIENDLY
CLOSED
UNREACHABLE
```

---

# 37. DISCOVERED

Пользователь заинтересовался заведением.

Но pet-policy неизвестна.

---

# 38. COMMUNITY_DATA

Есть ответы пользователей.

Но заведение ещё не подтвердило правила.

---

# 39. VERIFIED

Оператор связался с заведением.

Pet-policy подтверждена.

---

# 40. NEEDS_REVERIFICATION

Причины:

- прошло много времени;
- появились конфликтующие user reports;
- пользователь сообщил об изменении;
- venue обновило правила.

---

# 41. Verification CRM

CRM должна быть собственной.

Не нужен Salesforce/HubSpot на старте.

Она слишком специфична для продукта.

---

# 42. CRM Dashboard

Пример:

```text
TODAY

Active users                384
Place opens               1 927
Navigation clicks           217
Information requests         41
Pet reviews                  34
```

Database:

```text
Discovered                  812
Verified                    243
Community                    91
Unknown                     478
```

CRM:

```text
User requested               19
Need verification            63
High priority                18
Callbacks                     7
Reverify                     12
```

---

# 43. Most Requested Unknown

```text
1. MADO Nizami

Information requests: 9
Opens:               183
Navigate:              34


2. Paul Port Baku

Information requests: 6
Opens:               144
Navigate:              29
```

---

# 44. CRM workflow

```text
NEW
 ↓
TO_CALL
 ↓
CALLING

 ├── VERIFIED
 ├── CALLBACK
 ├── NO_ANSWER
 ├── REFUSED
 ├── UNREACHABLE
 └── CLOSED
```

---

# 45. Caller Dashboard

```text
Nigar

Today's queue: 32

🔥 USER REQUESTED
MADO
Paul
Chinar

HIGH
Cafe X
Restaurant Y

NORMAL
...
```

---

# 46. Caller metrics

Для внутренней операционной аналитики:

```text
Calls today
Successful verification
No answer
Callback
Refused
```

Не использовать как жёсткий performance-ranking сотрудников на старте.

---

# 47. Verification Questionnaire

CRM форма должна быть структурированной.

Не просто `notes`.

---

# 48. Общий статус

```text
Dogs allowed?

○ Yes
○ No
○ Under certain conditions
```

---

# 49. Indoor

```text
Dogs allowed inside?

○ Yes
○ No

Maximum weight:
[ ] kg

Allowed sizes:
□ Small
□ Medium
□ Large
□ Any
```

---

# 50. Terrace

```text
Dogs allowed on terrace?

○ Yes
○ No

Max weight:
[ ] kg
```

---

# 51. Outdoor / Garden

То же отдельно:

```text
OUTDOOR
GARDEN
```

---

# 52. Ограничения

```text
□ Leash required
□ Muzzle required
□ Carrier required
□ Dogs not allowed on furniture
□ Maximum number of dogs
□ Restricted hours
```

---

# 53. Породы

```text
Restricted breeds?

[ free text / structured list later ]
```

---

# 54. Amenities

```text
□ Water bowl
□ Dog menu
□ Treats
□ Dog area
□ Outdoor seating
```

---

# 55. Дополнительные вопросы

```text
Extra charge for dogs?
Restricted hours?
Special rules?
Anything else?
```

---

# 56. Verification Source

Сохраняем:

```text
VENUE_OWNER
VENUE_MANAGER
VENUE_EMPLOYEE
WEBSITE
COMMUNITY
OTHER
```

---

# 57. Verification metadata

```text
verified_at
verified_by_admin
source
contact_role
notes
```

В приложении:

```text
✓ Verified by venue
23 Sep 2026
```

---

# 58. Версионирование policy

Правила не перезаписываются бесследно.

Пример:

```text
12 Jun 2026

Indoor <= 10kg
Terrace any size
```

после изменения:

```text
23 Sep 2026

Indoor <= 15kg
Terrace any size
```

История сохраняется.

---

# 59. Re-verification

Можно автоматически создавать задачу спустя:

```text
3–6 месяцев
```

Точный период зависит от confidence / количества user reports.

---

# 60. Community Reports

Пользователь может сказать:

```text
Rules changed?
[ Report ]
```

---

# 61. User report не меняет policy автоматически

Например:

```text
Current verified:
Indoor <=10kg
```

Три пользователя сообщили:

```text
Refused
Refused
Terrace only
```

Мы НЕ меняем policy автоматически.

Создаём:

```text
POSSIBLE_POLICY_CHANGE
```

и CRM-задачу.

---

# 62. CRM recheck

Оператор видит:

```text
⚠ Possible policy change

Current:
Indoor <= 10kg

Reports:
3 conflicting reports

Last verified:
4 months ago

[ Call venue ]
```

---

# 63. Pet Rating

Отдельная система от Pet Policy.

## Pet Policy

Факты:

```text
Indoor <= 10 kg
Terrace any size
Leash required
Water available
```

## Pet Rating

Субъективно:

```text
🐾 4.8 / 5
37 ratings
```

---

# 64. Pet Review

Не обычное текстовое поле.

Структурированная форма.

---

# 65. Review Questions

```text
Were you allowed with your dog?

○ Inside
○ Terrace only
○ Not allowed
○ Didn't ask / Don't know
```

---

# 66. Dog size

```text
○ Small
○ Medium
○ Large
```

При наличии профиля можно prefill.

---

# 67. Ограничения

```text
□ Leash
□ Muzzle
□ Carrier
□ Weight restriction
□ Other
```

---

# 68. Amenities

```text
□ Water
□ Dog menu
□ Dog area
□ Treats
```

---

# 69. Rating

```text
How pet-friendly was the place?

★ ★ ★ ★ ★
```

---

# 70. Review after Navigation

Когда пользователь нажимает:

```text
Navigate
```

мы считаем это сильным сигналом, что он собирается посетить заведение.

---

# 71. Local Notification

После Navigate локально сохраняем:

```text
placeId
timestamp
```

Через условные 2–3 часа:

```text
🐾 How did Paul welcome your dog?

Help other dog owners.
It takes about 20 seconds.
```

---

# 72. Notification Deep Link

```text
app://places/{placeId}/review
```

Нажатие сразу открывает review form.

---

# 73. Регистрация для Review не нужна

Это принципиально.

Пользователь может оставить pet-data анонимно.

---

# 74. Notification Settings

Настройка:

```text
Ask me about places I navigate to
```

Пользователь должен иметь возможность отключить эту механику.

---

# 75. Notify after Request Information

Позже можно реализовать:

пользователь запросил информацию:

```text
Request Information
```

оператор проверил место:

```text
VERIFIED
```

пользователь получает:

```text
🐾 We checked Paul

Dogs up to 10 kg are allowed inside.
Terrace has no size restrictions.
```

---

# 76. Analytics

Analytics — core architecture.

Не просто маркетинговая статистика.

Она определяет:

- спрос;
- CRM priority;
- re-verification;
- product decisions.

---

# 77. Analytics events

Основные:

```text
APP_OPEN

MAP_OPEN
MAP_MOVE
MAP_ZOOM

FILTER_OPEN
FILTER_APPLY
FILTER_CLEAR

SEARCH
SEARCH_RESULT_OPEN

PLACE_IMPRESSION
PLACE_OPEN

PET_INFO_VIEW
PET_INFO_MISSING_VIEW

REQUEST_INFORMATION

GOOGLE_REVIEWS_OPEN

NAVIGATION_CLICK
NAVIGATION_PROVIDER_SELECTED

FAVORITE_ADD
FAVORITE_REMOVE

EVENT_VIEW
EVENT_NAVIGATE

PET_REVIEW_START
PET_REVIEW_SUBMIT

POLICY_REPORT

DOG_PROFILE_CREATE

REGISTRATION_START
REGISTRATION_COMPLETE
```

---

# 78. analytics_events

Пример:

```text
id
anonymous_user_id
user_id nullable

session_id

event_type

place_id nullable
event_id nullable

metadata

created_at
```

---

# 79. Analytics storage

На MVP можно хранить в PostgreSQL.

При росте объёмов analytics можно вынести отдельно:

```text
ClickHouse
PostHog
BigQuery
другая analytics infrastructure
```

Но раньше времени не усложнять.

---

# 80. Demand Coverage

Главная coverage-метрика:

НЕ:

```text
243 из 1000 ресторанов verified
```

А:

```text
какой процент реального пользовательского спроса
приходится на места с Verified pet-data
```

Например:

```text
Verified places = 30% базы

BUT

Verified places получают 92%
всех Place Opens
```

Это значит, что продукт покрывает реальный пользовательский спрос очень хорошо.

---

# 81. Google Reviews

Мы не делаем собственную копию Google reviews.

В приложении:

```text
Google Maps   ★ 4.6 (1 284) ›
```

Нажатие:

```text
→ Google Maps
```

---

# 82. Google Rating

Google rating ≠ Pet Rating.

Отображать рядом можно:

```text
Google Maps   ★ 4.6 (1 284)

🐾 Pet rating 4.8 (37)
```

---

# 83. Filters

Все работают без профиля.

---

# 84. Place type

```text
Restaurants
Cafes
Parks
Beaches
Hotels
Malls
Vet clinics
Grooming
Pet shops
Events
```

---

# 85. Access filters

```text
Indoor
Terrace
Outdoor
Any
```

---

# 86. Dog size

```text
Small
Medium
Large
Any
```

---

# 87. Weight

Дополнительный фильтр:

```text
Max allowed weight
```

---

# 88. Rules

```text
No muzzle required
No carrier required
Leash allowed / required
```

---

# 89. Amenities

```text
Water
Dog menu
Dog area
Treats
```

---

# 90. General filters

```text
Open now
Distance
Google rating
Verified only
```

---

# 91. Filter Persistence

Даже без аккаунта последние фильтры сохраняются локально.

Например:

```text
Large dog
Indoor
Verified only
```

следующий запуск сохраняет выбор.

---

# 92. Dog Profile

Не обязательный onboarding.

Пользователь может позже создать:

```text
Luna

Toy Poodle
6.5 kg
Female
```

---

# 93. Personalized compatibility

После Dog Profile вместо:

```text
Dogs <= 10kg
```

можно показывать:

```text
✓ Suitable for Luna
```

---

# 94. Multiple Dogs

В будущем:

```text
Luna
Rex
```

И пользователь выбирает:

```text
Who are you going with?
```

---

# 95. Navigation

Кнопка:

```text
Navigate
```

---

# 96. Navigator picker

```text
Open with:

Google Maps
Waze
Apple Maps
Yandex Navigator
2GIS
```

---

# 97. Preferred Navigator

Настройка:

```text
Default navigator: Waze
```

Если выбран default:

обычный tap открывает сразу Waze.

Отдельная стрелка или long press позволяет выбрать другой.

---

# 98. Route calculation

Наш backend НЕ рассчитывает маршруты.

Мы просто передаём:

```text
latitude
longitude
```

в выбранный навигатор.

---

# 99. Events

Отдельный раздел.

Типы:

```text
Dog walks
Dog festivals
Dog shows
Training
Adoption events
Breed meetups
Veterinary events
```

---

# 100. Event Card

```text
Dog Walk — Baku Boulevard

27 Sep
18:00

Free

Small / Medium / Large dogs

[ Open on map ]
[ Navigate ]
[ Save ]
```

---

# 101. Events on map

Events могут отображаться отдельными маркерами.

---

# 102. Event Management

В Admin:

```text
create
edit
publish
unpublish
cancel
```

---

# 103. Database — основные сущности

```text
places
external_place_refs

place_access_rules
place_amenities

place_verifications
place_policy_versions

pet_ratings
pet_reviews

user_reports
place_information_requests

events
event_places

users
dog_profiles
favorites

crm_seed_leads
crm_contacts
crm_tasks
crm_calls

analytics_events

admin_users
```

---

# 104. places

Пример:

```text
id
google_place_id

status
pet_policy_status

location GEOGRAPHY(Point)

first_seen_at
last_seen_at

created_at
updated_at
```

Не обязательно хранить Google name/photo/rating как собственные долговременные данные.

---

# 105. external_place_refs

```text
id

place_id

provider
external_id

created_at
```

Например:

```text
provider = GOOGLE
external_id = ChIJ...
```

---

# 106. place_access_rules

Не использовать один огромный JSON.

```text
id
place_id

area

allowed

max_weight_kg

leash_required
muzzle_required
carrier_required

max_dogs

notes
```

---

# 107. Areas

```text
INDOOR
TERRACE
OUTDOOR
GARDEN
```

---

# 108. place_amenities

```text
place_id

WATER
DOG_MENU
TREATS
DOG_AREA
OUTDOOR_SEATING
```

---

# 109. place_verifications

```text
id
place_id

source

verified_at
verified_by_admin

contact_role
notes
```

---

# 110. place_policy_versions

Хранит историю изменений.

```text
id
place_id

version
changed_by

reason

snapshot / normalized differences

created_at
```

---

# 111. place_information_requests

```text
id

place_id

anonymous_user_id
user_id nullable

status

created_at
resolved_at nullable
```

---

# 112. Information Request status

```text
OPEN
IN_PROGRESS
RESOLVED
CANCELLED
```

---

# 113. Anti-spam Information Request

Один пользователь не должен искусственно повышать priority повторными кликами.

Уникальность:

```text
place_id + anonymous_user_id
```

для anonymous.

Для account:

```text
place_id + user_id
```

---

# 114. pet_reviews

```text
id
place_id

anonymous_user_id nullable
user_id nullable

visit_result
dog_size
dog_weight nullable

pet_rating

created_at
```

---

# 115. user_reports

```text
id
place_id

type

anonymous_user_id
user_id nullable

message nullable

created_at
status
```

---

# 116. CRM aggregation

На один Place обычно должна существовать одна активная verification-задача.

Не создавать 20 CRM tasks из-за 20 пользователей.

Агрегировать:

```text
place_id

unique_requesters
request_count
navigation_count
reports_count

priority_score
```

---

# 117. crm_seed_leads

Для внешних стартовых списков.

```text
id

google_place_id nullable

source
source_url nullable
source_date nullable

source_note

status
priority

assigned_to nullable
created_at
```

---

# 118. Seed Lead lifecycle

```text
External list
    ↓
CRM seed lead
    ↓
operator calls
    ↓
verification
    ↓
Place / policy
    ↓
public data
```

---

# 119. Admin Roles

Минимум:

```text
ADMIN
CALLER
EDITOR
EVENT_MANAGER
```

---

# 120. CALLER

Может:

- смотреть assigned calls;
- видеть place;
- заполнять verification;
- назначать callback;
- добавлять call notes.

Не может:

- удалять пользователей;
- менять system configuration;
- удалять critical data.

---

# 121. Languages

Сразу архитектурно заложить:

```text
AZ
RU
EN
```

Большая часть pet-policy структурирована.

Например:

```text
WATER_AVAILABLE
LEASH_REQUIRED
INDOOR_ALLOWED
```

поэтому переводится интерфейсом.

---

# 122. Public user-generated text

Свободные пользовательские тексты лучше минимизировать на MVP.

Основную информацию собирать через structured forms.

Это:

- упрощает модерацию;
- перевод;
- аналитику;
- сравнение данных;
- verification.

---

# 123. Privacy

Нужно максимально минимизировать персональные данные.

Anonymous experience должен быть полноценным.

Не собирать email просто «потому что можем».

---

# 124. Geolocation

Не требовать геолокацию при первом запуске.

Можно показать карту Баку.

Геолокация запрашивается, например, после:

```text
Show places near me
```

---

# 125. Notifications

Не запрашивать Push permission сразу на первом экране без контекста.

Лучше запросить тогда, когда пользователь впервые использует сценарий, где уведомление имеет понятную ценность.

Например:

```text
Navigate
↓
Would you like us to ask later how your visit went?
```

или при:

```text
Request Information
```

---

# 126. Photos

Собственные community photos можно добавить позже.

На MVP можно использовать Google photos через Google UI component для общей части карточки.

---

# 127. Search

Два источника:

```text
Google Places discovery
+
наша собственная pet database
```

Если пользователь ищет обычное место, которого у нас нет, он всё равно должен его найти.

---

# 128. Search flow

```text
Search "Paul"
   ↓
Google Place
   ↓
Open
   ↓
lookup googlePlaceId in our DB
```

Если есть:

```text
Google content
+
pet content
```

Если нет:

```text
Google content
+
Request Information
```

---

# 129. SEO

Web должен генерировать страницы:

```text
Pet-friendly restaurants in Baku

Dog-friendly cafes in Baku

Can I bring my dog to Paul Port Baku?

Dog events in Baku
```

---

# 130. Public verified pages

После verification Place может иметь публичную SEO page.

До verification можно ограничить индексирование, если своей информации практически нет.

---

# 131. Repo structure

```text
pet-platform/

├── mobile/
│   ├── shared/
│   ├── androidApp/
│   └── iosApp/
│
├── web/
│   ├── site/
│   └── admin/
│
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/
│
├── docs/
└── infra/
```

---

# 132. KMP shared modules

Возможная структура:

```text
shared/

core/
network/
database/
analytics/

places/
events/
navigation/
reviews/
filters/
profile/
```

---

# 133. Repository pattern

Например:

```text
PlaceRepository
EventRepository
ReviewRepository
AnalyticsRepository
```

Platform-specific детали скрыты.

---

# 134. Use Cases

Например:

```text
GetNearbyPlacesUseCase

GetPlacePetPolicyUseCase

RequestPlaceInformationUseCase

SubmitPetReviewUseCase

NavigateToPlaceUseCase

TrackPlaceOpenUseCase
```

---

# 135. Google abstraction

Не размазывать Google SDK по business layer.

Например:

```text
ExternalPlaceProvider
```

Реализация:

```text
GooglePlaceProvider
```

Чтобы business domain не зависел напрямую от конкретного Google SDK.

---

# 136. Analytics abstraction

```text
AnalyticsService.track(event)
```

Business code не должен напрямую зависеть от конкретной analytics platform.

---

# 137. Notification abstraction

```text
NotificationService
```

Отдельно:

```text
LocalNotificationService
RemoteNotificationService
```

---

# 138. Navigation abstraction

```text
NavigatorProvider
```

Реализации:

```text
GoogleMapsNavigator
WazeNavigator
AppleMapsNavigator
YandexNavigator
TwoGisNavigator
```

---

# 139. MVP — Public

Первая версия:

```text
Map

Google POI discovery

Search

Filters

Place details

Google rating

Pet Policy

Pet Rating

Request Information

Navigate

Pet Review

Policy Report

Events

Anonymous Analytics

Review-after-navigation notification
```

---

# 140. MVP — Admin

```text
Places

CRM

Seed Leads

User Request queue

Call queue

Verification questionnaire

Verification history

Policy versions

Community Reports

Reverification queue

Events

Analytics Dashboard

Demand scoring

Demand coverage
```

---

# 141. Что НЕ входит в MVP

Не делать:

```text
Social feed
Chat
Nearby dog owners
Dog dating
Marketplace
Pet taxi
Vet booking
Groomer booking
Complex gamification
```

---

# 142. Основной product loop

```text
Google Place
    ↓
User discovers place
    ↓
User opens place
    ↓
Unknown pet policy
    ↓
Stub created
    ↓
Analytics tracks demand
    ↓
User can request information
    ↓
CRM priority increases
    ↓
Operator calls venue
    ↓
Pet policy verified
    ↓
Place becomes useful
    ↓
User navigates
    ↓
Local review notification
    ↓
User reports real experience
    ↓
Community monitors freshness
    ↓
Conflicts trigger CRM re-verification
```

---

# 143. Priority model

Практический порядок CRM:

```text
1. USER_INFORMATION_REQUEST

2. USER_POLICY_REPORT /
   strong conflict with verified data

3. HIGH REAL USER DEMAND
   many Navigate / Open

4. FRESH SEED LEADS

5. OTHER DISCOVERED PLACES
```

---

# 144. Первоначальное наполнение

Перед запуском:

1. собрать небольшой список мест-кандидатов;
2. сопоставить с Google Places;
3. добавить только как CRM Seed Leads;
4. оператор звонит;
5. verified policy публикуется.

Цель:

не обязательно иметь тысячи заведений.

Лучше иметь:

```text
100–300 качественно проверенных
и востребованных мест
```

чем:

```text
5000 сомнительных записей
```

---

# 145. Внутренний data moat

Главный актив проекта со временем:

```text
Place X

Indoor:
dogs <= 10kg

Terrace:
any dog

Leash:
required

Water:
available

Dog menu:
no

Verified:
venue manager

Verified at:
3 weeks ago
```

Такие данные сложно быстро скопировать.

---

# 146. Store Accounts

Для публикации понадобятся:

## Apple

Apple Developer Program.

Для нормального бренда желательно Organization Account.

## Google

Google Play Console developer account.

---

# 147. Domain

Нужен собственный домен:

```text
domain.com
```

Примеры:

```text
www.domain.com
admin.domain.com
api.domain.com
```

---

# 148. Инфраструктура на MVP

Возможный бесплатный/дешёвый набор:

```text
Supabase Free
Resend Free
Cloudflare Free
Google Maps mobile
Google Places UI Kit
FCM
APNs
```

---

# 149. Пример расходов первого этапа

Без разработки:

```text
Supabase            $0 initially

Email               $0

Push                $0

Cloudflare          $0 initially

Domain              ~$10–25/year

Apple Developer     $99/year

Google Play         ~$25 registration
```

Google Places usage зависит от выбранного UI Kit / usage volume.

---

# 150. Масштабирование

При росте:

```text
Supabase Pro
Cloudflare R2
Dedicated analytics
Separate worker/backend
Own PostgreSQL if necessary
```

Но всё это не нужно заранее.

---

# 151. Google Places technical spike

Перед активной mobile-разработкой сделать маленький prototype.

Проверить:

```text
Google POI tap
       ↓
placeId
       ↓
our Place lookup
       ↓
Google Places UI Kit Compact
       ↓
our pet section
```

Особенно проверить возможность получить дизайн:

```text
Google Maps   ★ 4.6 (1 284) ›
```

без лишней большой Google-карточки.

---

# 152. KMP technical spike

Проверить:

```text
shared Kotlin domain model

Android Compose
+
iOS SwiftUI

Swift ↔ Kotlin interop
```

Особенно:

- coroutines;
- Flow;
- errors;
- nullable types;
- serialization.

---

# 153. Analytics technical spike

На MVP можно писать события через backend.

Но стоит сразу определить:

- event names;
- event schema;
- anonymousId;
- sessionId;
- placeId;
- metadata conventions.

---

# 154. Development order

## Phase 0 — Technical Prototypes

1. Google Maps POI → Place ID.
2. Places UI Kit Compact.
3. KMP ↔ SwiftUI interop.
4. Supabase + PostGIS query.

---

## Phase 1 — Backend / Schema

Создать:

```text
database
migrations
PostGIS
Place
Pet Policy
Verification
Information Request
Analytics
CRM entities
```

---

## Phase 2 — Admin / CRM

Это желательно сделать очень рано.

Пока создаётся mobile приложение, оператор уже может собирать данные.

Реализовать:

```text
login

CRM queue

place page

verification questionnaire

call status

request information queue

reports

seed leads

priority score
```

---

## Phase 3 — Android MVP

Поскольку KMP Kotlin-centric, Android удобно использовать первым mobile client.

Реализовать:

```text
Map
Google POI
Place Card
Google Compact
Pet Layer
Filters
Request Information
Navigate
Review
Analytics
Notifications
```

---

## Phase 4 — iOS

Использовать тот же KMP core.

Реализовать UI на SwiftUI.

---

## Phase 5 — Web

Angular SSR:

```text
map
place pages
events
SEO pages
```

---

## Phase 6 — Accounts

Добавить:

```text
Google login
Apple login
Favorites sync
Dog Profile
cross-device sync
```

---

# 155. Product launch strategy

Сначала:

**Баку.**

Не пытаться сразу покрывать весь Азербайджан или несколько стран.

Причина:

качество базы важнее географии.

---

# 156. Launch metrics

Особенно отслеживать:

```text
Monthly active users

Place opens

Navigation clicks

Information requests

Pet reviews

Policy reports

Verified demand coverage

Average verification time

Request → verified conversion
```

---

# 157. Очень важная метрика

Время:

```text
Request Information
        ↓
Venue Verified
```

Например:

```text
median = 8 hours
```

Если команда сможет быстро отвечать пользователям, это может стать реальной конкурентной фишкой.

---

# 158. CRM SLA

В перспективе можно ввести:

```text
USER REQUESTED

Target:
call within 24h
```

При росте:

```text
URGENT
HIGH
NORMAL
```

---

# 159. Potential future feature

Можно показывать:

```text
3 people requested information about this place
```

Но только если это реально улучшает UX.

Не обязательно для MVP.

---

# 160. Potential venue self-service

В будущем заведение сможет самостоятельно:

```text
Claim this place
```

И управлять pet-policy.

Но изменения не обязательно должны публиковаться автоматически без moderation.

---

# 161. Venue Portal — later

Заведения смогут:

- обновлять policy;
- добавлять amenities;
- добавлять events;
- видеть pet-owner interest;
- покупать promotion.

Не MVP.

---

# 162. Потенциальная монетизация

Позже:

```text
Featured places
Promoted events
Pet brands
Vet advertising
Pet shop advertising
Hotels
Venue premium profiles
```

При этом core pet-policy нельзя делать pay-to-play.

Нельзя превращать:

```text
"pet-friendly"
```

в рекламный статус.

---

# 163. Trust model

Очень важно всегда показывать происхождение информации.

Например:

```text
Verified by venue
23 Sep 2026
```

или:

```text
Community information
3 recent reports
```

---

# 164. Confidence / freshness

Позже можно вычислять:

```text
HIGH
MEDIUM
LOW
```

на основе:

- verification age;
- количество подтверждений;
- количество конфликтов;
- source quality.

---

# 165. Freshness indicators

Например:

```text
Verified 8 days ago
```

или:

```text
⚠ Information may be outdated
```

---

# 166. No false certainty

Если данных нет:

не писать:

```text
Not pet-friendly
```

Нужно писать:

```text
Pet policy unknown
```

Это принципиальное отличие.

---

# 167. CLOSED LOOP DATA SYSTEM

Полная модель:

```text
GOOGLE
    ↓
DISCOVERY
    ↓
USER INTEREST
    ↓
ANALYTICS
    ↓
REQUEST INFORMATION
    ↓
CRM PRIORITY
    ↓
VENUE CALL
    ↓
VERIFIED PET POLICY
    ↓
NAVIGATION
    ↓
REAL VISIT
    ↓
PET REVIEW
    ↓
COMMUNITY SIGNALS
    ↓
REVERIFICATION
    ↓
UP-TO-DATE PET DATA
```

---

# 168. Главная продуктовая идея

Мы не строим ещё одну карту.

Мы строим:

**Pet Intelligence Layer поверх городской карты.**

---

# 169. Главная бизнес-ценность

Google знает:

```text
Paul
4.6 ★
Restaurant
Open until 23:00
```

Мы знаем:

```text
dogs <= 10kg indoors

any size on terrace

leash required

water available

verified 12 days ago

pet rating 4.8
```

---

# 170. Главная защита продукта

Карту повторить легко.

Кнопку Waze повторить легко.

Google rating повторить легко.

Но сложно повторить:

**структурированную, свежую и проверенную базу реальных pet-policy, постоянно обновляемую через CRM + community feedback + пользовательский спрос.**

Именно вокруг этого должна строиться вся архитектура продукта.
