# PlanAct — Product Requirements Document

**Document type:** Product Requirements Document  
**Product:** PlanAct  
**Current application version:** `0.1.7+2`
**Status:** Living Document / Active Development

## Document Governance

This document defines **what PlanAct must do and why**: product scope, user-visible behavior, acceptance criteria, priorities, and non-goals.

`AGENTS.md` is the companion implementation contract and defines **how the product must be built safely**: architecture boundaries, persistence/data-integrity rules, coding constraints, testing expectations, and AI-agent workflow.

For conflicts, the repository source-of-truth order is:

1. Explicit approved ADR / latest approved product decision.
2. `PRD.md` for product behavior and scope.
3. `AGENTS.md` for implementation constraints and safeguards.
4. `docs/ARCHITECTURE_AND_DOMAIN_RULES.md`.
5. Current milestone/task prompt.
6. Existing implementation conventions.

A task may narrow scope, but it must not silently weaken product acceptance criteria or data-integrity guarantees. Product-visible semantic changes must update this PRD; durable implementation constraints affected by those changes must be reflected in `AGENTS.md` in the same change.

---

## 1. Product Overview

PlanAct یک دستیار شخصی فارسی برای مدیریت تعهدها، برنامه‌ها و امور مالی روزمره است.

هدف محصول این نیست که صرفاً جایگزین تقویم، Todo List، Reminder یا اپلیکیشن حسابداری باشد. PlanAct باید این مفاهیم را در یک چرخه‌ی واحد به هم متصل کند:

**برنامه‌ریزی → زمان‌بندی → یادآوری → اقدام → ثبت واقعیت → تطبیق → تکمیل**

کاربر باید در هر لحظه بتواند سه سؤال را پاسخ دهد:

1. چه چیزی قرار بود اتفاق بیفتد؟
2. در واقعیت چه اتفاقی افتاد؟
3. اکنون چه چیزی نیاز به توجه دارد؟

PlanAct به‌صورت **offline-first** و **privacy-first** طراحی می‌شود و قابلیت‌های اصلی آن نباید به اینترنت یا سرویس ابری وابسته باشند.

---

# 2. Problem Statement

تعهدهای واقعی زندگی معمولاً فقط یک Task ساده نیستند.

برای مثال «کلاس زبان» می‌تواند شامل موارد زیر باشد:

- یک تعهد بلندمدت؛
- چند دوره یا ترم؛
- تعداد مشخصی جلسه؛
- برنامه هفتگی؛
- لغو یا جابه‌جایی جلسه؛
- جلسه جبرانی؛
- اعتبار باقی‌مانده؛
- پرداخت یک یا چند مبلغ؛
- یادآوری؛
- غیبت یا حضور؛
- توقف موقت؛
- تاریخ پایان برنامه‌ریزی‌شده و واقعی.

ابزارهای متداول این اطلاعات را در چند برنامه مجزا نگهداری می‌کنند:

- Calendar برای زمان؛
- Todo App برای کارها؛
- Reminder برای هشدار؛
- Banking/Expense App برای پرداخت؛
- Notes برای توضیحات.

نتیجه این است که رابطه میان **تعهد، برنامه، اتفاق واقعی و هزینه‌ی واقعی** از بین می‌رود.

PlanAct باید این رابطه را به‌صورت قابل توضیح و قابل بازیابی حفظ کند.

---

# 3. Product Vision

PlanAct باید تبدیل به یک **Personal Commitment Operating System** شود؛ سیستمی که تعهدهای کاربر را از زمان ایجاد تا پایان، همراه با زمان‌بندی، اتفاقات واقعی و آثار مالی آن‌ها مدیریت می‌کند.

اصل کلیدی محصول:

> PlanAct نباید فقط بگوید چه چیزی برنامه‌ریزی شده است؛ باید بتواند تفاوت بین «برنامه» و «واقعیت» را نیز توضیح دهد.

---

# 4. Target Users

## 4.1 Primary User

کاربر فارسی‌زبان که چند نوع تعهد شخصی، کاری، آموزشی یا مالی را هم‌زمان مدیریت می‌کند.

نمونه‌ها:

