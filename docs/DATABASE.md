<div dir="rtl" lang="fa">

# راهنمای جامع پایگاه دادهٔ PlanAct

این سند مرجع توسعه‌دهنده برای **ساختار فعلی ذخیره‌سازی**، جدول‌ها، ستون‌ها، ارتباط‌ها و قواعد کار با پایگاه داده است. مبنا: کد مخزن در ۲۰۲۶-۱۰-۱۴، نسخهٔ برنامه <span dir="ltr">`0.1.15+8`</span> و schema شخصی **۱۸**. وجود یک جدول به‌تنهایی به معنی آماده‌بودن قابلیت متناظر برای انتشار نیست.

مرجع اجرایی schema، [<span dir="ltr">app_database.dart</span>](../lib/core/database/app_database.dart) است؛ کد SQL تولیدشده در [<span dir="ltr">app_database.g.dart</span>](../lib/core/database/app_database.g.dart) قرار دارد. رفتار محصول از [<span dir="ltr">PRD</span>](product/PRD.md)، تصمیم‌های مصوب از [ADRها](adr/) و قواعد پیاده‌سازی از [<span dir="ltr">AGENTS.md</span>](../AGENTS.md) می‌آیند. این سند آن منابع را توضیح می‌دهد و تصمیم جدیدی دربارهٔ رفتار داده‌ها ایجاد نمی‌کند.

## فهرست

