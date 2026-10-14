# شواهد بررسی ارتباط تراکنش

ثبت ۲۰۲۶-۱۰-۰۷؛ مسیر محلی محدود پیاده است، نه تأیید انتشار بومی.

تصمیم مستقلِ باقی‌مانده از ارتباط مالی، دسته و برچسب جداست. ارتباط جزئی فقط تخصیص را پوشش می‌دهد و باقی‌ماندهٔ معتبر در امروز می‌ماند. مبلغ یا سابقهٔ تخصیص تازه، تأیید مستقل قبلی را بدون حذف نامعتبر می‌کند. توکن فرم و بازخوانی تازهٔ تراکنشی، بازبینی یکتا و جمع تخصیص را حتی خارج فرم کنترل می‌کنند؛ تلاش مجدد بی‌صدا تأیید تازه نیست.

«به تعهدی مربوط نیست»، واگرد و بازگشایی، تصمیم الحاقی‌اند و پول، موجودی، ارتباط، نتیجه یا انتظار را تغییر نمی‌دهند. بازگشت/انصراف بدون تصمیم نمی‌نویسد؛ پس از تصمیم امروز تازه می‌شود. مالی اقدام تعیین ارتباط برای مورد مستقل را حفظ می‌کند؛ انتقال/اصلاح/برگشت تکلیف بررسی نیستند.

مهاجرت ۱۶ → ۱۷ سابقه با FK، قید و حفاظت به‌روزرسانی/حذف افزود و قدیمی را بررسی‌نشده گذاشت. نمونهٔ مهاجرت و تثبیت کامل طرح پایگاه داده، تصویر داده شخصی و اعتبارسنجی ردیف جاری، سابقه را حفظ می‌کنند؛ واردسازی مستقیم همهٔ قالب‌های طرح پایگاه داده قدیمی مجاز نیست. محدودیت تاریخی کلید نصب برای خروجی جدید با [تصمیم ۰۰۱۸](adr/0018-independent-recovery-key-backups.md) جایگزین شده است.

شاهد تاریخی: ۴۰۴ تست کامل، تحلیل بدون ایراد، ۲۲ فایلِ بدون تغییر قالب و اختلاف موفق. تست دامنهٔ اثر انگشت/بازبینی، مخزن فایل سرد/رقابت اتصال جدا/کهنه/برگشت تراکنش/پشتیبان، دادهٔ آزمایشی تاریخی، امروز و مسیر واقعی جزئی/مستقل/بازگشایی/واگرد/انصراف/خطا را پوشش دادند. تفاوت قالب دو تست نامرتبط آن مرحله عمداً اصلاح نشد؛ نتیجهٔ امروز از بررسی جاری خوانده می‌شود.

تکمیل ۲۰۲۶-۱۰-۱۴: نمایش سابقه و اصلاح/قطع ارتباطِ پرداخت فعال با تأیید و پذیرش نویسنده اضافه شد؛ تخصیص تاریخی دیگر در تغییر وضعیت حذف/درج دوباره نمی‌شود. [شواهد واگرد](SCHEDULE_ACTUAL_VERIFICATION.md). بررسی دسته‌ای نیز [دامنهٔ محدود جدا](BULK_REVIEW_VERIFICATION.md) دارد. سیاست اضافه‌پرداخت/ویرایش استرداد، مقصد صرفاً تعهد و مرورگر عمومی سابقه هنوز ادعا نمی‌شوند.

تم مشترک، RTL و متن ۱٫۸برابر در دو تم شاهد ویجت دارند؛ این گواهی دستگاه/صفحه‌خوان/چرخه/مخزن کلید امن نیست. مسئول انتشار باید بومی و بازبینی مستقل و موانع پشتیبان را جدا ثبت کند؛ محاسبهٔ دامنهٔ اضافه‌پرداخت اجازهٔ ذخیرهٔ بیش‌تخصیص نیست.

## مراجع کد و شواهد

- [relationship_review.dart](../lib/features/reconciliation/domain/relationship_review.dart)
- [relationship_review_repository.dart](../lib/features/reconciliation/application/relationship_review_repository.dart)
- [contextual_reconciliation.dart](../lib/features/reconciliation/application/contextual_reconciliation.dart)
- [drift_reconciliation_repository.dart](../lib/features/reconciliation/data/drift_reconciliation_repository.dart)
- [transaction_relationship_page.dart](../lib/features/reconciliation/presentation/transaction_relationship_page.dart)
- [attention_engine.dart](../lib/features/today/application/attention_engine.dart)
- [planact_app.dart](../lib/app/planact_app.dart)
- [finance_page.dart](../lib/features/finance/presentation/finance_page.dart)
- [app_database.dart](../lib/core/database/app_database.dart)
- [sqlite_backup_storage.dart](../lib/features/backup/data/sqlite_backup_storage.dart)
- [backup_full_state_test.dart](../test/repository/backup_full_state_test.dart)
- [relationship_review_test.dart](../test/repository/relationship_review_test.dart)
- [relationship_review_test.dart](../test/unit/relationship_review_test.dart)
- [relationship_schema_fixture_test.dart](../test/repository/relationship_schema_fixture_test.dart)
- [sqlite_backup_schema_compatibility_test.dart](../test/repository/sqlite_backup_schema_compatibility_test.dart)
- [attention_engine_test.dart](../test/unit/attention_engine_test.dart)
- [contextual_reconciliation_test.dart](../test/widget/contextual_reconciliation_test.dart)
- [occurrence_test.dart](../test/unit/occurrence_test.dart)
- [series_editing_test.dart](../test/unit/series_editing_test.dart)
