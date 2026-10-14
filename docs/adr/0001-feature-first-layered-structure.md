<div dir="rtl" lang="fa">

# تصمیم معماری ۰۰۰۱: ساختار قابلیت‌محور و لایه‌ای

وضعیت: پذیرفته‌شده؛ تاریخ: <span dir="ltr">۲۰۲۶-۰۹-۲۰</span>.

پروژه به ساختار قابل پیش‌بینی و دامنهٔ مستقل از ویجت <span dir="ltr">Flutter</span>، جدول <span dir="ltr">Drift</span> و <span dir="ltr">API</span> پلتفرم نیاز دارد. هر قابلیت به‌اندازهٔ نیاز، لایه‌های <span dir="ltr">`domain`</span>، <span dir="ltr">`application`</span>، <span dir="ltr">`data`</span> و <span dir="ltr">`presentation`</span> دارد. انواع مشترک در <span dir="ltr">`lib/core`</span> و ترکیب وابستگی‌ها در <span dir="ltr">`lib/app`</span> قرار می‌گیرند.

جهت مجاز:
- <span dir="ltr">`presentation → application → domain`</span>
- <span dir="ltr">`data/infrastructure → domain/application contracts`</span>

پوشهٔ عمومی و بی‌مالک <span dir="ltr">`utils`</span>، <span dir="ltr">`helpers`</span> یا <span dir="ltr">`services`</span> ایجاد نمی‌شود. مالکیت کد روشن می‌ماند و منطق دامنه بدون رابط و پایگاه داده تست می‌شود. ساختار فعلی را برای زیبایی بازآرایی نکنید؛ وجود راهنمای پایه به معنی پیاده‌سازی قابلیت نیست.

</div>
