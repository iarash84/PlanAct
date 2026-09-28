# ADR 0012: سیاست مجوزهای Android

- وضعیت: تصمیم امنیتی برای فاز بعد؛ manifest و runtime behavior فعلی بدون تغییر می‌ماند
- تاریخ: 2026-09-28

## تصمیم

مجوزها باید least-privilege، capability-scoped و user-initiated باشند. SMS فقط هنگام ورود آگاهانه به قابلیت import درخواست شود؛ رد آن نباید قابلیت‌های دیگر را مختل کند. `READ_SMS` برای خواندن inbox و `RECEIVE_SMS` برای دریافت broadcast جدید دو capability مستقل‌اند و هرکدام باید rationale فارسی و نتیجهٔ قابل‌فهم داشته باشد.

`POST_NOTIFICATIONS` فقط برای reminder notification و `SCHEDULE_EXACT_ALARM` فقط در صورت نیاز واقعی به زمان‌بندی دقیق استفاده شود. `RECEIVE_BOOT_COMPLETED` فقط برای بازسازی reminderهای durable به‌کار رود. هیچ permission prompt در startup عمومی نباید به‌صورت implicit اضافه شود.

دسترسی‌ها باید در هر call بررسی شوند؛ failure یا revoke باید graceful و بدون logging متن/شناسهٔ حساس باشد. receiver exported، permission protection و intent filtering باید در review انتشار بررسی شوند.

## پیامدها

- مسیر SMS از [`BankSmsReceiver`](android/app/src/main/kotlin/com/example/planact/BankSmsReceiver.kt:9) باید فقط داده را به staging pipeline برساند و هرگز ledger را مستقیم تغییر ندهد.
- acceptance criteria فاز بعد شامل manifest review، runtime denial tests، Android version matrix و عدم نشت raw SMS است.
- این ADR حذف یا اضافه‌کردن permission را در این فاز انجام نمی‌دهد.
