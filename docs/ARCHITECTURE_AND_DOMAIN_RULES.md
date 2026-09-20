# معماری و قواعد دامنه — Personal Commitment Manager

این فایل نسخه‌ی repo-friendly از قواعد اصلی نقشه‌ی راه محصول است. هدف آن این است که قبل از توسعه هر Feature، مرزهای دامنه و تصمیمات غیرقابل شکستن مشخص باشند.

> برای قوانین اجرایی AI و توسعه روزانه، `AGENTS.md` مرجع اول است.

## 1. مدل ذهنی محصول

سؤال مرکزی سیستم:

> «قرار بود چه اتفاقی بیفتد، واقعاً چه اتفاقی افتاد، و الان چه چیزی نیاز به توجه دارد؟»

چرخه اصلی:

`Plan → Schedule → Remind → Action → Actual → Reconcile → Done`

## 2. مدل دامنه اصلی

```text
Commitment
  └── CommitmentCycle
        ├── ScheduleDefinition
        ├── SessionPolicy / EntitlementPlan (optional)
        ├── Occurrence*
        │     ├── ReminderInstance*
        │     └── Actual / Evidence*
        └── ReminderRule*

FinancialAccount ── AccountEntry ── FinancialTransaction
FinancialTransaction ── TransactionMatch ── Occurrence
```

### Commitment
مفهوم پایدار قابل پیگیری؛ مثال: «کلاس موسیقی»، «قبض اینترنت»، «تمدید بیمه».

### CommitmentCycle
یک دوره/ترم/پکیج/بازه فعال از Commitment. خرید ۴ جلسه جدید یا شروع ترم جدید، Cycle جدید می‌سازد و تاریخچه Cycle قبلی را بازنویسی نمی‌کند.

حداقل مفاهیم:

- `cycleType`: OpenEnded / FixedDateRange / FixedCount / ManualPackage / Hybrid
- `startDate`
- `plannedEndDate`
- `actualEndDate`
- `targetUnits`
- `completionRule`: ByDate / ByUnits / WhicheverFirst / WhicheverLast / Manual
- `status`: Draft / Active / Completed / Cancelled / Archived

### ScheduleDefinition
تعریف زمان‌بندی با نسخه‌بندی. حداقل باید mode، زمان محلی، timezone semantics، recurrence rule، generation horizon و version را نگه دارد.

### Occurrence
یک نمونه زمان‌بندی‌شده از Cycle. تاریخ اولیه و تاریخ فعلی باید برای Reschedule قابل تفکیک باشند.

### Actual / Evidence
آنچه واقعاً اتفاق افتاده: تکمیل، حضور، outcome، note، transaction link و در آینده سند/فایل.

## 3. State machine

### Commitment
`Active | Paused | Archived`

### Occurrence
`Scheduled | Due | Completed | Skipped | Cancelled | Rescheduled | Overdue`

قواعد:

- Transition نامعتبر در Domain رد شود.
- Reschedule تاریخ گذشته را پاک نکند؛ history/replacement حفظ شود.
- Completed بودن Occurrence به معنی Completed بودن Commitment نیست.
- Cancelled/Skipped/Completed داده تاریخی هستند.

## 4. Recurrence و تغییر سری

UI و Application باید scope تغییر را صریح کنند:

1. Only this occurrence
2. This and following
3. Entire active cycle، فقط وقتی تاریخچه تخریب نمی‌شود

`This and following` با `ScheduleDefinition` نسخه جدید پیاده‌سازی شود.

Occurrence generation باید:

- bounded horizon داشته باشد،
- idempotent باشد،
- duplicate نسازد،
- past/manual overrides را بازتولید نکند،
- history را پس از تغییر schedule بازنویسی نکند.

## 5. Time semantics

سه نوع زمان باید از هم جدا باشند:

- **Floating Local Time:** کلاس شنبه ساعت ۱۸؛ با DST همچنان ۱۸ محلی.
- **Fixed Instant:** زمان جهانی ثابت؛ نمایش محلی ممکن است عوض شود.
- **All-Day Local Date:** سررسید یک تاریخ بدون مفهوم ساعت.

Edge caseهای اجباری:

- روزهای 29/30/31 ماه و policy ماه کوتاه.
- 29 فوریه.
- DST gap/overlap.
- تغییر timezone.
- تعطیلی.
- تغییر روز/ساعت وسط دوره.
- pause/freeze.
- overlap/conflict.

## 6. Session packages و کلاس‌ها

### اصل اصلی

`Schedule != Entitlement`

Schedule زمان را مشخص می‌کند؛ Entitlement حق استفاده را.

### EntitlementPlan
نمونه فیلدها:

- `totalUnits`
- `unitType`: Session / Hour / Visit / Credit
- `validFrom`
- `plannedExpiry`
- `completionMode`
- `autoExtend`

### EntitlementLedger
Source of Truth مصرف اعتبار:

`Grant | Consume | Restore | Adjustment | Expire | Refund`

