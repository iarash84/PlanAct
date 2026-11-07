<div dir="rtl" lang="fa">

# انتخاب صریح حساب مالی — <span dir="ltr">۲۰۲۶-۱۰-۱۱</span>

مسیر: صندوق ← پیشنهاد ← تأیید و ثبت ← انتخاب حساب ← تأیید نهایی؛ و مالی ← درآمد/هزینهٔ دستی. بررسی مورد مرحله‌ای مجوز <span dir="ltr">SMS</span> نمی‌خواهد؛ خواندن ارائه‌دهنده می‌خواهد. حساب فعالِ پایدار با ارز سازگار لازم است و حتی یک حساب باید صریح انتخاب شود.

انتخابگر مشترک، انتظار، خالی، خطای خواندن/تلاش مجدد، تازه‌سازی و ساخت حساب در مسیر جدا با حفظ فرم و بازخوانی پس از بازگشت دارد. انصراف تراکنش نمی‌سازد؛ شکست ذخیره انتخاب و متن را حفظ و لمس تکراری بسته است. هنگام نوشتن، وضعیت/ارز حساب تازه بررسی می‌شوند. حساب/ثبت بایگانی برای تاریخچه خواندنی می‌مانند.

پیشنهاد قبلی یک حساب را بی‌صدا برمی‌گزید یا کاربر را به ویرایشگری بدون انتخابگر ارجاع می‌داد؛ فرم مالی هم تصویر داده کهنه/حساب اول داشت. تعیین ارتباط برای تراکنش ثبت‌شده مقصد تعهد/رخداد است، نه انتخابگر حساب و نباید جایگزین شود.

تأیید <span dir="ltr">SMS</span>، رفع پیشنهاد و یک ثبت دفتر را اتمیک ذخیره می‌کند؛ شناسهٔ ثبت موفق برای تعیین ارتباط و بازخوانی صندوق/امروز/مالی حفظ می‌شود. شکست پس از ثبت تراکنش از شکست ثبت جداست. کنترلر فرم حساب پس از پایان گذار مسیر آزاد می‌شود. انتقال مسیر جدا دارد؛ این کار طبقه‌بندی انتقال <span dir="ltr">SMS</span> اضافه نکرد.

شواهد: <span dir="ltr">`inbox_account_selection_test.dart`</span> حساب دوم، هر دو جهت، رد بایگانی، دو لمس، خالی/ساخت/بازگشت/لغو، <span dir="ltr">SQL</span> برگشت تراکنش، حفظ انتخاب و فایل سرد را می‌سنجد؛ <span dir="ltr">`finance_transaction_form_test.dart`</span> انتخاب تک‌حساب، پیش‌نویس/تلاش مجدد و بازخوانی معلق؛ <span dir="ltr">`financial_account_admission_test.dart`</span> حساب کهنه و تاریخچه/اجرای دوباره بدون ایجاد دادهٔ تکراری. مجموعهٔ تاریخی کامل ۵۲۵ تست و تحلیل/قالب/اختلاف موفق بود؛ طرحوارهٔ پایگاه داده، وابستگی، موجودی و پشتیبان تغییر نکردند.

تست قبلی تنها اتمیک‌بودن یا میان‌بر تک‌حساب را داشت، نه مسیر چندحساب. شاهد ردکردن مجوز/ارائه‌دهندهٔ <span dir="ltr">Android</span> و مسیر دستگاهِ ریشه تا سه صفحه هنوز اجرا نشده است؛ ممیزی مستقل کنتراست/هدف باریک نیز ادعا نمی‌شود. مسئول انتشار باید این موارد و بازبینی مستقل را بپذیرد؛ وضعیت <span dir="ltr">SMS</span> همچنان جزئی است.

## Commitment creation optional expectation account — 2026-11-07

Acceptance contract (recorded before implementation): root + → Add commitment →
expand financial details → choose payment/receivable → optionally select an active
IRR account, or retain/return to no account. Existing durable accounts are the only
source; no account is selected automatically. Loading/read failure/retry, empty
accounts and the existing account-creation route must not block accountless creation.
Collapsing sections and failed saves retain the draft; cancellation writes no plan.
The root save callback passes the explicit account through the application command
into initial expectations and the durable generation template. Cold reopen and
future materialization preserve it without posting account entries or altering
history. Existing expectation currency/account fields and backup representation are
reused; no schema migration, currency conversion or settlement behavior is in scope.
Required evidence: widget selection/clearing/retention and read-state tests, production
SQLite creation/reopen/rolling tests, accountless creation and atomic invalid-account
rejection, plus formatting/analyzer checks. Device and independent acceptance are
separate gates and are not implied by automated results.

Defect escape: creation tests covered amount/direction but not optional account
parity with the occurrence editor or propagation into the generation template.

Implementation: the existing shared account picker gained an opt-in optional mode,
reusing the editor's localized no-account label and account identity rows. Capture
receives the production finance repository; the draft/root callback/creation command
carry the selected ID into existing expectation rows and generation metadata. Fresh
active/IRR account validation occurs inside the existing writer-admitted production
creation transaction before any plan writes. No account entries are generated.
Required-account picker consumers retain their original type and behavior.

Verification: 46 tests passed across quick_capture_account_test,
quick_capture_sheet_test, commitment_creation_account_test, rolling_templates_test,
inbox_account_selection_test, finance_transaction_form_test,
financial_account_admission_test and planned_occurrence_backup_test. New tests prove
second-account selection/clearing, section and failed-save retention, empty/read
retry, active compatible filtering, 360dp RTL at 1.8 text scale in Light/Dark, both
financial directions through file-backed cold reopen and rolling generation, no
ledger effects and atomic missing/archived/incompatible account rejection. Existing
hybrid encrypted-backup regression passed; no new backup format/schema/dependency.
Formatting, full flutter analyze and git diff --check passed.

Status: scoped fix implemented and automated checks verified. Not independently
release-approved. The new root-to-capture-to-account-creation return journey and
account-specific export/restore have not received dedicated end-to-end/device
acceptance; existing shared-route and backup regressions are not that evidence.
Release owner: run those journeys on Android, review Persian shaping/accessibility
and obtain independent acceptance before claiming device-verified readiness. These
remaining gates are recorded, not waived by this fix.

</div>
