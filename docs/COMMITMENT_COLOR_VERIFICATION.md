<div dir="rtl" lang="fa">

# رنگ هویت پایدار تعهد

رنگ، فراداده اختیاری کاربر است، نه وضعیت/فوریت/پول/نتیجه. هشت کلید ثابت <span dir="ltr">`teal, blue, indigo, violet, rose, amber, olive, cyan`</span> به نام ذخیره می‌شوند؛ شمارهٔ ذخیره‌شدهٔ نوع شمارشی یا عدد رنگ هویت ذخیره نیست و نام منتشرشده عوض نمی‌شود.

<span dir="ltr">`null`</span> یعنی خودکار و در ذخیره <span dir="ltr">`null`</span> می‌ماند؛ پالت از شناسهٔ پایدار با محاسبه سی‌ودوبیتیِ <span dir="ltr">FNV-1a</span> یک کلید انتخاب می‌کند. رنگ می‌تواند مشترک باشد و شناسهٔ یکتا نیست؛ متن/نشانهٔ دیگر حفظ شود. جفت پیش‌زمینه/پس‌زمینه با حالت روشنایی حل می‌شود، نه جایگزینی رنگ وضعیت.

<span dir="ltr">`Commitment.withColor`</span>، فرمان ساخت/طرح، پیش‌نویس و ویرایش فراداده رنگ را حفظ می‌کنند؛ <span dir="ltr">`updateColor=true`</span> با <span dir="ltr">`null`</span> بازگشت صریح به خودکار است و ذکرنشدن رنگ تازهٔ پایدار را تغییر نمی‌دهد. انتخابگر مشترک با گزینهٔ خودکار، فارسی و غیرفعال هنگام ذخیره در ساخت/جزئیات است. فرم ساخت اکنون یک‌صفحه‌ای است؛ «<span dir="ltr">wizard</span>» نام تاریخیِ مصرف‌کننده بود.

مهاجرت طرحوارهٔ پایگاه داده ۱۸ ستون تهی‌پذیر <span dir="ltr">`color_key`</span> با <span dir="ltr">CHECK</span> کلیدها را افزود؛ قدیمی <span dir="ltr">`null`</span> ماند. پشتیبان ساختار تازه یا اثر انگشت کاملِ مهاجرت واقعی را با اعتبارسنجی ردیف در طرحوارهٔ پایگاه داده جدا می‌پذیرد؛ قید مخلوط/دست‌کاری پذیرفته نیست. دادهٔ آزمایشی موسوم <span dir="ltr">`fresh-v17.json`</span> از <span dir="ltr">DDL</span> ثبت‌شدهٔ <span dir="ltr">`fb69495-v17.json`</span> بازسازی و درواقع مسیر مهاجرت‌شده است، نه تولید مستقل <span dir="ltr">DDL</span> تازه. تصویر داده و برگشت تراکنش رنگ صریح/خودکار را با دادهٔ کامل حفظ می‌کنند.

شاهد تاریخی: ۴۱۰ تست با هم‌زمانی=2 پس از توقف غیرعادی <span dir="ltr">VM</span> اجرای پرتراکم، تحلیل بدون ایراد و تولید <span dir="ltr">Drift</span>/قالب موفق. کپی چرخه/فراداده/برچسب، بازنشانی صریح، مسیر جایگزین، هشت جفت کنتراست حداقل ۴٫۵:۱، فایل سرد، کلید نامعتبر، انتخابگر حالت‌های روشن و تیره، تلاش مجدد ساخت، ویرایش جزئیات بدون زنده‌شدن برچسب حذف‌شده و پشتیبان پوشش دارند.

مصرف پالت در ماه/هفته و نشان امروز بعداً اضافه شده و دیگر «کار والدِ انجام‌نشده» نیست؛ [سیستم طراحی](DESIGN_SYSTEM.md) و [شواهد هفته](WEEK_TIMELINE_VERIFICATION.md) مرجع‌اند. کلید مستقل قالب ۲ جای محدودیت تاریخی نصب را گرفته؛ پذیرش بومیِ پشتیبان و بازبینی دیداری همچنان باز است.

## مراجع کد و شواهد

- [<span dir="ltr">commitment_color.dart</span>](../lib/features/commitments/domain/commitment_color.dart)
- [<span dir="ltr">commitment.dart</span>](../lib/features/commitments/domain/commitment.dart)
- [<span dir="ltr">commitment_use_cases.dart</span>](../lib/features/commitments/application/commitment_use_cases.dart)
- [<span dir="ltr">commitment_plan_use_case.dart</span>](../lib/features/commitments/application/commitment_plan_use_case.dart)
- [<span dir="ltr">commitment_draft.dart</span>](../lib/features/commitments/application/commitment_draft.dart)
- [<span dir="ltr">commitment_identity_palette.dart</span>](../lib/app/theme/commitment_identity_palette.dart)
- [<span dir="ltr">commitment_color_picker.dart</span>](../lib/features/commitments/presentation/commitment_color_picker.dart)

</div>
