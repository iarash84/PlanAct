# PlanAct development workflow

این سند مسیر استاندارد توسعه، بررسی و انتشار PlanAct را توضیح می‌دهد.

## شاخه‌ها و Pull Request

- تغییرات را از `master` به شاخه‌ای با پیشوند `feature/`, `fix/`, `refactor/` یا `chore/` منتقل کنید.
- پیش از باز کردن Pull Request، شاخه را با آخرین `master` همگام کنید.
- Pull Request باید به `master` باز شود و توضیح هدف، ریسک و تست‌های انجام‌شده را داشته باشد.
- ادغام به‌صورت **Squash merge** انجام می‌شود تا هر تغییر محصول یک commit روشن در `master` داشته باشد.
- مستقیماً روی `master` توسعه ندهید.

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

انتشار فقط از `master` و با اجرای دستی workflow با نام **Release Android** انجام می‌شود:

1. مطمئن شوید نسخه در `pubspec.yaml` به شکل `X.Y.Z+build` تغییر کرده و تغییر آن در `master` ادغام شده است.
2. در GitHub به **Actions → Release Android → Run workflow** بروید.
3. workflow را از `master` اجرا کنید و مقدار version را بدون `v` وارد کنید؛ مانند `0.1.14`.
4. workflow نسخه را با `pubspec.yaml` تطبیق می‌دهد، validation مشترک را اجرا می‌کند، keystore production را فقط در همان job می‌سازد، APKهای امضاشده را تولید و با package/version/ABI/certificate بررسی می‌کند.
5. فقط پس از موفقیت کامل build و بررسی artifact، tag نسخه و GitHub Release ساخته می‌شود.

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