- فردی با چند کلاس یا فعالیت هفتگی؛
- والدینی که برنامه‌های خانواده را مدیریت می‌کنند؛
- فریلنسر با تعهدها و پرداخت‌های مختلف؛
- دانشجو با کلاس‌ها، دوره‌ها و هزینه‌ها؛
- فردی که می‌خواهد هزینه‌ها را در ارتباط با فعالیت‌های واقعی خود ببیند.

---

# 5. Product Principles

## 5.1 Offline First

عملکردهای اصلی برنامه باید بدون اینترنت قابل استفاده باشند.

## 5.2 Privacy First

اطلاعات شخصی و مالی به‌صورت پیش‌فرض روی دستگاه کاربر نگهداری شوند.

## 5.3 History First

ویرایش اطلاعات نباید گذشته را بدون ردپا بازنویسی کند.

در صورت تغییر برنامه، تا حد امکان باید مشخص باشد:

- برنامه اولیه چه بوده؛
- چه چیزی تغییر کرده؛
- چه چیزی واقعاً اتفاق افتاده است.

## 5.4 Deterministic Core

محاسبات مهم مانند:

- موجودی حساب؛
- اعتبار جلسات؛
- زمان‌بندی؛
- وضعیت رخداد؛
- matching؛
- پیش‌بینی deterministic؛

باید قابل تست و بازسازی باشند.

## 5.5 Human in the Loop

اتوماسیون می‌تواند پیشنهاد بدهد، اما تغییرات حساس نباید بدون تأیید کاربر انجام شوند.

## 5.6 Explainability

هر پیشنهاد یا تشخیص خودکار مهم باید دلیل قابل فهم داشته باشد.

## 5.7 Persian First

تجربه‌ی محصول باید از ابتدا برای:

- زبان فارسی؛
- RTL؛
- اعداد فارسی در محل مناسب؛
- تقویم جلالی؛

طراحی شود، نه اینکه بعداً به محصول انگلیسی اضافه شود.

---

# 6. Core Product Model

مدل اصلی محصول باید مفاهیم زیر را از یکدیگر جدا نگه دارد.

## 6.1 Commitment

تعهد نشان‌دهنده‌ی چیزی است که کاربر قصد پیگیری آن را دارد.

نمونه:

- کلاس زبان
- پرداخت اجاره
- ورزش
- جلسه مشاوره
- تمدید بیمه

تعهد نباید با یک رخداد تقویمی برابر در نظر گرفته شود.

---

## 6.2 Commitment Cycle

یک تعهد می‌تواند چند دوره‌ی مستقل داشته باشد.

مثال:

`کلاس زبان`

- ترم اول
- ترم دوم
- ترم سوم

تاریخچه‌ی دوره‌های قبلی باید حفظ شود.

---

## 6.3 Schedule Definition

قانون تولید زمان‌های برنامه‌ریزی‌شده.

باید از موارد زیر پشتیبانی کند:

- یک‌باره؛
- روزانه؛
- هفتگی؛
- ماهانه؛
- سالانه؛
- تعداد رخداد محدود؛
- پایان در تاریخ مشخص؛
- برنامه‌های دستی یا ترکیبی.

---

## 6.4 Occurrence

یک نمونه واقعی از برنامه.

مثال:

تعهد:

`کلاس زبان`

Occurrence:

`شنبه ۱۸ مهر ساعت ۱۸`

Occurrence باید هویت مستقل داشته باشد تا بتوان روی آن:

- reminder؛
- actual؛
- payment match؛
- cancellation؛
- replacement؛

ثبت کرد.

---

## 6.5 Actual

آنچه واقعاً برای یک Occurrence اتفاق افتاده است.

نمونه outcome:

- completed
- attended
- cancelled
- excused absence
- late cancellation
- no-show
- skipped

Plan و Actual نباید یکی باشند.

---

## 6.6 Entitlement

برای تعهدهایی که تعداد مصرف یا اعتبار دارند.

مثال:

کاربر بسته‌ی ۱۲ جلسه‌ای خریداری می‌کند.

اعتبار باقی‌مانده نباید فقط در یک counter ذخیره شود؛ باید از ledger قابل بازسازی باشد.

---

