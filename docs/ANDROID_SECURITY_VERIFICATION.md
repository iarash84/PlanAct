<div dir="rtl" lang="fa">

# بررسی امنیت <span dir="ltr">Android</span> و انتشار

## سیاست جاری

- <span dir="ltr">`android:allowBackup="false"`</span> و قواعد استخراج، انتقال ابری/دستگاهی سیستم‌عامل را محدود می‌کنند؛ پشتیبان خود برنامه مسیر جداست.
- <span dir="ltr">`usesCleartextTraffic="false"`</span> و <span dir="ltr">`network_security_config.xml`</span> ترافیک رمزنگاری‌نشدهٔ <span dir="ltr">HTTP</span> را رد می‌کنند؛ آداپتور شبکهٔ آینده <span dir="ltr">TLS</span> می‌خواهد و هسته محلی است.
- <span dir="ltr">`MainActivity`</span> برای راه‌انداز صادرشده است. گیرندهٔ عمومی پیامک با <span dir="ltr">`BROADCAST_SMS`</span> محافظت می‌شود؛ گیرندهٔ اعلان/راه‌اندازی دستگاه خصوصی است. گیرندهٔ وابستگی باید خصوصی یا با دسترسی سیستمی/امضایی محافظت شود؛ <span dir="ltr">Profile Installer</span> از <span dir="ltr">`DUMP`</span> استفاده می‌کند.
- <span dir="ltr">`READ_SMS/RECEIVE_SMS`</span> فقط برای مسیر اختیاری پیامک‌اند؛ ردشان برنامه‌ریزی، مالی یا پشتیبان را مسدود نمی‌کند. رضایت بازه و اقدام واردسازی جدا لازم است؛ دریافت <span dir="ltr">broadcast</span> به‌تنهایی اسکن یا ثبت مالی نیست.
- <span dir="ltr">`POST_NOTIFICATIONS`</span> و <span dir="ltr">`SCHEDULE_EXACT_ALARM`</span> برای تحویل یادآورند؛ رد/لغو باید درخواست ذخیره‌شده را حفظ و محدودیت را نمایان کند.
- <span dir="ltr">`RECEIVE_BOOT_COMPLETED`</span> برای بازسازی اعلان است؛ وجود <span dir="ltr">receiver</span>، تحویل پس از راه‌اندازی دوبارهٔ دستگاه را ثابت نمی‌کند. <span dir="ltr">`VIBRATE`</span> وابستگی اعلان مورد انتظار است.

## بررسی محلی

با <span dir="ltr">SDK</span> و مخزن کلید معتبر از ریشه:

<div dir="ltr">

```powershell
flutter analyze
flutter test
flutter build apk --release
cd android
.\gradlew.bat :app:processReleaseMainManifest :app:mergeReleaseResources :app:assembleRelease
cd ..
```

</div>

فهرست پیکربندی ادغام‌شدهٔ انتشار را در <span dir="ltr">`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`</span> بررسی کنید: عدم پشتیبان سیستمی، منع ارتباط بدون رمزنگاری، قواعد استخراج، محدودبودن دسترسی بیرونی به اجزای برنامه و دسترسی گیرندهٔ پیامک. مجوز غیرمنتظرهٔ ادغام‌شده پذیرفته نشود. <span dir="ltr">APK</span> با <span dir="ltr">`aapt dump permissions`</span>، <span dir="ltr">`aapt dump xmltree`</span> و <span dir="ltr">`apksigner verify --verbose --print-certs`</span> بررسی شود؛ آزمایشی مسیر جایگزین مجاز نیست. [راهنمای انتشار](ANDROID_RELEASE.md)

## ماتریس دستگاه؛ هنوز لازم

روی <span dir="ltr">Android</span> 13+ و یک نسخهٔ قبل از ۱۳، هویت ساخت/نسخه، <span dir="ltr">API</span> و وضعیت مجوز را ثبت کنید:
1. رد/اعطای پیامک، بدون لاگ متن یا خواندن تاریخچهٔ فاقد رضایت.
2. رد/اعطای اعلان، بدون فقدان درخواست ذخیره‌شده یا توقف غیرعادی.
3. لغو هشدار دقیق، با پیام محدودیت و حفظ داده.
4. راه‌اندازی دوبارهٔ دستگاه، با اعلان فعال آینده و بدون اعلان حل‌شده/بایگانی.
5. پیامک ساختگی، با مرز منبع امن و تأیید صریح؛ مجوز به‌تنهایی ثبت یا اسکن نمی‌کند.
6. رد <span dir="ltr">HTTP</span> روشن از محیط آزمون صرفاً آزمایشی و نبود استثنا در انتشار.

در گزارش، متن پیامک، فرستنده، شناسه، مبلغ حساس یا محتوای پشتیبان قرار نگیرد. این فهرست دستور بررسی است، نه نتیجهٔ اجرای دستگاه یا گواهی امنیت.

</div>
