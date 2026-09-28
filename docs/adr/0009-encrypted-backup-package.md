# ADR 0009: مدل backup رمزنگاری‌شده

- وضعیت: پذیرفته و پیاده‌سازی‌شده در فاز امنیت backup
- تاریخ: 2026-09-28

## تصمیم

قالب backup در فاز بعد باید یک envelope رمزنگاری‌شده و versioned باشد، نه payload خام با checksum به‌عنوان تنها کنترل. envelope حداقل شامل `schemaVersion`، `appVersion`، زمان ایجاد، الگوریتم/نسخهٔ رمزنگاری، شناسهٔ کلید یا KDF metadata، nonce/IV، ciphertext، authentication tag، checksum یا digest مربوط به دادهٔ رمزگشایی‌شده، و manifest پیوست‌ها خواهد بود.

کلیدها باید از secure platform storage یا مسیر امن معادل آن به‌دست آیند و در backup ذخیره نشوند. رمزنگاری authenticated باید قبل از اعتبارسنجی محتوای restore انجام شود. checksum جایگزین احراز اصالت نیست و فقط برای تشخیص خطای انتقال/سازگاری تکمیلی حفظ می‌شود.

Restore باید ابتدا package را در محل موقت validate/decrypt کند، سازگاری schema و integrity را بررسی کند، قبل از جایگزینی snapshot ایمنی بسازد، سپس جایگزینی اتمیک و rebuild cache/reminder را انجام دهد. شکست در هر مرحله نباید database جاری را از بین ببرد.

## پیامدها

- abstractionهای domain برای encryption و key storage تعریف شده‌اند؛ adapterها خارج از domain تزریق می‌شوند.
- الگوریتم این فاز AES-256-GCM با nonce دوازده‌بایتی و tag شانزده‌بایتی است؛ کلید در package ذخیره نمی‌شود.
- فقط format version 1 و schema دقیقاً جاری پذیرفته می‌شود؛ backupهای قدیمی بدون migration مستند عمداً رد می‌شوند.
- کلید گمشده یا metadata نامعتبر باید restore را متوقف کند، نه اینکه به payload خام fallback شود.