## 6.7 Financial Account & Ledger

حساب‌های مالی کاربر می‌توانند شامل:

- حساب بانکی؛
- پول نقد؛
- کیف پول دیجیتال؛

باشند.

موجودی باید از Account Entryها قابل بازسازی باشد.

---

## 6.8 Transaction Match

یک تراکنش مالی ممکن است به:

- یک تعهد؛
- یک occurrence؛
- چند occurrence؛

مرتبط باشد.

همچنین یک تعهد ممکن است توسط چند پرداخت تسویه شود.

بنابراین matching باید many-to-many باشد.

---

# 7. Core User Journeys

## Journey A — ثبت یک تعهد ساده

کاربر:

1. دکمه افزودن را انتخاب می‌کند.
2. عنوان تعهد را وارد می‌کند.
3. تاریخ و زمان را تعیین می‌کند.
4. اولویت و توضیح اختیاری اضافه می‌کند.
5. تعهد را ثبت می‌کند.
6. آن را در Today یا Calendar مشاهده می‌کند.

### Acceptance Criteria

- عنوان خالی قابل ثبت نباشد.
- تعهد بعد از restart برنامه باقی بماند.
- تاریخ برای کاربر به شکل جلالی نمایش داده شود.
- تغییر وضعیت تعهد persist شود.

---

# 8. Recurring Commitments

کاربر باید بتواند تعهد تکرارشونده ایجاد کند.

حداقل recurrenceهای مورد نیاز:

- Daily
- Weekly
- Monthly
- Yearly

برای برنامه‌های هفتگی باید انتخاب چند روز هفته امکان‌پذیر باشد.

Termination:

- بدون پایان مشخص با generation horizon؛
- تا تاریخ مشخص؛
- تعداد occurrence مشخص.

سیستم نباید برای recurrence نامحدود، بی‌نهایت occurrence در دیتابیس ایجاد کند.

برای جلوگیری از ابهام، recurrence دو بُعد مستقل دارد و هر دو باید در domain مشخص باشند:

- **Pattern/Frequency:** مانند Daily، Weekly، Monthly، Yearly یا الگوی دستی/ترکیبی.
- **Termination/Materialization:** بدون پایان با generation horizon، تا تاریخ مشخص، تعداد مشخص، یا package/manual semantics.

ویرایش recurrence باید با versioning/history rules در `AGENTS.md` سازگار باشد و گذشته را silently بازنویسی نکند.

---

# 9. Schedule Editing

برای تغییر یک برنامه‌ی تکرارشونده، محصول باید در نهایت سه scope را پشتیبانی کند:

### This occurrence

فقط همین رخداد تغییر کند.

### This and following

همین occurrence و آینده تغییر کنند.

### Active cycle

قانون کل cycle فعال تغییر کند.

Occurrenceهای گذشته نباید به‌طور مخفی بازنویسی شوند.

---

# 10. Today

صفحه Today باید پاسخ دهد:

> امروز چه چیزهایی نیاز به توجه دارند؟

محتوا می‌تواند شامل:

- رخدادهای امروز؛
- تعهدهای overdue؛
- reminderهای نزدیک؛
- کارهای بدون نتیجه ثبت‌شده؛
- پرداخت‌های سررسیدشده؛
- موارد نیازمند reconciliation.

هر آیتم باید action واضح داشته باشد.

---

# 11. Calendar

Calendar باید occurrenceهای برنامه‌ریزی‌شده را نمایش دهد.

Requirements:

- نمایش جلالی؛
- مرور ماه‌ها؛
- نمایش رخدادهای هر روز؛
- دسترسی از occurrence به commitment؛
- تمایز مناسب بین statusها؛
- عدم از دست رفتن occurrenceهای گذشته پس از تغییر schedule.

---

# 12. Reminder System

کاربر باید بتواند reminder را نسبت به occurrence تعریف کند.

نمونه:

- در زمان رخداد؛
- ۳۰ دقیقه قبل؛
- ۱ ساعت قبل؛
- یک روز قبل.

Rule و Instance باید از یکدیگر جدا باشند.

هنگام تغییر زمان occurrence:

- reminderهای قدیمی باید لغو شوند؛
- instanceهای معتبر جدید ساخته شوند.

