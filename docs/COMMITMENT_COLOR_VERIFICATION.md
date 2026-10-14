# رنگ هویت پایدار تعهد

رنگ، فراداده اختیاری کاربر است، نه وضعیت/فوریت/پول/نتیجه. هشت کلید ثابت `teal, blue, indigo, violet, rose, amber, olive, cyan` به نام ذخیره می‌شوند؛ شاخص شمارش نوع‌دار یا عدد رنگ هویت ذخیره نیست و نام منتشرشده عوض نمی‌شود.

`null` یعنی خودکار و در ذخیره `null` می‌ماند؛ پالت از شناسهٔ پایدار با محاسبه سی‌ودوبیتیِ FNV-1a یک کلید انتخاب می‌کند. رنگ می‌تواند مشترک باشد و شناسهٔ یکتا نیست؛ متن/نشانهٔ دیگر حفظ شود. جفت پیش‌زمینه/پس‌زمینه با حالت روشنایی حل می‌شود، نه جایگزینی رنگ وضعیت.

`Commitment.withColor`، فرمان ساخت/طرح، پیش‌نویس و ویرایش فراداده رنگ را حفظ می‌کنند؛ `updateColor=true` با `null` بازگشت صریح به خودکار است و ذکرنشدن رنگ تازهٔ پایدار را تغییر نمی‌دهد. انتخابگر مشترک با گزینهٔ خودکار، فارسی و غیرفعال هنگام ذخیره در ساخت/جزئیات است. فرم ساخت اکنون یک‌صفحه‌ای است؛ «wizard» نام تاریخیِ مصرف‌کننده بود.

مهاجرت طرح پایگاه داده ۱۸ ستون تهی‌پذیر `color_key` با CHECK کلیدها را افزود؛ قدیمی `null` ماند. پشتیبان ساختار تازه یا اثر انگشت کاملِ مهاجرت واقعی را با اعتبارسنجی ردیف در طرح پایگاه داده جدا می‌پذیرد؛ قید مخلوط/دست‌کاری پذیرفته نیست. دادهٔ آزمایشی موسوم `fresh-v17.json` از DDL ثبت‌شدهٔ `fb69495-v17.json` بازسازی و درواقع مسیر مهاجرت‌شده است، نه تولید مستقل DDL تازه. تصویر داده و برگشت تراکنش رنگ صریح/خودکار را با دادهٔ کامل حفظ می‌کنند.

شاهد تاریخی: ۴۱۰ تست با هم‌زمانی=2 پس از توقف غیرعادی VM اجرای پرتراکم، تحلیل بدون ایراد و تولید Drift/قالب موفق. کپی چرخه/فراداده/برچسب، بازنشانی صریح، مسیر جایگزین، هشت جفت کنتراست حداقل ۴٫۵:۱، فایل سرد، کلید نامعتبر، انتخابگر دو تم، تلاش مجدد ساخت، ویرایش جزئیات بدون زنده‌شدن برچسب حذف‌شده و پشتیبان پوشش دارند.

مصرف پالت در ماه/هفته و نشان امروز بعداً اضافه شده و دیگر «کار والدِ انجام‌نشده» نیست؛ [سیستم طراحی](DESIGN_SYSTEM.md) و [شواهد هفته](WEEK_TIMELINE_VERIFICATION.md) مرجع‌اند. کلید مستقل قالب ۲ جای محدودیت تاریخی نصب را گرفته؛ پذیرش بومیِ پشتیبان و بازبینی دیداری همچنان باز است.

## مراجع کد و شواهد

- [commitment_color.dart](../lib/features/commitments/domain/commitment_color.dart)
- [commitment.dart](../lib/features/commitments/domain/commitment.dart)
- [commitment_use_cases.dart](../lib/features/commitments/application/commitment_use_cases.dart)
- [commitment_plan_use_case.dart](../lib/features/commitments/application/commitment_plan_use_case.dart)
- [commitment_draft.dart](../lib/features/commitments/application/commitment_draft.dart)
- [commitment_identity_palette.dart](../lib/app/theme/commitment_identity_palette.dart)
- [commitment_color_picker.dart](../lib/features/commitments/presentation/commitment_color_picker.dart)
