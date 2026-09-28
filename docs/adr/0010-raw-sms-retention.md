# ADR 0010: retention متن خام SMS

- وضعیت: تصمیم امنیتی برای فاز بعد؛ رفتار فعلی بدون تغییر باقی می‌ماند
- تاریخ: 2026-09-28

## تصمیم

متن خام SMS فقط برای staging، توضیح پیشنهاد parser، ممیزی محدود و امکان بازبینی کاربر نگهداری شود. مسیر ingestion باید idempotent و قابل حذف باشد و raw text نباید به log، telemetry یا backup غیررمزشده راه پیدا کند.

Retention پیش‌فرض پیشنهادی برای فاز پیاده‌سازی: تا تعیین تکلیف کاربر در Inbox و برای یک پنجرهٔ محدود پس از آن؛ پس از پذیرش/رد یا پایان پنجره، raw body پاک یا با representation کم‌حساسیت جایگزین شود، درحالی‌که metadata لازم برای تاریخچهٔ تصمیم و `AccountEntry` حفظ می‌شود. مقدار دقیق پنجره باید قبل از اجرا در تنظیمات/UX محصول تصویب و قابل مشاهده باشد و نباید به‌صورت hidden default وارد شود.

تا زمان اجرای این تصمیم، جدول [`StagedImports`](lib/core/database/app_database.dart:264) و متن خام آن منبع دادهٔ فعلی هستند و پاک‌سازی خودکار فعال نیست؛ این موضوع باید در release security gate به‌عنوان limitation باقی بماند.

## پیامدها

- deletion باید audit-safe و transactional باشد و پیشنهادهای وابسته را بدون حذف تاریخچهٔ مالی مدیریت کند.
- backup/restore باید retention state و حذف‌های انجام‌شده را حفظ کند.
- تست لازم: پذیرش، رد، expiry، restart و عدم نشت raw text در log/backup export.