Reminderهای مربوط به occurrenceهای:

- completed؛
- cancelled؛
- expired؛

نباید بدون دلیل فعال باقی بمانند.

---

# 13. Classes, Sessions & Service Packages

PlanAct باید به‌طور خاص workflowهای session-based را پشتیبانی کند.

مثال‌ها:

- کلاس زبان؛
- موسیقی؛
- شنا؛
- مشاوره؛
- باشگاه؛
- جلسات درمانی یا خدماتی.

سیستم باید بتواند موارد زیر را ثبت کند:

- total units؛
- consumed units از طریق ledger؛
- provider cancellation؛
- user cancellation؛
- late cancellation؛
- no-show؛
- holiday؛
- free absence quota؛
- replacement/makeup session؛
- freeze؛
- extension.

---

# 14. Finance

کاربر باید بتواند چند حساب مالی ایجاد کند.

Minimum account types:

- Bank
- Cash
- Digital Wallet

Minimum transaction types:

- Income
- Expense
- Transfer In
- Transfer Out
- Adjustment
- Refund/Reversal

مبالغ باید به شکل integer در smallest supported unit ذخیره شوند و محاسبات مالی نباید به floating-point وابسته باشند.

انتقال بین دو حساب متعلق به کاربر نباید income یا expense محسوب شود.

---

# 15. Finance ↔ Commitment Matching

کاربر باید بتواند پرداخت را به تعهد یا occurrence مرتبط کند.

سناریوهای لازم:

- یک پرداخت کامل؛
- پرداخت ناقص؛
- چند پرداخت؛
- overpayment؛
- یک تراکنش برای چند occurrence؛
- اصلاح matching قبلی.

اصلاح matching نباید history قبلی را بدون ردپا حذف کند.

---

# 16. Inbox

داده‌ی خام خارجی نباید مستقیماً وارد ledger اصلی شود.

Flow:

`Source → Staged Import → Suggestion/Draft → User Review → Final Data`

Sourceهای احتمالی:

- SMS بانکی؛
- import دستی؛
- فایل؛
- integrationهای آینده.

برای هر staged item باید provenance قابل نگهداری باشد.

---

# 17. Duplicate Detection

قبل از تبدیل import به داده نهایی، سیستم باید duplicate احتمالی را بررسی کند.

سیگنال‌ها می‌توانند شامل موارد زیر باشند:

- source key؛
- fingerprint؛
- amount؛
- timestamp؛
- merchant؛
- reference.

موارد ambiguous باید برای کاربر نمایش داده شوند و silently merge نشوند.

---

# 18. Local Automation

قابلیت‌های هوشمند محصول باید ابتدا rule-based و deterministic باشند.

نمونه‌ها:

- merchant normalization؛
- تشخیص پرداخت دوره‌ای؛
- پیشنهاد category؛
- پیشنهاد commitment match؛
- تشخیص overdue؛
- تشخیص upcoming due date؛
- تشخیص low balance؛
- تشخیص amount anomaly.

---

# 19. AI Features

AI یک قابلیت optional است و نباید dependency هسته‌ی محصول باشد.

خاموش بودن AI نباید مانع موارد زیر شود:

- ثبت تعهد؛
- scheduling؛
- reminders؛
- actuals؛
- finance؛
- matching؛
- backup/restore.

AI نباید بدون تأیید کاربر:

- تراکنش نهایی ایجاد کند؛
- موجودی را تغییر دهد؛
- historical record را حذف کند؛
- entitlement را تغییر دهد؛
- transaction matching حساس را قطعی کند.

---

# 20. Backup & Restore

کاربر باید بتواند داده‌های محلی خود را backup کند.

Backup package باید حداقل شامل:

- schema version؛
- app version؛
- creation timestamp؛
- checksum؛
- database payload؛

باشد.

Restore باید:

1. فایل را validate کند.
2. compatibility را بررسی کند.
3. قبل از جایگزینی داده‌ی live، یک safety snapshot معتبر از وضعیت فعلی ایجاد کند.
4. داده را atomically جایگزین کند.
5. derived state را rebuild کند.
6. reminderها را مجدداً synchronize کند.

