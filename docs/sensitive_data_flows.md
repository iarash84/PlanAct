# مسیر دادهٔ حساس: SMS، staging و backup

این سند وضعیت فعلی و مرزهای امنیتی مورد نیاز برای فازهای بعد را ثبت می‌کند. این تغییر مستندسازی است و کد production را تغییر نمی‌دهد.

## مسیر SMS بانکی

```text
Android SMS broadcast
  → BankSmsReceiver
  → SmsBridge.publish (in-memory EventChannel)
  → AndroidSmsSource
  → inbox ingestion/parser
  → StagedImports.rawText + fingerprint/source metadata
  → InboxSuggestions
  → تأیید یا رد صریح کاربر
  → در پذیرش: AccountEntry / تاریخچهٔ مالی
```

- [`BankSmsReceiver`](android/app/src/main/kotlin/com/example/planact/BankSmsReceiver.kt:9) متن body و originating address را از broadcast می‌خواند و با `sourceKey` به [`SmsBridge.publish()`](android/app/src/main/kotlin/com/example/planact/SmsBridge.kt:19) می‌دهد.
- [`SmsBridge`](android/app/src/main/kotlin/com/example/planact/SmsBridge.kt:13) داده را از طریق EventChannel به Flutter می‌رساند و در صورت نبود permission آن را منتشر نمی‌کند.
- خواندن inbox از مسیر `readRelevant` حداکثر ۵۰۰ پیام را به Flutter برمی‌گرداند؛ body در این مرحله هنوز raw و حساس است.
- staging در جدول [`StagedImports`](lib/core/database/app_database.dart:264) قرار دارد. [`InboxSuggestions`](lib/core/database/app_database.dart:278) نتیجهٔ parser است و نباید منبع مستقیم mutation حساب مالی باشد.
- طبق قرارداد محصول، فقط پذیرش کاربر می‌تواند به `AccountEntry` برسد؛ reject نباید ledger را تغییر دهد.
- در وضعیت فعلی، raw text در staging retention نامحدود دارد و پاک‌سازی خودکار ندارد؛ این limitation در [`ADR 0010`](docs/adr/0010-raw-sms-retention.md) ثبت شده است.

## مسیر backup

```text
SQLite/domain state
  → backup payload serialization
  → BackupPackage envelope
  → validation/checksum فعلی
  → storage
  → restore validation
  → safety snapshot
  → replacement
  → rebuild derived state/reminders
```

- [`BackupPackage`](lib/features/backup/domain/backup_package.dart:7) در وضعیت فعلی payload را base64 و checksum را SHA-256 نگه می‌دارد؛ `encryptionMetadata` صرفاً metadata است و به‌تنهایی رمزنگاری ایجاد نمی‌کند.
- [`BackupService`](lib/features/backup/application/backup_service.dart:15) پیش از restore اعتبارسنجی می‌کند، safety snapshot می‌سازد، state را جایگزین و سپس rebuild می‌کند؛ در شکست rebuild به state قبلی برمی‌گردد.
- تا اجرای ADR 0009، backup را encrypted-at-rest فرض نکنید و raw SMS را بدون مسیر رمزنگاری authenticated صادر نکنید.
- platform notification IDها دادهٔ قابل حمل backup نیستند و باید پس از restore بازسازی شوند.

## نقاط کنترل اجباری فازهای بعد

1. raw SMS در log، crash report، telemetry و backup غیررمزشده ظاهر نشود.
2. staging و retention با migration، restart و deletion tests پوشش داده شوند.
3. backup قبل از جایگزینی decrypt/validate موقت، authenticated و schema-compatible باشد.
4. lifecycle database یک مالک composition-root داشته باشد و close آن با توقف adapterها هماهنگ شود.
5. permission denial/revocation graceful باشد و prompt فقط در capability موردنظر نمایش داده شود.


## Account identifiers — current implementation, 2026-10-12

Explicit user input → field validation/shared digit normalization → application command → account row and versioned per-account SQLite metadata → informational Finance card/edit form. Bank is selected, never inferred. Card number, Iranian IBAN and account number are optional strings with leading zeros preserved; no PIN, CVV or password storage is provided. These identifiers are personal financial data, not authentication credentials.

Cards and form fields mask identifiers by default; explicit reveal/hide is available and leaving foreground remasks them. Masking does not encrypt the SQLite database, remove identifiers from widget controllers, prevent OS screenshots/recents or establish native screen-reader privacy. Identifiers remain on-device in SQLite and are preserved in personal backup payloads; production exports use the existing encrypted backup envelope and independent recovery-key safeguards. Do not describe the database itself as encrypted or the feature as device-loss verified.

Clipboard copy requires a separate Persian warning and confirmation; cancellation writes nothing and copy errors are visible. Canonical unmasked text is handed to the OS clipboard only after confirmation. Other applications, clipboard history, keyboards or device clipboard sync may access it; PlanAct cannot guarantee removal or prevent propagation and does not automatically clear the clipboard. No identifier telemetry/logging is added. Account creation/edit retry retains draft data until the form closes; edits do not alter ledger/history. Native clipboard/IME/background/accessibility checks and independent review remain release blockers, owned by the maintainer/release reviewer; see [ACCOUNT verification](ACCOUNT_BRAND_VERIFICATION.md).
