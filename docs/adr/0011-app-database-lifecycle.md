# ADR 0011: lifecycle مالکیت AppDatabase

- وضعیت: تصمیم معماری برای فاز بعد؛ بدون تغییر کد در این فاز
- تاریخ: 2026-09-28

## تصمیم

در production، سازندهٔ application باید یک نمونهٔ مالک [`AppDatabase`](lib/core/database/app_database.dart:318) ایجاد کند و همان مالک، طول عمر آن را تا پایان application scope مدیریت کند. repositoryها فقط reference دریافت می‌کنند و مالک database نیستند؛ بنابراین repository نباید database را ببندد.

Startup باید database را پیش از ساخت repositoryها آماده کند و shutdown باید با `await database.close()` انجام شود. هر resourceای که از database استفاده می‌کند باید پیش از close متوقف شود؛ از جمله reminder reconciliation/adapter و subscriptionهای ingestion. `AppDatabase.forTesting` فقط برای test/fixture مجاز است و testها باید ownership و close را صریحاً در teardown داشته باشند.

برای جلوگیری از چند مالک و close زودهنگام، composition root باید lifecycle را در یک application scope/controller واحد نگه دارد. این تصمیم به‌تنهایی رفتار محصول را تغییر نمی‌دهد و فقط قرارداد مالکیت را مشخص می‌کند.

## پیامدها

- cold restart باید با بازکردن مجدد همان فایل SQLite همان state را بازسازی کند.
- migration و restart tests باید بازکردن، استفاده، close و بازکردن مجدد را پوشش دهند.
- هر future backup/restore باید در همین scope انجام شود و هنگام replacement، دسترسی‌های فعال را هماهنگ کند.
