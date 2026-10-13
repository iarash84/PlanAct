# PlanAct development workflow

این سند مسیر استاندارد توسعه، بررسی و انتشار PlanAct را توضیح می‌دهد.

## شاخه‌ها و Pull Request

- تغییرات را از `master` به شاخه‌ای با پیشوند `feature/`, `fix/`, `refactor/` یا `chore/` منتقل کنید.
- پیش از باز کردن Pull Request، شاخه را با آخرین `master` همگام کنید.
- Pull Request باید به `master` باز شود و توضیح هدف، ریسک و تست‌های انجام‌شده را داشته باشد.
- ادغام به‌صورت **Squash merge** انجام می‌شود تا هر تغییر محصول یک commit روشن در `master` داشته باشد.
- مستقیماً روی `master` توسعه ندهید.

## قرارداد پذیرش و تحویل محدود

[PRD](product/PRD.md) رفتار و تعریف آمادگی قابلیت را مشخص می‌کند و [AGENTS](../AGENTS.md) الزامات پیاده‌سازی و شواهد را. برای تغییر معنادار، پیش از پیاده‌سازی یک قرارداد کوتاه در task/PR یا سند verification موجود ثبت کنید؛ همان رکورد را به‌روز کنید، نه اینکه برای هر مرحله سند موازی بسازید:

- **نتیجه و دامنه:** کاربر از کدام مسیر واقعی وارد می‌شود، چه پیش‌نیازهایی دارد و چه چیزی صریحاً خارج از scope است؟
- **معیار قابل مشاهده:** موفقیت، خطا، لغو، retry و اصلاح/Undo در صورت کاربرد چگونه دیده می‌شوند؟
- **آثار:** چه داده‌ای باید پایدار بماند و restart، migration، backup/restore یا پلتفرم چه اثری دارند؟ کدام صفحه‌ها و مصرف‌کنندگان باید تازه شوند؟
- **شاهد لازم:** برای هر ادعا چه تست، بازگشایی پایگاه داده، مسیر رابط یا بررسی دستگاه لازم است؟

مسیر **اقدام کاربر → فرمان برنامه → قانون دامنه → ذخیرهٔ پایدار → تازه‌شدن رابط → مصرف‌کنندگان مرتبط** را ردیابی کنید. کوچک‌ترین مسیر کامل در scope مصوب را تحویل دهید؛ task صرفاً زیرساختی مجاز است، اما نتیجهٔ آن foundation است نه قابلیت آمادهٔ کاربر. تصمیم محصول یا پیش‌نیاز نامشخص را خودسرانه اختراع نکنید؛ توقف یا وضعیت partial را روشن گزارش کنید.

برای تغییر صرفاً مستندات/غلط‌گیری، بررسی diff، لینک‌ها و سازگاری کافی است؛ برای refactor بدون تغییر رفتار، شواهد regression مرتبط لازم است. این تناسب هیچ gate امنیت، داده یا پلتفرم موجود را حذف نمی‌کند.

## بررسی مستقل و رکورد شواهد

پیش از merge، reviewer باید قراردادِ دامنهٔ همان تغییر، شواهد و تصمیم exposure را بررسی کند. ادغام task زیرساختی یا checkpoint ناقص فقط با برچسب foundation/partial، ثبت بررسی‌های باقی‌مانده و بدون ادعای آماده‌بودن قابلیت مجاز است؛ الزامات ایمنی و صحت همان تغییر همچنان باید پاس شوند. پذیرش PR مجوز انتشار نیست: maintainer باید بعداً کل دامنهٔ قابل دسترس در build انتشار و gateهای مشترک را جداگانه بپذیرد.

پذیرش را از پیاده‌سازی جدا کنید. reviewer انسانی یا عامل جدا از عامل پیاده‌ساز باید قرارداد را با شواهد و counterexampleهای محتمل مقایسه کند، نه اینکه فقط گزارش پایان کار را تکرار کند. self-review مفید است اما بررسی مستقل نیست؛ خروجی عامل reviewer نیز به‌تنهایی مجوز انتشار محسوب نمی‌شود و تصمیم انتشار با maintainer مسئول است.