اگر backup نامعتبر باشد، داده‌ی فعلی نباید آسیب ببیند.

---

# 21. Persistence Requirements

هر داده‌ای که کاربر انتظار دارد بعد از بستن برنامه باقی بماند، باید در persistent storage ذخیره شود.

قبل از اعلام آماده بودن MVP، حداقل موارد زیر نباید صرفاً In-Memory باشند:

- Commitments
- Commitment Cycles
- Schedule Definitions
- Occurrences
- Financial Accounts
- Account Entries
- Reminder Rules / Instances
- Actuals

In-memory repositoryها می‌توانند برای testing استفاده شوند، اما نباید storage اصلی production باشند.

---

# 22. Current Implementation Baseline

در baseline فعلی `develop/new-feature`:

### Implemented / visible foundation

- Flutter application shell
- Persian RTL UI
- light/dark theme
- startup/loading state
- Commitment domain
- commitment status transitions
- SQLite + Drift database
- persistent CommitmentRepository
- Quick Capture
- Jalali date UI
- recurring commitment inputs
- Today page
- Calendar page
- basic Finance UI
- account/entry domain logic
- database schema for advanced scheduling
- entitlement ledger schema
- reminder schema
- actual/evidence schema
- transaction matching schema
- staged import / inbox schema

### Partially integrated

- scheduling
- recurring occurrences
- reminders
- finance persistence
- entitlement flows
- actual recording
- transaction matching
- inbox/import flow

### Important architectural gap

وجود table یا domain object به معنی کامل بودن feature در product flow نیست.

هر feature تنها زمانی «Implemented» محسوب شود که حداقل این زنجیره کامل باشد:

**Domain → Repository/Persistence → Application Use Case → UI → Error Handling → Tests**

برای featureهایی که state پایدار دارند، این زنجیره همچنین باید **restart persistence، migration impact، backup/restore impact** و در صورت نیاز **platform integration** را پوشش دهد. وجود schema، domain object یا UI به‌تنهایی فقط foundation/partial implementation محسوب می‌شود.

---

# 23. MVP Definition

نسخه MVP زمانی قابل قبول است که کاربر بتواند بدون از دست رفتن اطلاعات:

1. یک تعهد ایجاد کند.
2. آن را ویرایش کند.
3. تعهد یک‌باره یا تکرارشونده بسازد.
4. رخدادهای آن را در Today و Calendar ببیند.
5. وضعیت یا Actual رخداد را ثبت کند.
6. برنامه را بدون حذف history تغییر دهد.
7. reminder دریافت کند.
8. حساب مالی بسازد.
9. expense/income/transfer ثبت کند.
10. داده‌ها بعد از restart باقی بمانند.
11. backup بگیرد.
12. backup را با validation بازیابی کند.

---

# 24. Post-MVP

موارد زیر می‌توانند بعد از core MVP تکمیل شوند:

- SMS parsing کامل؛
- auto reconciliation؛
- anomaly detection پیشرفته؛
- on-device AI؛
- advanced financial reports؛
- complex forecasting؛
- cloud synchronization؛
- multi-device sync؛
- collaboration/family accounts.

---

# 25. Non-Goals

برای MVP موارد زیر هدف اصلی نیستند:

- social network؛
- تیم project management؛
- cloud-first architecture؛
- web banking؛
- bank account credentials؛
- autonomous financial decisions؛
- AI-dependent core flows؛
- replacement کامل نرم‌افزار حسابداری حرفه‌ای.

---

# 26. Product Success Metrics

از آنجا که محصول offline-first است، telemetry نباید پیش‌فرض اجباری باشد.

در تست و در صورت opt-in telemetry، شاخص‌های مناسب عبارت‌اند از:

### Reliability

- نرخ خطای migration نزدیک به صفر
- عدم از دست رفتن داده در restart
- restore موفق backupهای معتبر
- عدم ایجاد duplicate occurrence
- عدم ایجاد duplicate reminder

### Core Usage

- درصد تعهدهایی که occurrence دریافت می‌کنند
- درصد occurrenceهایی که Actual ثبت می‌شوند
- درصد recurring commitments که بدون اصلاح دستی schedule درست تولید می‌کنند

