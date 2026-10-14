# بسته‌های مستقل تعطیلات

این پوشه مقصد فایل‌های آمادهٔ تحویل است. دادهٔ نهایی بررسی‌شده در [فایل‌های سالانه](../third_party/iranian_holidays/reviewed/) قرار دارد؛ همان فایل‌ها مبنای دادهٔ همراه برنامه و ورودی امضای بسته‌اند.

برای نمونهٔ۱۴۰۶، با کلید خصوصی موجود ناشر در مسیری محافظت‌شده خارج مخزن:

```sh
dart run tool/holiday_package.dart validate third_party/iranian_holidays/reviewed/iran-1406-r1.json
dart run tool/holiday_package.dart sign PRIVATE_SEED third_party/iranian_holidays/reviewed/iran-1406-r1.json holiday-packages/iran-1406-r1.planact-holidays.json
dart run tool/holiday_package.dart verify holiday-packages/iran-1406-r1.planact-holidays.json
```

هر سال با همان ناشر امضا می‌شود. فایل payload خوانا مستقیماً واردشدنی نیست؛ فایل خروجی امضاشده از «بیشتر ← دادهٔ تعطیلات ← ورود بسته از فایل» وارد می‌شود. ناشر اول با اثرانگشت از کانال مستقل معتبر تأیید می‌شود. کلید خصوصی را اینجا نگذارید؛ بستهٔ اصلی خارج پشتیبان شخصی است و باید جدا نگهداری شود.

در این اصلاح فایل امضاشده با کلید ناشر واقعی تولید/منتشر نشده است. آزمون‌های مخزن فقط از امضاکنندهٔ مصنوعی و دادهٔ سال آیندهٔ مصنوعی استفاده می‌کنند؛ آن‌ها فایل قابل انتشار نیستند. برای سال‌های پس از۱۴۰۶ ابتدا بررسی واقعی منبع لازم است. [روش آماده‌سازی و بازبینی](../third_party/iranian_holidays/README.md) و [وضعیت پذیرش](../docs/IRANIAN_HOLIDAYS_VERIFICATION.md) را ببینید.