در PR یا سند verification موجود این رکورد مختصر را نگه دارید:

| معیار/دامنه | شاهد و محیط | نتیجه | کمبود و تصمیم |
| --- | --- | --- | --- |
| نتیجهٔ مورد انتظار از قرارداد | دستور/تست یا مراحل مشاهده، commit/build، تاریخ و در صورت کاربرد دستگاه/OS/حجم داده | Passed / Failed / Not run؛ لینک شاهد | مالک، اقدام بعدی و تصمیم exposure/release برای کمبود مهم |

شواهد قدیمی را حذف نکنید؛ مشخص کنید کدام شاهد برای تغییر و build فعلی معتبر است. گزارش نهایی **دامنهٔ پیاده‌شده، وضعیت راستی‌آزمایی، بررسی‌های اجرا‌نشده و موانع انتشار** را جدا کند. نام reviewer، نتیجهٔ پذیرش و دامنهٔ تأییدشده ثبت شوند؛ نبود reviewer مستقل به‌عنوان پذیرش انجام‌نشده گزارش شود.

- تست domain فقط محاسبه را ثابت می‌کند؛ دوام به repository تولیدی و cold reopen و مسیر رابط به entry route واقعی و refresh مصرف‌کنندگان نیاز دارد.
- ادعای بومی به بررسی نصب/دستگاه متناسب نیاز دارد؛ package، نسخه، نوع build و تفاوت احتمالی با artifact انتشار را ثبت کنید. اجرای debug جداگانه را شاهد کامل release production ننامید.
- برای ادعای scale/layout، حجم دادهٔ واقع‌بینانه و بودجهٔ دستگاه مرجع را مشخص کنید و عرض کم، متن بزرگ، RTL و روشن/تیره را در صورت کاربرد بررسی کنید.
- برای defect مهم، regression test و یک یادداشت کوتاه دربارهٔ معیار یا بررسی جاافتاده اضافه کنید؛ رفع bug را به refactor نامرتبط تبدیل نکنید.

## بررسی محلی

پیش‌نیازها با تنظیمات فعلی پروژه:

- Flutter `3.47.5`
- Dart سازگار با `pubspec.yaml`
- Java `17`
- Android SDK با compile SDK `36`

### Windows (PowerShell)

در PowerShell از ریشه repository اجرا کنید:

```powershell
.\tool\ci.ps1
```

اگر سیاست اجرای PowerShell مانع اجرای فایل شد، فقط برای همین فرایند PowerShell از این دستور استفاده کنید:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\ci.ps1
```

یا برای PowerShell 7:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tool\ci.ps1
```

برای اجرای format check، analyze و تست‌ها بدون ساخت Android App Bundle (برای مثال وقتی signing محلی در دسترس نیست)، اجرا کنید:

```powershell
$previousSkipAndroidBuild = $env:PLANACT_SKIP_ANDROID_BUILD
try {
    $env:PLANACT_SKIP_ANDROID_BUILD = 'true'
    .\tool\ci.ps1
} finally {
    if ($null -eq $previousSkipAndroidBuild) {
        Remove-Item Env:PLANACT_SKIP_ANDROID_BUILD -ErrorAction SilentlyContinue
    } else {
        $env:PLANACT_SKIP_ANDROID_BUILD = $previousSkipAndroidBuild
    }
}
```

این اجرا build اندروید را انجام نمی‌دهد و جایگزین CI کامل نیست. برای CI کامل، signing محلی معتبر را در `android/key.properties` یا متغیرهای `ANDROID_KEYSTORE_PATH`، `ANDROID_KEYSTORE_PASSWORD`، `ANDROID_KEY_ALIAS` و `ANDROID_KEY_PASSWORD` تنظیم کنید و دستور اصلی را بدون `PLANACT_SKIP_ANDROID_BUILD` اجرا کنید.

### Linux و macOS (Bash)