### Financial Integrity

- balance قابل بازسازی از ledger
- transferها بدون double-count شدن
- matchingها قابل trace و اصلاح باشند

---

# 27. Quality Requirements

## Testing

برای domainهای حساس تست الزامی است:

- recurrence generation
- Jalali/Gregorian boundaries
- month-end rules
- leap year
- timezone behavior
- status transitions
- entitlement ledger
- financial balance
- transfer
- matching
- migrations
- backup/restore

## CI

Pull Requestها باید حداقل این checks را پاس کنند:

- format
- static analysis
- tests

Release نباید در صورت شکست این موارد ساخته شود.

---

# 28. Data Integrity Rules

1. Historical record بدون action صریح کاربر حذف نشود.
2. Financial balance از ledger قابل بازسازی باشد.
3. Entitlement balance از ledger قابل بازسازی باشد.
4. Schedule edits گذشته را silently rewrite نکنند.
5. Matching correction سابقه اصلاح را نگه دارد.
6. Archived entities با history از دیتابیس hard-delete نشوند.
7. Referential integrity تا حد ممکن در SQLite enforce شود.
8. Migrationها باید backward-data-safe باشند.

---

# 29. Security & Privacy

- داده حساس به‌صورت پیش‌فرض local باشد.
- اطلاعات مالی یا شخصی در logهای عادی چاپ نشوند.
- فایل backup باید قبل از restore اعتبارسنجی شود.
- secret یا signing key خصوصی نباید داخل repository قرار گیرد.
- هر cloud/AI integration آینده باید opt-in باشد.

### قفل برنامه

- قفل برنامه اختیاری و به‌صورت پیش‌فرض خاموش است؛ تنظیم آن باید بعد از راه‌اندازی مجدد باقی بماند.
- فعال‌سازی و غیرفعال‌سازی نیازمند احراز هویت تازهٔ دستگاه و ذخیرهٔ موفق تنظیم است؛ لغو یا خطا نباید تنظیم را تغییر دهد.
- در صورت فعال‌بودن، ورود اولیه و بازگشت از پس‌زمینه باید پیش از نمایش دادهٔ خصوصی قفل شوند؛ صفحه‌ها، فرم‌ها و پنجره‌های باز نیز پوشش داده شوند، بدون حذف ورودی فرم.
- احراز هویت از اثر انگشت یا رمز دستگاه استفاده می‌کند؛ شکست یا نبود قابلیت باید با پیام فارسی و تلاش دوباره همراه باشد، نه دورزدن قفل یا حذف داده.
- قفل رابط کاربری جایگزین رمزنگاری پایگاه داده یا پشتیبان نیست.

Implementation checkpoint (2026-10-05): Priority 4 remains **partial for native release acceptance**. Root-route protection, lifecycle invalidation, authenticated setting changes, failure/retry feedback and persisted settings are implemented. The 271-test suite and isolated Android build pass; real-device authentication, process lifecycle, recents privacy and accessibility acceptance remain open. See [app-lock verification](../APP_LOCK_VERIFICATION.md).

---

# 30. Release Criteria

یک release candidate زمانی آماده است که:

- `flutter analyze` موفق باشد.
- test suite موفق باشد.
- migration از نسخه قبلی تست شده باشد.
- cold start با دیتابیس موجود تست شود.
- ایجاد و ویرایش commitment تست شود.
- restart persistence تست شود.
- recurring scheduling تست شود.
- financial balance integrity تست شود.
- backup/restore تست شود.
- Android release build موفق باشد.

---

# 31. Near-Term Product Priorities

ترتیب پیشنهادی تکمیل محصول:

### P0 — Persistence & Core Loop

- persistent scheduling repository
- persistent occurrence repository
- اتصال Today/Calendar به occurrenceهای واقعی دیتابیس
- persistent finance repository
- actual recording
- restart-safe state

### P0 — Data Integrity

- migrations
- recurrence edge cases
- ledger correctness
- history preservation

### P1 — Reminders

- platform notification integration
- reminder rescheduling
- snooze
- startup rebuild

