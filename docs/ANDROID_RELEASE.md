<div dir="rtl" lang="fa">

# ساخت و انتشار <span dir="ltr">Android</span>

## امضا

همهٔ ساخت عمومی باید یک مخزن کلید انتشارِ پایدار داشته باشند. کلید و <span dir="ltr">`android/key.properties`</span> در <span dir="ltr">Git</span> قرار نگیرند و پشتیبان امن آفلاین داشته باشند؛ تغییر/گم‌شدن کلید می‌تواند به‌روزرسانی نصب موجود را ناممکن کند.

رازهای سطح مخزن <span dir="ltr">GitHub Actions</span>:
- <span dir="ltr">`ANDROID_KEYSTORE_BASE64`</span>
- <span dir="ltr">`ANDROID_KEYSTORE_PASSWORD`</span>
- <span dir="ltr">`ANDROID_KEY_ALIAS`</span>
- <span dir="ltr">`ANDROID_KEY_PASSWORD`</span>
- <span dir="ltr">`ANDROID_SIGNING_CERT_SHA256`</span>: اثرانگشت گواهیِ مورد انتظار؛ گواهی متفاوت رد می‌شود.
- <span dir="ltr">`SYMBOLS_ENCRYPTION_PASSPHRASE`</span>: راز قویِ رمزگذاری نمادهای مبهم‌سازی؛ نماد عمومی منتشر نمی‌شود.

راز فقط در محیط انتشار، جای راز سطح مخزن این گردش‌کار را نمی‌گیرد. پیکربندی محلی:

<div dir="ltr">

```properties
storeFile=C:/secure/keys/planact-release.jks
storePassword=...
keyAlias=planact-release
keyPassword=...
```

</div>

مسیر مطلق یا نسبت به <span dir="ltr">`android/`</span> است. مخزن کلید و نام مستعار محلی/انتشار یکسان باشند. <span dir="ltr">Gradle</span> با امضای ناقص شکست می‌خورد و به کلید آزمایشی برنمی‌گردد.

<div dir="ltr">

```sh
keytool -list -v -keystore path/to/planact-release.jks -alias planact-release
```

</div>

## انتشار نسخه

نسخهٔ <span dir="ltr">`X.Y.Z+N`</span> را در <span dir="ltr">`pubspec.yaml`</span> و یادداشت <span dir="ltr">`docs/releases/X.Y.Z.md`</span> ثبت و روی <span dir="ltr">`master`</span> آماده کنید. از <span dir="ltr">`Actions → Release Android → Run workflow`</span> همان شاخه و <span dir="ltr">`X.Y.Z`</span> بدون <span dir="ltr">`v`</span> یا <span dir="ltr">`+N`</span> را انتخاب کنید. برچسب را قبلاً نسازید؛ گردش‌کار برچسب/انتشار موجود را رد و فقط بعد از اعتبارسنجی و امضای <span dir="ltr">APK</span>، <span dir="ltr">`vX.Y.Z`</span> را روی ثبت گیت دقیق می‌سازد. ارسال برچسب به‌تنهایی آغازگر نیست.

هدف جاری <span dir="ltr">`0.2.0+12`</span> و ورودی انتشار <span dir="ltr">`0.2.0`</span> است. [موانع پذیرش](releases/0.2.0.md) مستقل‌اند؛ آماده‌سازی مستند مجوز آغاز دستی نیست. یادداشت خالی، نامزد نامنطبق یا هش کنترلی تغییرکرده رد می‌شود و متن یادداشت با هویت ساخت بدنهٔ انتشار را می‌سازد.

سیاست مصوب <span dir="ltr">۲۰۲۶-۱۰-۱۳</span> برای نگهدارندهٔ فردی، <span dir="ltr">GitHub</span> محیط انتشار، بازبین دوم اجباری یا تأیید استقرار نمی‌خواهد. آغاز دستی پس از بررسی فنی اجازهٔ انتشار خودکار می‌دهد؛ مسئولیت بررسی محصول/دستگاه همچنان با نگهدارنده است.

ساخت از ثبت گیت تغییرناپذیر آغاز دستی انجام می‌شود. نامزد <span dir="ltr">`PlanAct-vX.Y.Z-candidate-RUN_ID`</span> سی روز نگهداری و همان فایل بدون ساخت دوباره منتشر می‌شود. هویت و هش کنترلی کنترل می‌شوند؛ شکست بررسی مانع انتشار است و لغو پس از ایجاد انتشار آن را واگرد نمی‌کند. ثبت گیت تازه اجرای تازه می‌خواهد.