Remaining units با fold کردن Ledger محاسبه شود.

### SessionPolicy
حداقل قابلیت مدل‌سازی:

- providerCancellationConsumes
- userCancellationNoticeHours
- lateCancellationConsumes
- noShowConsumes
- freeAbsenceQuota
- holidayConsumes
- makeupRequired
- autoExtendUntilUnitsConsumed
- maxExtensionDate
- partialUnitAllowed

### سناریوهای مرجع

**کلاس زبان ترمی:** FixedRangeRecurring؛ ابتدا و انتهای برنامه‌ریزی‌شده روشن است.

**موسیقی ۴ جلسه‌ای:** FixedCount/Hybrid؛ کنسلی مدرس اعتبار را نمی‌سوزاند؛ Replacement می‌تواند پایان واقعی را جلو ببرد.

**شنا ۱۰ جلسه‌ای با دو غیبت مجاز:** Hybrid + Entitlement Policy؛ دو غیبت اول طبق policy بدون مصرف، جلسات جبرانی در انتها اضافه می‌شوند؛ غیبت بعدی طبق policy ممکن است بسوزد.

**Freeze:** cycle موقتاً pause می‌شود؛ shift future sessions یا extend end date باید policy صریح داشته باشد.

`plannedEndDate` و `actualEndDate` همیشه مفاهیم جدا هستند.

## 7. Reminder Engine

```text
Occurrence
  ├─ ReminderRule
  └─ ReminderInstance
```

- Rule تعریف منطقی است؛ Instance schedule واقعی platform.
- Reschedule باید instanceهای قبلی آینده را cancel/recreate کند.
- completion/cancel/skip notificationهای غیرضروری را حذف کند.
- reboot/restart باید reconcile کند.
- restore باید reminderها را از DB بازسازی کند.

## 8. Today / Calendar / Inbox / Capture

### Today
Home اصلی و پاسخ به `What needs my attention now?`

حداقل grouping:

- Needs Attention
- Today
- Upcoming

Dashboard آماری شلوغ هدف نیست.

### Calendar
Projection از Domain است؛ source of truth نیست. Edit از Calendar همان Domain Commandهای عادی را فراخوانی می‌کند.

### Inbox
فقط برای مواردی که نیاز به تأیید کاربر دارند: suggested match، parsed SMS، suggested commitment/category/tag/pattern.

### Capture
ابتدا Structured Capture پایدار؛ سپس Natural Language.

NLP flow:

`Raw Input → Parser → Draft → Validation → User Confirmation → Domain Command`

Parser مستقیماً Entity نهایی را persist نمی‌کند.

## 9. مالی

### FinancialAccount
حداقل انواع مورد نظر:

- Bank Account
- Cash Wallet
- Digital Wallet
- Credit-style account later

### FinancialTransaction + AccountEntry
Balance از AccountEntryها بازسازی می‌شود.

قواعد:

- Money = integer minor units.
- Transfer bank→wallet = کاهش یک حساب + افزایش حساب دیگر، expense=0 و income=0.
- Opening balance correction بعد از history = Adjustment auditable.
- Refund و reversal باید link/audit داشته باشند.
- Account با history archive می‌شود.
- مدل باید راه multi-currency آینده را نبندد، ولی MVP می‌تواند single-currency باشد.

### TransactionMatch
many-to-many بین Transaction و Occurrence.

باید full / partial / multiple / overpayment / correction را پشتیبانی کند.

## 10. Persistence

Flutter + Drift + SQLite.

الزام‌ها:

- Foreign keys
- Indexes
- Transactional writes
- Explicit migrations
- Stable IDs
- Migration fixtures
- No historical hard-delete

## 11. Backup/Restore

Backup package فقط copy database نیست و metadata/version/checksum دارد.

Restore ابتدا validate، سپس atomic replace؛ در شکست، DB فعلی سالم می‌ماند. پس از restore، reminderها و derived cacheها rebuild می‌شوند.

## 12. Automation

ترتیب ترجیحی:

`Rules → Parsers → Pattern Detection → Heuristics → Local ML → Optional Local AI`

Suggestion باید type، confidence، source و payload داشته باشد و Accept/Edit/Reject را ثبت کند.

Automation در فازهای اولیه حق hidden mutation روی history/finance/matching را ندارد.

## 13. Regression scenarios اجباری

- Monthly bill: plan 500k، actual 498k، difference صحیح.
- Language class: fixed term + holiday + one-occurrence time edit.
- Music: 4 sessions، provider cancellation، no consumption، replacement، actual end extends.
- Swimming: 10 sessions، 2 free absences، third absence follows policy.
- Freeze: history unchanged, future schedule policy-applied.
- DST: weekly 18:00 stays 18:00 local.
- Bank→Wallet transfer: expense=0.
- Wallet expense: balance and expense correct.
- Partial payment: 6M + 4M matches 10M plan.
- Restore: logical state and balances identical; reminders rebuilt.