Implementation checkpoint (2026-10-05): reminders remain **partial**, not release-complete. Explicit Settings permission activation, durable creation intent, cancellation retry, occurrence-action synchronization, and owned-alarm cleanup are implemented. Actual native delivery/retry/cancellation/orphan cleanup was verified only on Android 11 in an isolated debug package. Reboot recovery, newer Android permission denial/revocation, full snooze/tap journeys, lifecycle reconciliation, and interruption-safe edit recovery remain acceptance work. See [reminder verification evidence](../REMINDER_VERIFICATION.md).

### P1 — Session Packages

- entitlement plans
- consumption ledger
- cancellation policies
- makeup sessions
- freeze

### P1 — Financial Matching

- transaction ↔ occurrence matching
- partial/multiple payments
- corrections

### P2 — Inbox

- staged imports
- SMS adapter

> Implementation checkpoint (2026-10-05): Priority 3 remains partial. Inbox provider rescans, receipt-time handling, ingestion feedback, and resolved-suggestion protection are implemented and validated by 256 passing tests and an isolated Android build. Background ingestion, pagination, native permission/replay evidence, and complete parser/account-selection journeys remain open. See [SMS verification](../SMS_VERIFICATION.md).
- duplicate detection
- user confirmation

### P2 — Automation

- recurring payment detection
- merchant normalization
- explainable suggestions
- risk detection

### P3 — Optional AI

- on-device enhancements
- optional classification
- optional prediction

---

# 32. Definition of Done for a Feature

یک feature زمانی Done محسوب می‌شود که:

- رفتار محصول مشخص باشد؛
- domain rule پیاده شده باشد؛
- repository مناسب وجود داشته باشد؛
- persistence production-ready باشد؛
- UI قابل استفاده وجود داشته باشد؛
- loading/error/empty state پوشش داده شده باشد؛
- edge caseهای اصلی تست شده باشند؛
- restart باعث از دست رفتن داده نشود؛
- history و integrity حفظ شوند؛
- documentation در صورت نیاز به‌روز شده باشد.

---

# 33. PRD ↔ Implementation Contract

برای جلوگیری از divergence بین محصول و پیاده‌سازی:

1. `PRD.md` مرجع رفتار محصول، acceptance criteria، scope، priorities و non-goals است.
2. `AGENTS.md` مرجع محدودیت‌های معماری، data integrity، persistence، testing و روش کار coding agent است.
3. تغییر semantic در رفتار کاربر باید در PRD ثبت شود؛ تغییر durable در معماری/قواعد پیاده‌سازی باید در AGENTS ثبت شود.
4. هیچ task promptی نباید بدون تصمیم صریح، acceptance criteria یا guaranteeهای integrity را تضعیف کند.
5. اگر requirementی فقط بخشی از زنجیره‌ی implementation را دارد، وضعیت آن باید `Partial` باشد نه `Implemented`.
6. در تعارض حل‌نشده، حفظ data/history و انتخاب کم‌برگشت‌ناپذیرترین مسیر اولویت دارد تا تصمیم صریح ثبت شود.

---

# 34. Product North Star

PlanAct باید بتواند برای هر تعهد مهم کاربر یک timeline قابل توضیح ارائه کند:

**چه چیزی متعهد شدم؟  
چه برنامه‌ای برای آن داشتم؟  
چه تغییراتی ایجاد شد؟  
واقعاً چه اتفاقی افتاد؟  
چقدر برای آن پرداخت کردم یا دریافت کردم؟  
چه چیزی هنوز باقی مانده است؟**

اگر محصول بتواند این زنجیره را با داده‌ی قابل اعتماد و بدون وابستگی به cloud حفظ کند، هدف اصلی PlanAct محقق شده است.

## Backup implementation status — Priority 1

The production encrypted export/import path is implemented, but the backup release gate remains partial. Current key recovery is restricted to the original installation: device loss, uninstall, or another device is not supported. Export/import confirmations disclose this restriction. Strict fresh-schema validation may reject migrated current-version databases. Exhaustive entity round-trip, concurrent command/lifecycle safety, and isolated native Android picker/Keystore/crash evidence remain required. This status does not reduce the backup/restore acceptance criteria. See docs/adr/0013-production-backup-restore.md.
