# برنامه پیاده‌سازی مرحله‌ای برای Vibe Coding

این فایل مشخص می‌کند پروژه با چه ترتیب و granularity اجرا شود. هر Task یک Prompt مستقل در پوشه `prompts/` دارد.

## روش استفاده

1. قبل از شروع، `AGENTS.md` و `docs/ARCHITECTURE_AND_DOMAIN_RULES.md` را در context ابزار کدنویسی قرار بده.
2. Promptها را به ترتیب اجرا کن؛ چند Task را با هم merge نکن مگر عمداً تصمیم گرفته باشی.
3. بعد از هر Task، تست‌ها و گزارش خروجی Agent را بررسی کن و commit جداگانه بزن.
4. تا Definition of Done یک Task پاس نشده، Prompt بعدی را اجرا نکن.
5. هر تغییر معماری پایدار یا dependency جدید را با ADR کوتاه ثبت کن.

## Milestone M0 — Foundation & Engineering Baseline

هدف: ساخت baseline قابل تست، بدون Feature محصول.

- `P00` — Repository audit / bootstrap و ساخت skeleton معماری.
- `P01` — Drift/SQLite baseline، database lifecycle و migration framework.
- `P02` — Core types: stable IDs، clock/time abstractions، money primitives و error model.
- `P03` — Test harness، logging/privacy baseline و dependency/ADR rules.

Gate: پروژه build/test/analyze می‌شود و یک persistence smoke test دارد.

## Milestone M1 — Commitment Core

هدف: مدل پایه Commitment و Cycle بدون scheduling پیچیده.

- `P04` — Commitment entity + lifecycle state machine.
- `P05` — CommitmentCycle entity + completion semantics.
- `P06` — Repositories/use cases برای create/update/pause/archive + transactional boundaries.
- `P07` — Drift persistence + migration + repository tests برای M1.

Gate: Commitment و Cycle تاریخچه‌پذیر و مستقل از UI ذخیره/بازیابی می‌شوند.

## Milestone M2 — Scheduling & Occurrence Engine

هدف: deterministic recurrence و versioned occurrence generation.

- `P08` — ScheduleDefinition و time semantics.
- `P09` — Occurrence model + bounded/idempotent generation engine.
- `P10` — Series editing: only-this / this-and-following / active-cycle.
- `P11` — Calendar edge policies: month-end، leap year، DST، timezone، pause/conflict.

Gate: future occurrences deterministic هستند و تغییر schedule گذشته را بازنویسی نمی‌کند.

## Milestone M3 — Session Packages & Exception Policies

هدف: مدل عمومی برای کلاس ترمی و بسته‌های جلسه‌ای.

- `P12` — EntitlementPlan + EntitlementLedger و fold logic.
- `P13` — SessionPolicy + attendance/outcome resolution.
- `P14` — Replacement/reschedule/makeup chain + plannedEnd/actualEnd.
- `P15` — Regression scenarios: language/music/swimming/freeze.

Gate: هیچ special-case مربوط به موسیقی/شنا در UI نوشته نشده و remaining units کاملاً از ledger بازسازی می‌شود.

## Milestone M4 — Reminder Engine

- `P16` — ReminderRule/ReminderInstance domain + platform adapter contract.
- `P17` — Schedule/cancel/snooze/reconcile window behavior.
- `P18` — Integration tests برای offline/restart/reschedule/timezone/duplicate prevention.

Gate: reminder orphan/duplicate در سناریوهای تست وجود ندارد.

## Milestone M5 — Today, Calendar & Structured Capture

- `P19` — Today queries و prioritization.
- `P20` — Calendar projection و edit routing through domain commands.
- `P21` — Structured Quick Capture.
- `P22` — Occurrence/commitment details، series edit UI و basic search.

Gate: کاربر می‌تواند بدون دیدن پیچیدگی Domain یک تعهد بسازد، زمان‌بندی کند، reminder بگیرد و resolve کند.

## Milestone M6 — Actual, Evidence & History

- `P23` — Actual/Evidence model + recording use cases.
- `P24` — History/audit projection + non-financial planned-vs-actual.

Gate: هر occurrence resolved نتیجه قابل توضیح و history پایدار دارد.

## Milestone M7 — Security, Backup/Restore & Release Hardening

- `P25` — Backup package + validation + atomic restore + reminder rebuild hook.
- `P26` — Migration fixtures، secure storage/privacy hardening، failure recovery.

Gate: Core Beta می‌تواند داده واقعی کاربر را با ریسک معقول نگه دارد.

## Milestone M8 — Finance Ledger

- `P27` — FinancialAccount + AccountEntry + rebuildable balance.
- `P28` — Expense/Income/Transfer/Adjustment/Refund/Reversal rules.
- `P29` — Bank/wallet UI/query layer + archive/opening-balance flows.

Gate: bank→wallet transfer در expense/income دوباره‌شماری نمی‌شود و balance قابل rebuild است.

## Milestone M9 — Financial Reconciliation

- `P30` — TransactionMatch many-to-many + allocation rules.
- `P31` — Financial planned-vs-actual + manual matching UI/history.

Gate: partial/full/over/corrected matching قابل توضیح و تست‌شده است.

## Milestone M10 — Inbox, Import & SMS Parsing

- `P32` — Source adapters + import staging + provenance/rollback.
- `P33` — Local SMS parsing + duplicate detection + draft transaction generation.
- `P34` — Suggestion/Inbox model + Confirm/Edit/Reject.

Gate: هیچ raw source مستقیماً ledger نهایی را mutate نمی‌کند.

## Milestone M11 — Local Automation & Pattern Detection

- `P35` — Merchant normalization + recurring/subscription pattern detection.
- `P36` — Smart match scoring + categorization suggestions + confidence policy.

Gate: automation explainable است و false positive به شکل مخفیانه داده را تغییر نمی‌دهد.

## Milestone M12 — Predictive / Optional Local AI

- `P37` — Forecast/risk/anomaly interfaces + deterministic baseline.
- `P38` — Optional on-device AI adapter + evaluation/privacy/offline fallback.

Gate: خاموش‌کردن AI هیچ Core flow را نمی‌شکند.

## Commit strategy پیشنهادی

برای vibe coding بهتر است هر Prompt تقریباً یک commit مستقل باشد:

```text
feat(m1): add commitment lifecycle model
feat(m2): add idempotent occurrence generation
feat(m3): add entitlement ledger
fix(m3): preserve entitlement on provider cancellation
...
```

اگر Task نیاز به migration دارد، migration و test آن در همان commit باشد.

## قانون توقف

اگر Agent در یک Task مجبور شد یکی از موارد زیر را بدون تصمیم قبلی انتخاب کند، بهتر است به‌جای گسترش scope یک ADR کوچک بسازد یا interface ایجاد کند:

- state management package
- ID library (UUIDv7 vs ULID)
- DB encryption library
- recurrence third-party package
- notification package
- backup encryption format
- multi-currency behavior

هدف این است که Prompt کوچک، قابل review و قابل rollback بماند.