1. [معماری و فایل‌های پایگاه داده](#1-storage)
2. [انواع جدول و فهرست کامل](#2-catalog)
3. [نمای کلی و روابط](#3-relations)
4. [قرارداد نام‌گذاری و نوع داده](#4-types)
5. [فرهنگ ستون‌های تمام جدول‌ها](#5-columns)
6. [کدهای enum ذخیره‌شده](#6-enums)
7. [JSON، metadata و داده‌های خارج از ستون‌های اصلی](#7-metadata)
8. [قیود، ایندکس‌ها و triggerها](#8-constraints)
9. [قواعد نوشتن، تاریخچه و محاسبات](#9-writes)
10. [نسخه‌بندی و migration](#10-migrations)
11. [بکاپ، restore و امنیت](#11-backup)
12. [راهنمای کار و بررسی برای توسعه‌دهنده](#12-development)
13. [دامنهٔ صحت این سند و نگهداری آن](#13-evidence)

<a id="1-storage"></a>

## ۱. معماری و فایل‌های پایگاه داده

PlanAct یک برنامهٔ local-first است. پایگاه دادهٔ اصلی relational و مبتنی بر **SQLite با Drift** است؛ فایل روی دستگاه نگهداری می‌شود و کارکرد اصلی به سرور، حساب ابری یا اینترنت وابسته نیست.

| فایل | کاربرد | نسخه / مالک |
| ---: | ---: | ---: |
| <span dir="ltr">`planact.sqlite`</span> | داده‌های شخصی، تعهد، زمان‌بندی، مالی، Inbox و تنظیمات | <span dir="ltr">`AppDatabase`، schema 18</span> |
| <span dir="ltr">`holiday-packages.sqlite`</span> | بسته‌های عمومی و امضاشدهٔ تعطیلات | <span dir="ltr">`SqliteHolidayPackageStore`، `user_version = 1`</span> |
| <span dir="ltr">`planact-schema-reference.sqlite`</span> | ساخت موقت schema مرجع برای اعتبارسنجی restore؛ پس از خواندن حذف می‌شود | <span dir="ltr">composition root</span> |
| <span dir="ltr">`planact.sqlite.restore-safety`</span> | snapshot ایمنی پیش از جایگزینی | چرخهٔ restore |
| <span dir="ltr">`planact.sqlite.restore-new`</span> | فایل آمادهٔ جایگزینی | چرخهٔ restore |
| <span dir="ltr">`planact.sqlite.restore-marker`</span> | نشانگر بازیابی در صورت قطع فرایند؛ دیتابیس نیست | چرخهٔ restore |
| <span dir="ltr">`planact.sqlite.restore-validation` / `.export-snapshot`</span> | فایل موقت اعتبارسنجی / snapshot خروجی | adapter بکاپ |

مسیر اصلی در [<span dir="ltr">BackupApplicationScope</span>](../lib/app/backup_application_scope.dart) از <span dir="ltr">`getApplicationDocumentsDirectory()`</span> گرفته می‌شود. این فایل‌ها را با مسیر ثابت مخصوص سیستم‌عامل باز نکنید. store تعطیلات مستقل از snapshot شخصی است؛ restore شخصی آن را جایگزین نمی‌کند.

یک نمونهٔ production از <span dir="ltr">`AppDatabase`</span> در composition root ساخته می‌شود و به repositoryها داده می‌شود. [<span dir="ltr">AppDatabaseLifecycle</span>](../lib/core/database/app_database_lifecycle.dart) مالک عمر آن است؛ repository نباید آن را ببندد. executor اصلی <span dir="ltr">`NativeDatabase.createInBackground`</span> است. <span dir="ltr">`AppDatabase.forTesting`</span> و repositoryهای حافظه‌ای برای تست/preview هستند.

مسیر دسترسی:

1. رویداد رابط کاربری.
2. فراخوانی command / use case در application.
3. اعتبارسنجی domain.
4. اجرای repository و transaction در لایهٔ data و نوشتن در SQLite.
5. خواندن مجدد و refresh مصرف‌کنندگان.
6. اجرای اثر platform پس از commit، در مسیرهای مربوط.

UI نباید جدول را مستقیم تغییر دهد؛ domain هم نباید به Drift یا Flutter وابسته شود. Calendar، Today و Attention projection هستند و پایگاه دادهٔ مستقل یا منبع حقیقت موازی ندارند.

<a id="2-catalog"></a>

## ۲. انواع جدول و فهرست کامل

از نظر فیزیکی، تمام **۲۴ جدول شخصی**، جدول عادی SQLite هستند؛ در تعریف فعلی <span dir="ltr">`AppDatabase`</span> هیچ view، materialized view یا virtual table ثبت نشده است. «نوع جدول» در فهرست زیر نقش معماری آن را مشخص می‌کند:

- **موجودیت اصلی:** هویت و وضعیت یک مفهوم پایدار.
- **پیکربندی:** قواعدی که رفتار آینده را تعیین می‌کنند.
- **رویداد/تاریخچه:** یک اتفاق برنامه‌ریزی‌شده یا ثبت‌شده.
- **دفتر کل (ledger):** ردیف‌های مبنای محاسبهٔ اعتبار یا موجودی.
- **واسط:** عضویت یا تخصیص در رابطهٔ چندبه‌چند.
- **ممیزی:** تصمیم‌های کاربر و دادهٔ لازم برای تشخیص تغییر/تعارض.
- **عملیاتی:** intent یا وضعیت هماهنگی با adapter.
- **staging:** دادهٔ ورودی و پیشنهاد پیش از تأیید کاربر.
- **کلید–مقدار:** تنظیمات و payloadهای نسخه‌دار.

| نام SQLite | کلاس Drift | نوع / نقش |
| ---: | ---: | ---: |
| <span dir="ltr">`schema_metadata`</span> | <span dir="ltr">`SchemaMetadata`</span> | کلید–مقدار؛ نسخه، تنظیمات، metadata و بخشی از audit |
| <span dir="ltr">`commitments`</span> | <span dir="ltr">`Commitments`</span> | موجودیت اصلی؛ تعهد پایدار |
| <span dir="ltr">`commitment_cycles`</span> | <span dir="ltr">`CommitmentCycles`</span> | موجودیت دوره/ترم/بستهٔ تعهد |
| <span dir="ltr">`schedule_definitions`</span> | <span dir="ltr">`ScheduleDefinitions`</span> | پیکربندی نسخه‌دار زمان‌بندی |
| <span dir="ltr">`occurrences`</span> | <span dir="ltr">`Occurrences`</span> | نوبت برنامه‌ریزی‌شده و وضعیت تاریخی آن |
| <span dir="ltr">`entitlement_plans`</span> | <span dir="ltr">`EntitlementPlans`</span> | پیکربندی اعتبار/حق استفادهٔ یک دوره |
| <span dir="ltr">`entitlement_ledger_entries`</span> | <span dir="ltr">`EntitlementLedgerEntries`</span> | دفتر کل اعتبار |
| <span dir="ltr">`session_policies`</span> | <span dir="ltr">`SessionPolicies`</span> | پیکربندی مصرف، غیبت و جبرانی |
| <span dir="ltr">`replacement_occurrences`</span> | <span dir="ltr">`ReplacementOccurrences`</span> | رکورد جبرانی و زنجیرهٔ جبرانی‌ها |
| <span dir="ltr">`reminder_rules`</span> | <span dir="ltr">`ReminderRules`</span> | پیکربندی یادآور برای نوبت |
| <span dir="ltr">`reminder_instances`</span> | <span dir="ltr">`ReminderInstances`</span> | intent عملیاتی اعلان مشخص |
| <span dir="ltr">`actuals`</span> | <span dir="ltr">`Actuals`</span> | تاریخچهٔ نتیجهٔ واقعی |
| <span dir="ltr">`evidences`</span> | <span dir="ltr">`Evidences`</span> | شاهد/ارجاع مربوط به نتیجه |
| <span dir="ltr">`financial_accounts`</span> | <span dir="ltr">`FinancialAccounts`</span> | موجودیت حساب مالی |
| <span dir="ltr">`account_entries`</span> | <span dir="ltr">`AccountEntries`</span> | دفتر کل مالی؛ رکورد تراکنش قابل تطبیق نیز همین است |
| <span dir="ltr">`transaction_matches`</span> | <span dir="ltr">`TransactionMatches`</span> | سرآیند ارتباط تراکنش و وضعیت اصلاح آن |
| <span dir="ltr">`match_allocations`</span> | <span dir="ltr">`MatchAllocations`</span> | واسط مبلغ‌دار میان match و نوبت |
| <span dir="ltr">`relationship_reviews`</span> | <span dir="ltr">`RelationshipReviews`</span> | ممیزی تصمیم مستقل/بازگشایی تراکنش |
| <span dir="ltr">`financial_expectations`</span> | <span dir="ltr">`FinancialExpectations`</span> | مبلغ برنامه‌ریزی‌شدهٔ اختیاری برای نوبت |
| <span dir="ltr">`tags`</span> | <span dir="ltr">`Tags`</span> | واژگان مشترک برچسب‌ها |
| <span dir="ltr">`commitment_tags`</span> | <span dir="ltr">`CommitmentTags`</span> | واسط تعهد–برچسب |
| <span dir="ltr">`account_entry_tags`</span> | <span dir="ltr">`AccountEntryTags`</span> | واسط ردیف مالی–برچسب |
| <span dir="ltr">`staged_imports`</span> | <span dir="ltr">`StagedImports`</span> | staging ورودی و منشأ آن |
| <span dir="ltr">`inbox_suggestions`</span> | <span dir="ltr">`InboxSuggestions`</span> | پیشنهاد مالی قابل بررسی |

در دیتابیس دوم، <span dir="ltr">`holiday_packages`</span> جدول مرجع عمومی است و در شمار ۲۴ جدول بالا نیست. جدول فیزیکی جداگانه‌ای به نام <span dir="ltr">`financial_transactions`</span>، <span dir="ltr">`attachments`</span>، <span dir="ltr">`remaining_sessions`</span> یا <span dir="ltr">`account_balances`</span> در <span dir="ltr">`AppDatabase`</span> وجود ندارد.

<a id="3-relations"></a>

## ۳. نمای کلی و روابط

### ۳.۱. نقشهٔ مفهومی

- **زمان‌بندی:** تعهد ← دوره ← تعریف زمان‌بندی ← نوبت.
- **اعتبار:** دوره ← برنامهٔ اعتبار ← دفتر کل اعتبار؛ سیاست جلسه نیز به دوره مربوط است.
- **یادآوری:** نوبت ← قانون یادآور ← نمونهٔ اعلان.
- **نتیجه:** نوبت ← نتیجهٔ واقعی ← شاهد.
- **مالی:** حساب مالی ← ردیف حساب ← تطبیق ← تخصیص پرداخت؛ تخصیص به نوبت مربوط می‌شود و نوبت می‌تواند انتظار مالی داشته باشد.
- **بررسی ارتباط:** ردیف حساب ← تاریخچهٔ بررسی ارتباط.
- **برچسب:** تعهد / ردیف حساب ↔ برچسب.
- **ورود اطلاعات:** ورودی staged ← پیشنهاد Inbox ← تأیید صریح ← ردیف حساب.

فلش این نقشهٔ مفهومی الزاماً FK نیست. به‌ویژه تأیید Inbox از طریق command انجام می‌شود و ستون FK مستقیمی بین suggestion و account entry وجود ندارد. موجودیت‌های مفهومی PRD را با جدول فیزیکی یکسان فرض نکنید؛ مثلاً <span dir="ltr">`reminder_rules`</span> فعلی به نوبت متصل است، نه مستقیم به cycle.

### ۳.۲. ERD دیتابیس شخصی

نمودار زیر **روابط FK تعریف‌شده در schema تازهٔ ۱۸** را نشان می‌دهد. <span dir="ltr">`||`</span> یعنی دقیقاً یک والد و <span dir="ltr">`o{`</span> یعنی صفر یا چند فرزند؛ <span dir="ltr">`o|`</span> یعنی صفر یا یک. وجود FK به‌تنهایی الزام نمی‌کند والد فرزند داشته باشد. خط پیوسته برای رابطه‌ای است که FK بخشی از PK فرزند است؛ خط نقطه‌چین برای فرزند دارای هویت مستقل است؛ هر دو FK واقعی‌اند. <span dir="ltr">`schema_metadata`</span> و <span dir="ltr">`replacement_occurrences`</span> به دلیل نداشتن FK به‌صورت مستقل آمده‌اند. ردیف‌های جدول‌های واسط کلید مرکب دارند. نمودار در پیش‌نمایش Markdown سازگار با Mermaid نمایش داده می‌شود؛ نقشهٔ متنی بالا به renderer وابسته نیست.

<div dir="ltr">

```mermaid
erDiagram
    schema_metadata {
        TEXT key PK
        TEXT value
    }
    commitments ||..o{ commitment_cycles : commitment_id
    commitment_cycles ||..o{ schedule_definitions : cycle_id
    commitment_cycles ||..o{ occurrences : cycle_id
    schedule_definitions ||..o{ occurrences : schedule_definition_id
    commitment_cycles ||..o{ entitlement_plans : cycle_id
    entitlement_plans ||..o{ entitlement_ledger_entries : plan_id
    commitment_cycles ||..o{ session_policies : cycle_id
    occurrences ||..o{ reminder_rules : occurrence_id
    reminder_rules ||..o{ reminder_instances : rule_id
    occurrences ||..o{ reminder_instances : occurrence_id
    occurrences ||..o{ actuals : occurrence_id
    actuals ||..o{ evidences : actual_id
    financial_accounts ||..o{ account_entries : account_id
    account_entries ||..o{ transaction_matches : transaction_id
    transaction_matches ||..o{ match_allocations : match_id
    occurrences ||..o{ match_allocations : occurrence_id
    account_entries ||..o{ relationship_reviews : transaction_id
    occurrences ||..o| financial_expectations : occurrence_id
    financial_accounts o|..o{ financial_expectations : account_id
    commitments ||--o{ commitment_tags : commitment_id
    tags ||--o{ commitment_tags : tag_id
    account_entries ||--o{ account_entry_tags : account_entry_id
    tags ||--o{ account_entry_tags : tag_id
    staged_imports ||..o{ inbox_suggestions : staged_import_id
    replacement_occurrences {
        TEXT id PK
        TEXT original_occurrence_id
        TEXT parent_replacement_id
    }
```

</div>

### ۳.۳. روابطی که باید جدا از FK فهمید

| ستون / داده | ارتباط منطقی | تضمین فعلی |
| ---: | ---: | ---: |
| <span dir="ltr">`replacement_occurrences.original_occurrence_id`</span> | نوبت اصلی | <span dir="ltr">`TEXT NOT NULL`</span>؛ FK ندارد |
| <span dir="ltr">`replacement_occurrences.parent_replacement_id`</span> | جبرانی قبلی | <span dir="ltr">`TEXT NULL`</span>؛ self-FK ندارد؛ domain ارجاع به خود را رد می‌کند |
| <span dir="ltr">`entitlement_ledger_entries.reference_id`</span> | منشأ مصرف/اصلاح، مثلاً occurrence یا audit | ارجاع عمومی؛ FK ندارد |
| <span dir="ltr">`account_entries.reference_id`</span> | منشأ ورودی یا ردیف مالی مرتبط، بسته به command | ارجاع عمومی؛ FK ندارد |
| <span dir="ltr">`account_entries.transfer_group_id`</span> | گروه دو سمت انتقال | شناسهٔ گروه؛ جدول transfer جدا و FK ندارد |
| <span dir="ltr">`transaction_matches.corrected_match_id`</span> | match مرتبط در تاریخچهٔ اصلاح | FK ندارد؛ semantics را command تطبیق تعیین می‌کند |
| <span dir="ltr">`inbox_suggestions.draft_id`</span> | شناسهٔ پیش‌نویس parser | جدول drafts و FK ندارد |
| <span dir="ltr">`commitments.attachment_ids` / `evidences.value`</span> | شناسه/ارجاع شاهد یا فایل | manifest یا جدول attachments در schema فعلی نیست |
| کلیدهای per-entity در <span dir="ltr">`schema_metadata`</span> | حساب، suggestion یا audit تعهد | هیچ FK یا پاک‌سازی cascade روی کلیدها وجود ندارد |

از نظر SQL، یک cycle می‌تواند چند <span dir="ltr">`entitlement_plans`</span> و چند <span dir="ltr">`session_policies`</span> داشته باشد؛ <span dir="ltr">`cycle_id`</span> در این دو جدول unique نیست. مسیر <span dir="ltr">`findByCycle`</span> سیاست جلسه انتظار صفر/یک ردیف دارد؛ این انتظار را با تضمین ۱:۱ دیتابیس اشتباه نگیرید. همچنین SQL تضمین نمی‌کند <span dir="ltr">`occurrences.cycle_id`</span> با cycle تعریف زمان‌بندی مربوط یکسان باشد، یا rule و instance به همان occurrence اشاره کنند؛ این سازگاری‌ها مسئولیت application/repository نیز هستند.

<a id="4-types"></a>

## ۴. قرارداد نام‌گذاری و نوع داده

در جدول‌های بعد، نام ستون‌ها **نام واقعی SQL با snake_case** است. معادل getter در Dart camelCase است؛ مثلاً <span dir="ltr">`schedule_definition_id`</span> ↔ <span dir="ltr">`scheduleDefinitionId`</span>.

| علامت / نوع | معنی |
| ---: | ---: |
| <span dir="ltr">`TEXT`</span> | <span dir="ltr">`String`</span> در Drift؛ برای UUID، متن، کد یا JSON |
| <span dir="ltr">`INTEGER`</span> | <span dir="ltr">`int`</span> در Drift؛ عدد صحیح، enum index یا مبلغ |
| <span dir="ltr">`INTEGER (زمان)`</span> | <span dir="ltr">`DateTimeColumn`</span> / <span dir="ltr">`DateTime`</span>؛ Unix epoch بر حسب **ثانیه** در تنظیم فعلی Drift |
| <span dir="ltr">`INTEGER (bool)`</span> | <span dir="ltr">`BoolColumn`</span> / <span dir="ltr">`bool`</span>؛ مقدار SQL صفر/یک با <span dir="ltr">CHECK</span> تولیدشدهٔ Drift |
| <span dir="ltr">NULL</span> «بله» | ستون nullable است؛ باقی ستون‌ها <span dir="ltr">`NOT NULL`</span> هستند |
| <span dir="ltr">`PK`</span> | کلید اصلی |
| <span dir="ltr">`FK → ...`</span> | <span dir="ltr">`references(...)`</span> واقعی در schema جاری |
| «—» در قید | default/قید اختصاصی ندارد؛ قواعد domain ممکن است اضافه باشند |

نکات عمومی:

- <span dir="ltr">`id`</span>های domain از نوع **UUIDv7** هستند؛ [<span dir="ltr">StableId</span>](../lib/core/ids/stable_id.dart) و [<span dir="ltr">ADR 0002</span>](adr/0002-uuidv7-stable-identifiers.md) مرجع‌اند. SQL برای تمام رشته‌های <span dir="ltr">`id`</span> اعتبار قالب UUID را CHECK نمی‌کند. هیچ شناسهٔ domain از <span dir="ltr">`rowid`</span> یا autoincrement مشتق نمی‌شود.
- استثناهای PK: <span dir="ltr">`schema_metadata.key`</span>، کلید مرکب دو جدول برچسب، و <span dir="ltr">`holiday_packages.year`</span>.
- نوع SQLite به‌تنهایی semantic نیست: <span dir="ltr">`INTEGER`</span> می‌تواند مقدار زمان، مبلغ، enum یا boolean باشد. به واحد و codec هر ستون توجه کنید.
- همهٔ مبلغ‌های مالی عدد صحیح هستند؛ <span dir="ltr">`REAL`</span>/<span dir="ltr">`double`</span> برای پول استفاده نشود. واحد durable ایرانی **IRR/ریال** است؛ انتخاب تومان فقط در ورودی/نمایش تبدیل دقیق انجام می‌دهد. نبود ارز در انتظار مالی را به IRR یا ارز حساب تبدیل نکنید.
- دقت ستون‌های <span dir="ltr">`DateTimeColumn`</span> فعلی ثانیه است؛ JSON و مقدار متنی نوبت ممکن است میلی‌ثانیه داشته باشند. در compare-and-append و fingerprint تفاوت دقت را لحاظ کنید.
- تاریخ نمایشی جلالی است، اما <span dir="ltr">`LocalDate`</span> و متن تاریخ schedule اجزای تاریخ میلادی محلی‌اند؛ مرجع **محاسبهٔ recurrence** جدا در JSON نگهداری می‌شود. تاریخ بدون ساعت را به midnight UTC تبدیل نکنید.
- تاریخ‌های cycle/entitlement/policy در schema فعلی <span dir="ltr">`DateTimeColumn`</span> هستند؛ برخلاف <span dir="ltr">`schedule_definitions.start_date`</span>، ستون date-only متنی نیستند. adapter فعلی آن‌ها را به UTC می‌نویسد؛ صرف نام <span dir="ltr">`*_date`</span> دلیل استفاده از codec <span dir="ltr">`LocalDate`</span> نیست.
- defaultهای SQL پایین الزاماً انتخاب پیش‌فرض مجاز در UX نیستند. تاریخ، زمان، مبلغ یا reminder غایب را با یک مقدار پنهان پر نکنید.

<a id="5-columns"></a>

## ۵. فرهنگ ستون‌های تمام جدول‌ها

قید PK و FK در این بخش برای **ساخت تازه با schema 18** است؛ تفاوت مسیرهای migration در بخش ۱۰ آمده است. nullable بودن، default و نوع فیزیکی جدا از اعتبارسنجی دامنه‌اند.

### ۵.۱. <span dir="ltr">`schema_metadata`</span> — کلید–مقدار پایدار

تنظیمات و payloadهای نسخه‌دار را نگه می‌دارد؛ فقط جدول نسخهٔ schema نیست. [جزئیات namespaceها](#7-metadata).

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`key`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | نام تنظیم/namespace |
| <span dir="ltr">`value`</span> | <span dir="ltr">TEXT</span> | خیر | — | رشتهٔ ساده یا JSON مطابق قرارداد key |

### ۵.۲. <span dir="ltr">`commitments`</span> — تعهد پایدار

یک مفهوم مانند «کلاس موسیقی»؛ دوره‌های متعدد آن هویت تعهد را عوض نمی‌کنند. برچسب‌های جاری از جدول واسط خوانده می‌شوند.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ تعهد |
| <span dir="ltr">`title`</span> | <span dir="ltr">TEXT</span> | خیر | — | عنوان |
| <span dir="ltr">`created_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ایجاد |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`CommitmentStatus`</span> |
| <span dir="ltr">`kind`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">DEFAULT 0</span> | <span dir="ltr">`CommitmentKind`</span> |
| <span dir="ltr">`priority`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">DEFAULT 1</span> | <span dir="ltr">`CommitmentPriority`</span> |
| <span dir="ltr">`color_key`</span> | <span dir="ltr">TEXT</span> | بله | <span dir="ltr">CHECK</span> هشت رنگ مجاز | هویت رنگی؛ <span dir="ltr">NULL</span> از palette مشترک fallback می‌گیرد |
| <span dir="ltr">`description`</span> | <span dir="ltr">TEXT</span> | بله | — | توضیح خصوصی |
| <span dir="ltr">`tags`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">DEFAULT `''`</span> | نمایش legacy برچسب‌ها؛ منبع عضویت جاری نیست |
| <span dir="ltr">`attachment_ids`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">DEFAULT `''`</span> | لیست رشته‌ای شناسهٔ پیوست‌ها |

### ۵.۳. <span dir="ltr">`commitment_cycles`</span> — دوره/ترم/بسته

خرید بستهٔ بعدی یک cycle جدید است. پایان برنامه‌ریزی‌شده با پایان واقعی یکسان نیست. <span dir="ltr">`consumed_units`</span> جای دفتر کل اعتبار را نمی‌گیرد.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ دوره |
| <span dir="ltr">`commitment_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → commitments.id</span> | تعهد مالک |
| <span dir="ltr">`cycle_type`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`CommitmentCycleType`</span> |
| <span dir="ltr">`start_date`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | شروع دوره در مدل فعلی |
| <span dir="ltr">`planned_end_date`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | پایان قراردادی/برنامه‌ریزی‌شده |
| <span dir="ltr">`actual_end_date`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | پایان واقعی |
| <span dir="ltr">`target_units`</span> | <span dir="ltr">INTEGER</span> | بله | — | هدف تعداد/واحد |
| <span dir="ltr">`consumed_units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | فیلد خلاصهٔ مصرف در مدل cycle؛ مرجع ماندهٔ اعتبار نیست |
| <span dir="ltr">`completion_rule`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`CompletionRule`</span> |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`CommitmentCycleStatus`</span> |

### ۵.۴. <span dir="ltr">`schedule_definitions`</span> — زمان‌بندی نسخه‌دار

frequency و termination دو موضوع مستقل‌اند. horizon تولید با پایان قرارداد یا count برابر نیست. [<span dir="ltr">codec recurrence</span>](#7-metadata).

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ تعریف/نسخه |
| <span dir="ltr">`cycle_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → commitment_cycles.id</span> | دورهٔ مالک |
| <span dir="ltr">`mode`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`ScheduleMode`</span> |
| <span dir="ltr">`time_semantics`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`TimeSemantics`</span> |
| <span dir="ltr">`start_date`</span> | <span dir="ltr">TEXT</span> | خیر | — | تاریخ محلی با قالب <span dir="ltr">`year-month-day`</span> |
| <span dir="ltr">`local_time`</span> | <span dir="ltr">TEXT</span> | بله | — | ساعت محلی با قالب <span dir="ltr">`hour:minute`</span> |
| <span dir="ltr">`time_zone_id`</span> | <span dir="ltr">TEXT</span> | بله | — | شناسهٔ timezone، در صورت وجود |
| <span dir="ltr">`fixed_instant`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | لحظهٔ UTC برای معنای fixed instant |
| <span dir="ltr">`recurrence_rule`</span> | <span dir="ltr">TEXT</span> | بله | — | JSON recurrence و templateهای تولید |
| <span dir="ltr">`end_date`</span> | <span dir="ltr">TEXT</span> | بله | — | انتهای تاریخ محلی؛ termination مصوب inclusive است |
| <span dir="ltr">`occurrence_count`</span> | <span dir="ltr">INTEGER</span> | بله | — | تعداد slotهای منطقی recurrence، مستقل از شمار ردیف‌ها |
| <span dir="ltr">`version`</span> | <span dir="ltr">INTEGER</span> | خیر | — | شمارهٔ نسخهٔ زمان‌بندی |
| <span dir="ltr">`effective_from`</span> | <span dir="ltr">TEXT</span> | خیر | — | تاریخ محلی شروع اثر نسخه |
| <span dir="ltr">`generation_horizon_days`</span> | <span dir="ltr">INTEGER</span> | خیر | — | پنجرهٔ عملیاتی materialization |

### ۵.۵. <span dir="ltr">`occurrences`</span> — نوبت واقعی ذخیره‌شده

UNIQUE روی <span dir="ltr">`(schedule_definition_id, occurrence_key)`</span> تولید تکراری در همان تعریف را محدود می‌کند. کنترل occupancy بین نسخه‌ها نیز لازم است.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ واقعی نوبت |
| <span dir="ltr">`cycle_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → commitment_cycles.id</span> | دوره |
| <span dir="ltr">`schedule_definition_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → schedule_definitions.id</span> | تعریف تولیدکننده |
| <span dir="ltr">`occurrence_key`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">UNIQUE</span> مرکب بالا | هویت slot در تعریف |
| <span dir="ltr">`time_semantics`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`TimeSemantics`</span> |
| <span dir="ltr">`original_scheduled_value`</span> | <span dir="ltr">TEXT</span> | خیر | — | زمان اولیه با codec صریح |
| <span dir="ltr">`current_scheduled_value`</span> | <span dir="ltr">TEXT</span> | خیر | — | زمان جاری پس از تغییر |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`OccurrenceStatus`</span> |
| <span dir="ltr">`is_manual_override`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | تغییر دستی؛ مانع بازتولید خاموش |

پیش‌نمایش آینده ردیف این جدول نیست و ID جعلی نمی‌گیرد. [جزئیات codec زمان](#7-metadata).

### ۵.۶. <span dir="ltr">`entitlement_plans`</span> — برنامهٔ حق استفاده

schedule زمان جلسه را تعیین می‌کند و entitlement حق مصرف را؛ شمار نوبت‌ها یا <span dir="ltr">`total_units`</span> به‌تنهایی ماندهٔ فعلی نیست.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ برنامهٔ اعتبار |
| <span dir="ltr">`cycle_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → commitment_cycles.id</span> | دوره |
| <span dir="ltr">`total_units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | مقدار تعریف‌شدهٔ اعتبار در plan |
| <span dir="ltr">`unit_type`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`EntitlementUnitType`</span> |
| <span dir="ltr">`valid_from`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | شروع اعتبار |
| <span dir="ltr">`planned_expiry`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | انقضای برنامه‌ریزی‌شده |
| <span dir="ltr">`auto_extend`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | تمدید خودکار مطابق سیاست |

### ۵.۷. <span dir="ltr">`entitlement_ledger_entries`</span> — دفتر کل اعتبار

مانده از fold ردیف‌ها محاسبه می‌شود. اصلاح credit ردیف جدید <span dir="ltr">`adjustment`</span> است؛ مصرف قبلی را بازنویسی نمی‌کند.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ entry |
| <span dir="ltr">`plan_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → entitlement_plans.id</span> | برنامهٔ اعتبار |
| <span dir="ltr">`type`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`EntitlementEntryType`</span> |
| <span dir="ltr">`units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | واحد؛ adjustment می‌تواند منفی باشد؛ غیرصفر بودن در domain |
| <span dir="ltr">`occurred_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان اثر |
| <span dir="ltr">`reference_id`</span> | <span dir="ltr">TEXT</span> | بله | بدون FK | ارجاع منشأ، از جمله audit اصلاح |
| <span dir="ltr">`note`</span> | <span dir="ltr">TEXT</span> | بله | — | دلیل/یادداشت |

append-only بودن این ledger قرارداد domain/repository است؛ برخلاف review history، SQL trigger جلوگیری از UPDATE/DELETE ندارد.

### ۵.۸. <span dir="ltr">`session_policies`</span> — سیاست جلسه

این جدول پیکربندی مصرف و جبرانی است و ثبت نتیجهٔ واقعی نیست.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ سیاست |
| <span dir="ltr">`cycle_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → commitment_cycles.id</span> | دوره؛ <span dir="ltr">UNIQUE</span> نیست |
| <span dir="ltr">`provider_cancellation_consumes`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | مصرف اعتبار در لغو ارائه‌دهنده |
| <span dir="ltr">`user_cancellation_notice_hours`</span> | <span dir="ltr">INTEGER</span> | خیر | — | حد اطلاع قبلی، بر حسب ساعت |
| <span dir="ltr">`late_cancellation_consumes`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | مصرف در لغو دیرهنگام |
| <span dir="ltr">`no_show_consumes`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | مصرف در عدم حضور |
| <span dir="ltr">`free_absence_quota`</span> | <span dir="ltr">INTEGER</span> | خیر | — | سهمیهٔ غیبت مجاز |
| <span dir="ltr">`holiday_consumes`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | مصرف در تعطیلی |
| <span dir="ltr">`makeup_required`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | نیاز به جلسهٔ جبرانی |
| <span dir="ltr">`auto_extend_until_units_consumed`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | ادامه تا مصرف واحدها |
| <span dir="ltr">`max_extension_date`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | سقف تمدید |
| <span dir="ltr">`partial_unit_allowed`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | مفهوم سیاستی مصرف جزئی؛ ستون units هنوز integer است |

### ۵.۹. <span dir="ltr">`replacement_occurrences`</span> — زنجیرهٔ جبرانی

رکورد domain جبرانی است؛ صرف وجود آن اثبات نمی‌کند یک occurrence عادی و reminder مربوط هم ساخته شده است.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ جبرانی |
| <span dir="ltr">`original_occurrence_id`</span> | <span dir="ltr">TEXT</span> | خیر | بدون FK | نوبت اصلی |
| <span dir="ltr">`parent_replacement_id`</span> | <span dir="ltr">TEXT</span> | بله | بدون FK | جبرانی والد؛ برای لغو دوبارهٔ جبرانی |
| <span dir="ltr">`scheduled_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان برنامه‌ریزی‌شدهٔ جبرانی |
| <span dir="ltr">`reason`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`ReplacementReason`</span> |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`ReplacementStatus`</span> |

### ۵.۱۰. <span dir="ltr">`reminder_rules`</span> — قانون یادآور

در schema فعلی rule مربوط به occurrence است. template یادآوری نوبت‌های آینده در JSON schedule نگهداری می‌شود.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ قانون |
| <span dir="ltr">`occurrence_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → occurrences.id</span> | نوبت |
| <span dir="ltr">`anchor`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`ReminderAnchor`</span> |
| <span dir="ltr">`offset_seconds`</span> | <span dir="ltr">INTEGER</span> | خیر | — | فاصله از anchor، بر حسب ثانیه |
| <span dir="ltr">`absolute_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | زمان صریح برای anchor مطلق |
| <span dir="ltr">`title`</span> | <span dir="ltr">TEXT</span> | بله | — | عنوان اعلان |
| <span dir="ltr">`body`</span> | <span dir="ltr">TEXT</span> | بله | — | متن اعلان |
| <span dir="ltr">`enabled`</span> | <span dir="ltr">INTEGER (bool)</span> | خیر | <span dir="ltr">CHECK 0/1</span> | فعال بودن rule |

### ۵.۱۱. <span dir="ltr">`reminder_instances`</span> — intent اعلان

UNIQUE روی <span dir="ltr">`(rule_id, occurrence_id, scheduled_at)`</span> هویت منطقی اعلان را حفاظت می‌کند. commit intent با موفقیت ارسال به سیستم‌عامل یک چیز نیست.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ instance |
| <span dir="ltr">`rule_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → reminder_rules.id</span> | قانون |
| <span dir="ltr">`occurrence_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → occurrences.id</span> | نوبت |
| <span dir="ltr">`scheduled_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | <span dir="ltr">UNIQUE</span> مرکب بالا | زمان اعلان |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`ReminderInstanceStatus`</span> |
| <span dir="ltr">`snoozed_until`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | زمان snooze، مستقل از rule |
| <span dir="ltr">`platform_notification_id`</span> | <span dir="ltr">TEXT</span> | بله | — | شناسهٔ محلی platform؛ قابل حمل نیست |

### ۵.۱۲. <span dir="ltr">`actuals`</span> — نتیجهٔ واقعی و تاریخچه

برای هر نوبت چند نتیجهٔ تاریخی مجاز است. <span dir="ltr">`reopened`</span> یک رویداد جدید است و نتیجه‌های قبلی باقی می‌مانند.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ نتیجه |
| <span dir="ltr">`occurrence_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → occurrences.id</span> | نوبت |
| <span dir="ltr">`outcome`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`ActualOutcome`</span> |
| <span dir="ltr">`recorded_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ثبت |
| <span dir="ltr">`note`</span> | <span dir="ltr">TEXT</span> | بله | — | یادداشت نتیجه |

### ۵.۱۳. <span dir="ltr">`evidences`</span> — شاهد/ارجاع

مدل شاهد وجود دارد؛ جدول را با ذخیره‌سازی کامل فایل یا قابلیت attachment آمادهٔ انتشار یکسان ندانید.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ شاهد |
| <span dir="ltr">`actual_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → actuals.id</span> | نتیجهٔ مربوط |
| <span dir="ltr">`type`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`EvidenceType`</span> |
| <span dir="ltr">`value`</span> | <span dir="ltr">TEXT</span> | خیر | — | متن یا ارجاع مطابق type |
| <span dir="ltr">`created_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ایجاد |

### ۵.۱۴. <span dir="ltr">`financial_accounts`</span> — حساب مالی

ستون balance ندارد. شناسه‌های کارت/شبا/حساب در metadata نسخه‌دار هستند، نه در این ستون‌ها.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ حساب |
| <span dir="ltr">`name`</span> | <span dir="ltr">TEXT</span> | خیر | — | نام نمایشی |
| <span dir="ltr">`currency`</span> | <span dir="ltr">TEXT</span> | خیر | — | ارز حساب |
| <span dir="ltr">`type`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`FinancialAccountType`</span> |
| <span dir="ltr">`bank_code`</span> | <span dir="ltr">TEXT</span> | بله | — | کد متنی بانک؛ enum index نیست |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`FinancialAccountStatus`</span> |

### ۵.۱۵. <span dir="ltr">`account_entries`</span> — دفتر کل مالی

این ردیف‌ها مبنای موجودی و منبع <span dir="ltr">`transaction_id`</span> در matching هستند. انتقال دو ردیف مرتبط دارد؛ اصلاح مالی با reversal و ردیف جدید تاریخچه را حفظ می‌کند.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ entry/تراکنش |
| <span dir="ltr">`account_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → financial_accounts.id</span> | حساب |
| <span dir="ltr">`type`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`AccountEntryType`</span> |
| <span dir="ltr">`minor_units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | مبلغ صحیح؛ علامت/اثر آن به type وابسته است |
| <span dir="ltr">`currency`</span> | <span dir="ltr">TEXT</span> | خیر | — | ارز؛ repository تطابق با حساب را بررسی می‌کند |
| <span dir="ltr">`occurred_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان تراکنش |
| <span dir="ltr">`reference_id`</span> | <span dir="ltr">TEXT</span> | بله | بدون FK | منشأ یا ردیف مرتبط |
| <span dir="ltr">`note`</span> | <span dir="ltr">TEXT</span> | بله | — | یادداشت |
| <span dir="ltr">`category`</span> | <span dir="ltr">TEXT</span> | بله | — | دستهٔ اختیاری؛ جدول category جدا ندارد |
| <span dir="ltr">`source`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">DEFAULT 0</span> | <span dir="ltr">`AccountEntrySource`</span> |
| <span dir="ltr">`transfer_group_id`</span> | <span dir="ltr">TEXT</span> | بله | بدون FK | گروه مشترک انتقال |

### ۵.۱۶. <span dir="ltr">`transaction_matches`</span> — سرآیند تطبیق

<span dir="ltr">`transaction_id`</span> به <span dir="ltr">`account_entries`</span> اشاره می‌کند. <span dir="ltr">`minor_units`</span> مبلغ تراکنش در مدل match است؛ مبالغ تخصیص‌یافته در فرزندان‌اند.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ match |
| <span dir="ltr">`transaction_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → account_entries.id</span> | ردیف مالی |
| <span dir="ltr">`minor_units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | مبلغ تراکنش در snapshot match |
| <span dir="ltr">`currency`</span> | <span dir="ltr">TEXT</span> | خیر | — | ارز snapshot |
| <span dir="ltr">`created_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ایجاد |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`MatchStatus`</span> |
| <span dir="ltr">`corrected_match_id`</span> | <span dir="ltr">TEXT</span> | بله | بدون FK | ارتباط تاریخچهٔ اصلاح match |

### ۵.۱۷. <span dir="ltr">`match_allocations`</span> — تخصیص مبلغ به نوبت

رابطهٔ تراکنش و occurrence از مسیر match و allocation چندبه‌چند می‌شود. ردیف واسط علاوه بر ارتباط، مبلغ، ارز و نوع اثر دارد.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ تخصیص |
| <span dir="ltr">`match_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → transaction_matches.id</span> | سرآیند match |
| <span dir="ltr">`occurrence_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → occurrences.id</span> | نوبت هدف |
| <span dir="ltr">`minor_units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | مبلغ تخصیص |
| <span dir="ltr">`currency`</span> | <span dir="ltr">TEXT</span> | خیر | — | ارز تخصیص |
| <span dir="ltr">`type`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`AllocationType`</span> |

SQL سقف مجموع تخصیص‌ها یا هم‌ارزی currency را تضمین نمی‌کند؛ admission تراکنشی repository باید آن را از state تازه بررسی کند.

### ۵.۱۸. <span dir="ltr">`relationship_reviews`</span> — ممیزی بررسی ارتباط

تصمیم «باقی‌مانده مستقل است» match، category یا tag نیست. Undo/بازگشایی ردیف جدید می‌افزاید و entry مالی را برنمی‌گرداند.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ تصمیم |
| <span dir="ltr">`transaction_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → account_entries.id</span> | تراکنش |
| <span dir="ltr">`revision`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">CHECK > 0</span>؛ <span dir="ltr">UNIQUE</span> با <span dir="ltr">`transaction_id`</span> | بازبینی افزایشی هر تراکنش |
| <span dir="ltr">`decision`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">CHECK BETWEEN 0 AND 1</span> | <span dir="ltr">`RelationshipReviewDecision`</span> |
| <span dir="ltr">`minor_units`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">CHECK > 0</span> | مبلغ تراکنش هنگام تصمیم |
| <span dir="ltr">`currency`</span> | <span dir="ltr">TEXT</span> | خیر | — | ارز هنگام تصمیم |
| <span dir="ltr">`allocation_fingerprint`</span> | <span dir="ltr">TEXT</span> | خیر | — | fingerprint تخصیص مؤثر |
| <span dir="ltr">`allocation_history_fingerprint`</span> | <span dir="ltr">TEXT</span> | خیر | — | fingerprint تاریخچهٔ تخصیص |
| <span dir="ltr">`remainder_minor_units`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">CHECK > 0 AND <= minor_units</span> | باقی‌ماندهٔ مورد بررسی |
| <span dir="ltr">`recorded_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ثبت تصمیم |

UPDATE و DELETE این جدول با trigger رد می‌شود. UNIQUE revision ترتیب یکتا را تضمین می‌کند، اما monotonic بودن و اعتبار fingerprint در domain/application بررسی می‌شود.

### ۵.۱۹. <span dir="ltr">`financial_expectations`</span> — مبلغ برنامه‌ریزی‌شده

برای هر occurrence حداکثر یک expectation وجود دارد. انتظار، تراکنش واقعی نیست و خودبه‌خود موجودی حساب را تغییر نمی‌دهد.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ انتظار |
| <span dir="ltr">`occurrence_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → occurrences.id؛ UNIQUE</span> | نوبت |
| <span dir="ltr">`direction`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`FinancialExpectationDirection`</span> |
| <span dir="ltr">`minor_units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | مبلغ مورد انتظار |
| <span dir="ltr">`currency`</span> | <span dir="ltr">TEXT</span> | بله | — | ارز اختیاری؛ نبود آن معنی‌دار است |
| <span dir="ltr">`account_id`</span> | <span dir="ltr">TEXT</span> | بله | <span dir="ltr">FK → financial_accounts.id</span> | حساب اختیاری |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`FinancialExpectationStatus`</span> |
| <span dir="ltr">`created_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ایجاد |
| <span dir="ltr">`updated_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان آخرین تغییر |

تسویه از allocationهای مؤثر محاسبه می‌شود، نه از completed شدن فعالیت یا یک ستون mutable «تسویه‌شده».

### ۵.۲۰. <span dir="ltr">`tags`</span> — برچسب مشترک

normalization را با [<span dir="ltr">tag.dart</span>](../lib/features/classification/domain/tag.dart) انجام دهید؛ label نمایشی با کلید یکتایی یکی نیست.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ برچسب |
| <span dir="ltr">`label`</span> | <span dir="ltr">TEXT</span> | خیر | — | نام نمایشی |
| <span dir="ltr">`normalized_label`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">UNIQUE</span> | کلید normalization برای جلوگیری از تکرار |
| <span dir="ltr">`created_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ایجاد |

### ۵.۲۱. <span dir="ltr">`commitment_tags`</span> — واسط تعهد و برچسب

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`commitment_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> مرکب؛ <span dir="ltr">`FK → commitments.id`</span> | تعهد |
| <span dir="ltr">`tag_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> مرکب؛ <span dir="ltr">`FK → tags.id`</span> | برچسب |

PK برابر <span dir="ltr">`(commitment_id, tag_id)`</span> است؛ attach تکراری نباید عضویت دوم بسازد. <span dir="ltr">`id`</span> مستقل ندارد.

### ۵.۲۲. <span dir="ltr">`account_entry_tags`</span> — واسط ردیف مالی و برچسب

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`account_entry_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> مرکب؛ <span dir="ltr">`FK → account_entries.id`</span> | ردیف مالی |
| <span dir="ltr">`tag_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> مرکب؛ <span dir="ltr">`FK → tags.id`</span> | برچسب |

PK برابر <span dir="ltr">`(account_entry_id, tag_id)`</span> است؛ دستهٔ تراکنش و تصمیم مستقل‌بودن را با tag یکی نکنید.

### ۵.۲۳. <span dir="ltr">`staged_imports`</span> — ورودی قابل بررسی

متن خام ممکن است حساس باشد. fingerprint و source key در schema فعلی UNIQUE نیستند؛ deduplication به قواعد ingestion/repository متکی است.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ ورودی |
| <span dir="ltr">`raw_text`</span> | <span dir="ltr">TEXT</span> | خیر | — | متن خام؛ بعد از redaction/expiry می‌تواند رشتهٔ خالی باشد |
| <span dir="ltr">`fingerprint`</span> | <span dir="ltr">TEXT</span> | خیر | — | اثر انگشت برای تشخیص تکرار |
| <span dir="ltr">`retention_status`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">DEFAULT 0</span> | <span dir="ltr">`RawTextRetentionStatus`</span> |
| <span dir="ltr">`retention_until`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | موعد نگهداری متن |
| <span dir="ltr">`last_decision_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | بله | — | آخرین تصمیم کاربر |
| <span dir="ltr">`source`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`ImportSource`</span> |
| <span dir="ltr">`source_key`</span> | <span dir="ltr">TEXT</span> | خیر | — | کلید provenance در منبع |
| <span dir="ltr">`imported_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان ورود |
| <span dir="ltr">`adapter_version`</span> | <span dir="ltr">TEXT</span> | خیر | — | نسخهٔ adapter |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`StagedItemStatus`</span> |

### ۵.۲۴. <span dir="ltr">`inbox_suggestions`</span> — پیشنهاد parser

این جدول ردیف مالی قطعی نیست. دادهٔ کامل بررسی شامل metadata مرتبط نیز هست؛ فقط خواندن این ستون‌ها برای بازسازی suggestion کافی نیست.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">PK</span> | شناسهٔ پیشنهاد |
| <span dir="ltr">`staged_import_id`</span> | <span dir="ltr">TEXT</span> | خیر | <span dir="ltr">FK → staged_imports.id</span> | ورودی |
| <span dir="ltr">`draft_id`</span> | <span dir="ltr">TEXT</span> | خیر | بدون FK | شناسهٔ پیش‌نویس |
| <span dir="ltr">`minor_units`</span> | <span dir="ltr">INTEGER</span> | خیر | — | مبلغ parser/پیشنهاد |
| <span dir="ltr">`currency`</span> | <span dir="ltr">TEXT</span> | خیر | — | ارز پیشنهاد |
| <span dir="ltr">`occurred_at`</span> | <span dir="ltr">INTEGER</span> (زمان) | خیر | — | زمان پیشنهادی؛ evidence منشأ تاریخ در metadata |
| <span dir="ltr">`type`</span> | <span dir="ltr">TEXT</span> | خیر | — | نوع متنی draft؛ enum index نیست |
| <span dir="ltr">`merchant`</span> | <span dir="ltr">TEXT</span> | بله | — | طرف/پذیرندهٔ استخراج‌شده |
| <span dir="ltr">`reference`</span> | <span dir="ltr">TEXT</span> | بله | — | مرجع استخراج‌شده |
| <span dir="ltr">`status`</span> | <span dir="ltr">INTEGER</span> | خیر | — | <span dir="ltr">`SuggestionStatus`</span> |

### ۵.۲۵. <span dir="ltr">`holiday_packages`</span> — جدول دیتابیس عمومی مستقل

تعریف مستقیم با sqlite3 در [<span dir="ltr">SqliteHolidayPackageStore</span>](../lib/features/calendar/data/sqlite_holiday_package_store.dart)؛ عضو <span dir="ltr">`AppDatabase`</span> نیست.

| ستون | نوع | پذیرش <span dir="ltr">`NULL`</span> | قید / مقدار پیش‌فرض | معنی |
| ---: | ---: | ---: | ---: | ---: |
| <span dir="ltr">`year`</span> | <span dir="ltr">INTEGER</span> | خیر | <span dir="ltr">INTEGER PRIMARY KEY</span> | سال جلالی بسته |
| <span dir="ltr">`revision`</span> | <span dir="ltr">INTEGER</span> | خیر | — | نسخهٔ بسته برای سال |
| <span dir="ltr">`envelope`</span> | <span dir="ltr">TEXT</span> | خیر | — | payload امضاشدهٔ بسته |

store با <span dir="ltr">`PRAGMA synchronous = FULL`</span> و <span dir="ltr">`BEGIN IMMEDIATE`</span> می‌نویسد. package ابتدا verify می‌شود؛ سپس snapshot در transaction مجدداً مقایسه و یک سال اتمیک جایگزین می‌شود. schema ناشناخته رد می‌شود. جدول flat برای تک‌تک تعطیلات یا FK به occurrence ندارد.

envelope با format برابر <span dir="ltr">`planact-holidays-v1`</span>، فیلدهای <span dir="ltr">`payload`</span>، <span dir="ltr">`publicKey`</span> و <span dir="ltr">`signature`</span> را به‌صورت base64 حمل می‌کند؛ امضا Ed25519 است. payload شامل year، revision، source، پوشش ۱۲ ماه و holidayهاست. [<span dir="ltr">HolidayDataPackage</span>](../lib/features/calendar/domain/holiday_data_package.dart) مرجع verify است؛ صحت امضا به‌تنهایی اعتماد کاربر به ناشر را ثابت نمی‌کند.

<a id="6-enums"></a>

## ۶. کدهای enum ذخیره‌شده

بیشتر enumها با <span dir="ltr">`.index`</span> نوشته و با <span dir="ltr">`Enum.values[index]`</span> خوانده می‌شوند. **تغییر ترتیب یا حذف عضو، معنای دادهٔ قبلی را عوض می‌کند.** افزودن عضو نیز بدون بررسی خوانندهٔ قدیمی، مجوز downgrade نیست. default صفر در schema به اولین عضو مربوط اشاره دارد، نه یک «unknown» عمومی.

| جدول و ستون | <span dir="ltr">enum</span> | نگاشت فعلی |
| ---: | ---: | ---: |
| <span dir="ltr">commitments.status</span> | <span dir="ltr">CommitmentStatus</span> | <span dir="ltr">0 active، 1 paused، 2 archived، 3 completed، 4 cancelled</span> |
| <span dir="ltr">commitments.kind</span> | <span dir="ltr">CommitmentKind</span> | <span dir="ltr">0 oneOff، 1 recurring</span> |
| <span dir="ltr">commitments.priority</span> | <span dir="ltr">CommitmentPriority</span> | <span dir="ltr">0 low، 1 normal، 2 high، 3 urgent</span> |
| <span dir="ltr">commitment_cycles.cycle_type</span> | <span dir="ltr">CommitmentCycleType</span> | <span dir="ltr">0 openEnded، 1 fixedDateRange، 2 fixedCount، 3 manualPackage، 4 hybrid</span> |
| <span dir="ltr">commitment_cycles.completion_rule</span> | <span dir="ltr">CompletionRule</span> | <span dir="ltr">0 byDate، 1 byUnits، 2 whicheverFirst، 3 whicheverLast، 4 manual</span> |
| <span dir="ltr">commitment_cycles.status</span> | <span dir="ltr">CommitmentCycleStatus</span> | <span dir="ltr">0 draft، 1 active، 2 completed، 3 cancelled، 4 archived</span> |
| <span dir="ltr">schedule_definitions.mode</span> | <span dir="ltr">ScheduleMode</span> | <span dir="ltr">0 oneOff، 1 openEndedRecurring، 2 fixedDateRangeRecurring، 3 fixedCount</span> |
| <span dir="ltr">schedule_definitions.time_semantics / occurrences.time_semantics</span> | <span dir="ltr">TimeSemantics</span> | <span dir="ltr">0 floatingLocalTime، 1 fixedInstant، 2 allDayLocalDate</span> |
| <span dir="ltr">occurrences.status</span> | <span dir="ltr">OccurrenceStatus</span> | <span dir="ltr">0 scheduled، 1 due، 2 completed، 3 skipped، 4 cancelled، 5 rescheduled، 6 overdue، 7 deferred، 8 pendingDecision</span> |
| <span dir="ltr">entitlement_plans.unit_type</span> | <span dir="ltr">EntitlementUnitType</span> | <span dir="ltr">0 session، 1 hour، 2 visit، 3 credit</span> |
| <span dir="ltr">entitlement_ledger_entries.type</span> | <span dir="ltr">EntitlementEntryType</span> | <span dir="ltr">0 grant، 1 consume، 2 restore، 3 adjustment، 4 expire، 5 refund</span> |
| <span dir="ltr">replacement_occurrences.reason</span> | <span dir="ltr">ReplacementReason</span> | <span dir="ltr">0 providerCancellation، 1 allowedAbsence، 2 holiday، 3 freeze، 4 makeup</span> |
| <span dir="ltr">replacement_occurrences.status</span> | <span dir="ltr">ReplacementStatus</span> | <span dir="ltr">0 planned، 1 completed، 2 cancelled</span> |
| <span dir="ltr">reminder_rules.anchor</span> | <span dir="ltr">ReminderAnchor</span> | <span dir="ltr">0 occurrenceStart، 1 absolute</span> |
| <span dir="ltr">reminder_instances.status</span> | <span dir="ltr">ReminderInstanceStatus</span> | <span dir="ltr">0 scheduled، 1 cancelled، 2 delivered، 3 snoozed</span> |
| <span dir="ltr">actuals.outcome</span> | <span dir="ltr">ActualOutcome</span> | <span dir="ltr">0 completed، 1 attended، 2 cancelled، 3 missed، 4 noShow، 5 partial، 6 reopened</span> |
| <span dir="ltr">evidences.type</span> | <span dir="ltr">EvidenceType</span> | <span dir="ltr">0 note، 1 document، 2 localReference</span> |
| <span dir="ltr">financial_accounts.type</span> | <span dir="ltr">FinancialAccountType</span> | <span dir="ltr">0 bank، 1 cash، 2 digitalWallet، 3 credit</span> |
| <span dir="ltr">financial_accounts.status</span> | <span dir="ltr">FinancialAccountStatus</span> | <span dir="ltr">0 active، 1 archived</span> |
| <span dir="ltr">account_entries.type</span> | <span dir="ltr">AccountEntryType</span> | <span dir="ltr">0 openingBalance، 1 income، 2 expense، 3 transferIn، 4 transferOut، 5 adjustment، 6 refund، 7 reversal</span> |
| <span dir="ltr">account_entries.source</span> | <span dir="ltr">AccountEntrySource</span> | <span dir="ltr">0 manual، 1 sms، 2 import</span> |
| <span dir="ltr">transaction_matches.status</span> | <span dir="ltr">MatchStatus</span> | <span dir="ltr">0 active، 1 corrected، 2 reversed</span> |
| <span dir="ltr">match_allocations.type</span> | <span dir="ltr">AllocationType</span> | <span dir="ltr">0 payment، 1 refund، 2 correction</span> |
| <span dir="ltr">relationship_reviews.decision</span> | <span dir="ltr">RelationshipReviewDecision</span> | <span dir="ltr">0 independent، 1 reopened</span> |
| <span dir="ltr">financial_expectations.direction</span> | <span dir="ltr">FinancialExpectationDirection</span> | <span dir="ltr">0 outgoing، 1 incoming</span> |
| <span dir="ltr">financial_expectations.status</span> | <span dir="ltr">FinancialExpectationStatus</span> | <span dir="ltr">0 active، 1 archived</span> |
| <span dir="ltr">staged_imports.source</span> | <span dir="ltr">ImportSource</span> | <span dir="ltr">0 sms، 1 file، 2 manual</span> |
| <span dir="ltr">staged_imports.status</span> | <span dir="ltr">StagedItemStatus</span> | <span dir="ltr">0 pending، 1 confirmed، 2 rejected، 3 rolledBack</span> |
| <span dir="ltr">staged_imports.retention_status</span> | <span dir="ltr">RawTextRetentionStatus</span> | <span dir="ltr">0 pending، 1 confirmed، 2 rejected، 3 expired</span> |
| <span dir="ltr">inbox_suggestions.status</span> | <span dir="ltr">SuggestionStatus</span> | <span dir="ltr">0 pending، 1 confirmed، 2 edited، 3 rejected، 4 duplicate</span> |

مرجع enumها در <span dir="ltr">`domain`</span> ویژگی مربوط است: [تعهد](../lib/features/commitments/domain/commitment.dart)، [دوره](../lib/features/commitments/domain/commitment_cycle.dart)، [زمان‌بندی](../lib/features/scheduling/domain/schedule_definition.dart)، [نوبت](../lib/features/scheduling/domain/occurrence.dart)، [اعتبار](../lib/features/sessions/domain/entitlement.dart)، [جبرانی](../lib/features/sessions/domain/replacement.dart)، [یادآور](../lib/features/reminders/domain/reminder.dart)، [نتیجه](../lib/features/actuals/domain/actual.dart)، [مالی](../lib/features/finance/domain/finance.dart)، [تطبیق](../lib/features/reconciliation/domain/reconciliation.dart)، [<span dir="ltr">review</span>](../lib/features/reconciliation/domain/relationship_review.dart)، [انتظار مالی](../lib/features/finance/domain/financial_expectation.dart) و [<span dir="ltr">Inbox</span>](../lib/features/inbox/domain/inbox.dart).

استثناهای متنی: <span dir="ltr">`color_key`</span> با نام رنگ، <span dir="ltr">`bank_code`</span> با <span dir="ltr">`.code`</span> بانک و <span dir="ltr">`inbox_suggestions.type`</span> با رشته ذخیره می‌شوند؛ آن‌ها را به enum index تبدیل نکنید. رنگ‌های مجاز: <span dir="ltr">`teal`</span>, <span dir="ltr">`blue`</span>, <span dir="ltr">`indigo`</span>, <span dir="ltr">`violet`</span>, <span dir="ltr">`rose`</span>, <span dir="ltr">`amber`</span>, <span dir="ltr">`olive`</span>, <span dir="ltr">`cyan`</span>.

<a id="7-metadata"></a>

## ۷. JSON، metadata و داده‌های خارج از ستون‌های اصلی

### ۷.۱. namespaceهای <span dir="ltr">`schema_metadata`</span>

| key / الگو | قالب و محتوای اصلی | مالک قرارداد |
| ---: | ---: | ---: |
| <span dir="ltr">`schema_version`</span> | رشتهٔ <span dir="ltr">`18`</span>؛ باید با <span dir="ltr">`PRAGMA user_version`</span> سازگار باشد | <span dir="ltr">AppDatabase</span> |
| <span dir="ltr">`theme_mode`</span> | <span dir="ltr">`light`, `dark`, `system`</span> | <span dir="ltr">AppSettings</span> |
| <span dir="ltr">`app_lock_enabled`</span> | رشتهٔ bool، <span dir="ltr">`true`</span> / <span dir="ltr">`false`</span> | AppSettings و مسیر تأیید احراز هویت |
| <span dir="ltr">`iranian_money_unit_v1`</span> | <span dir="ltr">`rial`</span> / <span dir="ltr">`toman`</span>؛ فقط واحد ورودی و نمایش | <span dir="ltr">AppSettings</span> |
| <span dir="ltr">`account_identifiers_v1:<accountId>`</span> | JSON با <span dir="ltr">`version: 1`</span> و <span dir="ltr">`cardNumber`</span>, <span dir="ltr">`iban`</span>, <span dir="ltr">`accountNumber`</span> nullable | <span dir="ltr">DriftFinanceRepository</span> |
| <span dir="ltr">`inbox_review_v1:<suggestionId>`</span> | JSON نسخهٔ ۱؛ revision، history، reviewed، extractedEvidence، currencyEvidence و provenance استخراج | <span dir="ltr">DriftInboxRepository</span> |
| <span dir="ltr">`sms_scan_v1`</span> | payload نسخه‌دار رضایت، checkpoint و progress اسکن | مسیر SMS ingestion |
| <span dir="ltr">`commitment_correction_v1:<auditId>`</span> | رکورد JSON ممیزی اصلاح شمار schedule یا credit | <span dir="ltr">DriftCommitmentCorrectionRepository</span> |

مرجع تنظیمات [<span dir="ltr">app_settings.dart</span>](../lib/app/app_settings.dart)، شناسهٔ حساب [<span dir="ltr">drift_finance_repository.dart</span>](../lib/features/finance/data/drift_finance_repository.dart)، Inbox [<span dir="ltr">drift_inbox_repository.dart</span>](../lib/features/inbox/data/drift_inbox_repository.dart)، اسکن [<span dir="ltr">sms_ingestion.dart</span>](../lib/features/inbox/application/sms_ingestion.dart) و اصلاح [<span dir="ltr">drift_commitment_correction_repository.dart</span>](../lib/features/commitments/data/drift_commitment_correction_repository.dart) است.

این جدول دادهٔ شخصی پایدار دارد؛ حذف آن با تصور «فقط metadata فنی» به از دست رفتن state و audit منجر می‌شود. version داخل JSON و suffix key مستقل از <span dir="ltr">`schemaVersion`</span> فیزیکی هستند. تغییر payload بدون migration SQL هم نیاز به تست restart، legacy، backup و سازگاری reader/writer دارد.

payload اسکن <span dir="ltr">`sms_scan_v1`</span> دارای <span dir="ltr">`version: 1`</span>، <span dir="ltr">`from`</span>, <span dir="ltr">`until`</span>, <span dir="ltr">`newOnly`</span>, <span dir="ltr">`timestamp`</span>, <span dir="ltr">`id`</span>, <span dir="ltr">`inspected`</span>, <span dir="ltr">`unsupported`</span>, <span dir="ltr">`complete`</span> است. <span dir="ltr">`from`</span> و <span dir="ltr">`until`</span> و timestamp منبع بر حسب **میلی‌ثانیه** هستند؛ با ثانیهٔ ستون‌های Drift اشتباه نشوند. <span dir="ltr">`id`</span> در checkpoint شناسهٔ منبع SMS است، نه UUID domain.

شناسه‌های حساب رشته‌اند تا صفر ابتدایی حفظ شود. نبود metadata حساب به معنی شناسهٔ خالی است؛ نسخهٔ ناشناخته یا مقدار نامعتبر نباید بی‌صدا با مقدار ساختگی جایگزین شود. برای Inbox قدیمی، نبود metadata با قرارداد repository به version 1، revision 0 و history خالی خوانده می‌شود؛ اطلاعات استخراج‌شده‌ای که واقعاً وجود ندارد نباید ساخته شود.

تاریخچهٔ Inbox داخل JSON با revision جدید افزوده می‌شود؛ audit اصلاح تعهد با key جدید insert می‌شود و شامل <span dir="ltr">`commitmentId`</span>, <span dir="ltr">`cycleId`</span>, <span dir="ltr">`at`</span>, <span dir="ltr">`reason`</span>, <span dir="ltr">`scope`</span>, <span dir="ltr">`beforeCount`</span>, <span dir="ltr">`afterCount`</span>, <span dir="ltr">`beforeRemaining`</span>, <span dir="ltr">`afterRemaining`</span>, <span dir="ltr">`scheduleId`</span>, <span dir="ltr">`cancelledIds`</span> است. در سطح SQL خود <span dir="ltr">`schema_metadata`</span> mutable است و trigger append-only ندارد؛ حفاظت audit از مسیر command می‌آید.

### ۷.۲. JSON در <span dir="ltr">`schedule_definitions.recurrence_rule`</span>

codec فعلی در [<span dir="ltr">DriftCommitmentPlanRepository</span>](../lib/features/commitments/data/drift_commitment_plan_repository.dart) است:

| فیلد | نوع / معنی |
| ---: | ---: |
| <span dir="ltr">`formatVersion`</span> | عدد ۲ در writer جاری |
| <span dir="ltr">`frequency`</span> | <span dir="ltr">enum index: 0 daily، 1 weekly، 2 monthly، 3 yearly</span> |
| <span dir="ltr">`interval`</span> | فاصلهٔ صحیح recurrence |
| <span dir="ltr">`weekdays`</span> | آرایهٔ روزهای هفته با قرارداد Dart؛ دوشنبه ۱ تا یکشنبه ۷، شنبه ۶ |
| <span dir="ltr">`dayOfMonth`</span> | anchor روز ماه یا <span dir="ltr">NULL</span> |
| <span dir="ltr">`monthOfYear`</span> | anchor ماه سال یا <span dir="ltr">NULL</span> |
| <span dir="ltr">`calendar`</span> | نام <span dir="ltr">`gregorian`</span> / <span dir="ltr">`jalali`</span>؛ مرجع recurrence |
| <span dir="ltr">`legacyCalendarSemantics`</span> | bool برای حفظ تفسیر سابق |
| <span dir="ltr">`monthEndPolicy`</span> | <span dir="ltr">enum index: 0 skip، 1 clampToLastDay</span> |
| <span dir="ltr">`generationReminderMinutes`</span> | آرایهٔ offsetها بر حسب دقیقه برای نوبت‌های جدید |
| <span dir="ltr">`generationFinancialExpectation`</span> | <span dir="ltr">NULL</span> یا object شامل direction index، amount صحیح، currency nullable و accountId nullable |

نبود <span dir="ltr">`formatVersion`</span> به legacy semantics و نبود <span dir="ltr">`calendar`</span> به Gregorian خوانده می‌شود. تبدیل نمایش به جلالی مجوز reinterpret کردن دادهٔ قدیمی نیست. policy مصوب روز ناموجود، clamp به آخر همان ماه و حفظ anchor اصلی است؛ anchor اسفند ۳۰ در سال کبیسه دوباره ۳۰ خواهد شد. نگهداری عضو <span dir="ltr">`skip`</span> در enum به معنی default محصول نیست. سالانه را با افزودن تعداد ثابت روز محاسبه نکنید.

templateها همراه recurrence durable هستند؛ read preview نباید از آن‌ها اعلان، انتظار مالی یا مصرف جلسه ایجاد کند. پیش از materialization باید metadata و occupancy تازه دوباره بررسی شوند. [<span dir="ltr">ADR 0019</span>](adr/0019-long-term-hybrid-commitments.md) و [<span dir="ltr">verification recurrence</span>](MONTHLY_YEARLY_RECURRENCE_VERIFICATION.md) جزئیات termination و phase را مشخص می‌کنند.

### ۷.۳. codec تاریخ و زمان نوبت

| نوع domain | نمونهٔ متنی | معنی |
| ---: | ---: | ---: |
| <span dir="ltr">LocalDate</span> | <span dir="ltr">`date:2026-10-4`</span> | روز محلی بدون ساعت |
| <span dir="ltr">floating local DateTime</span> | <span dir="ltr">`local:2026-10-4T18:0:0.000`</span> | ساعت دیواری محلی؛ UTC instant نیست |
| <span dir="ltr">fixed instant</span> | <span dir="ltr">`instant:2026-10-04T15:00:00.000Z`</span> | لحظهٔ جهانی UTC |

تاریخ و زمان محلی در writer فعلی zero-pad کامل ندارند. مقایسهٔ lexicographic رشته‌ها برای range زمانی معتبر نیست؛ مثلاً <span dir="ltr">`2026-10-4`</span> و <span dir="ltr">`2026-10-14`</span> را بر اساس ترتیب متن مرتب نکنید. از codec/domain و queryهای date-aware مسیر production استفاده کنید. <span dir="ltr">`original_scheduled_value`</span> و <span dir="ltr">`current_scheduled_value`</span> را هنگام reschedule یکی نکنید.

### ۷.۴. لیست‌های legacy و مرز فایل‌ها

<span dir="ltr">`commitments.tags`</span> و <span dir="ltr">`attachment_ids`</span> در adapter فعلی با separator دو کاراکتری literal <span dir="ltr">`\n`</span> (<span dir="ltr">`join('\\n')`</span> در کد Dart)، نه الزاماً newline واقعی، encode/decode می‌شوند. منبع عضویت برچسب <span dir="ltr">`commitment_tags`</span> است؛ snapshot قدیمی یک save نباید عضویت‌های جدید را بازگرداند. در migration نیز separator و normalization موجود را رعایت کنید.

<span dir="ltr">`evidences.value`</span> ارجاع است و تضمین نمی‌کند فایل در backup حاضر باشد. کلید رمزنگاری بکاپ در secure platform storage / مسیر recovery key قرار دارد و ستون این دیتابیس نیست. شناسهٔ platform اعلان متعلق به نصب دستگاه است و نباید هویت domain فرض شود.

<a id="8-constraints"></a>

## ۸. قیود، ایندکس‌ها و triggerها

### ۸.۱. تضمین‌های SQL تازه

- هر جدول PK دارد؛ دو جدول واسط PK مرکب دارند.
- FKهای ERD با <span dir="ltr">`PRAGMA foreign_keys = ON`</span> در <span dir="ltr">`beforeOpen`</span> فعال می‌شوند. اتصال مستقیم sqlite3 باید وضعیت FK خودش را بررسی کند؛ این PRAGMA سراسری همهٔ connectionها نیست.
- هیچ <span dir="ltr">`ON DELETE CASCADE`</span> یا <span dir="ltr">`ON UPDATE CASCADE`</span> صریحی در references فعلی تعریف نشده است؛ روی cascade برای حذف یا تغییر هویت تکیه نکنید.
- UNIQUEهای domain: occurrence slot، reminder identity، یک expectation برای occurrence، normalized tag و revision review برای هر transaction.
- CHECKهای اختصاصی: هشت رنگ commitment، مقادیر مثبت/محدودهٔ decision/remainder در review؛ Drift برای boolها CHECK صفر/یک ایجاد می‌کند.
- بیشتر enumها، مبلغ‌ها، سهمیه‌ها، <span dir="ltr">`units`</span> و شمارها CHECK دامنه‌ای SQL ندارند. وجود <span dir="ltr">`INTEGER NOT NULL`</span> اعتبار تمام مقادیر را اثبات نمی‌کند.

### ۸.۲. ایندکس‌های نام‌دار

علاوه بر ایندکس‌های ضمنی PK/UNIQUE، موارد زیر در کد دیده می‌شوند. **همه در onCreate تازه ساخته نمی‌شوند**؛ مسیرهای migration را جدا در نظر بگیرید.

| نام | ستون‌ها | نحوهٔ تعریف |
| ---: | ---: | ---: |
| <span dir="ltr">`relationship_reviews_transaction_revision`</span> | <span dir="ltr">transaction_id, revision؛ UNIQUE</span> | <span dir="ltr">`@TableIndex`</span> برای تازه و migration نسخهٔ ۱۷ |
| <span dir="ltr">`reminder_instances_logical_identity`</span> | <span dir="ltr">rule_id, occurrence_id, scheduled_at؛ UNIQUE</span> | migration از قبلِ ۱۴؛ تازه <span dir="ltr">UNIQUE</span> جدول دارد |
| <span dir="ltr">`match_allocations_match_id`</span> | <span dir="ltr">match_id</span> | migration از قبلِ ۱۴ |
| <span dir="ltr">`tags_normalized_label`</span> | <span dir="ltr">normalized_label</span> | مسیر repair/migration برای <span dir="ltr">`from <= 15`</span>؛ جدول تازه <span dir="ltr">UNIQUE</span> دارد |
| <span dir="ltr">`commitment_tags_tag_id`</span> | <span dir="ltr">tag_id</span> | مسیر repair/migration برای <span dir="ltr">`from <= 15`</span> |
| <span dir="ltr">`account_entry_tags_tag_id`</span> | <span dir="ltr">tag_id</span> | مسیر repair/migration برای <span dir="ltr">`from <= 15`</span> |

FK به‌خودی‌خود index lookup در فرزند ایجاد نمی‌کند. برای ادعای performance، ساخت تازه و chainهای تاریخی را جدا با <span dir="ltr">`PRAGMA index_list`</span> و <span dir="ltr">`EXPLAIN QUERY PLAN`</span> بررسی کنید. افزودن index نام‌دار می‌تواند signature سخت‌گیرانهٔ backup را تغییر دهد و باید در migration/fixtures/validation لحاظ شود.

### ۸.۳. triggerهای append-only

| <span dir="ltr">trigger</span> | اثر |
| ---: | ---: |
| <span dir="ltr">`relationship_reviews_no_update`</span> | <span dir="ltr">BEFORE UPDATE؛ `RAISE(ABORT, ...)`</span> |
| <span dir="ltr">`relationship_reviews_no_delete`</span> | <span dir="ltr">BEFORE DELETE؛ `RAISE(ABORT, ...)`</span> |

این triggerها در ساخت تازه و upgrade به ۱۷ ایجاد می‌شوند. محافظ SQL برای این جدول وجود دارد؛ برای ledgerها و audit JSON چنین trigger عمومی‌ای تعریف نشده است. افزودن trigger یا دستکاری آن هم تغییر schema محسوب می‌شود.

<a id="9-writes"></a>

## ۹. قواعد نوشتن، تاریخچه و محاسبات

### ۹.۱. transaction و admission تازه

نوشتن‌های وابسته باید اتمیک باشند. در commandهای حساس، form/preview قبلی اجازهٔ استفاده از state کهنه نیست: writer admission بگیرید، state پایدار را در transaction دوباره بخوانید، token/fingerprint را مقایسه کنید و سپس بنویسید. <span dir="ltr">`CommandGate`</span> به هماهنگی عمر application و جلوگیری از فعالیت هنگام restore کمک می‌کند؛ جای serialization خود SQLite را نمی‌گیرد.

مسیر اصلاح تعهد و materialization برای گرفتن write admission، روی ردیف <span dir="ltr">`schema_version`</span> یک <span dir="ltr">`UPDATE value = value`</span> داخل transaction انجام می‌دهد؛ قصد آن تغییر نسخه نیست. در rollback دادهٔ نیمه‌کاره نباید باقی بماند. retry خودکار نباید یک تأیید قدیمی را به موافقت تازه تبدیل کند.

| عمل | durable write و قواعد مرتبط | مصرف‌کننده/اثر بعدی |
| ---: | ---: | ---: |
| ساخت تعهد برنامه‌دار | تعهد، cycle، schedule، occurrenceهای bounded و intentهای مربوط در مسیر plan | Details، Today، Calendar؛ اعلان پس از commit |
| ویرایش recurrence | تعریف نسخهٔ مؤثر جدید؛ حفظ نوبت resolved/manual/گذشته | preview و materialization نسخهٔ درست |
| آماده‌سازی slot آینده | admission تازه، کنترل مالک/version/template/occupancy، insert نوبت و intent وابسته | refresh و platform delivery پس از commit |
| ثبت actual / بازگشایی | append نتیجه و تغییر وضعیت نوبت در مسیر repository | تاریخچه و reconcile یادآور |
| انتقال مالی | دو entry با transfer group مشترک و fee اختیاری در transaction | موجودی هر حساب؛ انتقال درآمد/هزینه نیست |
| اصلاح مالی | reversal و entry صحیح جدید، بدون overwrite تاریخچهٔ ledger | موجودی، گزارش، eligibility تطبیق |
| تأیید Inbox | خواندن suggestion/staged/metadata/account تازه، entry و تصمیم تأیید در transaction | Finance، Today و Inbox refresh |
| ثبت allocation | کنترل مبلغ قابل تخصیص و state review تازه، سپس write match/children | تسویهٔ انتظار، باقی‌مانده و Attention |
| review مستقل / reopened | compare-and-append تاریخچهٔ review با revision و fingerprints | طبقه‌بندی باقی‌مانده در Today |
| اصلاح شمار / credit | دو command مستقل؛ schedule version یا adjustment ledger و audit جدید | حفظ تاریخچه، refresh و reconcile یادآور |

مرجع مسیرها: [<span dir="ltr">plan repository</span>](../lib/features/commitments/data/drift_commitment_plan_repository.dart)، [<span dir="ltr">actual repository</span>](../lib/features/actuals/data/drift_actual_repository.dart)، [<span dir="ltr">finance repository</span>](../lib/features/finance/data/drift_finance_repository.dart)، [<span dir="ltr">Inbox repository</span>](../lib/features/inbox/data/drift_inbox_repository.dart) و [<span dir="ltr">reconciliation repository</span>](../lib/features/reconciliation/data/drift_reconciliation_repository.dart).

### ۹.۲. موجودی و اعتبار مشتق‌شده

موجودی حساب از <span dir="ltr">`rebuildBalance`</span> در domain مالی محاسبه می‌شود. <span dir="ltr">`expense`</span> و <span dir="ltr">`transferOut`</span> اثر منفی amount دارند؛ سایر typeها مقدار amount را با علامت خودش اعمال می‌کنند. برای adjustment/reversal فرض نکنید همهٔ <span dir="ltr">`minor_units`</span>ها مثبت‌اند. جمع سادهٔ SQL همهٔ مبالغ، موجودی درست را به دست نمی‌دهد.

اعتبار از <span dir="ltr">`EntitlementLedger.fold`</span> محاسبه می‌شود: grant، restore و refund به credit اضافه می‌کنند؛ consume و expire به مصرف اضافه می‌کنند؛ adjustment با علامت خودش **credit اعطاشده** را اصلاح می‌کند. remaining برابر granted منهای consumed است. غیر-adjustmentها باید واحد مثبت داشته باشند؛ SQL فعلی این قاعده را CHECK نمی‌کند. <span dir="ltr">`total_units`</span>، <span dir="ltr">`target_units`</span> یا <span dir="ltr">`consumed_units`</span> را به ماندهٔ مستقل و mutable تبدیل نکنید.

تسویهٔ expectation از allocationهای مؤثر با قواعد correction/reversal و currency به دست می‌آید. وجود یک match نباید تمام تراکنش را از Attention حذف کند؛ باقی‌ماندهٔ واجد شرایط باید از projection دامنه بررسی شود. تغییر مبلغ یا تاریخچهٔ تخصیص، اثر تصمیم قدیمی independent را برای باقی‌ماندهٔ جاری نامعتبر می‌کند و خود سابقه حذف نمی‌شود.

### ۹.۳. حفظ تاریخچه و محدودیت تضمین‌ها

آرشیو تعهد/حساب/expectation تغییر وضعیت است، نه hard-delete. حذف معمول completed/cancelled/skipped occurrence، entry مالی، ledger اعتبار یا audit مجاز نیست. repository مالی تغییر entry موجود به دادهٔ متفاوت را رد می‌کند. match repository ممکن است فرزندان allocation یک aggregate را هنگام save جایگزین کند؛ از این جزئیات داخلی، مجوز حذف تاریخچهٔ match یا حذف ارتباط تأییدشده در UI برداشت نکنید.

تمام این invariants صرفاً با FK برقرار نمی‌شوند. برای نمونه، future generation باید مرز مؤثر نسخه و occupancy اصلی/فعلی را بررسی کند؛ notification نوبت لغوشده باید reconcile شود؛ cancellation ارائه‌دهنده فقط طبق سیاست مصوب اثر اعتبار می‌دهد. **commit موفق دیتابیس اثبات موفقیت platform delivery نیست.**

<a id="10-migrations"></a>

## ۱۰. نسخه‌بندی و migration

Drift نسخهٔ فیزیکی را با <span dir="ltr">`schemaVersion`</span>/<span dir="ltr">`PRAGMA user_version`</span> مدیریت می‌کند و <span dir="ltr">`schema_metadata.schema_version`</span> نیز نوشته می‌شود. در restore باید هر دو با نسخهٔ مورد انتظار سازگار باشند؛ ویرایش دستی یکی از آن‌ها migration نیست.

| نسخهٔ مقصد | تغییر ثبت‌شده در migration جاری |
| ---: | ---: |
| 1 | پایهٔ metadata |
| 2 | commitments و commitment_cycles |
| 3 | schedule_definitions و occurrences |
| 4 | <span dir="ltr">entitlement_plans، entitlement_ledger_entries، session_policies، replacement_occurrences</span> |
| 5 | reminder_rules و reminder_instances |
| 6 | kind، priority، description، tags و attachment_ids تعهد |
| 7 | actuals و evidences |
| 8 | financial_accounts و account_entries |
| 9 | transaction_matches و match_allocations |
| 10 | staged_imports و inbox_suggestions |
| 11 | <span dir="ltr">financial_expectations</span> |
| 12 | category و source ردیف مالی |
| 13 | retention_status، retention_until و last_decision_at ورودی |
| 14 | ایندکس reminder identity و match allocation |
| 15 | tagging؛ کد جاری برای <span dir="ltr">`from <= 15`</span> ساخت/repair جدول‌ها و مهاجرت labelهای legacy را اجرا می‌کند |
| 16 | bank_code حساب؛ عبور <span dir="ltr">۱۵→۱۶</span> هم repair tagging را انجام می‌دهد |
| 17 | relationship_reviews، index revision و triggerهای append-only |
| 18 | color_key اختیاری تعهد با <span dir="ltr">CHECK</span> رنگ‌ها |

این جدول شرح گام‌های موجود است، نه DDL مناسب برای اجرای دستی. <span dir="ltr">`onCreate`</span> کل schema جاری را با <span dir="ltr">`m.createAll()`</span> می‌سازد؛ <span dir="ltr">`onUpgrade`</span> مجموعهٔ شرط‌های <span dir="ltr">`from`</span> را اجرا می‌کند. ترتیب ستون‌ها/DDL یا FKها و indexهای بعضی جدول‌های قدیمی ممکن است با ساخت تازه تفاوت داشته باشد، حتی وقتی هر دو <span dir="ltr">`user_version = 18`</span> دارند. upgrade جاری جدول‌های قدیمی را برای افزودن تمام FKهای جدید بازسازی نمی‌کند.

بکاپ فقط signatureهای کامل و مورد اعتماد تاریخیِ migrateشده به ۱۸ را، علاوه بر schema تازه، می‌پذیرد. ترکیب دلخواه DDL چند schema، فقدان قید یا signature ورودی ناشناخته مجاز نیست. برای بررسی دادهٔ legacy، validator ردیف‌ها را در schema مرجع isolated کپی و قیود جدید را کنترل می‌کند؛ payload اصلی را repair نمی‌کند.

برای تغییر schema:

1. تعریف Drift و forward migration را تغییر دهید؛ تغییر destructive نیاز به تصمیم مصوب و backup امن دارد.
2. <span dir="ltr">`app_database.g.dart`</span> را با generator بازتولید کنید؛ این فایل را دستی اصلاح نکنید.
3. fixture قدیمی واقعی، upgrade، cold reopen و ساخت تازه را تست کنید.
4. snapshot/restore کامل، signature معتبر و رد schema دستکاری‌شده را بررسی کنید.
5. تاثیر semantic روی binary قدیمی را جدا از سازگاری فیزیکی schema بررسی کنید.
6. این سند و ADR/verification مربوط را همراه تغییر به‌روز کنید.

[fixtureهای schema](../test/fixtures/backup_schema/)، [تست دیتابیس](../test/repository/app_database_test.dart)، [تست fixture review](../test/repository/relationship_schema_fixture_test.dart) و [تست سازگاری backup](../test/repository/sqlite_backup_schema_compatibility_test.dart) منابع بررسی هستند. افزایش payload JSON یا افزودن enum نیز ممکن است downgrade را ناامن کند؛ ثابت‌ماندن schema 18 اثبات امنیت semantic downgrade نیست.

<a id="11-backup"></a>

## ۱۱. بکاپ، restore و امنیت

### ۱۱.۱. snapshot و حمل داده

[<span dir="ltr">sqliteBackupSnapshot</span>](../lib/features/backup/data/sqlite_backup_snapshot.dart) با <span dir="ltr">`VACUUM INTO`</span> snapshot سازگار می‌سازد و تمام جدول‌ها، ledgerها، metadata، indexها و triggerها را حمل می‌کند. برای export کاربر، نسخهٔ snapshot redact می‌شود: <span dir="ltr">`staged_imports.raw_text`</span> خالی، <span dir="ltr">`reminder_instances.platform_notification_id`</span> برابر NULL و سپس <span dir="ltr">`VACUUM`</span> اجرا می‌شود. live database تغییر نمی‌کند. این redaction همهٔ دادهٔ شخصی را ناشناس نمی‌کند؛ یادداشت، مبلغ، حساب و metadata هنوز شخصی‌اند. snapshot ایمنی داخلی می‌تواند unredacted باشد.

envelope خروجی رمزنگاری‌شده است. format 2 از recovery key مستقل برای بازیابی بین نصب‌ها استفاده می‌کند؛ format 1 به کلید نصب وابسته است. تصمیم‌ها و محدودیت‌ها در [<span dir="ltr">ADR 0009</span>](adr/0009-encrypted-backup-package.md)، [<span dir="ltr">ADR 0013</span>](adr/0013-production-backup-restore.md)، [<span dir="ltr">ADR 0018</span>](adr/0018-independent-recovery-key-backups.md) و [<span dir="ltr">BACKUP_VERIFICATION</span>](BACKUP_VERIFICATION.md) ثبت شده‌اند. دادهٔ عمومی تعطیلات جزو snapshot شخصی نیست.

### ۱۱.۲. restore ایمن

مسیر restore ابتدا envelope/checksum/authentication و schema را در محل موقت بررسی می‌کند؛ سپس snapshot ایمنی می‌سازد، commandها را drain/retire و دیتابیس live را می‌بندد، فایل را جایگزین و generation جدید repository/UI را باز می‌کند. reminderها پس از جایگزینی reconcile می‌شوند. نشانگر recovery تا تکمیل موفق باقی می‌ماند؛ startup قطع‌شده به snapshot ایمنی برمی‌گردد.

[<span dir="ltr">SqliteBackupStorage</span>](../lib/features/backup/data/sqlite_backup_storage.dart) علاوه بر signature <span dir="ltr">`sqlite_master`</span>، <span dir="ltr">`user_version`</span>، metadata نسخه، <span dir="ltr">`integrity_check`</span> و <span dir="ltr">`foreign_key_check`</span> را بررسی می‌کند. payload با شمارهٔ schema قدیمی صرفاً چون application forward migration دارد به‌طور خودکار قابل restore نیست؛ validator فعلی نسخهٔ مورد انتظار و schema تازه یا signature کامل migrateشدهٔ trusted را می‌خواهد. اضافه‌کردن signature از یک فایل دریافتی ممنوع است.

### ۱۱.۳. دادهٔ حساس

SQLite شخصی فعلی را **رمزنگاری‌شده** توصیف نکنید؛ رمزنگاری envelope بکاپ با رمزنگاری فایل live فرق دارد. App lock و mask UI نیز رمزنگاری ستون یا تضمین screenshot privacy نیستند. raw SMS، شناسه‌های حساب، یادداشت‌ها و مقدارهای مالی را در log یا نمونهٔ مستند قرار ندهید. از دادهٔ مصنوعی برای query/debug استفاده کنید. keys در secure storage هستند و حذف نصب/تغییر دستگاه باید مطابق قرارداد recovery بررسی شود.

پاک‌شدن منطقی <span dir="ltr">`raw_text`</span> به‌تنهایی ادعای حذف forensic همهٔ صفحات live نیست. policy retention و redaction snapshot را مطابق [<span dir="ltr">sms_ingestion_privacy</span>](sms_ingestion_privacy.md)، [<span dir="ltr">sensitive_data_flows</span>](sensitive_data_flows.md) و verification مربوط بررسی کنید. هیچ telemetry یا انتقال داده از دیتابیس به سرویس بیرونی به‌طور ضمنی مجاز نیست.

<a id="12-development"></a>

## ۱۲. راهنمای کار و بررسی برای توسعه‌دهنده

### ۱۲.۱. محل کدهای مسئول

| موضوع | مسیر اصلی |
| ---: | ---: |
| <span dir="ltr">schema، migration، trigger، metadata primitive</span> | <span dir="ltr">`lib/core/database/app_database.dart`</span> |
| مالک عمر دیتابیس و command gate | <span dir="ltr">`lib/core/database/app_database_lifecycle.dart`، `lib/core/application/command_gate.dart`</span> |
| فایل live و چرخهٔ backup/reopen | <span dir="ltr">`lib/app/backup_application_scope.dart`</span> |
| metadata تعهد/برچسب | <span dir="ltr">`lib/features/commitments/data/drift_commitment_repository.dart`</span> |
| cycle، schedule، occurrence و generation | <span dir="ltr">`lib/features/commitments/data/drift_commitment_plan_repository.dart`</span> |
| اصلاح مستقل شمار/credit و audit | <span dir="ltr">`lib/features/commitments/data/drift_commitment_correction_repository.dart`</span> |
| اعتبار، سیاست و جبرانی | <span dir="ltr">`lib/features/sessions/data/drift_session_repositories.dart`</span> |
| rule و instance اعلان | <span dir="ltr">`lib/features/reminders/data/drift_reminder_repository.dart`</span> |
| <span dir="ltr">actual/evidence</span> | <span dir="ltr">`lib/features/actuals/data/drift_actual_repository.dart`</span> |
| حساب و entry | <span dir="ltr">`lib/features/finance/data/drift_finance_repository.dart`</span> |
| <span dir="ltr">expectation</span> | <span dir="ltr">`lib/features/finance/data/drift_financial_expectation_repository.dart`</span> |
| matching، allocation و review | <span dir="ltr">`lib/features/reconciliation/data/drift_reconciliation_repository.dart`</span> |
| خواندن transactionهای matching | <span dir="ltr">`lib/features/reconciliation/data/drift_transaction_match_reader.dart`</span> |
| برچسب و عضویت | <span dir="ltr">`lib/features/classification/data/drift_tag_repository.dart`</span> |
| staged، suggestion و metadata Inbox | <span dir="ltr">`lib/features/inbox/data/drift_inbox_repository.dart`</span> |
| snapshot و validation/replacement | <span dir="ltr">`lib/features/backup/data/sqlite_backup_snapshot.dart`، `sqlite_backup_storage.dart`</span> |
| store تعطیلات | <span dir="ltr">`lib/features/calendar/data/sqlite_holiday_package_store.dart`</span> |

### ۱۲.۲. inspect فقط‌خواندنی

روی یک fixture یا کپی مجاز و مصنوعی، با ابزار SQLite یا connection read-only می‌توان این queryها را اجرا کرد. دادهٔ production را مستقیم اصلاح نکنید؛ تغییر باید از command محصول عبور کند.

<div dir="ltr">

```sql
PRAGMA user_version;
SELECT value FROM schema_metadata WHERE key = 'schema_version';
SELECT type, name, tbl_name, sql
FROM sqlite_master
WHERE name NOT LIKE 'sqlite_%'
ORDER BY type, name;

PRAGMA table_info('occurrences');
PRAGMA foreign_key_list('occurrences');
PRAGMA index_list('occurrences');
PRAGMA foreign_key_check;
PRAGMA integrity_check;
```

</div>

<span dir="ltr">`PRAGMA foreign_keys`</span> فقط تنظیم connection فعلی را نشان می‌دهد؛ یک اتصال read-only تازهٔ sqlite3 الزاماً وضعیت connection production را بازتاب نمی‌دهد. برای رابطهٔ بدون FK هم <span dir="ltr">`foreign_key_check`</span> کافی نیست؛ invariant domain جدا باید بررسی شود.

نمونهٔ trace ساختار تعهد، بدون استخراج یادداشت/مبلغ/شناسهٔ حساب:

<div dir="ltr">

```sql
SELECT c.id AS commitment_id, cy.id AS cycle_id,
       s.id AS schedule_id, s.version,
       o.id AS occurrence_id, o.status
FROM commitments AS c
JOIN commitment_cycles AS cy ON cy.commitment_id = c.id
LEFT JOIN schedule_definitions AS s ON s.cycle_id = cy.id
LEFT JOIN occurrences AS o ON o.schedule_definition_id = s.id
WHERE c.id = :commitment_id;
```

</div>

در این query ترتیب زمانی نوبت‌ها از متن <span dir="ltr">`current_scheduled_value`</span> استنتاج نمی‌شود. برای گزارش موجودی/مانده/تسویه از projection دامنه استفاده کنید؛ query فوق calculation محصول نیست.

### ۱۲.۳. ابزار و تست‌های مرتبط

برای تغییر کد schema، ابزارهای موجود مخزن عبارت‌اند از:

<div dir="ltr">

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test test/repository/app_database_test.dart
flutter test test/repository/sqlite_backup_schema_compatibility_test.dart
```

</div>

این فرمان‌ها راهنمای اجرای آینده‌اند؛ ثبت آن‌ها ادعای اجرای آن‌ها در تغییر مستندات نیست. pipeline کامل [<span dir="ltr">tool/ci.ps1</span>](../tool/ci.ps1) را مطابق [<span dir="ltr">development-workflow</span>](development-workflow.md) دنبال کنید. تست اضافه باید از acceptance رفتار واقعی بیاید، نه فقط mirror تعریف جدول.

| ریسک / قابلیت | شواهد تست موجود برای مراجعه |
| ---: | ---: |
| snapshot تمام state | <span dir="ltr">[backup_full_state_test](../test/repository/backup_full_state_test.dart)، [sqlite_backup_snapshot_test](../test/repository/sqlite_backup_snapshot_test.dart)</span> |
| validation، replacement و failure recovery | <span dir="ltr">[sqlite_backup_restore_test](../test/repository/sqlite_backup_restore_test.dart)، [backup_failure_stages_test](../test/repository/backup_failure_stages_test.dart)</span> |
| کلید مستقل recovery | <span dir="ltr">[independent_recovery_backup_test](../test/repository/independent_recovery_backup_test.dart)</span> |
| <span dir="ltr">recurrence legacy/version/concurrency</span> | <span dir="ltr">[recurrence_version_legacy_test](../test/repository/recurrence_version_legacy_test.dart)، [recurrence_concurrency_test](../test/repository/recurrence_concurrency_test.dart)، [rolling_recurrence_test](../test/repository/rolling_recurrence_test.dart)</span> |
| preview/preparation و backup | <span dir="ltr">[planned_occurrences_test](../test/repository/planned_occurrences_test.dart)، [planned_occurrence_backup_test](../test/repository/planned_occurrence_backup_test.dart)</span> |
| اصلاح شمار/credit | <span dir="ltr">[commitment_correction_test](../test/repository/commitment_correction_test.dart)، [commitment_correction_backup_test](../test/repository/commitment_correction_backup_test.dart)</span> |
| حساب، metadata و ledger correction | <span dir="ltr">[account_metadata_test](../test/repository/account_metadata_test.dart)، [financial_account_admission_test](../test/repository/financial_account_admission_test.dart)، [finance_correction_atomic_test](../test/repository/finance_correction_atomic_test.dart)</span> |
| بررسی مستقل و migration review | <span dir="ltr">[relationship_review_test](../test/repository/relationship_review_test.dart)، [relationship_schema_fixture_test](../test/repository/relationship_schema_fixture_test.dart)</span> |
| تأیید/اصلاح Inbox و replay | <span dir="ltr">[inbox_confirmation_test](../test/repository/inbox_confirmation_test.dart)، [inbox_review_repair_test](../test/repository/inbox_review_repair_test.dart)، [sms_replay_test](../test/repository/sms_replay_test.dart)</span> |
| actual و اعلان | <span dir="ltr">[occurrence_actual_history_test](../test/repository/occurrence_actual_history_test.dart)، [reminder_interruption_recovery_test](../test/repository/reminder_interruption_recovery_test.dart)</span> |
| اعتبار و برچسب | <span dir="ltr">[session_repositories_test](../test/repository/session_repositories_test.dart)، [tag_lifecycle_test](../test/repository/tag_lifecycle_test.dart)</span> |
| store مستقل تعطیلات | <span dir="ltr">[holiday_package_test](../test/repository/holiday_package_test.dart)</span> |

برای claim دوام، تست file-backed و cold reopen لازم است؛ in-memory به‌تنهایی کافی نیست. اثبات native notification، lifecycle/authentication، file picker/Keystore، بازیابی دستگاه ازدست‌رفته یا performance دستگاه مرجع به شواهد مستقل مربوط نیاز دارد.

<a id="13-evidence"></a>

## ۱۳. دامنهٔ صحت این سند و نگهداری آن

این تغییر **فقط مستندات** است: قرارداد آن پوشش تمام جدول‌ها/ستون‌های جاری، تفکیک رابطهٔ SQL از ارجاع منطقی، بیان نقش جدول و ارائهٔ شمای کلی قابل مراجعه است. behavior، schema، migration و dependency تغییر نمی‌کنند. معیار بررسی سند، تطبیق نام/نوع/nullability/default/PK/FK/UNIQUE و enumها با کد جاری، بررسی لینک‌ها و diff است؛ اجرای journey دستگاه برای این تغییر لازم نیست.

وضعیت زیر را جدا نگه دارید:

- **پیاده‌سازی:** وجود schema/repository تنها زیرساخت همان قابلیت است؛ readiness از PRD و verification هر ویژگی تعیین می‌شود.
- **تأیید این سند:** تطبیق ساختاری با کد، صحت محتوا را در محدودهٔ شرح schema بررسی می‌کند؛ با قبول مستقل قابلیت محصول برابر نیست.
- **شواهد اجرا:** جدول تست‌های بالا فهرست منابع است و ادعای اجرای مجدد یا گذر release gate نیست.
- **محدودیت‌ها:** روابط منطقی بدون FK، تفاوت DDL تازه/مهاجرت‌یافته، indexهای وابسته به مسیر migration و حفاظت application برای بخشی از audit/ledger باید در تغییر بعدی هم صریح باقی بمانند.

رکورد بررسی این تغییر مستندات در ۲۰۲۶-۱۰-۱۴:

| بررسی | نتیجه / دامنهٔ شاهد |
| ---: | ---: |
| تطبیق با تعریف Drift | ۲۴ جدول و ۱۸۰ ستون؛ نام، نوع، <span dir="ltr">NULL</span>، default، FK، <span dir="ltr">PK</span> و tupleهای <span dir="ltr">UNIQUE</span> بررسی شد |
| نگاشت enum و ERD | ۳۰ ردیف نگاشت enum و تمام ۲۴ ارتباط FK با source تطبیق داده شد |
| لینک و ساختار متن | مسیر فایل‌ها/anchorهای ارجاع‌شده، whitespace و بسته‌بودن code fenceها بررسی شد |
| تست Flutter/analyzer/native | اجرا نشد؛ تغییر فقط Markdown است و کد، schema یا dependency عوض نشده است |
| نمایش گرافیکی Mermaid و review مستقل | انجام نشده؛ صحت ارتباط‌ها بررسی ساختاری شده، پذیرش مستقل با reviewer مخزن است |

بازبینی جهت نمایش در ۲۰۲۶-۱۰-۱۶: متن، تیترها، فهرست‌ها و جدول‌ها جهت راست‌به‌چپ دارند؛ شناسه‌ها، عبارت‌های فنی و بلوک‌های کد جهت چپ‌به‌راست مستقل دارند. دو مسیر متنی فارسی به فهرست خوانا تبدیل شدند. رندر Markdown و ساختار HTML از نظر جهت، حفظ داده‌های جدول‌ها، مثال‌های فنی و لینک‌ها بررسی شد؛ بررسی تصویری مرورگر به‌علت محدودیت اجرای ابزار در محیط انجام نشد و پیش‌نمایش نهایی داخل IDE نیز تأیید نشده است.

مالک نگهداری این سند، توسعه‌دهندهٔ تغییر بعدی persistence است؛ اقدام بعدی هنگام هر تغییر جدول، enum، codec یا namespace، به‌روزرسانی همین مرجع و تست‌های compatibility مربوط است. تصمیم exposure/release همچنان در PRD و verificationهای موجود باقی می‌ماند؛ این سند هیچ release gate را نمی‌بندد و sign-off مستقل انتشار محسوب نمی‌شود.

</div>