از ریشه repository اجرا کنید:

```bash
bash tool/ci.sh
```

هر دو اسکریپت ابتدا lockfile را با `flutter pub get --enforce-lockfile` بررسی می‌کنند، سپس format check، analyze، تست‌ها و در حالت پیش‌فرض build سازگار Android release را اجرا می‌کنند. برای رد کردن build اندروید در Bash می‌توان `PLANACT_SKIP_ANDROID_BUILD=true` را برای اجرای دستور تنظیم کرد؛ این حالت نیز CI کامل محسوب نمی‌شود. در اجرای کامل محلی باید signing معتبر در `android/key.properties` یا متغیرهای `ANDROID_KEYSTORE_PATH`، `ANDROID_KEYSTORE_PASSWORD`، `ANDROID_KEY_ALIAS` و `ANDROID_KEY_PASSWORD` تنظیم شده باشد.

اگر build اندروید را موقتاً خارج از یک بررسی کامل اجرا می‌کنید، آن را به‌عنوان جایگزین CI گزارش نکنید؛ CI همیشه build release را enforce می‌کند.

## CI و رفع شکست

GitHub Actions برای Pull Requestهای مقصد `master` و pushهای `master` اجرا می‌شود. CI شامل نصب وابستگی‌ها، format check، `flutter analyze`، تمام تست‌ها و build release-compatible اندروید است. اجراهای قدیمی‌تر برای همان شاخه یا Pull Request لغو می‌شوند.

در صورت شکست:

1. ابتدا لاگ همان مرحله را بخوانید و علت واقعی را اصلاح کنید.
2. دستور متناسب با سیستم‌عامل را محلی اجرا کنید: `.\tool\ci.ps1` در Windows PowerShell یا `bash tool/ci.sh` در Linux/macOS.
3. اگر شکست ناشی از زیرساخت موقت GitHub یا شبکه بود، از گزینه **Re-run failed jobs** استفاده کنید؛ برای retry بی‌معنی commit جدید نسازید.
4. اگر lockfile، migration یا signing تغییر کرده است، اثر آن را در توضیح Pull Request بنویسید.

## انتشار Android

انتشار دو gate مستقل دارد: **سلامت فنی** (CI/build و checks زیر) و **آمادگی محصول** (قرارداد پذیرش، شواهد متناسب و بررسی مستقل). سبز بودن اولی دومی را ثابت نمی‌کند. دامنهٔ انتشار شامل همهٔ مسیرهای همچنان در دسترس کاربر و موانع به‌ارث‌رسیده است، نه فقط قابلیت تغییرکرده در آخرین PR. پنهان‌کردن یک ورودی رابط، gate مشترک امنیت، persistence یا پلتفرم را معاف نمی‌کند.

maintainer باید پذیرش را به یک commit SHA ثابت و شناسهٔ build/artifact متصل کند؛ checkout، شواهد، فایل‌های پذیرفته‌شده و tag باید همان revision را نشان دهند. برای بررسی لازم روی فایل نهایی، مسیر مورد نیاز **ساخت کاندیدِ غیرمنتشرشده → پذیرش مستقل → انتشار همان فایل‌ها بدون rebuild** است؛ نام نسخه یا تست فایل debug به‌تنهایی هویت فایل انتشار را ثابت نمی‌کند.

[workflow انتشار](../.github/workflows/release.yml) کاندید را از commit ثابت اجرای دستی می‌سازد و APKها، checksumها و هویت commit/run را پیش از انتشار به artifact می‌فرستد. job انتشار پشت environment محافظت‌شدهٔ `android-release` منتظر پذیرش می‌ماند و پس از تأیید، همان فایل‌ها را بدون rebuild با tag متصل به همان commit منتشر می‌کند. environment باید از قبل required reviewer مستقل و Prevent self-review داشته باشد؛ workflow نبود یا عدم دسترسی به این پیکربندی را خطا می‌داند. maintainer باید bypass مدیران را غیرفعال و شواهد را پیش از تأیید ثبت کند. اجرای واقعی این مسیر و بررسی دستگاه همچنان gate مستقل است؛ صرف پیاده‌سازی automation مجوز انتشار نیست.