<span dir="ltr">`versionName`</span> باید با نسخهٔ درخواست‌شده/فایل پروژه برابر باشد. ساخت محلی از پسوند پروژه استفاده می‌کند، ولی <span dir="ltr">APK</span> منتشرشده <span dir="ltr">`github.run_number`</span> را <span dir="ltr">`versionCode`</span> می‌گیرد. اجرای دوبارهٔ همان اجرا شماره را زیاد نمی‌کند؛ اجرا تازه زیاد می‌کند. شماره باید از هر <span dir="ltr">APK</span> قبلاً توزیع‌شده بیشتر باشد؛ پسوند محلی اثبات این ترتیب نیست. همهٔ <span dir="ltr">APK</span>های یک اجرا شمارهٔ برابر دارند.

<span dir="ltr">Flutter</span> <span dir="ltr">`3.47.5`</span> و <span dir="ltr">Dart</span> <span dir="ltr">`3.13.4`</span> در گردش‌کارها تثبیت شده‌اند. بررسی مشترک فایل قفل، قالب، تحلیل، تست و <span dir="ltr">App Bundle</span> را می‌سنجد. <span dir="ltr">CI</span> کلید موقت و انتشار کلید تولیدی دارد. <span dir="ltr">R8</span>/کوچک‌سازی منابع و مبهم‌سازی <span dir="ltr">Dart</span> برای <span dir="ltr">APK</span> انتشار فعال‌اند؛ نمادهای جامع/تفکیک‌شده در مسیر جدا رمزگذاری و نود روز به‌عنوان خروجی خصوصی <span dir="ltr">Actions</span> نگهداری می‌شوند.

## فایل‌ها و بررسی

- <span dir="ltr">`PlanAct-vX.Y.Z-universal.apk`</span>: برای اغلب دستگاه‌ها.
- <span dir="ltr">`arm64-v8a`</span>: گوشی <span dir="ltr">ARM</span> جدید؛ <span dir="ltr">`armeabi-v7a`</span>: <span dir="ltr">ARM</span> سی‌ودوبیتی؛ <span dir="ltr">`x86_64`</span>: اغلب شبیه‌ساز.
- <span dir="ltr">`SHA256SUMS.txt`</span>، <span dir="ltr">`SIGNING-CERTIFICATE-SHA256.txt`</span> و <span dir="ltr">`BUILD-IDENTITY.txt`</span>: سلامت، امضا و منشأ ساخت.

<div dir="ltr">

```sh
sha256sum -c SHA256SUMS.txt
adb install path/to/PlanAct-vX.Y.Z-universal.apk
```

</div>

<span dir="ltr">`adb install -r`</span> فقط برای ارتقای همان شناسه و امضاست. خطاها:
- <span dir="ltr">`INSTALL_FAILED_NO_MATCHING_ABIS`</span>: نسخهٔ جامع یا <span dir="ltr">ABI</span> مناسب.
- <span dir="ltr">`INSTALL_FAILED_UPDATE_INCOMPATIBLE`</span>: امضای متفاوت؛ داده را قبل از هر حذف نصب قابل بازیابی کنید.
- <span dir="ltr">`INSTALL_FAILED_VERSION_DOWNGRADE`</span>: شمارهٔ کمتر؛ ساخت جدیدتر لازم است.
- <span dir="ltr">`INSTALL_FAILED_OLDER_SDK`</span>: <span dir="ltr">Android</span> پایین‌تر از حداقل.
- <span dir="ltr">`INSTALL_PARSE_FAILED_*`</span>: فایل خراب/ناخوانا؛ دریافت مجدد و هش کنترلی.

شناسهٔ جاری <span dir="ltr">`com.iarash.planact`</span> نصب <span dir="ltr">`com.example.planact`</span> را ارتقا نمی‌دهد. کلید آزمایشی قدیمی هم هویت انتشار نیست. **نصب حاوی دادهٔ شخصی را صرفاً برای رفع خطای نصب حذف نکنید.** پشتیبان قالب ۱ با ازدست‌رفتن کلید نصب ممکن است بازیابی نشود. انتقال باید پس از تأیید بازیابی در نصب آزمایشی جدا، با فایل و کلید مستقلِ معتبر یا مسیر مهاجرتِ پذیرفته‌شده انجام شود.

خروجی کامل <span dir="ltr">Package Manager</span> را بدون دادهٔ حساس حفظ کنید. گردش‌کار <span dir="ltr">ZIP</span>، <span dir="ltr">alignment</span>، بسته/نسخه، حداقل <span dir="ltr">SDK</span>، <span dir="ltr">ABI</span> و گواهی غیرآزمایشی را بررسی می‌کند. برای رمزگشایی نماد، خروجی همان نسخه و رمز حفظ‌شده و پوشهٔ نماد همان <span dir="ltr">ABI</span> را به <span dir="ltr">`flutter symbolize`</span> بدهید. ساخت و اجرای جدید در این تنقیح مستند انجام نشده است.

</div>
