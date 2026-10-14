<div dir="rtl" lang="fa">

# تصمیم معماری ۰۰۰۶: معنای پایان دورهٔ تعهد

وضعیت: پذیرفته‌شده؛ تاریخ: <span dir="ltr">۲۰۲۶-۰۹-۲۰</span>.

<span dir="ltr">`CommitmentCycle`</span> ترم، بسته یا بازهٔ فعالِ متعلق به <span dir="ltr">`Commitment`</span> پایدار است. تاریخ پایان برنامه‌ریزی‌شده <span dir="ltr">`plannedEndDate`</span> از پایان واقعی <span dir="ltr">`actualEndDate`</span> جداست. مدل، دورهٔ باز، بازهٔ تاریخ، تعداد ثابت، بستهٔ دستی و ترکیبی را پشتیبانی می‌کند؛ مدل به‌تنهایی وجود مسیر کامل رابط را ثابت نمی‌کند.

قواعد پایان صریح‌اند:
- <span dir="ltr">`ByDate`</span>: رسیدن تاریخ برنامه‌ریزی‌شده.
- <span dir="ltr">`ByUnits`</span>: مصرف واحد هدف.
- <span dir="ltr">`WhicheverFirst`</span>: رسیدن یکی از دو شرط.
- <span dir="ltr">`WhicheverLast`</span>: رسیدن هر دو شرط.
- <span dir="ltr">`Manual`</span>: پایان فقط با فرمان صریح.

دوره وضعیت مستقل دارد و وضعیت تعهد والد را حدس نمی‌زند یا تغییر نمی‌دهد. پیکربندی و گذار نامعتبر در دامنه رد می‌شوند.

</div>