معیار الزامی ناموفق/اجرا‌نشده یا مانع امنیت، حفظ داده و پلتفرم، اجازهٔ ادعای ready یا انتشار دامنهٔ متأثر را نمی‌دهد. قابلیت ناقص خارج از scope باید با تصمیم صریح دربارهٔ exposure و محدودیت قابل فهم کاربر مدیریت شود؛ برچسب آزمایشی جای تضمین ضروری را نمی‌گیرد. قواعد و workflow فعلی این پذیرش محصول را خودکار enforce نمی‌کنند؛ مسئولیت ثبت و کنترل آن با maintainer است. gateها و وضعیت‌های partial در اسناد verification و PRD همچنان پابرجا هستند.

انتشار فقط از `master` و با اجرای دستی workflow با نام **Release Android** انجام می‌شود:

1. مطمئن شوید نسخه در `pubspec.yaml` به شکل `X.Y.Z+build` تغییر کرده و تغییر آن در `master` ادغام شده است.
2. در GitHub به **Actions → Release Android → Run workflow** بروید.
3. workflow را از `master` اجرا کنید و مقدار version را بدون `v` وارد کنید؛ مانند `0.1.15`. environment محافظت‌شدهٔ `android-release` باید از قبل تنظیم شده باشد.
4. workflow نسخه را با `pubspec.yaml` تطبیق می‌دهد، validation مشترک را اجرا می‌کند، keystore production را فقط در همان job می‌سازد، APKهای امضاشده را تولید و با package/version/ABI/certificate بررسی می‌کند.
5. artifact کاندید همان run را دانلود کنید؛ شواهد بررسی مستقل و دستگاه را به commit/run/versionCode/checksum آن متصل کنید. تا رفع تمام gateهای الزامی، deployment منتظر را تأیید نکنید.
6. پس از تأیید مستقل environment، همان APKها بدون rebuild و پس از بررسی مجدد هویت و checksum منتشر می‌شوند؛ tag نسخه به commit ثابت اشاره می‌کند. رد یا لغو تأیید مانع انتشار است.

Tag را دستی نسازید و push نکنید. کلید خصوصی، `android/key.properties` و keystore نباید وارد repository شوند.

Secrets موردنیاز release:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_SIGNING_CERT_SHA256`
- `SYMBOLS_ENCRYPTION_PASSPHRASE`

## تنظیمات دستی repository در GitHub

این موارد باید توسط maintainer در Settings تنظیم شوند و این فایل‌ها ادعا نمی‌کنند که آن‌ها را خودکار اعمال کرده‌اند:

- برای `master` branch protection یا ruleset فعال کنید.
- ادغام را پس از موفقیت check مربوط به CI مجاز کنید.
- Require pull request، حداقل یک review و conversation resolution را فعال کنید.
- direct push به `master` را محدود کنید و squash merge را مجاز/ترجیحی قرار دهید.
- workflow release را فقط برای maintainerهای قابل اعتماد قابل اجرا نگه دارید.
- secrets release را در GitHub Actions Secrets یا Environment محافظت‌شده ذخیره کنید.

## همگام‌سازی و بازگشت

قبل از شروع کار جدید:

```bash
git fetch origin
git switch master
git pull --ff-only origin master
git switch -c feature/short-description
```

پیش از Pull Request شاخه را به‌روز کنید:

```bash
git fetch origin
git rebase origin/master
```

سپس بررسی محلی را با دستور سیستم‌عامل خود اجرا کنید:

```powershell
.\tool\ci.ps1
```

```bash
bash tool/ci.sh
```

اگر تغییر هنوز منتشر نشده است، اصلاح را در همان شاخه انجام دهید. تاریخچه، داده‌های مالی، occurrenceهای حل‌شده و اطلاعات backup را برای ساده‌سازی حذف نکنید.
