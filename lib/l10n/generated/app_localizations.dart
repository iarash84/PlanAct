import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fa')];

  /// Application copy. Original usage: lib/app/app_lock.dart:30.
  ///
  /// In fa, this message translates to:
  /// **'برای ورود به پلن‌اکت هویت خود را تأیید کنید.'**
  String get appLockAuthenticationReason;

  /// Application copy. Original usage: lib/app/app_lock.dart:193.
  ///
  /// In fa, this message translates to:
  /// **'احراز هویت انجام نشد. برای تلاش دوباره دکمه را بزنید.'**
  String get appLockLockAndAuthenticateMessage;

  /// Application copy. Original usage: lib/app/app_lock.dart:197.
  ///
  /// In fa, this message translates to:
  /// **'احراز هویت در دسترس نیست. قفل دستگاه را بررسی و دوباره تلاش کنید.'**
  String get appLockLockAndAuthenticateMessage2;

  /// Application copy. Original usage: lib/app/app_lock.dart:238.
  ///
  /// In fa, this message translates to:
  /// **'پلن‌اکت قفل است'**
  String get appLockLockedTitle;

  /// Application copy. Original usage: lib/app/app_lock.dart:243.
  ///
  /// In fa, this message translates to:
  /// **'برای ادامه، هویت خود را تأیید کنید.'**
  String get appLockContinuePrompt;

  /// Application copy. Original usage: lib/app/app_lock.dart:253.
  ///
  /// In fa, this message translates to:
  /// **'در حال بررسی…'**
  String get appLockChecking;

  /// Application copy. Original usage: lib/app/app_lock.dart:253.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن قفل'**
  String get appLockUnlock;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ واردشدهٔ تعطیلات قابل بررسی نیست؛ تقویم پایه نمایش داده می‌شود. دادهٔ قبلی حفظ شده است؛ برای بازیابی فایل با پشتیبانی تماس بگیرید.'**
  String get backupApplicationScopeStartMessage;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:145.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها ذخیره شده‌اند، اما مجوز اعلان یا زنگ دقیق فعال نیست. از تنظیمات یادآوری‌ها را فعال کنید.'**
  String get backupApplicationScopeStartMessage2;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:170.
  ///
  /// In fa, this message translates to:
  /// **'آماده‌سازی امن اطلاعات ممکن نشد. دوباره تلاش کنید.'**
  String get backupApplicationScopeStartMessage3;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:221.
  ///
  /// In fa, this message translates to:
  /// **'عملیات پشتیبان‌گیری یا بازیابی با موفقیت انجام شد.'**
  String get backupApplicationScopeExclusiveMessage;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:225.
  ///
  /// In fa, this message translates to:
  /// **'عملیات انجام نشد. فایل، فضای ذخیره‌سازی و کلید بازیابی (یا کلید نصب اصلی برای فایل قدیمی) را بررسی کنید و دوباره تلاش کنید.'**
  String get backupApplicationScopeExclusiveMessage2;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:286.
  ///
  /// In fa, this message translates to:
  /// **'در حال آماده‌سازی اطلاعات'**
  String get backupApplicationScopeBuildSemanticsLabel;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:291.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی امن نیاز به تلاش دوباره دارد.'**
  String get backupApplicationScopeBuildChildren;

  /// Application copy. Original usage: lib/app/backup_application_scope.dart:294.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره'**
  String get commonRetry;

  /// Application copy. Original usage: lib/app/planact_app.dart:136.
  ///
  /// In fa, this message translates to:
  /// **'خواندن واحد پول انجام نشد؛ دوباره تلاش کنید.'**
  String get planactAppLoadMoneyUnitMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:163.
  ///
  /// In fa, this message translates to:
  /// **'خواندن تنظیمات قفل برنامه ممکن نشد. دوباره تلاش کنید.'**
  String get planactAppLoadAppLockSettingMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:192.
  ///
  /// In fa, this message translates to:
  /// **'پلن‌اکت'**
  String get appName;

  /// Application copy. Original usage: lib/app/planact_app.dart:415.
  ///
  /// In fa, this message translates to:
  /// **'زمان‌بندی ثبت شده است؛ هماهنگی یادآوری دوباره تلاش می‌شود.'**
  String get planactAppMaintainSchedulesContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:426.
  ///
  /// In fa, this message translates to:
  /// **'ادامهٔ زمان‌بندی یا هماهنگی یادآوری انجام نشد. با بازگشت به برنامه دوباره تلاش می‌شود.'**
  String get planactAppMaintainSchedulesMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:525.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری اقدامات انجام نشد؛ دوباره تلاش کنید.'**
  String get planactAppRefreshMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:577.
  ///
  /// In fa, this message translates to:
  /// **'ارتباط تراکنش ثبت شد.'**
  String get planactAppOpenRelationshipMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:585.
  ///
  /// In fa, this message translates to:
  /// **'صندوق ورودی'**
  String get planactAppOpenInboxTitle;

  /// Application copy. Original usage: lib/app/planact_app.dart:645.
  ///
  /// In fa, this message translates to:
  /// **'تعهد و برچسب‌ها ذخیره شدند؛ نمایش اطلاعات به‌روز نشد.'**
  String get planactAppSaveCapturedCommitmentMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:649.
  ///
  /// In fa, this message translates to:
  /// **'تعهد ذخیره شد؛ هماهنگ‌سازی یادآوری هنوز انجام نشده است. مجوزهای یادآوری را در تنظیمات بررسی کنید؛ با بازکردن دوباره برنامه، هماهنگ‌سازی تکرار می‌شود.'**
  String get planactAppSaveCapturedCommitmentMessage2;

  /// Application copy. Original usage: lib/app/planact_app.dart:679.
  ///
  /// In fa, this message translates to:
  /// **'ابتدا یک حساب اضافه کنید.'**
  String get planactAppShowQuickFinancialEntryMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:727.
  ///
  /// In fa, this message translates to:
  /// **'درآمد ثبت شد.'**
  String get planactAppSaveQuickFinancialEntryMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:727.
  ///
  /// In fa, this message translates to:
  /// **'هزینه ثبت شد.'**
  String get planactAppSaveQuickFinancialEntryMessage2;

  /// Application copy. Original usage: lib/app/planact_app.dart:729.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش و برچسب‌ها ذخیره شدند؛ نمایش اطلاعات به‌روز نشد.'**
  String get planactAppSaveQuickFinancialEntryMessage3;

  /// Application copy. Original usage: lib/app/planact_app.dart:737.
  ///
  /// In fa, this message translates to:
  /// **'برای انتقال، دست‌کم دو حساب فعال لازم است.'**
  String get planactAppShowQuickTransferMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:760.
  ///
  /// In fa, this message translates to:
  /// **'انتقال ثبت شد.'**
  String get planactAppShowQuickTransferMessage2;

  /// Application copy. Original usage: lib/app/planact_app.dart:762.
  ///
  /// In fa, this message translates to:
  /// **'ثبت انتقال انجام نشد؛ دوباره تلاش کنید.'**
  String get planactAppShowQuickTransferMessage3;

  /// Application copy. Original usage: lib/app/planact_app.dart:796.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد'**
  String get planactAppShowCommitmentDetailsTitle;

  /// Application copy. Original usage: lib/app/planact_app.dart:805.
  ///
  /// In fa, this message translates to:
  /// **'توقف موقت'**
  String get planactAppShowCommitmentDetailsTitle2;

  /// Application copy. Original usage: lib/app/planact_app.dart:814.
  ///
  /// In fa, this message translates to:
  /// **'ادامه'**
  String get planactAppShowCommitmentDetailsTitle3;

  /// Application copy. Original usage: lib/app/planact_app.dart:824.
  ///
  /// In fa, this message translates to:
  /// **'لغو تعهد'**
  String get planactAppShowCommitmentDetailsTitle4;

  /// Application copy. Original usage: lib/app/planact_app.dart:833.
  ///
  /// In fa, this message translates to:
  /// **'بایگانی'**
  String get planactAppShowCommitmentDetailsTitle5;

  /// Application copy. Original usage: lib/app/planact_app.dart:842.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی از بایگانی'**
  String get planactAppShowCommitmentDetailsTitle6;

  /// Application copy. Original usage: lib/app/planact_app.dart:850.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات و ویرایش'**
  String get planactAppShowCommitmentDetailsTitle7;

  /// Application copy. Original usage: lib/app/planact_app.dart:892.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ وضعیت انجام نشد؛ دوباره تلاش کنید.'**
  String get planactAppApplyStatusContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:904.
  ///
  /// In fa, this message translates to:
  /// **'تعهد از بایگانی بازگردانی شد.'**
  String get planactAppRestoreCommitmentContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:910.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی تعهد انجام نشد؛ دوباره تلاش کنید.'**
  String get planactAppRestoreCommitmentContent2;

  /// Application copy. Original usage: lib/app/planact_app.dart:942.
  ///
  /// In fa, this message translates to:
  /// **'خط زمانی تعهدات باقی‌مانده'**
  String get planactAppShowTimelineTitle;

  /// Application copy. Original usage: lib/app/planact_app.dart:946.
  ///
  /// In fa, this message translates to:
  /// **'تعهد باقی‌مانده‌ای وجود ندارد.'**
  String get planactAppShowTimelineContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:960.
  ///
  /// In fa, this message translates to:
  /// **'زمان‌بندی در دسترس نیست'**
  String get planactAppShowTimelineSubtitle;

  /// Application copy. Original usage: lib/app/planact_app.dart:960.
  ///
  /// In fa, this message translates to:
  /// **'{value1} · {value2}'**
  String planactAppShowTimelineSubtitle2(String value1, String value2);

  /// گسترش همان پنل خط زمانی یا تاریخچه تا تمام ارتفاع امن صفحه.
  ///
  /// In fa, this message translates to:
  /// **'نمایش تمام‌صفحه'**
  String get commitmentBrowseExpand;

  /// خطای قابل تلاش مجدد در بازکردن جزئیات از پنل خط زمانی یا تاریخچه؛ خود فهرست حفظ می‌شود.
  ///
  /// In fa, this message translates to:
  /// **'نمایش جزئیات انجام نشد؛ برای تلاش دوباره تعهد را انتخاب کنید.'**
  String get commitmentBrowseOpenError;

  /// بازگرداندن پنل خط زمانی یا تاریخچه به ارتفاع میانی بدون بستن آن.
  ///
  /// In fa, this message translates to:
  /// **'نمایش کوچک‌تر'**
  String get commitmentBrowseCollapse;

  /// Application copy. Original usage: lib/app/planact_app.dart:974.
  ///
  /// In fa, this message translates to:
  /// **'بستن'**
  String get commonClose;

  /// Application copy. Original usage: lib/app/planact_app.dart:1040.
  ///
  /// In fa, this message translates to:
  /// **'{value1} {value2}، {value3}'**
  String planactAppFormatDateMessage(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/app/planact_app.dart:1051.
  ///
  /// In fa, this message translates to:
  /// **'تعهد بایگانی شد.'**
  String get planactAppArchiveCommitmentContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:1055.
  ///
  /// In fa, this message translates to:
  /// **'بایگانی انجام نشد؛ دوباره تلاش کنید.'**
  String get planactAppArchiveCommitmentContent2;

  /// Application copy. Original usage: lib/app/planact_app.dart:1163.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get commonToday;

  /// Application copy. Original usage: lib/app/planact_app.dart:1163.
  ///
  /// In fa, this message translates to:
  /// **'تقویم'**
  String get navigationCalendar;

  /// Application copy. Original usage: lib/app/planact_app.dart:1163.
  ///
  /// In fa, this message translates to:
  /// **'مدیریت مالی'**
  String get planactAppTitlesMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:1163.
  ///
  /// In fa, this message translates to:
  /// **'بیشتر'**
  String get navigationMore;

  /// Application copy. Original usage: lib/app/planact_app.dart:1174.
  ///
  /// In fa, this message translates to:
  /// **'گزینه‌های بیشتر'**
  String get planactAppBuildTooltip;

  /// Application copy. Original usage: lib/app/planact_app.dart:1194.
  ///
  /// In fa, this message translates to:
  /// **'افزودن تعهد'**
  String get planactAppBuildTitle;

  /// Application copy. Original usage: lib/app/planact_app.dart:1202.
  ///
  /// In fa, this message translates to:
  /// **'خط زمانی تعهدات'**
  String get planactAppBuildTitle2;

  /// Application copy. Original usage: lib/app/planact_app.dart:1211.
  ///
  /// In fa, this message translates to:
  /// **'گزارش‌ها'**
  String get planactAppBuildTitle3;

  /// Application copy. Original usage: lib/app/planact_app.dart:1252.
  ///
  /// In fa, this message translates to:
  /// **'افزودن سریع'**
  String get commonQuickAdd;

  /// Application copy. Original usage: lib/app/planact_app.dart:1303.
  ///
  /// In fa, this message translates to:
  /// **'مالی'**
  String get navigationFinance;

  /// Application copy. Original usage: lib/app/planact_app.dart:1375.
  ///
  /// In fa, this message translates to:
  /// **'تغییرات ذخیره نشده'**
  String get planactAppConfirmLeaveTitle;

  /// Application copy. Original usage: lib/app/planact_app.dart:1376.
  ///
  /// In fa, this message translates to:
  /// **'تغییرات ذخیره نشده‌اند. خارج می‌شوید؟'**
  String get planactAppConfirmLeaveContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:1380.
  ///
  /// In fa, this message translates to:
  /// **'ادامهٔ ویرایش'**
  String get planactAppConfirmLeaveActions;

  /// Application copy. Original usage: lib/app/planact_app.dart:1384.
  ///
  /// In fa, this message translates to:
  /// **'خروج بدون ذخیره'**
  String get planactAppConfirmLeaveActions2;

  /// Application copy. Original usage: lib/app/planact_app.dart:1409.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ تغییرات انجام نشد؛ دوباره تلاش کنید.'**
  String get planactAppSaveContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:1427.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات تعهد'**
  String get planactAppBuildTitle4;

  /// Application copy. Original usage: lib/app/planact_app.dart:1432.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت: {value1}'**
  String planactAppBuildChildren(String value1);

  /// Application copy. Original usage: lib/app/planact_app.dart:1437.
  ///
  /// In fa, this message translates to:
  /// **'نوع: {value1}'**
  String planactAppBuildChildren2(String value1);

  /// Application copy. Original usage: lib/app/planact_app.dart:1443.
  ///
  /// In fa, this message translates to:
  /// **'عنوان'**
  String get planactAppBuildLabelText;

  /// Application copy. Original usage: lib/app/planact_app.dart:1449.
  ///
  /// In fa, this message translates to:
  /// **'توضیحات'**
  String get planactAppBuildLabelText2;

  /// Application copy. Original usage: lib/app/planact_app.dart:1459.
  ///
  /// In fa, this message translates to:
  /// **'اولویت'**
  String get planactAppBuildLabelText3;

  /// Application copy. Original usage: lib/app/planact_app.dart:1521.
  ///
  /// In fa, this message translates to:
  /// **'نوبت‌ها'**
  String get planactAppBuildChildren3;

  /// Application copy. Original usage: lib/app/planact_app.dart:1571.
  ///
  /// In fa, this message translates to:
  /// **'زمان ذخیره شد؛ هماهنگ‌سازی یادآوری در انتظار است.'**
  String get planactAppBuildContent;

  /// Application copy. Original usage: lib/app/planact_app.dart:1572.
  ///
  /// In fa, this message translates to:
  /// **'زمان ذخیره شد؛ سوابق قبلی محفوظ است.'**
  String get planactAppBuildContent2;

  /// Application copy. Original usage: lib/app/planact_app.dart:1581.
  ///
  /// In fa, this message translates to:
  /// **'تغییر زمان انجام نشد. نوبت‌های گذشته، دستی یا تغییر تاریخ سری ماهانه و سالانه قابل ویرایش نیستند؛ نوبت را دوباره بررسی کنید.'**
  String get planactAppBuildContent3;

  /// Application copy. Original usage: lib/app/planact_app.dart:1603.
  ///
  /// In fa, this message translates to:
  /// **'انتظار مالی نوبت‌ها'**
  String get planactAppBuildTitle5;

  /// Application copy. Original usage: lib/app/planact_app.dart:1606.
  ///
  /// In fa, this message translates to:
  /// **'برای هر نوبتِ این تعهد، مبلغ جداگانه و اختیاری ثبت کنید.'**
  String get planactAppBuildChildren4;

  /// Application copy. Original usage: lib/app/planact_app.dart:1626.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get commonSave;

  /// Application copy. Original usage: lib/app/planact_app.dart:1671.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ نوبت مشخص نشده است'**
  String get planactAppDateLabelMessage;

  /// Application copy. Original usage: lib/app/planact_app.dart:1677.
  ///
  /// In fa, this message translates to:
  /// **'برای ثبت یا ویرایش انتظار مالی باز کنید'**
  String get planactAppBuildSubtitle;

  /// Application copy. Original usage: lib/app/planact_app.dart:1697.
  ///
  /// In fa, this message translates to:
  /// **'فعال'**
  String get planactAppCommitmentStatusActive;

  /// Application copy. Original usage: lib/app/planact_app.dart:1698.
  ///
  /// In fa, this message translates to:
  /// **'متوقف‌شده'**
  String get planactAppCommitmentStatusPaused;

  /// Application copy. Original usage: lib/app/planact_app.dart:1699.
  ///
  /// In fa, this message translates to:
  /// **'تکمیل‌شده'**
  String get planactAppCommitmentStatusCompleted;

  /// Application copy. Original usage: lib/app/planact_app.dart:1700.
  ///
  /// In fa, this message translates to:
  /// **'لغوشده'**
  String get occurrenceCancelled;

  /// Application copy. Original usage: lib/app/planact_app.dart:1701.
  ///
  /// In fa, this message translates to:
  /// **'بایگانی‌شده'**
  String get planactAppCommitmentStatusArchived;

  /// Application copy. Original usage: lib/app/planact_app.dart:1705.
  ///
  /// In fa, this message translates to:
  /// **'یک‌باره'**
  String get planactAppCommitmentKindOneOff;

  /// Application copy. Original usage: lib/app/planact_app.dart:1706.
  ///
  /// In fa, this message translates to:
  /// **'تکرارشونده'**
  String get planactAppCommitmentKindRecurring;

  /// Application copy. Original usage: lib/app/planact_app.dart:1710.
  ///
  /// In fa, this message translates to:
  /// **'کم'**
  String get planactAppCommitmentPriorityLow;

  /// Application copy. Original usage: lib/app/planact_app.dart:1711.
  ///
  /// In fa, this message translates to:
  /// **'عادی'**
  String get planactAppCommitmentPriorityNormal;

  /// Application copy. Original usage: lib/app/planact_app.dart:1712.
  ///
  /// In fa, this message translates to:
  /// **'زیاد'**
  String get planactAppCommitmentPriorityHigh;

  /// Application copy. Original usage: lib/app/planact_app.dart:1713.
  ///
  /// In fa, this message translates to:
  /// **'فوری'**
  String get planactAppCommitmentPriorityUrgent;

  /// Application copy. Original usage: lib/app/planact_app.dart:1744.
  ///
  /// In fa, this message translates to:
  /// **'عملکرد، پرداخت‌ها و اعتبار با فیلتر تاریخ و هشتگ'**
  String get planactAppBuildSubtitle2;

  /// Application copy. Original usage: lib/app/planact_app.dart:1754.
  ///
  /// In fa, this message translates to:
  /// **'بررسی پیام‌های واردشده پیش از ثبت مالی'**
  String get planactAppBuildSubtitle3;

  /// Application copy. Original usage: lib/app/planact_app.dart:1762.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get planactAppBuildTitle6;

  /// Application copy. Original usage: lib/app/planact_app.dart:1763.
  ///
  /// In fa, this message translates to:
  /// **'نمایش، امنیت و مجوزهای برنامه'**
  String get planactAppBuildSubtitle4;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:37.
  ///
  /// In fa, this message translates to:
  /// **'سبزآبی'**
  String get commitmentIdentityPaletteCommitmentColorTeal;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:38.
  ///
  /// In fa, this message translates to:
  /// **'آبی'**
  String get commitmentIdentityPaletteCommitmentColorBlue;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:39.
  ///
  /// In fa, this message translates to:
  /// **'نیلی'**
  String get commitmentIdentityPaletteCommitmentColorIndigo;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:40.
  ///
  /// In fa, this message translates to:
  /// **'بنفش'**
  String get commitmentIdentityPaletteCommitmentColorViolet;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:41.
  ///
  /// In fa, this message translates to:
  /// **'صورتی'**
  String get commitmentIdentityPaletteCommitmentColorRose;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:42.
  ///
  /// In fa, this message translates to:
  /// **'کهربایی'**
  String get commitmentIdentityPaletteCommitmentColorAmber;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:43.
  ///
  /// In fa, this message translates to:
  /// **'زیتونی'**
  String get commitmentIdentityPaletteCommitmentColorOlive;

  /// Application copy. Original usage: lib/app/theme/commitment_identity_palette.dart:44.
  ///
  /// In fa, this message translates to:
  /// **'فیروزه‌ای'**
  String get commitmentIdentityPaletteCommitmentColorCyan;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:6.
  ///
  /// In fa, this message translates to:
  /// **'فروردین'**
  String get jalaliMonthFarvardin;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:7.
  ///
  /// In fa, this message translates to:
  /// **'اردیبهشت'**
  String get jalaliMonthOrdibehesht;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:8.
  ///
  /// In fa, this message translates to:
  /// **'خرداد'**
  String get jalaliMonthKhordad;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:9.
  ///
  /// In fa, this message translates to:
  /// **'تیر'**
  String get jalaliMonthTir;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:10.
  ///
  /// In fa, this message translates to:
  /// **'مرداد'**
  String get jalaliMonthMordad;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:11.
  ///
  /// In fa, this message translates to:
  /// **'شهریور'**
  String get jalaliMonthShahrivar;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:12.
  ///
  /// In fa, this message translates to:
  /// **'مهر'**
  String get jalaliMonthMehr;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:13.
  ///
  /// In fa, this message translates to:
  /// **'آبان'**
  String get jalaliMonthAban;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:14.
  ///
  /// In fa, this message translates to:
  /// **'آذر'**
  String get jalaliMonthAzar;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:15.
  ///
  /// In fa, this message translates to:
  /// **'دی'**
  String get jalaliMonthDey;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:16.
  ///
  /// In fa, this message translates to:
  /// **'بهمن'**
  String get jalaliMonthBahman;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:17.
  ///
  /// In fa, this message translates to:
  /// **'اسفند'**
  String get jalaliMonthEsfand;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:21.
  ///
  /// In fa, this message translates to:
  /// **'شنبه'**
  String get weekdaySaturday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:22.
  ///
  /// In fa, this message translates to:
  /// **'یکشنبه'**
  String get weekdaySunday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:23.
  ///
  /// In fa, this message translates to:
  /// **'دوشنبه'**
  String get weekdayMonday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:24.
  ///
  /// In fa, this message translates to:
  /// **'سه‌شنبه'**
  String get weekdayTuesday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:25.
  ///
  /// In fa, this message translates to:
  /// **'چهارشنبه'**
  String get weekdayWednesday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:26.
  ///
  /// In fa, this message translates to:
  /// **'پنجشنبه'**
  String get weekdayThursday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:27.
  ///
  /// In fa, this message translates to:
  /// **'جمعه'**
  String get weekdayFriday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:32.
  ///
  /// In fa, this message translates to:
  /// **'ش'**
  String get weekdayShortSaturday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:33.
  ///
  /// In fa, this message translates to:
  /// **'ی'**
  String get weekdayShortSunday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:34.
  ///
  /// In fa, this message translates to:
  /// **'د'**
  String get weekdayShortMonday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:35.
  ///
  /// In fa, this message translates to:
  /// **'س'**
  String get weekdayShortTuesday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:36.
  ///
  /// In fa, this message translates to:
  /// **'چ'**
  String get weekdayShortWednesday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:37.
  ///
  /// In fa, this message translates to:
  /// **'پ'**
  String get weekdayShortThursday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:38.
  ///
  /// In fa, this message translates to:
  /// **'ج'**
  String get weekdayShortFriday;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:45.
  ///
  /// In fa, this message translates to:
  /// **'{value1}، {value2} {value3}'**
  String persianDateFormatterDateMessage(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:57.
  ///
  /// In fa, this message translates to:
  /// **'فردا'**
  String get commonTomorrow;

  /// Application copy. Original usage: lib/core/localization/persian_date_formatter.dart:58.
  ///
  /// In fa, this message translates to:
  /// **'دیروز'**
  String get commonYesterday;

  /// Application copy. Original usage: lib/core/money/iranian_money_unit.dart:6.
  ///
  /// In fa, this message translates to:
  /// **'ریال'**
  String get currencyRial;

  /// Application copy. Original usage: lib/core/money/iranian_money_unit.dart:6.
  ///
  /// In fa, this message translates to:
  /// **'تومان'**
  String get currencyToman;

  /// Application copy. Original usage: lib/core/presentation/planact_form_sheet.dart:13.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get commonCancel;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:37.
  ///
  /// In fa, this message translates to:
  /// **'تعطیلی هفتگی'**
  String get planactJalaliDatePickerCalendarHolidayKindWeekend;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:39.
  ///
  /// In fa, this message translates to:
  /// **'تعطیل رسمی'**
  String get planactJalaliDatePickerKindLabelMessage;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:40.
  ///
  /// In fa, this message translates to:
  /// **'تعطیلی خاص'**
  String get planactJalaliDatePickerCalendarHolidayKindSpecial;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:94.
  ///
  /// In fa, this message translates to:
  /// **'ماه قبل'**
  String get planactJalaliDatePickerBuildTooltip;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:105.
  ///
  /// In fa, this message translates to:
  /// **'ماه بعد'**
  String get planactJalaliDatePickerBuildTooltip2;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:205.
  ///
  /// In fa, this message translates to:
  /// **'، '**
  String get commonListSeparator;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:301.
  ///
  /// In fa, this message translates to:
  /// **'منبع و جزئیات تعطیلات'**
  String get planactJalaliDatePickerBuildTitle;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:307.
  ///
  /// In fa, this message translates to:
  /// **'{value1}\nمنبع: {value2}\nنسخه: {value3}\nمحدوده: {value4}'**
  String planactJalaliDatePickerBuildChildren(
    String value1,
    String value2,
    String value3,
    String value4,
  );

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:317.
  ///
  /// In fa, this message translates to:
  /// **'پوشش تعطیلات رسمی این سال کامل نیست؛ نبود نشانهٔ تعطیلی به معنی روز کاری قطعی نیست.'**
  String get planactJalaliDatePickerBuildChildren2;

  /// Application copy. Original usage: lib/core/presentation/planact_jalali_date_picker.dart:333.
  ///
  /// In fa, this message translates to:
  /// **'تأیید تاریخ'**
  String get planactJalaliDatePickerBuildActions;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:84.
  ///
  /// In fa, this message translates to:
  /// **'برای این برنامه هنوز نتیجه‌ای ثبت نشده است.'**
  String get actualUseCasesBuildExplanation;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:92.
  ///
  /// In fa, this message translates to:
  /// **'برنامه انجام شد.'**
  String get actualUseCasesActualOutcomeCompleted;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:93.
  ///
  /// In fa, this message translates to:
  /// **'حضور ثبت شد.'**
  String get actualUseCasesActualOutcomeAttended;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:94.
  ///
  /// In fa, this message translates to:
  /// **'برنامه لغو شد.'**
  String get actualUseCasesActualOutcomeCancelled;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:95.
  ///
  /// In fa, this message translates to:
  /// **'برنامه از دست رفت.'**
  String get actualUseCasesActualOutcomeMissed;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:96.
  ///
  /// In fa, this message translates to:
  /// **'عدم حضور ثبت شد.'**
  String get actualUseCasesActualOutcomeNoShow;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:97.
  ///
  /// In fa, this message translates to:
  /// **'برنامه به‌صورت ناقص انجام شد.'**
  String get actualUseCasesActualOutcomePartial;

  /// Application copy. Original usage: lib/features/actuals/application/actual_use_cases.dart:98.
  ///
  /// In fa, this message translates to:
  /// **'نتیجه بازگردانی شد؛ سابقهٔ قبلی محفوظ است.'**
  String get actualUseCasesActualOutcomeReopened;

  /// Application copy. Original usage: lib/features/automation/application/local_ai.dart:109.
  ///
  /// In fa, this message translates to:
  /// **'هوش مصنوعی محلی در دسترس یا قابل اعتماد نبود؛ نتیجه قطعی‌پذیر استفاده شد.'**
  String get localAiFallbackExplanation;

  /// Application copy. Original usage: lib/features/automation/application/local_ai.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'هوش مصنوعی اختیاری خاموش است؛ نتیجه قطعی‌پذیر استفاده شد.'**
  String get localAiFallbackExplanation2;

  /// Application copy. Original usage: lib/features/automation/application/local_ai.dart:129.
  ///
  /// In fa, this message translates to:
  /// **'خلاصه اختیاری روی دستگاه تولید شد؛ داده‌های قطعی‌پذیر همچنان مبنای نتیجه هستند.'**
  String get localAiEvaluateExplanation;

  /// Application copy. Original usage: lib/features/automation/domain/automation.dart:118.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت‌های {value1}گانه با فاصله تقریبی {value2} روز و مبلغ مشابه شناسایی شد.'**
  String automationDetectExplanation(String value1, String value2);

  /// Application copy. Original usage: lib/features/automation/domain/automation.dart:160.
  ///
  /// In fa, this message translates to:
  /// **'واحد پول یکسان است'**
  String get automationScoreMessage;

  /// Application copy. Original usage: lib/features/automation/domain/automation.dart:168.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ در محدوده قابل قبول است'**
  String get automationScoreMessage2;

  /// Application copy. Original usage: lib/features/automation/domain/automation.dart:174.
  ///
  /// In fa, this message translates to:
  /// **'نام پذیرنده یکسان است'**
  String get automationScoreMessage3;

  /// Application copy. Original usage: lib/features/automation/domain/automation.dart:179.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ‌ها نزدیک هستند'**
  String get automationScoreMessage4;

  /// Application copy. Original usage: lib/features/automation/domain/automation.dart:214.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌بندی بر اساس تطبیق دقیق نام پذیرنده پیشنهاد شد؛ تأیید کاربر لازم است.'**
  String get automationSuggestExplanation;

  /// Application copy. Original usage: lib/features/automation/domain/predictive.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'نباید پیش از ابتدای بازه باشد.'**
  String get predictiveForecastMessage;

  /// Application copy. Original usage: lib/features/automation/domain/predictive.dart:129.
  ///
  /// In fa, this message translates to:
  /// **'برآورد قطعی‌پذیر بر پایه {value1} پرداخت دوره‌ای با فاصله {value2} روز است.'**
  String predictiveForecastExplanation(String value1, String value2);

  /// Application copy. Original usage: lib/features/automation/domain/predictive.dart:165.
  ///
  /// In fa, this message translates to:
  /// **'{value1} مورد عقب‌افتاده وجود دارد'**
  String predictiveAssessMessage(String value1);

  /// Application copy. Original usage: lib/features/automation/domain/predictive.dart:170.
  ///
  /// In fa, this message translates to:
  /// **'{value1} مورد اخیر انجام نشده است'**
  String predictiveAssessMessage2(String value1);

  /// Application copy. Original usage: lib/features/automation/domain/predictive.dart:177.
  ///
  /// In fa, this message translates to:
  /// **'سررسید تا سه روز آینده است'**
  String get predictiveAssessMessage3;

  /// Application copy. Original usage: lib/features/automation/domain/predictive.dart:181.
  ///
  /// In fa, this message translates to:
  /// **'موجودی قابل تخصیص کافی نیست'**
  String get predictiveAssessMessage4;

  /// Application copy. Original usage: lib/features/automation/domain/predictive.dart:237.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ با میانه پرداخت‌های قبلی همین پذیرنده تفاوت معنادار دارد؛ فقط نیازمند بررسی کاربر است.'**
  String get predictiveDetectExplanation;

  /// Application copy. Original usage: lib/features/backup/data/file_backup_actions.dart:77.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره نسخه پشتیبان'**
  String get fileBackupActionsPathDialogTitle;

  /// Application copy. Original usage: lib/features/backup/data/file_backup_actions.dart:99.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب نسخه پشتیبان'**
  String get fileBackupActionsResultDialogTitle;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:25.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی نسخه پشتیبان؟'**
  String get backupSettingsCardConfirmedTitle;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:25.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره نسخه پشتیبان؟'**
  String get backupSettingsCardConfirmedTitle2;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:29.
  ///
  /// In fa, this message translates to:
  /// **'تمام اطلاعات فعلی با اطلاعات فایل جایگزین می‌شود. پیش از جایگزینی، نسخه ایمنی ساخته می‌شود. فایل جدید به کلید بازیابی خودش نیاز دارد؛ فایل قدیمی فقط با کلید نصب اصلی قابل بازیابی است.'**
  String get backupSettingsCardConfirmedContent;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:30.
  ///
  /// In fa, this message translates to:
  /// **'این فایل حاوی اطلاعات شخصی و مالی رمزنگاری‌شده است؛ آن را در محل امن نگه دارید. متن خام پیامک‌ها صادر نمی‌شود. در مرحله بعد کلید مستقل این نسخه نمایش داده می‌شود؛ آن را جدا و امن نگه دارید.'**
  String get backupSettingsCardConfirmedContent2;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:39.
  ///
  /// In fa, this message translates to:
  /// **'تأیید بازیابی'**
  String get backupSettingsCardConfirmedActions;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:39.
  ///
  /// In fa, this message translates to:
  /// **'تأیید ذخیره'**
  String get backupSettingsCardConfirmedActions2;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:74.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات با موفقیت بازیابی شد.'**
  String get backupSettingsCardRunContent;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:75.
  ///
  /// In fa, this message translates to:
  /// **'نسخه پشتیبان ذخیره شد.'**
  String get backupSettingsCardRunContent2;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:84.
  ///
  /// In fa, this message translates to:
  /// **'عملیات انجام نشد. فایل، کلید بازیابی و فضای ذخیره‌سازی را بررسی کنید و دوباره تلاش کنید. فایل قدیمی به کلید نصب اصلی نیاز دارد.'**
  String get backupSettingsCardRunMessage;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:98.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان‌گیری و بازیابی'**
  String get backupSettingsCardBuildTitle;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:100.
  ///
  /// In fa, this message translates to:
  /// **'نسخه رمزنگاری‌شده محلی؛ بدون متن خام پیامک'**
  String get backupSettingsCardBuildSubtitle;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:105.
  ///
  /// In fa, this message translates to:
  /// **'در حال پشتیبان‌گیری یا بازیابی'**
  String get backupSettingsCardBuildSemanticsLabel;

  /// Application copy. Original usage: lib/features/backup/presentation/backup_settings_card.dart:115.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی از فایل'**
  String get backupSettingsCardBuildTitle2;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:15.
  ///
  /// In fa, this message translates to:
  /// **'کلید بازیابی این نسخه'**
  String get recoveryKeyDialogsConfirmRecoveryKeyTitle;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:22.
  ///
  /// In fa, this message translates to:
  /// **'این کلید را در محل امن و جدا از فایل پشتیبان نگه دارید. هر نسخه کلید تازه‌ای دارد. برای بازیابی روی نصب جدید فقط فایل و همین کلید لازم است. برنامه کلید را نگه نمی‌دارد.'**
  String get recoveryKeyDialogsConfirmRecoveryKeyChildren;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:28.
  ///
  /// In fa, this message translates to:
  /// **'اگر کلید گم شود، این نسخهٔ پشتیبان دیگر قابل بازیابی نیست.'**
  String get recoveryKeyDialogsConfirmRecoveryKeyChildren2;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:52.
  ///
  /// In fa, this message translates to:
  /// **'کلید کپی شد.'**
  String get recoveryKeyDialogsConfirmRecoveryKeyOnPressed;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:55.
  ///
  /// In fa, this message translates to:
  /// **'کپی کلید انجام نشد. دوباره تلاش کنید.'**
  String get recoveryKeyDialogsConfirmRecoveryKeyOnPressed2;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:64.
  ///
  /// In fa, this message translates to:
  /// **'کپی کلید'**
  String get recoveryKeyDialogsConfirmRecoveryKeyLabel;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'کلید حساس است؛ برنامه‌های دیگر ممکن است به کلیپ‌بورد دسترسی داشته باشند.'**
  String get recoveryKeyDialogsConfirmRecoveryKeyChildren3;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:76.
  ///
  /// In fa, this message translates to:
  /// **'در حال کپی کلید…'**
  String get recoveryKeyDialogsConfirmRecoveryKeyChildren4;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:82.
  ///
  /// In fa, this message translates to:
  /// **'کلید را جدا و امن نگه داشتم و خطر گم‌شدن آن را می‌پذیرم.'**
  String get recoveryKeyDialogsConfirmRecoveryKeyTitle2;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:100.
  ///
  /// In fa, this message translates to:
  /// **'ادامه و ذخیره فایل'**
  String get recoveryKeyDialogsConfirmRecoveryKeyActions;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:117.
  ///
  /// In fa, this message translates to:
  /// **'ورود کلید بازیابی'**
  String get recoveryKeyDialogsRequestRecoveryKeyTitle;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:123.
  ///
  /// In fa, this message translates to:
  /// **'کلید همین فایل را وارد کنید. بدون کلید درست، اطلاعات فعلی جایگزین نمی‌شود.'**
  String get recoveryKeyDialogsRequestRecoveryKeyChildren;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:133.
  ///
  /// In fa, this message translates to:
  /// **'کلید بازیابی'**
  String get recoveryKeyDialogsRequestRecoveryKeyLabelText;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:152.
  ///
  /// In fa, this message translates to:
  /// **'کلید کامل و دقیق را وارد کنید.'**
  String get recoveryKeyDialogsRequestRecoveryKeyOnPressed;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:155.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی با این کلید'**
  String get recoveryKeyDialogsRequestRecoveryKeyActions;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:172.
  ///
  /// In fa, this message translates to:
  /// **'نسخه قدیمی وابسته به نصب'**
  String get recoveryKeyDialogsConfirmLegacyBackupTitle;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:174.
  ///
  /// In fa, this message translates to:
  /// **'این فایل قالب ۱ است و فقط با کلید نصب اصلی بازیابی می‌شود. کلید بازیابی جدید برای آن کار نمی‌کند. پس از حذف نصب یا از دست رفتن دستگاه ممکن است قابل بازیابی نباشد. فایل قدیمی بازنویسی نمی‌شود.'**
  String get recoveryKeyDialogsConfirmLegacyBackupContent;

  /// Application copy. Original usage: lib/features/backup/presentation/recovery_key_dialogs.dart:185.
  ///
  /// In fa, this message translates to:
  /// **'ادامه با کلید نصب اصلی'**
  String get recoveryKeyDialogsConfirmLegacyBackupActions;

  /// Application copy. Original usage: lib/features/calendar/application/holiday_package_service.dart:33.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ واردشدهٔ تعطیلات قابل بررسی نیست. دادهٔ قبلی حفظ شده است؛ برای بازیابی فایل با پشتیبانی تماس بگیرید.'**
  String get holidayPackageServiceLoadMessage;

  /// Application copy. Original usage: lib/features/calendar/application/holiday_package_service.dart:46.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ ذخیره‌شدهٔ تعطیلات معتبر نیست. بسته‌ها را از منبع مورد اعتماد دوباره وارد کنید.'**
  String get holidayPackageServiceLoadVerifiedMessage;

  /// Application copy. Original usage: lib/features/calendar/application/holiday_package_service.dart:69.
  ///
  /// In fa, this message translates to:
  /// **'امضای این بسته با ناشر مورد اعتماد شما یکسان نیست.'**
  String get holidayPackageServiceValidateReplacementMessage;

  /// Application copy. Original usage: lib/features/calendar/application/holiday_package_service.dart:76.
  ///
  /// In fa, this message translates to:
  /// **'این نسخه یا نسخهٔ جدیدتر این سال قبلاً نصب شده است.'**
  String get holidayPackageServiceValidateReplacementMessage2;

  /// Application copy. Original usage: lib/features/calendar/application/holiday_package_service.dart:87.
  ///
  /// In fa, this message translates to:
  /// **'ورود بستهٔ دیگری در حال انجام است.'**
  String get holidayPackageServiceInstallMessage;

  /// Application copy. Original usage: lib/features/calendar/application/holiday_package_service.dart:91.
  ///
  /// In fa, this message translates to:
  /// **'اعتماد به ناشر باید به‌صورت صریح تأیید شود.'**
  String get holidayPackageServiceInstallMessage2;

  /// Application copy. Original usage: lib/features/calendar/data/file_holiday_package_source.dart:12.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب بستهٔ تعطیلات'**
  String get fileHolidayPackageSourceResultDialogTitle;

  /// Application copy. Original usage: lib/features/calendar/data/file_holiday_package_source.dart:18.
  ///
  /// In fa, this message translates to:
  /// **'فایل انتخاب‌شده در دسترس نیست.'**
  String get fileHolidayPackageSourcePickMessage;

  /// Application copy. Original usage: lib/features/calendar/data/file_holiday_package_source.dart:22.
  ///
  /// In fa, this message translates to:
  /// **'حجم بسته بیش از حد مجاز است.'**
  String get fileHolidayPackageSourcePickMessage2;

  /// Application copy. Original usage: lib/features/calendar/data/sqlite_holiday_package_store.dart:63.
  ///
  /// In fa, this message translates to:
  /// **'ناشر یا نسخهٔ بسته با دادهٔ ذخیره‌شده سازگار نیست.'**
  String get sqliteHolidayPackageStoreSaveMessage;

  /// Application copy. Original usage: lib/features/calendar/data/sqlite_holiday_package_store.dart:81.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ تعطیلات هم‌زمان تغییر کرده است؛ دوباره تلاش کنید.'**
  String get sqliteHolidayPackageStoreSaveMessage2;

  /// Application copy. Original usage: lib/features/calendar/data/sqlite_holiday_package_store.dart:87.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ ذخیره‌شده معتبر نیست.'**
  String get sqliteHolidayPackageStoreSaveMessage3;

  /// Application copy. Original usage: lib/features/calendar/domain/holiday_data_package.dart:150.
  ///
  /// In fa, this message translates to:
  /// **'بسته معتبر نیست؛ امضا، ساختار یا پوشش کامل سال را بررسی کنید.'**
  String get holidayDataPackageVerifyMessage;

  /// Application copy. Original usage: lib/features/calendar/domain/holiday_provider.dart:60.
  ///
  /// In fa, this message translates to:
  /// **'تعطیلی هفتگی (جمعه)'**
  String get holidayProviderHolidaysForTitle;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_commitment_card.dart:77.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات رخداد در دسترس نیست.'**
  String get calendarCommitmentCardBuildChildren;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_commitment_card.dart:91.
  ///
  /// In fa, this message translates to:
  /// **'ساعت {value1}'**
  String calendarCommitmentCardBuildText(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_commitment_card.dart:92.
  ///
  /// In fa, this message translates to:
  /// **'تمام‌روز (بدون ساعت)'**
  String get calendarCommitmentCardBuildText2;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_commitment_card.dart:118.
  ///
  /// In fa, this message translates to:
  /// **'بدون یادآوری'**
  String get calendarCommitmentCardRemindersMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_commitment_card.dart:119.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری: {value1}'**
  String calendarCommitmentCardRemindersMessage2(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:200.
  ///
  /// In fa, this message translates to:
  /// **'ماه'**
  String get calendarPageToggleLabel;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:201.
  ///
  /// In fa, this message translates to:
  /// **'هفته'**
  String get calendarPageToggleLabel2;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:214.
  ///
  /// In fa, this message translates to:
  /// **'رفتن به تاریخ'**
  String get calendarPageDateButtonLabel;

  /// Calendar action returning to the current local date while preserving Month/Week mode. Short label approved 2026-10-14.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get calendarPageTodayButtonLabel;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:260.
  ///
  /// In fa, this message translates to:
  /// **'هفته قبل'**
  String get calendarPageBuildTooltip;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:272.
  ///
  /// In fa, this message translates to:
  /// **'هفته بعد'**
  String get calendarPageBuildTooltip2;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:316.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ تعطیلات رسمی این سال کامل نیست؛ تعطیلات قمری نمایش داده نمی‌شوند. نبودن نشان تعطیلی به معنی روز کاری قطعی نیست.'**
  String get calendarPageBuildChildren;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:323.
  ///
  /// In fa, this message translates to:
  /// **'در حال بارگذاری رخدادهای ماه…'**
  String get calendarPageBuildChildren2;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:329.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری رخدادهای ماه انجام نشد.'**
  String get calendarPageBuildChildren3;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:339.
  ///
  /// In fa, this message translates to:
  /// **'برای این ماه تعهدی ثبت نشده است.'**
  String get calendarPageBuildChildren4;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:345.
  ///
  /// In fa, this message translates to:
  /// **'نمایش فهرست روز انتخاب‌شده'**
  String get calendarPageBuildLabel;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:388.
  ///
  /// In fa, this message translates to:
  /// **'تعهد'**
  String get calendarPageMarkerPainterText;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:395.
  ///
  /// In fa, this message translates to:
  /// **'تعطیل'**
  String get calendarPageHolidayHeightMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:537.
  ///
  /// In fa, this message translates to:
  /// **'فهرست رخدادها هنوز در دسترس نیست.'**
  String get calendarPageBuildChildren5;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:539.
  ///
  /// In fa, this message translates to:
  /// **'برای این روز تعهدی ثبت نشده است.'**
  String get calendarPageBuildChildren6;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:581.
  ///
  /// In fa, this message translates to:
  /// **'تعطیل رسمی: {value1}'**
  String calendarPageHolidayLabelMessage(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:583.
  ///
  /// In fa, this message translates to:
  /// **'تعطیلی موردی ({value1}): {value2}'**
  String calendarPageCalendarHolidayKindSpecial(String value1, String value2);

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:651.
  ///
  /// In fa, this message translates to:
  /// **'، انتخاب‌شده'**
  String get calendarPageSelectionLabelMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:652.
  ///
  /// In fa, this message translates to:
  /// **'، امروز'**
  String get calendarPageTodayLabelMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:655.
  ///
  /// In fa, this message translates to:
  /// **'، {value1}'**
  String calendarPageHolidayLabelMessage2(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:657.
  ///
  /// In fa, this message translates to:
  /// **'بدون تعهد'**
  String get calendarPageCountLabelMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:657.
  ///
  /// In fa, this message translates to:
  /// **'{value1} تعهد'**
  String calendarPageCountLabelMessage2(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/calendar_page.dart:663.
  ///
  /// In fa, this message translates to:
  /// **'{value1}{value2}{value3}{value4}، {value5}، {value6}، نمایش فهرست روز'**
  String calendarPageBuildLabel2(
    String value1,
    String value2,
    String value3,
    String value4,
    String value5,
    String value6,
  );

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:37.
  ///
  /// In fa, this message translates to:
  /// **'تأیید بستهٔ تعطیلات'**
  String get holidayPackageSettingsCardApprovedTitle;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:44.
  ///
  /// In fa, this message translates to:
  /// **'سال {value1} · نسخه {value2}'**
  String holidayPackageSettingsCardApprovedChildren(
    String value1,
    String value2,
  );

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:46.
  ///
  /// In fa, this message translates to:
  /// **'منبع: {value1}'**
  String holidayPackageSettingsCardApprovedChildren2(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:47.
  ///
  /// In fa, this message translates to:
  /// **'اثر انگشت ناشر:'**
  String get holidayPackageSettingsCardApprovedChildren3;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:54.
  ///
  /// In fa, this message translates to:
  /// **'این ناشر هنوز مورد اعتماد شما نیست. اثر انگشت را از یک مسیر مستقل با ناشر بررسی کنید. تأیید، این کلید را برای بسته‌های بعدی مورد اعتماد قرار می‌دهد؛ امضا به معنی تأیید رسمی منبع نیست.'**
  String get holidayPackageSettingsCardApprovedChildren4;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:55.
  ///
  /// In fa, this message translates to:
  /// **'امضا با ناشر مورد اعتماد یکسان است. دادهٔ این سال جایگزین می‌شود.'**
  String get holidayPackageSettingsCardApprovedChildren5;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:58.
  ///
  /// In fa, this message translates to:
  /// **'رخدادها، یادآورها و سوابق شما تغییر نمی‌کنند. بسته‌ها در نسخهٔ پشتیبان شخصی نیستند؛ فایل اصلی را نگه دارید.'**
  String get holidayPackageSettingsCardApprovedChildren6;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'تأیید ناشر و ورود بسته'**
  String get holidayPackageSettingsCardApprovedActions;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'ورود بسته'**
  String get holidayPackageSettingsCardApprovedActions2;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:82.
  ///
  /// In fa, this message translates to:
  /// **'بستهٔ تعطیلات ذخیره شد و بدون اینترنت در دسترس است.'**
  String get holidayPackageSettingsCardImportMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:90.
  ///
  /// In fa, this message translates to:
  /// **'ورود بسته انجام نشد. فایل و فضای ذخیره‌سازی را بررسی کنید؛ دادهٔ قبلی حفظ شده است.'**
  String get holidayPackageSettingsCardImportMessage2;

  /// Holiday reference-data coverage in More; derived from effective validated annual data.
  ///
  /// In fa, this message translates to:
  /// **'سال‌ها و منابع تعطیلات'**
  String get holidayDataCoverageTitle;

  /// Holiday reference-data coverage in More; derived from effective validated annual data.
  ///
  /// In fa, this message translates to:
  /// **'سال‌های دارای پوشش کامل: {years}'**
  String holidayDataCoveredYears(String years);

  /// Holiday reference-data coverage in More; derived from effective validated annual data.
  ///
  /// In fa, this message translates to:
  /// **'سال {year}؛ {origin}'**
  String holidayDataYearOrigin(String year, String origin);

  /// Holiday reference-data coverage in More; derived from effective validated annual data.
  ///
  /// In fa, this message translates to:
  /// **'همراه برنامه'**
  String get holidayDataOriginBundled;

  /// Holiday reference-data coverage in More; derived from effective validated annual data.
  ///
  /// In fa, this message translates to:
  /// **'بستهٔ واردشده'**
  String get holidayDataOriginImported;

  /// Holiday reference-data coverage in More; derived from effective validated annual data.
  ///
  /// In fa, this message translates to:
  /// **'بازبینی {revision}'**
  String holidayDataRevision(String revision);

  /// Holiday reference-data coverage in More; derived from effective validated annual data.
  ///
  /// In fa, this message translates to:
  /// **'برای سال‌هایی که در این فهرست نیستند، پوشش کامل تعطیلات رسمی نداریم؛ نبود نشانهٔ تعطیلی به معنی روز کاری قطعی نیست.'**
  String get holidayDataMissingCoverage;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:104.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ تعطیلات'**
  String get holidayPackageSettingsCardBuildTitle;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:107.
  ///
  /// In fa, this message translates to:
  /// **'ورود سال‌های جدید بدون به‌روزرسانی برنامه'**
  String get holidayPackageSettingsCardBuildSubtitle;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:108.
  ///
  /// In fa, this message translates to:
  /// **'بسته‌های نصب‌شده: {value1}'**
  String holidayPackageSettingsCardBuildSubtitle2(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:127.
  ///
  /// In fa, this message translates to:
  /// **'در حال بررسی و ذخیرهٔ بسته'**
  String get holidayPackageSettingsCardBuildSemanticsLabel;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:130.
  ///
  /// In fa, this message translates to:
  /// **'در حال ورود بسته…'**
  String get holidayPackageSettingsCardBuildLabel;

  /// Application copy. Original usage: lib/features/calendar/presentation/holiday_package_settings_card.dart:130.
  ///
  /// In fa, this message translates to:
  /// **'ورود بسته از فایل'**
  String get holidayPackageSettingsCardBuildLabel2;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:58.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نمایش برنامه'**
  String get plannedOccurrenceWidgetsBuildTitle;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:60.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نمایش برنامه · '**
  String get plannedOccurrenceWidgetsBuildSubtitle;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:60.
  ///
  /// In fa, this message translates to:
  /// **'{value1}{value2} · {value3}'**
  String plannedOccurrenceWidgetsBuildSubtitle2(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:65.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نوبت'**
  String get plannedOccurrenceWidgetsBuildTooltip;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:157.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نوبت از پیش‌نمایش'**
  String get plannedOccurrenceWidgetsConfirmedTitle;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:159.
  ///
  /// In fa, this message translates to:
  /// **'این پیش‌نمایش هنوز نوبت ثبت‌شده نیست. با تأیید، نوبت و تنظیمات وابسته ثبت می‌شوند؛ نتیجه یا پرداختی ثبت نمی‌شود.'**
  String get plannedOccurrenceWidgetsConfirmedContent;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:168.
  ///
  /// In fa, this message translates to:
  /// **'تأیید و ثبت نوبت'**
  String get plannedOccurrenceWidgetsConfirmedActions;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:197.
  ///
  /// In fa, this message translates to:
  /// **'نوبت ثبت شد؛ تازه‌سازی انجام نشد. دوباره فهرست را بارگذاری کنید.'**
  String get plannedOccurrenceWidgetsPrepareContent;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:198.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نوبت انجام نشد؛ برنامه ممکن است تغییر کرده باشد. فهرست را دوباره بررسی کنید.'**
  String get plannedOccurrenceWidgetsPrepareContent2;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:214.
  ///
  /// In fa, this message translates to:
  /// **'نوبت ثبت شد؛ هماهنگ‌سازی یادآوری در انتظار است.'**
  String get plannedOccurrenceWidgetsPrepareContent3;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:215.
  ///
  /// In fa, this message translates to:
  /// **'نوبت ثبت شد.'**
  String get plannedOccurrenceWidgetsPrepareContent4;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:231.
  ///
  /// In fa, this message translates to:
  /// **'تعداد نهایی: تعیین نشده'**
  String get plannedOccurrenceWidgetsBuildChildren;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:232.
  ///
  /// In fa, this message translates to:
  /// **'تعداد کل برنامه: {value1} نوبت'**
  String plannedOccurrenceWidgetsBuildChildren2(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:236.
  ///
  /// In fa, this message translates to:
  /// **'پایان برنامه: تاریخ پایان تعیین نشده'**
  String get plannedOccurrenceWidgetsBuildChildren3;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:237.
  ///
  /// In fa, this message translates to:
  /// **'پایان برنامه: {value1}'**
  String plannedOccurrenceWidgetsBuildChildren4(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:240.
  ///
  /// In fa, this message translates to:
  /// **'محدودهٔ نمایش، تعداد کل یا پایان برنامه را تغییر نمی‌دهد.'**
  String get plannedOccurrenceWidgetsBuildChildren5;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:247.
  ///
  /// In fa, this message translates to:
  /// **'ماه قبل نوبت‌ها'**
  String get plannedOccurrenceWidgetsBuildTooltip2;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:268.
  ///
  /// In fa, this message translates to:
  /// **'محدودهٔ نوبت‌ها: {value1}'**
  String plannedOccurrenceWidgetsBuildChildren6(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:273.
  ///
  /// In fa, this message translates to:
  /// **'ماه بعد نوبت‌ها'**
  String get plannedOccurrenceWidgetsBuildTooltip3;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:289.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری نوبت‌ها انجام نشد.'**
  String get plannedOccurrenceWidgetsBuildChildren7;

  /// Application copy. Original usage: lib/features/calendar/presentation/planned_occurrence_widgets.dart:311.
  ///
  /// In fa, this message translates to:
  /// **'در این محدوده نوبتی وجود ندارد.'**
  String get plannedOccurrenceWidgetsBuildChildren8;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:154.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری هفته'**
  String get weekTimelineViewBuildSemanticsLabel;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:162.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری هفته انجام نشد.'**
  String get weekTimelineViewBuildChildren;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:242.
  ///
  /// In fa, this message translates to:
  /// **'۲۳:۵۹'**
  String get weekTimelineViewCardHeightMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:291.
  ///
  /// In fa, this message translates to:
  /// **'کارت‌ها زمان شروع را نشان می‌دهند؛ زمان پایان ثبت نشده است.'**
  String get weekTimelineViewContentChildren;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:295.
  ///
  /// In fa, this message translates to:
  /// **'برای این هفته رخدادی ثبت نشده است.'**
  String get weekTimelineViewContentChildren2;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:320.
  ///
  /// In fa, this message translates to:
  /// **'تمام‌روز'**
  String get weekTimelineViewContentChildren3;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:374.
  ///
  /// In fa, this message translates to:
  /// **'دادهٔ تعطیلات کامل نیست؛ نبود نشان تعطیلی به معنی روز کاری قطعی نیست.'**
  String get weekTimelineViewContentChildren4;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:524.
  ///
  /// In fa, this message translates to:
  /// **'{value1} · امروز'**
  String weekTimelineViewPainterText(String value1);

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:583.
  ///
  /// In fa, this message translates to:
  /// **' · امروز'**
  String get weekTimelineViewAgendaDelegate;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:583.
  ///
  /// In fa, this message translates to:
  /// **'{value1}{value2}'**
  String weekTimelineViewAgendaDelegate2(String value1, String value2);

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:670.
  ///
  /// In fa, this message translates to:
  /// **'رخدادی ثبت نشده است.'**
  String get weekTimelineViewAgendaEntriesMessage;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:774.
  ///
  /// In fa, this message translates to:
  /// **'زمان پایان ثبت نشده'**
  String get weekTimelineViewCardLabel;

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:774.
  ///
  /// In fa, this message translates to:
  /// **'{value1}، {value2}، {value3}، {value4}'**
  String weekTimelineViewCardLabel2(
    String value1,
    String value2,
    String value3,
    String value4,
  );

  /// Application copy. Original usage: lib/features/calendar/presentation/week_timeline_view.dart:885.
  ///
  /// In fa, this message translates to:
  /// **'زمان اکنون'**
  String get weekTimelineViewBuildLabel;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:89.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ و زمان شروع را انتخاب کنید.'**
  String get quickCaptureSheetErrorMessage;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:119.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تعهد انجام نشد؛ اطلاعات شما حفظ شده است. دوباره تلاش کنید.'**
  String get quickCaptureSheetSaveMessage;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:175.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تعهد'**
  String get quickCaptureSheetBuildPrimaryLabel;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:193.
  ///
  /// In fa, this message translates to:
  /// **'عنوان تعهد'**
  String get quickCaptureSheetBuildLabelText;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:194.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً کلاس زبان'**
  String get quickCaptureSheetBuildHintText;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:200.
  ///
  /// In fa, this message translates to:
  /// **'زمان‌بندی'**
  String get quickCaptureSheetBuildChildren;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:208.
  ///
  /// In fa, this message translates to:
  /// **'یادآور'**
  String get quickCaptureSheetBuildTitle;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:210.
  ///
  /// In fa, this message translates to:
  /// **'بدون یادآور'**
  String get quickCaptureSheetBuildSubtitle;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:218.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار جلسات'**
  String get quickCaptureSheetBuildTitle2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:220.
  ///
  /// In fa, this message translates to:
  /// **'بدون بستهٔ جلسه'**
  String get quickCaptureSheetBuildSubtitle2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:221.
  ///
  /// In fa, this message translates to:
  /// **'{value1} جلسه اعتبار'**
  String quickCaptureSheetBuildSubtitle3(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:227.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات مالی'**
  String get quickCaptureSheetBuildTitle3;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:229.
  ///
  /// In fa, this message translates to:
  /// **'بدون انتظار مالی'**
  String get quickCaptureSheetCommitmentFinancialMeaningNone;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:231.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت مورد انتظار'**
  String get quickCaptureSheetCommitmentFinancialMeaningPaymentRequired;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:233.
  ///
  /// In fa, this message translates to:
  /// **'دریافت مورد انتظار'**
  String get quickCaptureSheetCommitmentFinancialMeaningReceivable;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:240.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات بیشتر'**
  String get quickCaptureSheetBuildTitle4;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:241.
  ///
  /// In fa, this message translates to:
  /// **'توضیحات، اولویت، رنگ و برچسب‌ها'**
  String get quickCaptureSheetBuildSubtitle4;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:286.
  ///
  /// In fa, this message translates to:
  /// **'توضیحات (اختیاری)'**
  String get quickCaptureSheetDetailFieldsLabelText;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:351.
  ///
  /// In fa, this message translates to:
  /// **'نوع برنامه'**
  String get quickCaptureSheetScheduleFieldsLabelText;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:374.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تاریخ'**
  String get quickCaptureSheetScheduleFieldsLabel;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:386.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب زمان'**
  String get quickCaptureSheetScheduleFieldsLabel2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:397.
  ///
  /// In fa, this message translates to:
  /// **'تکرار'**
  String get quickCaptureSheetScheduleFieldsLabelText2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:401.
  ///
  /// In fa, this message translates to:
  /// **'روزانه'**
  String get recurrenceDaily;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:405.
  ///
  /// In fa, this message translates to:
  /// **'هفتگی'**
  String get recurrenceWeekly;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:409.
  ///
  /// In fa, this message translates to:
  /// **'ماهانه'**
  String get recurrenceMonthly;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:413.
  ///
  /// In fa, this message translates to:
  /// **'سالانه'**
  String get recurrenceYearly;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:426.
  ///
  /// In fa, this message translates to:
  /// **'تقویم تکرار'**
  String get quickCaptureSheetScheduleFieldsLabelText3;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:430.
  ///
  /// In fa, this message translates to:
  /// **'شمسی'**
  String get quickCaptureSheetScheduleFieldsItems;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:434.
  ///
  /// In fa, this message translates to:
  /// **'میلادی'**
  String get quickCaptureSheetScheduleFieldsItems2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:442.
  ///
  /// In fa, this message translates to:
  /// **'روز و ماه از تاریخ شروع در تقویم تکرار گرفته می‌شود. اگر روز در ماه مقصد وجود نداشته باشد، آخرین روز همان ماه انتخاب می‌شود؛ روز اصلی برای نوبت‌های بعد حفظ می‌شود. نمایش تاریخ‌ها همیشه شمسی است.'**
  String get quickCaptureSheetScheduleFieldsChildren;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:476.
  ///
  /// In fa, this message translates to:
  /// **'پایان تکرار'**
  String get quickCaptureSheetScheduleFieldsLabelText4;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:480.
  ///
  /// In fa, this message translates to:
  /// **'بدون پایان'**
  String get quickCaptureSheetScheduleFieldsItems3;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:484.
  ///
  /// In fa, this message translates to:
  /// **'تا تاریخ مشخص'**
  String get quickCaptureSheetScheduleFieldsItems4;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:488.
  ///
  /// In fa, this message translates to:
  /// **'تعداد مشخص'**
  String get quickCaptureSheetScheduleFieldsItems5;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:496.
  ///
  /// In fa, this message translates to:
  /// **'نوبت‌های آینده در بازهٔ محدود ساخته می‌شوند و با بازکردن یا بازگشت به برنامه ادامه می‌یابند؛ تعداد ساخته‌شده به معنی پایان تکرار نیست.'**
  String get quickCaptureSheetScheduleFieldsChildren2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:505.
  ///
  /// In fa, this message translates to:
  /// **'تعداد نوبت‌ها'**
  String get quickCaptureSheetScheduleFieldsLabelText5;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:526.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تاریخ پایان'**
  String get quickCaptureSheetScheduleFieldsLabel3;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:539.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌های این تعهد'**
  String get quickCaptureSheetReminderPickerChildren;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:541.
  ///
  /// In fa, this message translates to:
  /// **'می‌توانید چند یادآوری، پیش از زمان هر نوبت ثبت کنید.'**
  String get quickCaptureSheetReminderPickerChildren2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:557.
  ///
  /// In fa, this message translates to:
  /// **'زمان دلخواه'**
  String get quickCaptureSheetReminderPickerLabel;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:577.
  ///
  /// In fa, this message translates to:
  /// **'حذف یادآوری'**
  String get quickCaptureSheetReminderPickerTooltip;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:617.
  ///
  /// In fa, this message translates to:
  /// **'{value1} روز قبل'**
  String quickCaptureSheetReminderLabelMessage(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:620.
  ///
  /// In fa, this message translates to:
  /// **'{value1} ساعت قبل'**
  String quickCaptureSheetReminderLabelMessage2(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:622.
  ///
  /// In fa, this message translates to:
  /// **'{value1} دقیقه قبل'**
  String quickCaptureSheetReminderLabelMessage3(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:631.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار جلسه'**
  String get quickCaptureSheetEntitlementFieldsLabelText;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:635.
  ///
  /// In fa, this message translates to:
  /// **'بدون بسته'**
  String get quickCaptureSheetEntitlementFieldsItems;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:639.
  ///
  /// In fa, this message translates to:
  /// **'تعداد ثابت جلسه'**
  String get quickCaptureSheetEntitlementFieldsItems2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:652.
  ///
  /// In fa, this message translates to:
  /// **'تعداد جلسه'**
  String get quickCaptureSheetEntitlementFieldsLabelText2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:657.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار جلسات مستقل از تعداد نوبت‌های زمان‌بندی‌شده است.'**
  String get quickCaptureSheetEntitlementFieldsChildren;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:672.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ مورد انتظار به {value1}'**
  String quickCaptureSheetFinancialFieldsLabelText(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:678.
  ///
  /// In fa, this message translates to:
  /// **'معنای مالی (فقط انتظار مالی، بدون ثبت خودکار تراکنش)'**
  String get quickCaptureSheetFinancialFieldsChildren;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:684.
  ///
  /// In fa, this message translates to:
  /// **'ندارد'**
  String get quickCaptureSheetFinancialFieldsLabel;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:688.
  ///
  /// In fa, this message translates to:
  /// **'پرداختی'**
  String get quickCaptureSheetFinancialFieldsLabel2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:692.
  ///
  /// In fa, this message translates to:
  /// **'دریافتی'**
  String get quickCaptureSheetFinancialFieldsLabel3;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:707.
  ///
  /// In fa, this message translates to:
  /// **'خلاصهٔ تعهد'**
  String get quickCaptureSheetSummaryChildren;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:720.
  ///
  /// In fa, this message translates to:
  /// **'شروع: {value1}'**
  String quickCaptureSheetSummaryChildren2(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:724.
  ///
  /// In fa, this message translates to:
  /// **'ساعت: {value1}'**
  String quickCaptureSheetSummaryChildren3(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:728.
  ///
  /// In fa, this message translates to:
  /// **'روزها: {value1}'**
  String quickCaptureSheetSummaryChildren4(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:737.
  ///
  /// In fa, this message translates to:
  /// **'پایان: {value1}'**
  String quickCaptureSheetSummaryChildren5(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:741.
  ///
  /// In fa, this message translates to:
  /// **'یادآور: {value1}'**
  String quickCaptureSheetSummaryChildren6(String value1);

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:748.
  ///
  /// In fa, this message translates to:
  /// **'کلاس / دوره'**
  String get quickCaptureSheetCommitmentCategoryClassCourse;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:749.
  ///
  /// In fa, this message translates to:
  /// **'قرار / جلسه'**
  String get quickCaptureSheetCommitmentCategoryAppointment;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:750.
  ///
  /// In fa, this message translates to:
  /// **'فعالیت شخصی تکرارشونده'**
  String get quickCaptureSheetCommitmentCategoryPersonalRecurring;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:751.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک / خدمت پولی'**
  String get quickCaptureSheetCommitmentCategorySubscription;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:752.
  ///
  /// In fa, this message translates to:
  /// **'سایر'**
  String get quickCaptureSheetCommitmentCategoryOther;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:774.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری دلخواه'**
  String get quickCaptureSheetBuildTitle5;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:781.
  ///
  /// In fa, this message translates to:
  /// **'چند دقیقه قبل؟'**
  String get quickCaptureSheetBuildLabelText2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:782.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً ۹۰'**
  String get quickCaptureSheetBuildHintText2;

  /// Application copy. Original usage: lib/features/capture/presentation/quick_capture_sheet.dart:797.
  ///
  /// In fa, this message translates to:
  /// **'افزودن'**
  String get quickCaptureSheetBuildActions;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:71.
  ///
  /// In fa, this message translates to:
  /// **'خواندن برچسب‌ها انجام نشد؛ دوباره تلاش کنید.'**
  String get tagControlsLoadMessage;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:89.
  ///
  /// In fa, this message translates to:
  /// **'نام برچسب را وارد کنید.'**
  String get tagControlsAddMessage;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:112.
  ///
  /// In fa, this message translates to:
  /// **'برچسب‌ها (اختیاری)'**
  String get tagControlsBuildChildren;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:116.
  ///
  /// In fa, this message translates to:
  /// **'برچسب‌ها همراه با ثبت نهایی ذخیره می‌شوند؛ انصراف تغییری ایجاد نمی‌کند.'**
  String get tagControlsBuildChildren2;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:151.
  ///
  /// In fa, this message translates to:
  /// **'برچسب جدید'**
  String get tagControlsBuildLabelText;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:157.
  ///
  /// In fa, this message translates to:
  /// **'افزودن برچسب به پیش‌نویس'**
  String get tagControlsBuildLabel;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:184.
  ///
  /// In fa, this message translates to:
  /// **'همهٔ برچسب‌ها'**
  String get tagControlsBuildLabel2;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:330.
  ///
  /// In fa, this message translates to:
  /// **'برچسب‌ها به‌روز شدند.'**
  String get tagControlsMutateContent;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:336.
  ///
  /// In fa, this message translates to:
  /// **'تغییر ذخیره شد؛ نمایش اطلاعات به‌روز نشد. دوباره تلاش کنید.'**
  String get tagControlsMutateMessage;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:337.
  ///
  /// In fa, this message translates to:
  /// **'تغییر برچسب انجام نشد؛ نام تکراری یا نامعتبر را بررسی و دوباره تلاش کنید.'**
  String get tagControlsMutateMessage2;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:365.
  ///
  /// In fa, this message translates to:
  /// **'تغییر نام برچسب'**
  String get tagControlsLabelTitle;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:369.
  ///
  /// In fa, this message translates to:
  /// **'نام برچسب'**
  String get tagControlsLabelLabelText;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:396.
  ///
  /// In fa, this message translates to:
  /// **'حذف برچسب از همهٔ موارد؟'**
  String get tagControlsConfirmedTitle;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:398.
  ///
  /// In fa, this message translates to:
  /// **'برچسب {value1} و اتصال آن به همهٔ تعهدها و تراکنش‌ها حذف می‌شود. خود تعهدها و تراکنش‌ها باقی می‌مانند. این کار قابل بازگردانی نیست.'**
  String tagControlsConfirmedContent(String value1);

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:407.
  ///
  /// In fa, this message translates to:
  /// **'حذف از همهٔ موارد'**
  String get tagControlsConfirmedActions;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:424.
  ///
  /// In fa, this message translates to:
  /// **'مدیریت برچسب‌ها'**
  String get tagControlsContentChildren;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:424.
  ///
  /// In fa, this message translates to:
  /// **'برچسب‌های این مورد'**
  String get tagControlsContentChildren2;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:430.
  ///
  /// In fa, this message translates to:
  /// **'تغییر برچسب‌ها بلافاصله ذخیره می‌شود؛ نیازی به ذخیرهٔ فرم نیست.'**
  String get tagControlsContentChildren3;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:444.
  ///
  /// In fa, this message translates to:
  /// **'هنوز برچسبی ندارید؛ یک برچسب بسازید.'**
  String get tagControlsContentChildren4;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:455.
  ///
  /// In fa, this message translates to:
  /// **'برداشتن از این مورد'**
  String get tagControlsContentTooltip;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:456.
  ///
  /// In fa, this message translates to:
  /// **'افزودن به این مورد'**
  String get tagControlsContentTooltip2;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:482.
  ///
  /// In fa, this message translates to:
  /// **'تغییر نام {value1}'**
  String tagControlsContentTooltip3(String value1);

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:487.
  ///
  /// In fa, this message translates to:
  /// **'حذف سراسری {value1}'**
  String tagControlsContentTooltip4(String value1);

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:505.
  ///
  /// In fa, this message translates to:
  /// **'ساخت برچسب'**
  String get tagControlsContentLabel;

  /// Application copy. Original usage: lib/features/classification/presentation/tag_controls.dart:505.
  ///
  /// In fa, this message translates to:
  /// **'ساخت و افزودن برچسب'**
  String get tagControlsContentLabel2;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:119.
  ///
  /// In fa, this message translates to:
  /// **'عنوان تعهد را وارد کنید.'**
  String get commitmentTitleRequired;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:127.
  ///
  /// In fa, this message translates to:
  /// **'حداقل یک روز هفته را انتخاب کنید.'**
  String get commitmentDraftValidateForStepMessage;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:132.
  ///
  /// In fa, this message translates to:
  /// **'تعداد جلسهٔ معتبر را وارد کنید.'**
  String get commitmentDraftValidateForStepMessage2;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:137.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ مورد انتظار را وارد کنید.'**
  String get commitmentDraftValidateForStepMessage3;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:142.
  ///
  /// In fa, this message translates to:
  /// **'تعداد تکرار را وارد کنید.'**
  String get commitmentDraftValidateForStepMessage4;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:147.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ پایان را انتخاب کنید.'**
  String get commitmentDraftValidateForStepMessage5;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:153.
  ///
  /// In fa, this message translates to:
  /// **'تعداد تکرار باید مثبت باشد.'**
  String get commitmentDraftValidateForStepMessage6;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:161.
  ///
  /// In fa, this message translates to:
  /// **'پایان برنامه نمی‌تواند قبل از شروع باشد.'**
  String get commitmentDraftValidateForStepMessage7;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:168.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ انتخاب‌شده'**
  String get commitmentDraftScheduleMessage;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:168.
  ///
  /// In fa, this message translates to:
  /// **'زمان انتخاب‌شده'**
  String get commitmentDraftScheduleMessage2;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:168.
  ///
  /// In fa, this message translates to:
  /// **'یک‌بار در {value1}'**
  String commitmentDraftScheduleMessage3(String value1);

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:169.
  ///
  /// In fa, this message translates to:
  /// **'تقویم میلادی'**
  String get commitmentDraftScheduleMessage4;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:169.
  ///
  /// In fa, this message translates to:
  /// **'تقویم شمسی'**
  String get commitmentDraftScheduleMessage5;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:172.
  ///
  /// In fa, this message translates to:
  /// **'تا تاریخ پایان انتخاب‌شده'**
  String get commitmentDraftRecurrenceTerminationEndDate;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:171.
  ///
  /// In fa, this message translates to:
  /// **'{value1} نوبت'**
  String commitmentDraftRecurrenceTerminationCount(String value1);

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:169.
  ///
  /// In fa, this message translates to:
  /// **'تکرار {value1} · {value2} · {value3}'**
  String commitmentDraftScheduleMessage6(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:176.
  ///
  /// In fa, this message translates to:
  /// **'بدون محدودیت تعداد جلسه'**
  String get commitmentDraftEntitlementDraftUnlimited;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:178.
  ///
  /// In fa, this message translates to:
  /// **'{value1} جلسه'**
  String commitmentDraftEntitlementDraftFixedUnits(String value1);

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:179.
  ///
  /// In fa, this message translates to:
  /// **'معتبر تا تاریخ انتخاب‌شده'**
  String get commitmentDraftEntitlementDraftValidUntil;

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:184.
  ///
  /// In fa, this message translates to:
  /// **'{value1} ریال'**
  String commitmentDraftCommitmentFinancialMeaningPaymentRequired(
    String value1,
  );

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:184.
  ///
  /// In fa, this message translates to:
  /// **'نیازمند پرداخت ({value1})'**
  String commitmentDraftCommitmentFinancialMeaningPaymentRequired2(
    String value1,
  );

  /// Application copy. Original usage: lib/features/commitments/application/commitment_draft.dart:186.
  ///
  /// In fa, this message translates to:
  /// **'دارای دریافتی مورد انتظار ({value1})'**
  String commitmentDraftCommitmentFinancialMeaningReceivable(String value1);

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:79.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات تغییر کرده است؛ پیش‌نمایش را دوباره بررسی کنید.'**
  String get driftCommitmentCorrectionRepositoryConfirmMessage;

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:165.
  ///
  /// In fa, this message translates to:
  /// **'یک اصلاح مستقل و دلیل آن را وارد کنید.'**
  String get driftCommitmentCorrectionRepositoryPrepareMessage;

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:172.
  ///
  /// In fa, this message translates to:
  /// **'تعهد فعال و برنامهٔ ثبت‌شده لازم است.'**
  String get driftCommitmentCorrectionRepositoryPrepareMessage2;

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:191.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح اعتبار معتبر نیست یا از اعتبار باقی‌مانده بیشتر است.'**
  String get driftCommitmentCorrectionRepositoryPrepareMessage3;

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:227.
  ///
  /// In fa, this message translates to:
  /// **'فقط تعداد برنامهٔ شمارشی قابل اصلاح است؛ تعداد جدید باید متفاوت و بین ۱ تا ۱۰۰۰ باشد.'**
  String get driftCommitmentCorrectionRepositoryPrepareMessage4;

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:268.
  ///
  /// In fa, this message translates to:
  /// **'این الگوی تکرار در اصلاح تعداد پشتیبانی نمی‌شود.'**
  String get driftCommitmentCorrectionRepositoryPrepareMessage5;

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:286.
  ///
  /// In fa, this message translates to:
  /// **'کاهش تعداد با نوبت گذشته، دستی، پرداخت یا مصرف ثبت‌شده سازگار نیست.'**
  String get driftCommitmentCorrectionRepositoryPrepareMessage6;

  /// Application copy. Original usage: lib/features/commitments/data/drift_commitment_correction_repository.dart:296.
  ///
  /// In fa, this message translates to:
  /// **'افزایش تعداد نباید نوبت لغوشده را بازنویسی کند.'**
  String get driftCommitmentCorrectionRepositoryPrepareMessage7;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_color_picker.dart:24.
  ///
  /// In fa, this message translates to:
  /// **'رنگ تعهد (اختیاری)'**
  String get commitmentColorPickerBuildChildren;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_color_picker.dart:33.
  ///
  /// In fa, this message translates to:
  /// **'خودکار'**
  String get commitmentColorPickerBuildLabel;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_color_picker.dart:54.
  ///
  /// In fa, this message translates to:
  /// **'رنگ فقط برای شناسایی تعهد است؛ وضعیت را تغییر نمی‌دهد.'**
  String get commitmentColorPickerBuildChildren2;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:58.
  ///
  /// In fa, this message translates to:
  /// **'عدد معتبر وارد کنید.'**
  String get commitmentCorrectionCardPreviewMessage;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:72.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نمایش اصلاح'**
  String get commitmentCorrectionCardConfirmedTitle;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:79.
  ///
  /// In fa, this message translates to:
  /// **'تعهد دارای سابقه است؛ سوابق محفوظ می‌مانند.'**
  String get commitmentCorrectionCardConfirmedChildren;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:80.
  ///
  /// In fa, this message translates to:
  /// **'تعهد ثبت‌شده بدون سابقهٔ نتیجه؛ این اصلاح ثبت می‌شود.'**
  String get commitmentCorrectionCardConfirmedChildren2;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:83.
  ///
  /// In fa, this message translates to:
  /// **'تعداد برنامه: {value1} ← {value2}'**
  String commitmentCorrectionCardConfirmedChildren3(
    String value1,
    String value2,
  );

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:86.
  ///
  /// In fa, this message translates to:
  /// **'نوبت آیندهٔ افزوده در بازهٔ تولید: {value1}'**
  String commitmentCorrectionCardConfirmedChildren4(String value1);

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:88.
  ///
  /// In fa, this message translates to:
  /// **'نوبت آیندهٔ لغوشده: {value1}'**
  String commitmentCorrectionCardConfirmedChildren5(String value1);

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:90.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار باقی‌مانده: {value1} ← {value2}'**
  String commitmentCorrectionCardConfirmedChildren6(
    String value1,
    String value2,
  );

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:94.
  ///
  /// In fa, this message translates to:
  /// **'فقط اعتبار بسته اصلاح می‌شود؛ برنامه و مصرف قبلی تغییر نمی‌کنند.'**
  String get commitmentCorrectionCardConfirmedChildren7;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:95.
  ///
  /// In fa, this message translates to:
  /// **'از فردا؛ الگوی تکرار و نوبت‌های محافظت‌شده تغییر نمی‌کنند. اعتبار بسته تغییر نمی‌کند.'**
  String get commitmentCorrectionCardConfirmedChildren8;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:98.
  ///
  /// In fa, this message translates to:
  /// **'هیچ سابقه‌ای حذف نمی‌شود. اصلاح بعدی نیاز به تأیید جداگانه دارد.'**
  String get commitmentCorrectionCardConfirmedChildren9;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'تأیید اصلاح'**
  String get commitmentCorrectionCardConfirmedActions;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:132.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح ثبت شد؛ هماهنگ‌سازی یا بازخوانی در انتظار است. صفحه را دوباره باز کنید.'**
  String get commitmentCorrectionCardPreviewMessage2;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:133.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح ثبت شد؛ سوابق قبلی محفوظ است.'**
  String get commitmentCorrectionCardPreviewMessage3;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:141.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح انجام نشد؛ ورودی‌ها محفوظ است. دوباره تلاش کنید.'**
  String get commitmentCorrectionCardPreviewMessage4;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:154.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح تعداد برنامه یا اعتبار بسته'**
  String get commitmentCorrectionCardBuildTitle;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:156.
  ///
  /// In fa, this message translates to:
  /// **'آزمایشی: اصلاح تعداد فقط برای برنامهٔ شمارشی و از فردا؛ اعتبار بسته مستقل است.'**
  String get commitmentCorrectionCardBuildSubtitle;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:166.
  ///
  /// In fa, this message translates to:
  /// **'نوع اصلاح'**
  String get commitmentCorrectionCardBuildLabelText;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:170.
  ///
  /// In fa, this message translates to:
  /// **'تعداد نوبت‌های برنامه'**
  String get commitmentCorrectionCardBuildItems;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:174.
  ///
  /// In fa, this message translates to:
  /// **'افزایش یا کاهش اعتبار بسته'**
  String get commitmentCorrectionCardBuildItems2;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:193.
  ///
  /// In fa, this message translates to:
  /// **'تغییر اعتبار (مثلاً ۲ یا ۲-)'**
  String get commitmentCorrectionCardBuildLabelText2;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:194.
  ///
  /// In fa, this message translates to:
  /// **'تعداد کل جدید برنامه'**
  String get commitmentCorrectionCardBuildLabelText3;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:200.
  ///
  /// In fa, this message translates to:
  /// **'دلیل اصلاح'**
  String get commitmentCorrectionCardBuildLabelText4;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:218.
  ///
  /// In fa, this message translates to:
  /// **'بازخوانی سوابق اصلاح'**
  String get commitmentCorrectionCardBuildBuilder;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:223.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح ثبت‌شده‌ای وجود ندارد.'**
  String get commitmentCorrectionCardBuildBuilder2;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:226.
  ///
  /// In fa, this message translates to:
  /// **'سوابق اصلاح'**
  String get commitmentCorrectionCardBuildTitle2;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:232.
  ///
  /// In fa, this message translates to:
  /// **'{value1}\nتعداد: {value2} ← {value3}\nاعتبار: {value4} ← {value5}'**
  String commitmentCorrectionCardBuildSubtitle2(
    String value1,
    String value2,
    String value3,
    String value4,
    String value5,
  );

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_correction_card.dart:244.
  ///
  /// In fa, this message translates to:
  /// **'بررسی اثر اصلاح'**
  String get commitmentCorrectionCardBuildChildren;

  /// Application copy. Original usage: lib/features/commitments/presentation/commitment_identity_marker.dart:27.
  ///
  /// In fa, this message translates to:
  /// **'رنگ تعهد: {value1}'**
  String commitmentIdentityMarkerBuildLabel(String value1);

  /// Application copy. Original usage: lib/features/finance/domain/account_identifiers.dart:38.
  ///
  /// In fa, this message translates to:
  /// **'شماره کارت باید ۱۶ رقم باشد.'**
  String get accountIdentifiersCardErrorMessage;

  /// Application copy. Original usage: lib/features/finance/domain/account_identifiers.dart:48.
  ///
  /// In fa, this message translates to:
  /// **'شماره کارت معتبر نیست.'**
  String get accountIdentifiersCardErrorMessage2;

  /// Application copy. Original usage: lib/features/finance/domain/account_identifiers.dart:55.
  ///
  /// In fa, this message translates to:
  /// **'شبا باید IR و ۲۴ رقم داشته باشد.'**
  String get accountIdentifiersIbanErrorMessage;

  /// Application copy. Original usage: lib/features/finance/domain/account_identifiers.dart:62.
  ///
  /// In fa, this message translates to:
  /// **'شماره شبا معتبر نیست.'**
  String get accountIdentifiersIbanErrorMessage2;

  /// Application copy. Original usage: lib/features/finance/domain/account_identifiers.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'شماره حساب باید بین ۱ تا ۳۰ رقم باشد.'**
  String get accountIdentifiersAccountErrorMessage;

  /// Application copy. Original usage: lib/features/finance/domain/finance_reports.dart:111.
  ///
  /// In fa, this message translates to:
  /// **'بدون دسته‌بندی'**
  String get financeReportsKeyMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:125.
  ///
  /// In fa, this message translates to:
  /// **'افزودن حساب انجام نشد؛ ورودی‌ها حفظ شدند. دوباره تلاش کنید.'**
  String get accountFormSheetSaveMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:126.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش انجام نشد؛ ممکن است حساب تغییر کرده باشد. دوباره تلاش کنید یا فرم را ببندید و از نو باز کنید.'**
  String get accountFormSheetSaveMessage2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:136.
  ///
  /// In fa, this message translates to:
  /// **'افزودن حساب'**
  String get accountFormSheetBuildTitle;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:136.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش حساب'**
  String get accountFormSheetBuildTitle2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:149.
  ///
  /// In fa, this message translates to:
  /// **'نام حساب'**
  String get accountFormSheetBuildLabelText;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:151.
  ///
  /// In fa, this message translates to:
  /// **'نام حساب را وارد کنید.'**
  String get accountFormSheetBuildValidator;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:157.
  ///
  /// In fa, this message translates to:
  /// **'نوع حساب'**
  String get accountFormSheetBuildLabelText2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:181.
  ///
  /// In fa, this message translates to:
  /// **'موجودی اولیه (اختیاری)'**
  String get accountFormSheetBuildLabelText3;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:186.
  ///
  /// In fa, this message translates to:
  /// **'موجودی اولیه معتبر نیست.'**
  String get accountFormSheetBuildValidator2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:191.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات حساب (اختیاری)'**
  String get accountFormSheetBuildTitle3;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:195.
  ///
  /// In fa, this message translates to:
  /// **'این اطلاعات فقط برای شناسایی حساب است؛ رمز، PIN یا CVV وارد نکنید.'**
  String get accountFormSheetBuildChildren;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:201.
  ///
  /// In fa, this message translates to:
  /// **'بانک (اختیاری)'**
  String get accountFormSheetBuildLabelText4;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:205.
  ///
  /// In fa, this message translates to:
  /// **'بدون انتخاب'**
  String get commonNoSelection;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:219.
  ///
  /// In fa, this message translates to:
  /// **'شماره کارت (اختیاری)'**
  String get accountFormSheetBuildChildren2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:226.
  ///
  /// In fa, this message translates to:
  /// **'شماره شبا (اختیاری)'**
  String get accountFormSheetBuildChildren3;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:234.
  ///
  /// In fa, this message translates to:
  /// **'شماره حساب (اختیاری)'**
  String get accountFormSheetBuildChildren4;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:263.
  ///
  /// In fa, this message translates to:
  /// **'نمایش'**
  String get accountFormSheetIdentifierTooltip;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:263.
  ///
  /// In fa, this message translates to:
  /// **'پنهان کردن'**
  String get accountFormSheetIdentifierTooltip2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:263.
  ///
  /// In fa, this message translates to:
  /// **'{value1} {value2}'**
  String accountFormSheetIdentifierTooltip3(String value1, String value2);

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:281.
  ///
  /// In fa, this message translates to:
  /// **'بانکی'**
  String get accountFormSheetFinancialAccountTypeBank;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:282.
  ///
  /// In fa, this message translates to:
  /// **'نقدی'**
  String get accountFormSheetFinancialAccountTypeCash;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:283.
  ///
  /// In fa, this message translates to:
  /// **'کیف پول'**
  String get accountFormSheetFinancialAccountTypeDigitalWallet;

  /// Application copy. Original usage: lib/features/finance/presentation/account_form_sheet.dart:284.
  ///
  /// In fa, this message translates to:
  /// **'اعتباری'**
  String get accountFormSheetFinancialAccountTypeCredit;

  /// Application copy. Original usage: lib/features/finance/presentation/account_identity_icon.dart:25.
  ///
  /// In fa, this message translates to:
  /// **'نشان بانک {value1}'**
  String accountIdentityIconBuildSemanticLabel(String value1);

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:65.
  ///
  /// In fa, this message translates to:
  /// **'کپی اطلاعات حساب'**
  String get accountInformationCardApprovedTitle;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:67.
  ///
  /// In fa, this message translates to:
  /// **'این شناسه در کلیپ‌بورد دستگاه قرار می‌گیرد و ممکن است برنامه‌های دیگر یا همگام‌سازی دستگاه به آن دسترسی داشته باشند. ادامه می‌دهید؟'**
  String get accountInformationCardApprovedContent;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:76.
  ///
  /// In fa, this message translates to:
  /// **'تأیید کپی'**
  String get accountInformationCardApprovedActions;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:87.
  ///
  /// In fa, this message translates to:
  /// **'شناسه کپی شد؛ اطلاعات کلیپ‌بورد را پس از استفاده پاک کنید.'**
  String get accountInformationCardCopyMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:91.
  ///
  /// In fa, this message translates to:
  /// **'کپی انجام نشد؛ دوباره تلاش کنید.'**
  String get accountInformationCardCopyMessage2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:126.
  ///
  /// In fa, this message translates to:
  /// **'بانک {value1}'**
  String accountInformationCardBuildChildren(String value1);

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:133.
  ///
  /// In fa, this message translates to:
  /// **'موجودی دفتر حساب'**
  String get accountInformationCardBuildChildren2;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:143.
  ///
  /// In fa, this message translates to:
  /// **'شماره کارت'**
  String get accountInformationCardBuildChildren3;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:145.
  ///
  /// In fa, this message translates to:
  /// **'شماره شبا'**
  String get accountInformationCardBuildChildren4;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:147.
  ///
  /// In fa, this message translates to:
  /// **'شماره حساب'**
  String get accountInformationCardBuildChildren5;

  /// Application copy. Original usage: lib/features/finance/presentation/account_information_card.dart:189.
  ///
  /// In fa, this message translates to:
  /// **'کپی {value1}'**
  String accountInformationCardIdentifierLabel(String value1);

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:59.
  ///
  /// In fa, this message translates to:
  /// **'حساب‌های مالی'**
  String get financePageBuildTitle;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:163.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری اطلاعات مالی انجام نشد. دوباره تلاش کنید.'**
  String get financePageRefreshMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:186.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر برچسب انجام نشد؛ دوباره تلاش کنید.'**
  String get financePageFilterTagMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:227.
  ///
  /// In fa, this message translates to:
  /// **'حساب افزوده شد.'**
  String get financePageAccountFormMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:227.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات حساب ذخیره شد.'**
  String get financePageAccountFormMessage2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:234.
  ///
  /// In fa, this message translates to:
  /// **'حساب ذخیره شد؛ تازه‌سازی نمایش‌های مرتبط انجام نشد.'**
  String get financePageAccountFormMessage3;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:267.
  ///
  /// In fa, this message translates to:
  /// **'ثبت درآمد / واریز'**
  String get financePageResultTitle;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:267.
  ///
  /// In fa, this message translates to:
  /// **'ثبت هزینه'**
  String get financePageResultTitle2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:268.
  ///
  /// In fa, this message translates to:
  /// **'ثبت'**
  String get financePageResultPrimaryLabel;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:275.
  ///
  /// In fa, this message translates to:
  /// **'حساب مالی را انتخاب کنید.'**
  String get financePageResultOnPrimary;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:284.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ معتبر وارد کنید.'**
  String get financePageResultOnPrimary2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:303.
  ///
  /// In fa, this message translates to:
  /// **'دریافت'**
  String get financePageResultCategory;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:303.
  ///
  /// In fa, this message translates to:
  /// **'عمومی'**
  String get commonGeneral;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:318.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تراکنش انجام نشد؛ اطلاعات شما حفظ شده است. دوباره تلاش کنید.'**
  String get financePageResultOnPrimary3;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:347.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ به {value1}'**
  String financePageResultLabelText(String value1);

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:353.
  ///
  /// In fa, this message translates to:
  /// **'شرح درآمد'**
  String get financePageResultLabelText2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:353.
  ///
  /// In fa, this message translates to:
  /// **'شرح هزینه'**
  String get financePageResultLabelText3;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:446.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش ثبت شد.'**
  String get financePageRecordTransactionMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:453.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تراکنش انجام نشد؛ دوباره تلاش کنید.'**
  String get financePageRecordTransactionMessage2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:469.
  ///
  /// In fa, this message translates to:
  /// **'حذف امن تراکنش'**
  String get financePageConfirmedTitle;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:471.
  ///
  /// In fa, this message translates to:
  /// **'این تراکنش از تاریخچه حذف نمی‌شود و با یک ثبت جبرانی خنثی می‌شود.'**
  String get financePageConfirmedContent;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:480.
  ///
  /// In fa, this message translates to:
  /// **'تأیید'**
  String get financePageConfirmedActions;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:490.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش با ثبت جبرانی خنثی شد.'**
  String get financePageVoidEntryMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:492.
  ///
  /// In fa, this message translates to:
  /// **'حذف امن تراکنش انجام نشد.'**
  String get financePageVoidEntryMessage2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:536.
  ///
  /// In fa, this message translates to:
  /// **'جریان نقدی این داده‌ها'**
  String get financePageBuildSummaryChildren;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:541.
  ///
  /// In fa, this message translates to:
  /// **'ورودی: {value1}'**
  String financePageBuildSummaryChildren2(String value1);

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:544.
  ///
  /// In fa, this message translates to:
  /// **'خروجی: {value1}'**
  String financePageBuildSummaryChildren3(String value1);

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:547.
  ///
  /// In fa, this message translates to:
  /// **'خالص: {value1}'**
  String financePageBuildSummaryChildren4(String value1);

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:551.
  ///
  /// In fa, this message translates to:
  /// **'این گزارش فقط بر اساس تراکنش‌های ثبت‌شده روی دستگاه است.'**
  String get financePageBuildSummaryChildren5;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:555.
  ///
  /// In fa, this message translates to:
  /// **'حساب‌هایی با واحد پول دیگر در این جمع لحاظ نشده‌اند.'**
  String get financePageBuildSummaryChildren6;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:576.
  ///
  /// In fa, this message translates to:
  /// **'نوع'**
  String get financePageBuildFiltersHint;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:578.
  ///
  /// In fa, this message translates to:
  /// **'همه تراکنش‌ها'**
  String get financePageBuildFiltersItems;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:581.
  ///
  /// In fa, this message translates to:
  /// **'ورودی'**
  String get financePageBuildFiltersItems2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:585.
  ///
  /// In fa, this message translates to:
  /// **'خروجی'**
  String get financePageBuildFiltersItems3;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:594.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌بندی'**
  String get financePageBuildFiltersHint2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:596.
  ///
  /// In fa, this message translates to:
  /// **'همه دسته‌ها'**
  String get financePageBuildFiltersItems4;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:618.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات مالی در دسترس نیست.'**
  String get financePageBuildChildren;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:636.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'**
  String get financePageBuildTitle2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:671.
  ///
  /// In fa, this message translates to:
  /// **'حساب‌ها'**
  String get financePageBuildChildren2;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:680.
  ///
  /// In fa, this message translates to:
  /// **'ثبت درآمد یا واریز'**
  String get financePageBuildTooltip;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:694.
  ///
  /// In fa, this message translates to:
  /// **'هنوز حسابی ثبت نشده است.'**
  String get financePageBuildTitle3;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:709.
  ///
  /// In fa, this message translates to:
  /// **'آخرین تراکنش‌ها'**
  String get financePageBuildChildren3;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:715.
  ///
  /// In fa, this message translates to:
  /// **'تراکنشی با این فیلترها پیدا نشد.'**
  String get financePageBuildTitle4;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:754.
  ///
  /// In fa, this message translates to:
  /// **'بدون شرح'**
  String get financePageBuildChildren4;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:781.
  ///
  /// In fa, this message translates to:
  /// **'عملیات تراکنش'**
  String get financePageEntryOperationsTooltip;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:793.
  ///
  /// In fa, this message translates to:
  /// **'تعیین ارتباط'**
  String get financePageEntryOperationsItemBuilder;

  /// Application copy. Original usage: lib/features/finance/presentation/finance_page.dart:795.
  ///
  /// In fa, this message translates to:
  /// **'برچسب‌های تراکنش'**
  String get financePageEntryOperationsItemBuilder2;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_account_picker.dart:67.
  ///
  /// In fa, this message translates to:
  /// **'خواندن حساب‌ها انجام نشد؛ دوباره تلاش کنید.'**
  String get financialAccountPickerLoadMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_account_picker.dart:79.
  ///
  /// In fa, this message translates to:
  /// **'در حال بارگذاری حساب‌ها…'**
  String get financialAccountPickerBuildChildren;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_account_picker.dart:87.
  ///
  /// In fa, this message translates to:
  /// **'حساب فعال سازگار پیدا نشد. برای ثبت، حساب بسازید.'**
  String get financialAccountPickerBuildChildren2;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_account_picker.dart:94.
  ///
  /// In fa, this message translates to:
  /// **'حساب مالی'**
  String get financialAccountPickerBuildLabelText;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_account_picker.dart:95.
  ///
  /// In fa, this message translates to:
  /// **'حساب را انتخاب کنید'**
  String get financialAccountPickerBuildHintText;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_account_picker.dart:117.
  ///
  /// In fa, this message translates to:
  /// **'تازه‌سازی حساب‌ها'**
  String get financialAccountPickerBuildLabel;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_account_picker.dart:127.
  ///
  /// In fa, this message translates to:
  /// **'ساخت حساب'**
  String get financialAccountPickerBuildLabel2;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:78.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ مثبت را وارد کنید.'**
  String get financialExpectationEditorSaveMessage;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:100.
  ///
  /// In fa, this message translates to:
  /// **'انتظار مالی ذخیره شد.'**
  String get financialExpectationEditorSaveMessage2;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:102.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ انتظار مالی انجام نشد.'**
  String get financialExpectationEditorSaveMessage3;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:129.
  ///
  /// In fa, this message translates to:
  /// **'انتظار مالی این نوبت'**
  String get financialExpectationEditorBuildTitle;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:130.
  ///
  /// In fa, this message translates to:
  /// **'اختیاری؛ مستقل از انجام تعهد'**
  String get financialExpectationEditorBuildSubtitle;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:169.
  ///
  /// In fa, this message translates to:
  /// **'ارز، مانند IRR'**
  String get financialExpectationEditorBuildLabelText;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:175.
  ///
  /// In fa, this message translates to:
  /// **'حساب (اختیاری)'**
  String get financialExpectationEditorBuildLabelText2;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:180.
  ///
  /// In fa, this message translates to:
  /// **'بدون حساب'**
  String get financialExpectationEditorBuildItems;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:195.
  ///
  /// In fa, this message translates to:
  /// **'در حال ذخیره…'**
  String get financialExpectationEditorBuildChildren;

  /// Application copy. Original usage: lib/features/finance/presentation/financial_expectation_editor.dart:195.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ انتظار'**
  String get financialExpectationEditorBuildChildren2;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:7.
  ///
  /// In fa, this message translates to:
  /// **'واریز'**
  String get transactionDirectionAccountEntryTypeIncome;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:8.
  ///
  /// In fa, this message translates to:
  /// **'برداشت'**
  String get transactionDirectionAccountEntryTypeExpense;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:9.
  ///
  /// In fa, this message translates to:
  /// **'انتقال ورودی'**
  String get transactionDirectionAccountEntryTypeTransferIn;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:10.
  ///
  /// In fa, this message translates to:
  /// **'انتقال خروجی'**
  String get transactionDirectionAccountEntryTypeTransferOut;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:11.
  ///
  /// In fa, this message translates to:
  /// **'موجودی اولیه'**
  String get transactionDirectionAccountEntryTypeOpeningBalance;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:12.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح موجودی'**
  String get transactionDirectionAccountEntryTypeAdjustment;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:13.
  ///
  /// In fa, this message translates to:
  /// **'بازپرداخت'**
  String get transactionDirectionAccountEntryTypeRefund;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:14.
  ///
  /// In fa, this message translates to:
  /// **'ثبت جبرانی'**
  String get transactionDirectionAccountEntryTypeReversal;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:34.
  ///
  /// In fa, this message translates to:
  /// **'خروجی از حساب'**
  String get transactionDirectionBuildSemanticLabel;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:34.
  ///
  /// In fa, this message translates to:
  /// **'ورودی به حساب'**
  String get transactionDirectionBuildSemanticLabel2;

  /// Application copy. Original usage: lib/features/finance/presentation/transaction_direction.dart:34.
  ///
  /// In fa, this message translates to:
  /// **'{value1}؛ {value2}'**
  String transactionDirectionBuildSemanticLabel3(String value1, String value2);

  /// Application copy. Original usage: lib/features/inbox/application/android_sms_source.dart:28.
  ///
  /// In fa, this message translates to:
  /// **'شناسهٔ پیامک معتبر نیست.'**
  String get androidSmsSourceMessage;

  /// Application copy. Original usage: lib/features/inbox/application/android_sms_source.dart:31.
  ///
  /// In fa, this message translates to:
  /// **'متن پیامک معتبر نیست.'**
  String get androidSmsSourceMessage2;

  /// Application copy. Original usage: lib/features/inbox/application/android_sms_source.dart:34.
  ///
  /// In fa, this message translates to:
  /// **'زمان پیامک معتبر نیست.'**
  String get androidSmsSourceMessage3;

  /// Application copy. Original usage: lib/features/inbox/application/android_sms_source.dart:38.
  ///
  /// In fa, this message translates to:
  /// **'مبدأ پیامک معتبر نیست.'**
  String get androidSmsSourceMessage4;

  /// Application copy. Original usage: lib/features/inbox/application/android_sms_source.dart:87.
  ///
  /// In fa, this message translates to:
  /// **'صفحهٔ پیامک معتبر نیست.'**
  String get androidSmsSourceReadPageMessage;

  /// Application copy. Original usage: lib/features/inbox/application/android_sms_source.dart:95.
  ///
  /// In fa, this message translates to:
  /// **'نشانگر پیامک معتبر نیست.'**
  String get androidSmsSourceReadPageMessage2;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:28.
  ///
  /// In fa, this message translates to:
  /// **'پیامک بانکی'**
  String get inboxReviewProjectionImportSourceSms;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:29.
  ///
  /// In fa, this message translates to:
  /// **'فایل واردشده'**
  String get inboxReviewProjectionImportSourceFile;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:30.
  ///
  /// In fa, this message translates to:
  /// **'ورود دستی'**
  String get inboxReviewProjectionImportSourceManual;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:100.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ و جهت تراکنش از متن پیامک بانکی تشخیص داده شد'**
  String get inboxReviewProjectionItemMessage;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:102.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ از متن پیامک تشخیص داده شد؛ جهت تراکنش قطعی نیست'**
  String get inboxReviewProjectionItemMessage2;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:104.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات واردشده نیاز به بررسی دستی دارد'**
  String get inboxReviewProjectionItemMessage3;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:107.
  ///
  /// In fa, this message translates to:
  /// **'نام پذیرنده از متن پیامک استخراج شد'**
  String get inboxReviewProjectionItemMessage4;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'تنها حساب فعال سازگار با واحد پول پیدا شد'**
  String get inboxReviewProjectionItemMessage5;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:112.
  ///
  /// In fa, this message translates to:
  /// **'حساب فعال سازگار برای ثبت پیدا نشد'**
  String get inboxReviewProjectionItemMessage6;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:114.
  ///
  /// In fa, this message translates to:
  /// **'چند حساب سازگار وجود دارد؛ حساب باید انتخاب شود'**
  String get inboxReviewProjectionItemMessage7;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:124.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش دیگری با همین مبلغ و نوع قبلاً ثبت شده است'**
  String get inboxReviewProjectionItemMessage8;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:125.
  ///
  /// In fa, this message translates to:
  /// **'هشدار تکراری بودن بر اساس مبلغ و نوع تراکنش'**
  String get inboxReviewProjectionItemMessage9;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:133.
  ///
  /// In fa, this message translates to:
  /// **'شناسه پیگیری قبلاً در دفترکل دیده شده است'**
  String get inboxReviewProjectionItemMessage10;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_review_projection.dart:134.
  ///
  /// In fa, this message translates to:
  /// **'هشدار تکراری بودن بر اساس شناسه پیگیری'**
  String get inboxReviewProjectionItemMessage11;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_use_cases.dart:105.
  ///
  /// In fa, this message translates to:
  /// **'قالب پیامک قابل تشخیص نیست.'**
  String get inboxUseCasesMessage;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_use_cases.dart:109.
  ///
  /// In fa, this message translates to:
  /// **'این پیامک قبلاً وارد شده است.'**
  String get inboxUseCasesMessage2;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_use_cases.dart:469.
  ///
  /// In fa, this message translates to:
  /// **'متن یا شناسهٔ پیامک معتبر نیست.'**
  String get inboxUseCasesStageSmsMessage;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_use_cases.dart:560.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد بررسی‌شده قابل ویرایش نیست.'**
  String get inboxUseCasesEditMessage;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_use_cases.dart:564.
  ///
  /// In fa, this message translates to:
  /// **'شواهد واحد پیامک نباید حذف شود.'**
  String get inboxUseCasesEditMessage2;

  /// Application copy. Original usage: lib/features/inbox/application/inbox_use_cases.dart:568.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد تغییر کرده است؛ ابتدا بازخوانی کنید.'**
  String get inboxUseCasesEditMessage3;

  /// Application copy. Original usage: lib/features/inbox/application/sms_ingestion.dart:48.
  ///
  /// In fa, this message translates to:
  /// **'نسخهٔ ورود پیامک پشتیبانی نمی‌شود.'**
  String get smsIngestionMessage;

  /// Application copy. Original usage: lib/features/inbox/application/sms_ingestion.dart:85.
  ///
  /// In fa, this message translates to:
  /// **'بازهٔ پیامک معتبر نیست.'**
  String get smsIngestionConsentMessage;

  /// Application copy. Original usage: lib/features/inbox/application/sms_ingestion.dart:107.
  ///
  /// In fa, this message translates to:
  /// **'ابتدا بازهٔ پیامک را انتخاب کنید.'**
  String get smsIngestionRunMessage;

  /// Application copy. Original usage: lib/features/inbox/application/sms_ingestion.dart:111.
  ///
  /// In fa, this message translates to:
  /// **'مجوز پیامک فعال نیست.'**
  String get smsIngestionRunMessage2;

  /// Application copy. Original usage: lib/features/inbox/application/sms_ingestion.dart:139.
  ///
  /// In fa, this message translates to:
  /// **'ترتیب صفحهٔ پیامک معتبر نیست.'**
  String get smsIngestionRunMessage3;

  /// Application copy. Original usage: lib/features/inbox/data/drift_inbox_repository.dart:77.
  ///
  /// In fa, this message translates to:
  /// **'تغییر جدیدی ثبت شده است؛ ابتدا بازخوانی کنید.'**
  String get driftInboxRepositoryReviewAtomicallyMessage;

  /// Application copy. Original usage: lib/features/inbox/data/drift_inbox_repository.dart:85.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش تأییدشده را از بخش مالی اصلاح کنید.'**
  String get driftInboxRepositoryReviewAtomicallyMessage2;

  /// Application copy. Original usage: lib/features/inbox/data/drift_inbox_repository.dart:226.
  ///
  /// In fa, this message translates to:
  /// **'نوع تراکنش در این مسیر پشتیبانی نمی‌شود.'**
  String get driftInboxRepositoryConfirmAtomicallyMessage;

  /// Application copy. Original usage: lib/features/inbox/data/drift_inbox_repository.dart:233.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ پیامک را صریحاً انتخاب کنید.'**
  String get driftInboxRepositoryConfirmAtomicallyMessage2;

  /// Application copy. Original usage: lib/features/inbox/data/drift_inbox_repository.dart:412.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد بررسی‌شده قابل بازنویسی نیست.'**
  String get driftInboxRepositorySaveSuggestionMessage;

  /// Application copy. Original usage: lib/features/inbox/data/drift_inbox_repository.dart:425.
  ///
  /// In fa, this message translates to:
  /// **'شناسه یا وضعیت پیشنهاد قابل تغییر نیست.'**
  String get driftInboxRepositorySaveSuggestionMessage2;

  /// Application copy. Original usage: lib/features/inbox/domain/inbox.dart:194.
  ///
  /// In fa, this message translates to:
  /// **'ثبت انتقال از پیامک در این مسیر پشتیبانی نمی‌شود.'**
  String get inboxValidateConfirmationMessage;

  /// Application copy. Original usage: lib/features/inbox/domain/inbox.dart:198.
  ///
  /// In fa, this message translates to:
  /// **'نوع تراکنش را صریحاً انتخاب کنید.'**
  String get inboxValidateConfirmationMessage2;

  /// Application copy. Original usage: lib/features/inbox/domain/inbox.dart:202.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ معتبر و مثبت وارد کنید.'**
  String get inboxValidateConfirmationMessage3;

  /// Application copy. Original usage: lib/features/inbox/domain/inbox.dart:213.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ و واحد بررسی‌شده با هم سازگار نیستند.'**
  String get inboxValidateConfirmationMessage4;

  /// Application copy. Original usage: lib/features/inbox/domain/inbox.dart:287.
  ///
  /// In fa, this message translates to:
  /// **'نسخهٔ شواهد پیامک پشتیبانی نمی‌شود.'**
  String get inboxMessage;

  /// Application copy. Original usage: lib/features/inbox/domain/sms_currency_evidence.dart:14.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ خارج از محدودهٔ مجاز است.'**
  String get smsCurrencyEvidenceCanonicalIrrMessage;

  /// Application copy. Original usage: lib/features/inbox/domain/sms_currency_evidence.dart:49.
  ///
  /// In fa, this message translates to:
  /// **'نسخهٔ شواهد واحد پیامک پشتیبانی نمی‌شود.'**
  String get smsCurrencyEvidenceMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:106.
  ///
  /// In fa, this message translates to:
  /// **'دریافت پیامک قطع شد؛ برای همگام‌سازی دوباره تلاش کنید.'**
  String get inboxPageInitStateOnError;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:183.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری صف بررسی انجام نشد.'**
  String get inboxPageReloadMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:218.
  ///
  /// In fa, this message translates to:
  /// **'خواندن پیامک‌ها انجام نشد.'**
  String get inboxPageSyncSmsMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:230.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی به پیامک‌های بانکی'**
  String get inboxPageConsentTitle;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:232.
  ///
  /// In fa, this message translates to:
  /// **'برای ورود پیامک‌های بانکی، دسترسی خواندن و دریافت پیامک لازم است. پیامک‌های مرتبط فقط روی دستگاه بررسی و در صف بررسی ثبت می‌شوند؛ تراکنش مالی بدون تأیید شما ثبت نمی‌شود. می‌توانید دسترسی را در تنظیمات دستگاه لغو کنید.'**
  String get inboxPageConsentContent;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:239.
  ///
  /// In fa, this message translates to:
  /// **'فعلاً نه'**
  String get inboxPageConsentActions;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:266.
  ///
  /// In fa, this message translates to:
  /// **'مجوز پیامک فعال نیست؛ تنظیمات برنامه را بررسی کنید.'**
  String get inboxPageEnableSmsMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:284.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی پیامک داده نشد. برای فعال‌سازی دوباره تلاش کنید یا مجوز را در تنظیمات برنامه فعال کنید.'**
  String get inboxPageEnableSmsMessage2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:295.
  ///
  /// In fa, this message translates to:
  /// **'درخواست مجوز پاسخ نداد. مجوز پیامک را از تنظیمات برنامه بررسی کنید.'**
  String get inboxPageEnableSmsMessage3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:296.
  ///
  /// In fa, this message translates to:
  /// **'درخواست دسترسی انجام نشد؛ دوباره تلاش کنید.'**
  String get inboxPageEnableSmsMessage4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:375.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش ثبت شد؛ تازه‌سازی نمایش انجام نشد. دوباره تازه‌سازی کنید.'**
  String get inboxPageConfirmContent;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:410.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد به صف بررسی برگشت.'**
  String get inboxPageRejectContent;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:411.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد رد شد؛ تراکنشی حذف یا ثبت نشد.'**
  String get inboxPageRejectContent2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:416.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی'**
  String get inboxPageRejectLabel;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:441.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره انجام نشد؛ پیشنهاد حفظ شد. دوباره تلاش کنید.'**
  String get inboxPageRejectContent3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:475.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش ذخیره شد؛ برای ثبت مالی تأیید نهایی لازم است.'**
  String get inboxPageEditContent;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:499.
  ///
  /// In fa, this message translates to:
  /// **'رد کردن پیشنهادهای انتخاب‌شده؟'**
  String get inboxPageConfirmedTitle;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:501.
  ///
  /// In fa, this message translates to:
  /// **'{value1} پیشنهاد از همین صفحهٔ بارگذاری‌شده رد می‌شود؛ این انتخاب شامل همهٔ نتایج فیلتر نیست. تراکنش یا موجودی تغییر نمی‌کند. برای بازگردانی، از فیلتر «ردشده» هر پیشنهاد را بازگشایی کنید.'**
  String inboxPageConfirmedContent(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:512.
  ///
  /// In fa, this message translates to:
  /// **'رد کردن انتخاب‌ها'**
  String get inboxPageConfirmedActions;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:573.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب فقط در همین صفحهٔ بارگذاری‌شده · حداکثر {value1} پیشنهاد'**
  String inboxPageBulkControlsChildren(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:576.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب‌شده: {value1} · همهٔ نتایج فیلتر انتخاب نمی‌شوند.'**
  String inboxPageBulkControlsChildren2(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:589.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب موارد همین صفحه'**
  String get inboxPageBulkControlsChildren3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:595.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن انتخاب'**
  String get inboxPageBulkControlsChildren4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:601.
  ///
  /// In fa, this message translates to:
  /// **'رد کردن گروهی'**
  String get inboxPageBulkControlsChildren5;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:609.
  ///
  /// In fa, this message translates to:
  /// **'صفحهٔ {value1}'**
  String inboxPageBulkControlsChildren6(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:617.
  ///
  /// In fa, this message translates to:
  /// **'صفحهٔ قبل'**
  String get inboxPageBulkControlsChildren7;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:627.
  ///
  /// In fa, this message translates to:
  /// **'صفحهٔ بعد'**
  String get inboxPageBulkControlsChildren8;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:635.
  ///
  /// In fa, this message translates to:
  /// **'بررسی‌شده: {value1} از {value2} · ردشده: {value3} · ناموفق: {value4}'**
  String inboxPageBulkControlsChildren9(
    String value1,
    String value2,
    String value3,
    String value4,
  );

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:644.
  ///
  /// In fa, this message translates to:
  /// **'در انتظار پایان مورد جاری'**
  String get inboxPageBulkControlsChildren10;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:645.
  ///
  /// In fa, this message translates to:
  /// **'توقف پس از مورد جاری'**
  String get inboxPageBulkControlsChildren11;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:650.
  ///
  /// In fa, this message translates to:
  /// **'عملیات پایان یافت؛ موارد انجام‌نشده تغییر نکردند. بازگردانی از فیلتر «ردشده» انجام می‌شود.'**
  String get inboxPageBulkControlsChildren12;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:654.
  ///
  /// In fa, this message translates to:
  /// **'برخی موارد ذخیره نشدند یا تغییر جدیدتری دارند. تلاش دوباره تصمیم جدیدتر را بازنویسی نمی‌کند؛ برای انتخاب دوباره بازخوانی کنید.'**
  String get inboxPageBulkControlsChildren13;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:660.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره برای موارد ناموفق'**
  String get inboxPageBulkControlsChildren14;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:682.
  ///
  /// In fa, this message translates to:
  /// **'صف بررسی در دسترس نیست'**
  String get inboxPageBuildTitle;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:715.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت بررسی'**
  String get inboxPageHeaderLabelText;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:717.
  ///
  /// In fa, this message translates to:
  /// **'نیازمند بررسی'**
  String get inboxPageHeaderItems;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:720.
  ///
  /// In fa, this message translates to:
  /// **'ردشده'**
  String get inboxPageHeaderItems2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:724.
  ///
  /// In fa, this message translates to:
  /// **'تأییدشده'**
  String get inboxPageHeaderItems3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:740.
  ///
  /// In fa, this message translates to:
  /// **'بانک'**
  String get inboxPageHeaderLabelText2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:742.
  ///
  /// In fa, this message translates to:
  /// **'همهٔ بانک‌ها'**
  String get inboxPageHeaderItems4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:746.
  ///
  /// In fa, this message translates to:
  /// **'بانک نامشخص'**
  String get inboxPageHeaderItems5;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:770.
  ///
  /// In fa, this message translates to:
  /// **'قدیمی‌ترین دریافت / ورود ابتدا'**
  String get inboxPageHeaderLabel;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:771.
  ///
  /// In fa, this message translates to:
  /// **'جدیدترین دریافت / ورود ابتدا'**
  String get inboxPageHeaderLabel2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:781.
  ///
  /// In fa, this message translates to:
  /// **'صف بررسی خالی است'**
  String get inboxPageHeaderTitle;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:782.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات واردشده و پیشنهادهای مالی برای بررسی در اینجا نمایش داده می‌شوند.'**
  String get inboxPageHeaderMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:872.
  ///
  /// In fa, this message translates to:
  /// **'این پیامک انتقال است؛ درآمد یا هزینه ثبت نمی‌شود. انتقال را در بخش مالی بین دو حساب ثبت کنید.'**
  String get inboxPageSaveMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:878.
  ///
  /// In fa, this message translates to:
  /// **'نوع تراکنش نامشخص است؛ در ویرایش پیشنهاد جهت را بررسی و انتخاب کنید.'**
  String get inboxPageSaveMessage2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:883.
  ///
  /// In fa, this message translates to:
  /// **'طبقه‌بندی درآمد یا هزینه را صریحاً تأیید کنید.'**
  String get inboxPageSaveMessage3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:890.
  ///
  /// In fa, this message translates to:
  /// **'زمان پیشنهادی را صریحاً تأیید کنید یا برای انتخاب تاریخ و ساعت به ویرایش بروید.'**
  String get inboxPageSaveMessage4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:897.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ نامشخص است؛ به ویرایش پیشنهاد بروید و ریال یا تومان را انتخاب کنید.'**
  String get inboxPageSaveMessage5;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:924.
  ///
  /// In fa, this message translates to:
  /// **'ثبت انجام نشد؛ پیشنهاد و انتخاب شما حفظ شده‌اند. اعتبار حساب را بررسی کنید و دوباره تلاش کنید.'**
  String get inboxPageSaveMessage6;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:934.
  ///
  /// In fa, this message translates to:
  /// **'تأیید پیشنهاد تراکنش'**
  String get inboxPageBuildTitle2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:935.
  ///
  /// In fa, this message translates to:
  /// **'تأیید نهایی'**
  String get inboxPageBuildPrimaryLabel;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:950.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ پیامک نامشخص است؛ ابتدا در ویرایش پیشنهاد واحد را انتخاب کنید.'**
  String get inboxPageBuildChildren;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:962.
  ///
  /// In fa, this message translates to:
  /// **'زمان بررسی‌شده برای ثبت: {value1}'**
  String inboxPageBuildChildren2(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:972.
  ///
  /// In fa, this message translates to:
  /// **'نوع تراکنش نامشخص است؛ ابتدا در ویرایش پیشنهاد بررسی کنید.'**
  String get inboxPageBuildChildren3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:984.
  ///
  /// In fa, this message translates to:
  /// **'هزینه'**
  String get inboxPageBuildTitle3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:984.
  ///
  /// In fa, this message translates to:
  /// **'درآمد'**
  String get inboxPageBuildTitle4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:984.
  ///
  /// In fa, this message translates to:
  /// **'ثبت مالی به‌عنوان {value1} را تأیید می‌کنم.'**
  String inboxPageBuildTitle5(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:987.
  ///
  /// In fa, this message translates to:
  /// **'واریز و برداشت به‌تنهایی طبقه‌بندی مالی نیستند؛ انتقال بین حساب‌های خودتان را اینجا ثبت نکنید.'**
  String get inboxPageBuildSubtitle;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1002.
  ///
  /// In fa, this message translates to:
  /// **'زمان پیشنهادی را برای ثبت تراکنش تأیید می‌کنم.'**
  String get inboxPageBuildTitle6;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1007.
  ///
  /// In fa, this message translates to:
  /// **'این زمان دریافت پیامک است، نه زمان استخراج‌شدهٔ تراکنش. برای تغییر تاریخ یا ساعت، به ویرایش بروید.'**
  String get inboxPageBuildSubtitle2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1008.
  ///
  /// In fa, this message translates to:
  /// **'منشأ زمان ذخیره‌شده نامشخص است. برای تغییر تاریخ یا ساعت، به ویرایش بروید.'**
  String get inboxPageBuildSubtitle3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1012.
  ///
  /// In fa, this message translates to:
  /// **'نیازمند انتخاب'**
  String get inboxPageBuildChildren4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1012.
  ///
  /// In fa, this message translates to:
  /// **'حساب پیشنهادی: {value1}؛ انتخاب نهایی با شماست.'**
  String inboxPageBuildChildren5(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1046.
  ///
  /// In fa, this message translates to:
  /// **'ورود پیامک بانکی'**
  String get inboxPageBuildTitle7;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1051.
  ///
  /// In fa, this message translates to:
  /// **'مجوز فعال است؛ بازهٔ خواندن پیامک را جداگانه انتخاب کنید.'**
  String get inboxPageBuildSubtitle4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1052.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی خواندن و دریافت پیامک فعال نیست؛ ورود خودکار انجام نمی‌شود.'**
  String get inboxPageBuildSubtitle5;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1053.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت مجوز پیامک هنوز بررسی نشده است.'**
  String get inboxPageBuildSubtitle6;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1058.
  ///
  /// In fa, this message translates to:
  /// **'بازخوانی'**
  String get inboxPageBuildTooltip;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1062.
  ///
  /// In fa, this message translates to:
  /// **'فعال‌سازی'**
  String get inboxPageBuildTrailing;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1098.
  ///
  /// In fa, this message translates to:
  /// **'{value1} (واحد نامشخص)'**
  String inboxPageAmountMessage(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1119.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب برای رد گروهی'**
  String get inboxPageBuildTitle8;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1128.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ دریافت پیامک: نامشخص'**
  String get inboxPageBuildChildren6;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1129.
  ///
  /// In fa, this message translates to:
  /// **'دریافت پیامک: {value1}'**
  String inboxPageBuildChildren7(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1133.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ استخراج‌شدهٔ تراکنش: {value1}'**
  String inboxPageBuildChildren8(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1135.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تراکنش نامشخص؛ تاریخ دریافت برای ثبت پیشنهاد شده است.'**
  String get inboxPageBuildChildren9;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1137.
  ///
  /// In fa, this message translates to:
  /// **'زمان انتخاب‌شدهٔ شما: {value1}'**
  String inboxPageBuildChildren10(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1138.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تراکنش و منشأ تاریخ ذخیره‌شده نامشخص است.'**
  String get inboxPageBuildChildren11;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1140.
  ///
  /// In fa, this message translates to:
  /// **'نامشخص'**
  String get commonUnknown;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1140.
  ///
  /// In fa, this message translates to:
  /// **'بانک: {value1}'**
  String inboxPageBuildChildren12(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1143.
  ///
  /// In fa, this message translates to:
  /// **'واحد پیامک قدیمی نامشخص؛ مبلغ ذخیره‌شده بدون تغییر حفظ شده است.'**
  String get inboxPageBuildChildren13;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1145.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ نامشخص است؛ در ویرایش، ریال یا تومان را انتخاب کنید.'**
  String get inboxPageBuildChildren14;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1146.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب شما'**
  String get inboxPageBuildChildren15;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1146.
  ///
  /// In fa, this message translates to:
  /// **'شواهد پیامک'**
  String get inboxPageBuildChildren16;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1146.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ: {value1}؛ {value2}'**
  String inboxPageBuildChildren17(String value1, String value2);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1150.
  ///
  /// In fa, this message translates to:
  /// **'حساب پیشنهادی: {value1}'**
  String inboxPageBuildChildren18(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1154.
  ///
  /// In fa, this message translates to:
  /// **'هشدار: {value1}'**
  String inboxPageBuildChildren19(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1162.
  ///
  /// In fa, this message translates to:
  /// **'بستن جزئیات'**
  String get inboxPageBuildLabel;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1162.
  ///
  /// In fa, this message translates to:
  /// **'جزئیات پیشنهاد'**
  String get inboxPageBuildLabel2;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1168.
  ///
  /// In fa, this message translates to:
  /// **'مقادیر فعلی بررسی'**
  String get inboxPageBuildChildren20;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1172.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ بررسی‌شده: {value1}'**
  String inboxPageBuildChildren21(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1173.
  ///
  /// In fa, this message translates to:
  /// **'جهت بررسی‌شده: {value1}'**
  String inboxPageBuildChildren22(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1174.
  ///
  /// In fa, this message translates to:
  /// **'شرح بررسی‌شده: {value1}'**
  String inboxPageBuildChildren23(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1175.
  ///
  /// In fa, this message translates to:
  /// **'راهنمای حساب: {value1}'**
  String inboxPageBuildChildren24(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1176.
  ///
  /// In fa, this message translates to:
  /// **'شناسه پیگیری: {value1}'**
  String inboxPageBuildChildren25(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1177.
  ///
  /// In fa, this message translates to:
  /// **'زمان برای ثبت: {value1}'**
  String inboxPageBuildChildren26(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1179.
  ///
  /// In fa, this message translates to:
  /// **'چرا این پیشنهاد؟'**
  String get inboxPageBuildChildren27;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1187.
  ///
  /// In fa, this message translates to:
  /// **'تأییدشده؛ برای اصلاح یا برگشت تراکنش به بخش مالی بروید. حذف از صندوق ممکن نیست.'**
  String get inboxPageBuildChildren28;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1193.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی به صف بررسی'**
  String get inboxPageBuildLabel3;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1203.
  ///
  /// In fa, this message translates to:
  /// **'تأیید و ثبت'**
  String get inboxPageBuildLabel4;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1208.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش'**
  String get inboxPageBuildLabel5;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1213.
  ///
  /// In fa, this message translates to:
  /// **'رد کردن'**
  String get inboxPageBuildLabel6;

  /// Application copy. Original usage: lib/features/inbox/presentation/inbox_page.dart:1226.
  ///
  /// In fa, this message translates to:
  /// **'نوع نامشخص'**
  String get inboxPageTransactionDirectionUnknown;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:44.
  ///
  /// In fa, this message translates to:
  /// **'{value1} (سال نامشخص)'**
  String smsReviewEditorDateLabelMessage(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:57.
  ///
  /// In fa, this message translates to:
  /// **'شواهد اصلی پیامک (بدون تغییر)'**
  String get smsReviewEditorBuildChildren;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:61.
  ///
  /// In fa, this message translates to:
  /// **'شواهد اصلی پیامک قدیمی در دسترس نیست.'**
  String get smsReviewEditorBuildChildren2;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:64.
  ///
  /// In fa, this message translates to:
  /// **'واحد نامشخص'**
  String get smsReviewEditorBuildChildren3;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:64.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ اصلی: {value1}'**
  String smsReviewEditorBuildChildren4(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:67.
  ///
  /// In fa, this message translates to:
  /// **'انتقال'**
  String get smsReviewEditorBuildChildren5;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:67.
  ///
  /// In fa, this message translates to:
  /// **'جهت پیامک: {value1}'**
  String smsReviewEditorBuildChildren6(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:69.
  ///
  /// In fa, this message translates to:
  /// **'شرح اصلی: {value1}'**
  String smsReviewEditorBuildChildren7(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'بانک اصلی: {value1}'**
  String smsReviewEditorBuildChildren8(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:71.
  ///
  /// In fa, this message translates to:
  /// **'راهنمای حساب اصلی: {value1}'**
  String smsReviewEditorBuildChildren9(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:72.
  ///
  /// In fa, this message translates to:
  /// **'پیگیری اصلی: {value1}'**
  String smsReviewEditorBuildChildren10(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:73.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ پیامک: {value1}'**
  String smsReviewEditorBuildChildren11(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:75.
  ///
  /// In fa, this message translates to:
  /// **'ساعت پیامک: {value1}'**
  String smsReviewEditorBuildChildren12(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:78.
  ///
  /// In fa, this message translates to:
  /// **'زمان دریافت پیامک: {value1}'**
  String smsReviewEditorBuildChildren13(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:197.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ نامشخص است؛ ریال یا تومان را انتخاب کنید.'**
  String get smsReviewEditorSaveMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:202.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ باید معتبر و بزرگ‌تر از صفر باشد.'**
  String get smsReviewEditorSaveMessage2;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:210.
  ///
  /// In fa, this message translates to:
  /// **'برای تغییر زمان تراکنش، تاریخ و ساعت را صریحاً انتخاب کنید.'**
  String get smsReviewEditorSaveMessage3;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:219.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ پیامک باید در واحد انتخابی عدد صحیح باشد؛ برای باقی‌ماندهٔ ریالی، ریال را انتخاب کنید.'**
  String get smsReviewEditorSaveMessage4;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:280.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره انجام نشد؛ مقادیر فرم حفظ شده‌اند. دوباره تلاش کنید.'**
  String get smsReviewEditorSaveMessage5;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:301.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش پیشنهاد تراکنش'**
  String get smsReviewEditorBuildTitle;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:302.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره و بررسی'**
  String get smsReviewEditorBuildPrimaryLabel;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:312.
  ///
  /// In fa, this message translates to:
  /// **'مقادیر بررسی‌شدهٔ شما؛ ذخیرهٔ ویرایش هنوز تراکنش مالی ثبت نمی‌کند.'**
  String get smsReviewEditorBuildChildren14;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:318.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ (واحد انتخابی)'**
  String get smsReviewEditorBuildChildren15;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:324.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ'**
  String get smsReviewEditorBuildLabelText;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:333.
  ///
  /// In fa, this message translates to:
  /// **'واحد پیامک قدیمی نامشخص است؛ مقدار ذخیره‌شده بازتفسیر نمی‌شود.'**
  String get smsReviewEditorBuildChildren16;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:335.
  ///
  /// In fa, this message translates to:
  /// **'پذیرنده یا شرح'**
  String get smsReviewEditorBuildChildren17;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:336.
  ///
  /// In fa, this message translates to:
  /// **'شناسه پیگیری'**
  String get smsReviewEditorBuildChildren18;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:337.
  ///
  /// In fa, this message translates to:
  /// **'نام بانک'**
  String get smsReviewEditorBuildChildren19;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:338.
  ///
  /// In fa, this message translates to:
  /// **'راهنمای حساب یا کارت'**
  String get smsReviewEditorBuildChildren20;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:342.
  ///
  /// In fa, this message translates to:
  /// **'جهت پیامک'**
  String get smsReviewEditorBuildLabelText2;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:350.
  ///
  /// In fa, this message translates to:
  /// **'واریز یا برداشت به‌تنهایی به معنی درآمد یا هزینه نیست؛ طبقه‌بندی مالی را پیش از تأیید نهایی بررسی کنید.'**
  String get smsReviewEditorBuildChildren21;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:354.
  ///
  /// In fa, this message translates to:
  /// **'شواهد پیامک نشان‌دهندهٔ انتقال است؛ ثبت درآمد یا هزینه مجاز نیست. انتقال را در بخش مالی بین دو حساب ثبت کنید.'**
  String get smsReviewEditorBuildChildren22;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:358.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد زمان دریافت (نه زمان تراکنش): {value1}'**
  String smsReviewEditorBuildChildren23(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:364.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تاریخ تراکنش (نامشخص)'**
  String get smsReviewEditorBuildLabel;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:365.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تراکنش: {value1}'**
  String smsReviewEditorBuildLabel2(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:388.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب ساعت تراکنش (نامشخص)'**
  String get smsReviewEditorBuildLabel3;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:389.
  ///
  /// In fa, this message translates to:
  /// **'ساعت تراکنش: {value1}'**
  String smsReviewEditorBuildLabel4(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:400.
  ///
  /// In fa, this message translates to:
  /// **'تأیید ساعت'**
  String get smsReviewEditorResultConfirmText;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_review_editor.dart:401.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب ساعت تراکنش'**
  String get smsReviewEditorResultHelpText;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:45.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری وضعیت ورود پیامک انجام نشد.'**
  String get smsScanCardLoadMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:66.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب بازهٔ ورود پیامک'**
  String get smsScanCardDaysTitle;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:68.
  ///
  /// In fa, this message translates to:
  /// **'مجوز پیامک اجازهٔ خواندن تاریخچه نیست. بازه را انتخاب کنید؛ بررسی فقط روی دستگاه است و ثبت مالی نیاز به تأیید شما دارد.'**
  String get smsScanCardDaysContent;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:77.
  ///
  /// In fa, this message translates to:
  /// **'فقط پیامک‌های جدید از این لحظه'**
  String get smsScanCardDaysActions;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:81.
  ///
  /// In fa, this message translates to:
  /// **'۷ روز گذشته'**
  String get smsScanCardDaysActions2;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:85.
  ///
  /// In fa, this message translates to:
  /// **'۳۰ روز گذشته'**
  String get smsScanCardDaysActions3;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:101.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ انتخاب انجام نشد؛ دوباره تلاش کنید.'**
  String get smsScanCardChooseMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:121.
  ///
  /// In fa, this message translates to:
  /// **'ورود متوقف شد؛ مجوز را بررسی و دوباره ادامه دهید. پیامک‌های ثبت‌شده حفظ شده‌اند.'**
  String get smsScanCardRunMessage;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:143.
  ///
  /// In fa, this message translates to:
  /// **'ورود پیامک با انتخاب شما'**
  String get smsScanCardBuildChildren;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:147.
  ///
  /// In fa, this message translates to:
  /// **'فقط پیامک‌های جدید از {value1}'**
  String smsScanCardBuildChildren2(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:148.
  ///
  /// In fa, this message translates to:
  /// **'از {value1} تا {value2}'**
  String smsScanCardBuildChildren3(String value1, String value2);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:152.
  ///
  /// In fa, this message translates to:
  /// **'تعداد پیامک‌های بررسی‌شده: {value1}'**
  String smsScanCardBuildChildren4(String value1);

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:156.
  ///
  /// In fa, this message translates to:
  /// **'برخی پیامک‌ها قابل تشخیص نبودند؛ تراکنشی از آن‌ها ثبت نشد.'**
  String get smsScanCardBuildChildren5;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:161.
  ///
  /// In fa, this message translates to:
  /// **'بررسی بازه کامل شد.'**
  String get smsScanCardBuildChildren6;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:165.
  ///
  /// In fa, this message translates to:
  /// **'توقف ورود پیامک'**
  String get smsScanCardBuildChildren7;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:172.
  ///
  /// In fa, this message translates to:
  /// **'بررسی پیامک‌های جدید'**
  String get smsScanCardBuildChildren8;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:173.
  ///
  /// In fa, this message translates to:
  /// **'ادامه / تلاش دوباره'**
  String get smsScanCardBuildChildren9;

  /// Application copy. Original usage: lib/features/inbox/presentation/sms_scan_card.dart:178.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب بازهٔ پیامک'**
  String get smsScanCardBuildChildren10;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:38.
  ///
  /// In fa, this message translates to:
  /// **'ثبت سریع برداشت از یک حساب'**
  String get quickAddSheetBuildSubtitle;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:45.
  ///
  /// In fa, this message translates to:
  /// **'ثبت سریع واریز به یک حساب'**
  String get quickAddSheetBuildSubtitle2;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:52.
  ///
  /// In fa, this message translates to:
  /// **'جابجایی بین حساب‌های خودتان'**
  String get quickAddSheetBuildSubtitle3;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:59.
  ///
  /// In fa, this message translates to:
  /// **'ثبت عنوان، زمان‌بندی و گزینه‌های اختیاری'**
  String get quickAddSheetBuildSubtitle4;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:159.
  ///
  /// In fa, this message translates to:
  /// **'ثبت انجام نشد؛ اطلاعات و برچسب‌های شما حفظ شده است. دوباره تلاش کنید.'**
  String get quickAddSheetSubmitMessage;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:169.
  ///
  /// In fa, this message translates to:
  /// **'ثبت سریع درآمد'**
  String get quickAddSheetBuildTitle;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:169.
  ///
  /// In fa, this message translates to:
  /// **'ثبت سریع هزینه'**
  String get quickAddSheetBuildTitle2;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:192.
  ///
  /// In fa, this message translates to:
  /// **'حساب'**
  String get quickAddSheetBuildLabelText;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:208.
  ///
  /// In fa, this message translates to:
  /// **'شرح درآمد (اختیاری)'**
  String get quickAddSheetBuildLabelText2;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:209.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت (اختیاری)'**
  String get quickAddSheetBuildLabelText3;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:298.
  ///
  /// In fa, this message translates to:
  /// **'حساب مبدأ و مقصد باید متفاوت باشند.'**
  String get quickAddSheetSubmitMessage2;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:308.
  ///
  /// In fa, this message translates to:
  /// **'ثبت سریع انتقال'**
  String get quickAddSheetBuildTitle3;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:309.
  ///
  /// In fa, this message translates to:
  /// **'ثبت انتقال'**
  String get quickAddSheetBuildPrimaryLabel;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:329.
  ///
  /// In fa, this message translates to:
  /// **'از حساب'**
  String get quickAddSheetBuildLabelText4;

  /// Application copy. Original usage: lib/features/quick_add/presentation/quick_add_sheet.dart:337.
  ///
  /// In fa, this message translates to:
  /// **'به حساب'**
  String get quickAddSheetBuildLabelText5;

  /// Application copy. Original usage: lib/features/reconciliation/application/reconciliation_use_cases.dart:377.
  ///
  /// In fa, this message translates to:
  /// **'برای این تعهد پرداختی تطبیق داده نشده است.'**
  String get reconciliationUseCasesPlannedVsActualExplanation;

  /// Application copy. Original usage: lib/features/reconciliation/application/reconciliation_use_cases.dart:379.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت کامل تطبیق داده شده است.'**
  String get reconciliationUseCasesPlannedVsActualExplanation2;

  /// Application copy. Original usage: lib/features/reconciliation/application/reconciliation_use_cases.dart:380.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت به‌صورت جزئی تطبیق داده شده است.'**
  String get reconciliationUseCasesPlannedVsActualExplanation3;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ یکسان است'**
  String get reconciliationScoreText;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:74.
  ///
  /// In fa, this message translates to:
  /// **'اختلاف مبلغ در محدوده مجاز است'**
  String get reconciliationScoreText2;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:78.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت جزئی است'**
  String get reconciliationScoreText3;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:80.
  ///
  /// In fa, this message translates to:
  /// **'اختلاف مبلغ زیاد است'**
  String get reconciliationScoreText4;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:89.
  ///
  /// In fa, this message translates to:
  /// **'جهت تراکنش درست است'**
  String get reconciliationScoreText5;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:91.
  ///
  /// In fa, this message translates to:
  /// **'جهت تراکنش نادرست است'**
  String get reconciliationScoreText6;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:106.
  ///
  /// In fa, this message translates to:
  /// **'حساب مورد انتظار و حساب تراکنش یکسان است'**
  String get reconciliationScoreText7;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'حساب تراکنش متفاوت است'**
  String get reconciliationScoreText8;

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:120.
  ///
  /// In fa, this message translates to:
  /// **'{value1} روز با تاریخ مورد انتظار فاصله دارد'**
  String reconciliationScoreText9(String value1);

  /// Application copy. Original usage: lib/features/reconciliation/domain/reconciliation.dart:127.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تراکنش خارج از بازه بررسی است'**
  String get reconciliationScoreText10;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:78.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری صف انجام نشد؛ دوباره تلاش کنید.'**
  String get relationshipQueuePageLoadMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:101.
  ///
  /// In fa, this message translates to:
  /// **'تأیید مستقل بودن باقی‌مانده‌ها'**
  String get relationshipQueuePageApprovedTitle;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:103.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب‌شده از صفحهٔ نمایش‌داده‌شده'**
  String get relationshipQueuePageApprovedContent;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:103.
  ///
  /// In fa, this message translates to:
  /// **'ناموفق از انتخاب قبلی'**
  String get relationshipQueuePageApprovedContent2;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:103.
  ///
  /// In fa, this message translates to:
  /// **'{value1} مورد {value2} به تعهدی مربوط نیستند؟\nاین انتخاب همهٔ نتایج فیلتر نیست. فقط باقی‌مانده‌ها مستقل ثبت می‌شوند؛ موجودی، تراکنش‌ها و ارتباط‌های قبلی تغییر نمی‌کنند.'**
  String relationshipQueuePageApprovedContent3(String value1, String value2);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:113.
  ///
  /// In fa, this message translates to:
  /// **'تأیید مستقل بودن'**
  String get relationshipQueuePageApprovedActions;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:157.
  ///
  /// In fa, this message translates to:
  /// **'تصمیم‌ها ذخیره شدند؛ به‌روزرسانی نمایش انجام نشد. بازخوانی کنید.'**
  String get relationshipQueuePageConfirmMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:181.
  ///
  /// In fa, this message translates to:
  /// **'بررسی ارتباط دوباره باز شد؛ تاریخچه و موجودی حفظ شدند.'**
  String get relationshipQueuePageReopenContent;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:194.
  ///
  /// In fa, this message translates to:
  /// **'بازگشایی انجام نشد یا نمایش به‌روز نشد؛ بازخوانی کنید و دوباره تلاش کنید.'**
  String get relationshipQueuePageReopenMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:214.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی انجام نشد؛ ممکن است تصمیم یا ارتباط جدیدی ثبت شده باشد. بازخوانی کنید.'**
  String get relationshipQueuePageUndoReopenMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:226.
  ///
  /// In fa, this message translates to:
  /// **'صف بررسی ارتباط تراکنش‌ها'**
  String get relationshipQueuePageBuildTitle;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:231.
  ///
  /// In fa, this message translates to:
  /// **'فقط باقی‌ماندهٔ درآمدها و هزینه‌های برگشت‌نخورده بررسی می‌شود.'**
  String get relationshipQueuePageBuildChildren;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:234.
  ///
  /// In fa, this message translates to:
  /// **'جستجوی شرح تراکنش'**
  String get relationshipQueuePageBuildLabelText;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:241.
  ///
  /// In fa, this message translates to:
  /// **'همه'**
  String get relationshipQueuePageBuildLabel;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:258.
  ///
  /// In fa, this message translates to:
  /// **'مستقل‌های بررسی‌شده'**
  String get relationshipQueuePageBuildLabel2;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:265.
  ///
  /// In fa, this message translates to:
  /// **'صفحهٔ {value1} · حداکثر {value2} مورد؛ انتخاب همهٔ نتایج نیست.'**
  String relationshipQueuePageBuildChildren2(String value1, String value2);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:301.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب همین صفحه'**
  String get relationshipQueuePageBuildChildren3;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:306.
  ///
  /// In fa, this message translates to:
  /// **'پاک‌کردن انتخاب'**
  String get relationshipQueuePageBuildChildren4;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:312.
  ///
  /// In fa, this message translates to:
  /// **'مستقل ثبت کن ({value1})'**
  String relationshipQueuePageBuildChildren5(String value1);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:325.
  ///
  /// In fa, this message translates to:
  /// **'بررسی‌شده: {value1} · موفق: {value2} · ناموفق: {value3}'**
  String relationshipQueuePageBuildChildren6(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:338.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره برای ناموفق‌ها'**
  String get relationshipQueuePageBuildChildren7;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:354.
  ///
  /// In fa, this message translates to:
  /// **'موردی در این صفحه برای بررسی وجود ندارد.'**
  String get relationshipQueuePageBuildChildren8;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:367.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش بدون شرح'**
  String get relationshipQueuePageBuildSemanticLabel;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:367.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب {value1}'**
  String relationshipQueuePageBuildSemanticLabel2(String value1);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:381.
  ///
  /// In fa, this message translates to:
  /// **' · مستقل'**
  String get relationshipQueuePageBuildSubtitle;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:381.
  ///
  /// In fa, this message translates to:
  /// **'{value1} · باقی‌مانده: {value2}{value3}'**
  String relationshipQueuePageBuildSubtitle2(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:388.
  ///
  /// In fa, this message translates to:
  /// **'ثبت انجام نشد؛ بازخوانی یا تلاش دوباره با تأیید لازم است.'**
  String get relationshipQueuePageBuildChildren9;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:397.
  ///
  /// In fa, this message translates to:
  /// **'بررسی تکی ارتباط'**
  String get relationshipQueuePageBuildChildren10;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/relationship_queue_page.dart:404.
  ///
  /// In fa, this message translates to:
  /// **'بازگشایی بررسی ارتباط'**
  String get relationshipQueuePageBuildChildren11;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:80.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری تراکنش انجام نشد؛ دوباره تلاش کنید.'**
  String get transactionRelationshipPageLoadMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:97.
  ///
  /// In fa, this message translates to:
  /// **'رخداد و مبلغ معتبر در محدودهٔ مبلغ باقی‌مانده را انتخاب کنید.'**
  String get transactionRelationshipPageSaveMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:121.
  ///
  /// In fa, this message translates to:
  /// **'ثبت ارتباط انجام نشد؛ انتخاب و مبلغ شما حفظ شده است. مبلغ باقی‌مانده را بازخوانی کنید و دوباره تلاش کنید.'**
  String get transactionRelationshipPageSaveMessage2;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:161.
  ///
  /// In fa, this message translates to:
  /// **'باقی‌ماندهٔ تراکنش مستقل ثبت شد؛ ارتباط‌های قبلی حفظ شدند.'**
  String get transactionRelationshipPageDecideContent;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:162.
  ///
  /// In fa, this message translates to:
  /// **'بررسی ارتباط دوباره باز شد؛ اکنون می‌توانید ارتباط ثبت کنید.'**
  String get transactionRelationshipPageDecideContent2;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:175.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تصمیم انجام نشد؛ انتخاب و مبلغ شما حفظ شده است. اطلاعات را بازخوانی کنید و دوباره تلاش کنید.'**
  String get transactionRelationshipPageDecideMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:195.
  ///
  /// In fa, this message translates to:
  /// **'بدون تاریخ'**
  String get transactionRelationshipPageDateMessage;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:219.
  ///
  /// In fa, this message translates to:
  /// **'تعیین ارتباط تراکنش'**
  String get transactionRelationshipPageBuildTitle;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:249.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ تراکنش: {value1}'**
  String transactionRelationshipPageBuildChildren(String value1);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:251.
  ///
  /// In fa, this message translates to:
  /// **'حساب در دسترس نیست'**
  String get transactionRelationshipPageBuildChildren2;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:251.
  ///
  /// In fa, this message translates to:
  /// **'حساب: {value1}'**
  String transactionRelationshipPageBuildChildren3(String value1);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:253.
  ///
  /// In fa, this message translates to:
  /// **'باقی‌مانده برای ارتباط: {value1}'**
  String transactionRelationshipPageBuildChildren4(String value1);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:258.
  ///
  /// In fa, this message translates to:
  /// **'بررسی‌شده: باقی‌ماندهٔ تراکنش به تعهدی مربوط نیست.'**
  String get transactionRelationshipPageBuildChildren5;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:261.
  ///
  /// In fa, this message translates to:
  /// **'برای ثبت ارتباط جدید، ابتدا بررسی را دوباره باز کنید. ارتباط‌های قبلی حفظ شده‌اند.'**
  String get transactionRelationshipPageBuildChildren6;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:272.
  ///
  /// In fa, this message translates to:
  /// **'اگر مبلغ باقی‌مانده مستقل است، آن را صریحاً تأیید کنید. این تصمیم ارتباط‌های قبلی، موجودی و تاریخچه را تغییر نمی‌دهد.'**
  String get transactionRelationshipPageBuildChildren7;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:278.
  ///
  /// In fa, this message translates to:
  /// **'به تعهدی مربوط نیست'**
  String get transactionRelationshipPageBuildChildren8;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:283.
  ///
  /// In fa, this message translates to:
  /// **'در حال ثبت…'**
  String get transactionRelationshipPageBuildChildren9;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:287.
  ///
  /// In fa, this message translates to:
  /// **'تعهد و نوبت مربوط را انتخاب کنید؛ هیچ نتیجه یا مبلغ مورد انتظاری تغییر نمی‌کند.'**
  String get transactionRelationshipPageBuildChildren10;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:291.
  ///
  /// In fa, this message translates to:
  /// **'جستجوی تعهد'**
  String get transactionRelationshipPageBuildLabelText;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:297.
  ///
  /// In fa, this message translates to:
  /// **'هنوز رخدادی برای انتخاب ثبت نشده است.'**
  String get transactionRelationshipPageBuildChildren11;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:299.
  ///
  /// In fa, this message translates to:
  /// **'تعهدی با این عبارت پیدا نشد.'**
  String get transactionRelationshipPageBuildChildren12;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:310.
  ///
  /// In fa, this message translates to:
  /// **' · بایگانی‌شده'**
  String get transactionRelationshipPageBuildSubtitle;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:329.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ ارتباط به {value1}'**
  String transactionRelationshipPageBuildLabelText2(String value1);

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:337.
  ///
  /// In fa, this message translates to:
  /// **'تأیید ارتباط'**
  String get transactionRelationshipPageBuildChildren13;

  /// Application copy. Original usage: lib/features/reconciliation/presentation/transaction_relationship_page.dart:341.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ این تراکنش به‌طور کامل مرتبط شده است.'**
  String get transactionRelationshipPageBuildChildren14;

  /// Application copy. Original usage: lib/features/reminders/application/reminder_platform.dart:129.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری پلن‌اکت'**
  String get reminderPlatformScheduleTitle;

  /// Application copy. Original usage: lib/features/reminders/application/reminder_platform.dart:130.
  ///
  /// In fa, this message translates to:
  /// **'زمان انجام یک تعهد فرا رسیده است.'**
  String get reminderPlatformScheduleBody;

  /// Application copy. Original usage: lib/features/reminders/application/reminder_platform.dart:135.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها'**
  String get reminderPlatformScheduleAndroid;

  /// Application copy. Original usage: lib/features/reminders/application/reminder_platform.dart:136.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری تعهدهای پلن‌اکت'**
  String get reminderPlatformScheduleChannelDescription;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:14.
  ///
  /// In fa, this message translates to:
  /// **'{value1}، {value2}'**
  String occurrenceRemindersReminderRuleLabelMessage(
    String value1,
    String value2,
  );

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:16.
  ///
  /// In fa, this message translates to:
  /// **'هنگام شروع'**
  String get occurrenceRemindersReminderRuleLabelMessage2;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:19.
  ///
  /// In fa, this message translates to:
  /// **'{value1} روز'**
  String occurrenceRemindersValueMessage(String value1);

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:21.
  ///
  /// In fa, this message translates to:
  /// **'{value1} ساعت'**
  String occurrenceRemindersValueMessage2(String value1);

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:23.
  ///
  /// In fa, this message translates to:
  /// **'{value1} دقیقه'**
  String occurrenceRemindersValueMessage3(String value1);

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:24.
  ///
  /// In fa, this message translates to:
  /// **'{value1} ثانیه'**
  String occurrenceRemindersValueMessage4(String value1);

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:25.
  ///
  /// In fa, this message translates to:
  /// **'بعد'**
  String get occurrenceRemindersReminderRuleLabelMessage3;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:25.
  ///
  /// In fa, this message translates to:
  /// **'قبل'**
  String get occurrenceRemindersReminderRuleLabelMessage4;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:25.
  ///
  /// In fa, this message translates to:
  /// **'{value1} {value2} از شروع'**
  String occurrenceRemindersReminderRuleLabelMessage5(
    String value1,
    String value2,
  );

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:66.
  ///
  /// In fa, this message translates to:
  /// **'{value1}، ساعت {value2}'**
  String occurrenceRemindersOccurrenceLabelMessage(
    String value1,
    String value2,
  );

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:67.
  ///
  /// In fa, this message translates to:
  /// **'{value1} (بدون ساعت)'**
  String occurrenceRemindersOccurrenceLabelMessage2(String value1);

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:97.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها ذخیره نشدند؛ وضعیت نوبت را بررسی و دوباره تلاش کنید.'**
  String get occurrenceRemindersEditContent;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:113.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها ذخیره شدند؛ هماهنگ‌سازی اعلان‌ها در انتظار است.'**
  String get occurrenceRemindersEditContent2;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:114.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها ذخیره شدند.'**
  String get occurrenceRemindersEditContent3;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:126.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها ذخیره شدند؛ برای تازه‌سازی نمایش دوباره وارد صفحه شوید.'**
  String get occurrenceRemindersEditContent4;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:142.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری یادآوری‌ها انجام نشد؛ تلاش دوباره'**
  String get occurrenceRemindersBuildLabel;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:154.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌های {value1}'**
  String occurrenceRemindersBuildTitle(String value1);

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:164.
  ///
  /// In fa, this message translates to:
  /// **'برای ویرایش، ابتدا نتیجهٔ نوبت را بازگردانید'**
  String get occurrenceRemindersBuildTooltip;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:165.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش یادآوری‌ها'**
  String get occurrenceRemindersBuildTooltip2;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:219.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش یادآوری‌های این نوبت'**
  String get occurrenceRemindersBuildTitle2;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:226.
  ///
  /// In fa, this message translates to:
  /// **'تغییر فقط برای این نوبت ذخیره می‌شود؛ سابقهٔ اعلان‌ها محفوظ می‌ماند.'**
  String get occurrenceRemindersBuildChildren;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:233.
  ///
  /// In fa, this message translates to:
  /// **'حذف این یادآوری'**
  String get occurrenceRemindersBuildTooltip3;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:242.
  ///
  /// In fa, this message translates to:
  /// **'حذف همهٔ یادآوری‌های این نوبت'**
  String get occurrenceRemindersBuildChildren2;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:264.
  ///
  /// In fa, this message translates to:
  /// **'دقایق قبل از شروع (دلخواه)'**
  String get occurrenceRemindersBuildLabelText;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:275.
  ///
  /// In fa, this message translates to:
  /// **'تعداد دقیقه را صفر یا بیشتر وارد کنید.'**
  String get occurrenceRemindersBuildOnPressed;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:282.
  ///
  /// In fa, this message translates to:
  /// **'افزودن یادآوری'**
  String get occurrenceRemindersBuildChildren3;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:286.
  ///
  /// In fa, this message translates to:
  /// **'این نوبت ساعت ندارد؛ افزودن یادآوری نسبی نیازمند انتخاب صریح ساعت است.'**
  String get occurrenceRemindersBuildChildren4;

  /// Application copy. Original usage: lib/features/reminders/presentation/occurrence_reminders.dart:298.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ یادآوری‌ها'**
  String get occurrenceRemindersBuildActions;

  /// Application copy. Original usage: lib/features/reminders/presentation/reminder_permissions_card.dart:27.
  ///
  /// In fa, this message translates to:
  /// **'مجوزها فعال شدند و یادآوری‌های آینده دوباره زمان‌بندی شدند.'**
  String get reminderPermissionsCardEnableMessage;

  /// Application copy. Original usage: lib/features/reminders/presentation/reminder_permissions_card.dart:28.
  ///
  /// In fa, this message translates to:
  /// **'مجوز اعلان یا زنگ دقیق فعال نیست. یادآوری‌ها ذخیره شده‌اند؛ مجوزها را بررسی کنید و دوباره تلاش کنید.'**
  String get reminderPermissionsCardEnableMessage2;

  /// Application copy. Original usage: lib/features/reminders/presentation/reminder_permissions_card.dart:34.
  ///
  /// In fa, this message translates to:
  /// **'فعال‌سازی یادآوری‌ها انجام نشد. اطلاعات شما محفوظ است؛ دوباره تلاش کنید.'**
  String get reminderPermissionsCardEnableMessage3;

  /// Application copy. Original usage: lib/features/reminders/presentation/reminder_permissions_card.dart:49.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌های دستگاه'**
  String get reminderPermissionsCardBuildTitle;

  /// Application copy. Original usage: lib/features/reminders/presentation/reminder_permissions_card.dart:51.
  ///
  /// In fa, this message translates to:
  /// **'برای نمایش به‌موقع یادآوری‌ها، اجازهٔ اعلان و زنگ دقیق لازم است. اگر تنظیمات اعلان دستگاه باز شد، اعلان‌های برنامه را فعال کنید و به برنامه برگردید تا یادآوری‌ها بازسازی شوند. ثبت و نگهداری تعهدها به این مجوزها وابسته نیست.'**
  String get reminderPermissionsCardBuildSubtitle;

  /// Application copy. Original usage: lib/features/reminders/presentation/reminder_permissions_card.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'در حال بررسی مجوزها'**
  String get reminderPermissionsCardBuildLabel;

  /// Application copy. Original usage: lib/features/reminders/presentation/reminder_permissions_card.dart:71.
  ///
  /// In fa, this message translates to:
  /// **'فعال‌سازی و بازسازی یادآوری‌ها'**
  String get reminderPermissionsCardBuildLabel2;

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:59.
  ///
  /// In fa, this message translates to:
  /// **'کمینه: {value1}؛ بیشینه: {value2}؛ خط مبنا صفر است.'**
  String financialReportChartBuildChildren(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:62.
  ///
  /// In fa, this message translates to:
  /// **'گروه‌ها از راست به چپ: {value1}'**
  String financialReportChartBuildChildren2(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:64.
  ///
  /// In fa, this message translates to:
  /// **'زمان از راست به چپ؛ مقدار هر نقطه در جزئیات آمده است.'**
  String get financialReportChartBuildChildren3;

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:67.
  ///
  /// In fa, this message translates to:
  /// **'جمع منفی ناشی از اصلاح در سهم دایره لحاظ نمی‌شود؛ مقدار دقیق در جزئیات است.'**
  String get financialReportChartBuildChildren4;

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'سهم مثبت برای نمایش دایره وجود ندارد.'**
  String get financialReportChartBuildChildren5;

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:72.
  ///
  /// In fa, this message translates to:
  /// **'همهٔ مقادیر صفر هستند.'**
  String get financialReportChartBuildChildren6;

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:100.
  ///
  /// In fa, this message translates to:
  /// **'؛ {value1}٪'**
  String financialReportChartBuildChildren7(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:100.
  ///
  /// In fa, this message translates to:
  /// **'{value1} · {value2}: {value3}{value4}'**
  String financialReportChartBuildChildren8(
    String value1,
    String value2,
    String value3,
    String value4,
  );

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:104.
  ///
  /// In fa, this message translates to:
  /// **'مقادیر دقیق نمودار'**
  String get financialReportChartBuildTitle;

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'؛ '**
  String get commonClauseSeparator;

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'{value1} {value2}{value3}'**
  String financialReportChartBuildChildren9(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/features/reports/presentation/financial_report_chart.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'{value1}: {value2}'**
  String financialReportChartBuildChildren10(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/report_bar_chart.dart:35.
  ///
  /// In fa, this message translates to:
  /// **'مبدأ میله‌ها صفر است؛ مقدار منفی با علامت − مشخص شده است.'**
  String get reportBarChartBuildChildren;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:26.
  ///
  /// In fa, this message translates to:
  /// **'مرور هفته و ماه'**
  String get reportsPagePersonalReportKindOverview;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:27.
  ///
  /// In fa, this message translates to:
  /// **'برنامه در برابر عملکرد'**
  String get reportsPagePersonalReportKindPerformance;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:28.
  ///
  /// In fa, this message translates to:
  /// **'موارد نیازمند پیگیری'**
  String get reportsPagePersonalReportKindAttention;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:29.
  ///
  /// In fa, this message translates to:
  /// **'دخل‌وخرج'**
  String get reportsPagePersonalReportKindCashFlow;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:30.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت‌های برنامه‌ریزی‌شده و واقعی'**
  String get reportsPagePersonalReportKindSettlement;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:31.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت کلاس‌ها و بسته‌ها'**
  String get reportsPagePersonalReportKindPackages;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:32.
  ///
  /// In fa, this message translates to:
  /// **'گزارش موضوعی و هشتگ'**
  String get reportsPagePersonalReportKindTopic;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:33.
  ///
  /// In fa, this message translates to:
  /// **'برنامه و پرداخت‌های پیش‌رو'**
  String get reportsPagePersonalReportKindUpcoming;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:34.
  ///
  /// In fa, this message translates to:
  /// **'جابه‌جایی و لغو برنامه‌ها'**
  String get reportsPagePersonalReportKindChanges;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:35.
  ///
  /// In fa, this message translates to:
  /// **'گردش و موجودی حساب‌ها'**
  String get reportsPagePersonalReportKindAccounts;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:36.
  ///
  /// In fa, this message translates to:
  /// **'هزینه‌های تکرارشونده و اقساط'**
  String get reportsPagePersonalReportKindRecurringFinance;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:144.
  ///
  /// In fa, this message translates to:
  /// **'گزارش بارگیری نشد؛ دوباره تلاش کنید.'**
  String get reportsPageLoadMessage;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:175.
  ///
  /// In fa, this message translates to:
  /// **'بازه باید به‌ترتیب تاریخ و حداکثر ۳۶۶ روز باشد.'**
  String get reportsPagePickDateContent;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:195.
  ///
  /// In fa, this message translates to:
  /// **'این هفته'**
  String get reportsPagePresetMessage;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:198.
  ///
  /// In fa, this message translates to:
  /// **'ماه گذشته'**
  String get reportsPagePresetMessage2;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:201.
  ///
  /// In fa, this message translates to:
  /// **'۳۰ روز آینده'**
  String get reportsPagePresetMessage3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:258.
  ///
  /// In fa, this message translates to:
  /// **'فیلترهای گزارش'**
  String get reportsPageFiltersTitle;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:260.
  ///
  /// In fa, this message translates to:
  /// **'بدون جست‌وجو'**
  String get reportsPageFiltersSubtitle;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:260.
  ///
  /// In fa, this message translates to:
  /// **'هشتگ‌ها: {value1}؛ {value2}'**
  String reportsPageFiltersSubtitle2(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:268.
  ///
  /// In fa, this message translates to:
  /// **'جست‌وجو در عنوان و توضیحات'**
  String get reportsPageFiltersLabelText;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:273.
  ///
  /// In fa, this message translates to:
  /// **'روش انتخاب هشتگ'**
  String get reportsPageFiltersChildren;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:274.
  ///
  /// In fa, this message translates to:
  /// **'حداقل یکی از هشتگ‌ها'**
  String get reportsPageFiltersChildren2;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:275.
  ///
  /// In fa, this message translates to:
  /// **'همهٔ هشتگ‌ها'**
  String get reportsPageFiltersChildren3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:276.
  ///
  /// In fa, this message translates to:
  /// **'بدون هشتگ'**
  String get reportsPageFiltersChildren4;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:278.
  ///
  /// In fa, this message translates to:
  /// **'هنوز هشتگی ثبت نشده است.'**
  String get reportsPageFiltersChildren5;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:302.
  ///
  /// In fa, this message translates to:
  /// **'حذف هشتگ از نتایج'**
  String get reportsPageFiltersTitle2;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:309.
  ///
  /// In fa, this message translates to:
  /// **'حذف {value1}'**
  String reportsPageFiltersLabel(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:336.
  ///
  /// In fa, this message translates to:
  /// **'دوره یا بسته'**
  String get reportsPageFiltersChildren6;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:341.
  ///
  /// In fa, this message translates to:
  /// **'{value1} — {value2}'**
  String reportsPageFiltersChildren7(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:343.
  ///
  /// In fa, this message translates to:
  /// **'نوع تعهد'**
  String get reportsPageFiltersChildren8;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:348.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت نوبت'**
  String get reportsPageFiltersChildren9;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:359.
  ///
  /// In fa, this message translates to:
  /// **'واحد پول'**
  String get reportsPageFiltersChildren10;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:367.
  ///
  /// In fa, this message translates to:
  /// **'جهت مالی'**
  String get reportsPageFiltersChildren11;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:369.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت'**
  String get reportsPageFiltersChildren12;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:382.
  ///
  /// In fa, this message translates to:
  /// **'منبع تراکنش'**
  String get reportsPageFiltersChildren13;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:383.
  ///
  /// In fa, this message translates to:
  /// **'دستی'**
  String get reportsPageFiltersChildren14;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:384.
  ///
  /// In fa, this message translates to:
  /// **'پیامک'**
  String get reportsPageFiltersChildren15;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:385.
  ///
  /// In fa, this message translates to:
  /// **'واردشده'**
  String get reportsPageFiltersChildren16;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:390.
  ///
  /// In fa, this message translates to:
  /// **'مبنای هشتگ تراکنش'**
  String get reportsPageFiltersChildren17;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:391.
  ///
  /// In fa, this message translates to:
  /// **'هشتگ خود تراکنش'**
  String get reportsPageFiltersChildren18;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:392.
  ///
  /// In fa, this message translates to:
  /// **'سهم تطبیق‌یافته با تعهد هشتگ‌دار'**
  String get reportsPageFiltersChildren19;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:395.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت تسویه'**
  String get reportsPageFiltersChildren20;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:401.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر بر اساس تاریخ اولیه'**
  String get reportsPageFiltersTitle3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:416.
  ///
  /// In fa, this message translates to:
  /// **'پاک‌کردن فیلترها (تاریخ حفظ می‌شود)'**
  String get reportsPageFiltersChildren21;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:432.
  ///
  /// In fa, this message translates to:
  /// **'تازه‌کردن گزارش'**
  String get reportsPageBuildTooltip;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:454.
  ///
  /// In fa, this message translates to:
  /// **'نوع گزارش'**
  String get reportsPageBuildLabelText;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:480.
  ///
  /// In fa, this message translates to:
  /// **'این ماه'**
  String get reportsPageBuildChildren;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:497.
  ///
  /// In fa, this message translates to:
  /// **'از {value1}'**
  String reportsPageBuildChildren2(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:501.
  ///
  /// In fa, this message translates to:
  /// **'تا {value1}'**
  String reportsPageBuildChildren3(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:507.
  ///
  /// In fa, this message translates to:
  /// **'فقط داده‌های ثبت‌شده روی این دستگاه؛ پایان بازه شامل تمام روز است.'**
  String get reportsPageBuildChildren4;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:531.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب: {value1}؛ حذف: {value2}'**
  String reportsPageBuildChildren5(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:553.
  ///
  /// In fa, this message translates to:
  /// **'نتیجهٔ فعلی برای تاریخ نوبت‌های انتخاب‌شده؛ ثبت نتیجه، زمان واقعی انجام را مشخص نمی‌کند.'**
  String get reportsPageContentMessage;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:559.
  ///
  /// In fa, this message translates to:
  /// **'توزیع وضعیت نوبت‌ها'**
  String get reportsPageContentTitle;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:579.
  ///
  /// In fa, this message translates to:
  /// **'نوبت‌های ثبت‌شده: {value1}؛ تعیین‌وضعیت‌شده: {value2}'**
  String reportsPageContentMessage2(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:596.
  ///
  /// In fa, this message translates to:
  /// **'نوبت ثبت‌شده‌ای با این فیلترها وجود ندارد.'**
  String get reportsPageContentMessage3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:605.
  ///
  /// In fa, this message translates to:
  /// **'انتقال، موجودی اولیه و تعدیل در دخل‌وخرج حساب نمی‌شوند؛ بازپرداخت در ورودی لحاظ می‌شود.'**
  String get reportsPageContentMessage4;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:613.
  ///
  /// In fa, this message translates to:
  /// **'فقط سهم تطبیق‌یافتهٔ تراکنش‌های معتبر؛ این نما گزارش کل گردش نقدی نیست.'**
  String get reportsPageContentMessage5;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:630.
  ///
  /// In fa, this message translates to:
  /// **'جریان نقدی — {value1}'**
  String reportsPageContentMessage6(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:631.
  ///
  /// In fa, this message translates to:
  /// **'مقایسهٔ دخل‌وخرج'**
  String get reportsPageContentMessage7;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:634.
  ///
  /// In fa, this message translates to:
  /// **'خالص'**
  String get reportsPageContentMessage8;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:644.
  ///
  /// In fa, this message translates to:
  /// **'دریافت یا پرداختی با این فیلترها وجود ندارد.'**
  String get reportsPageContentMessage9;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:647.
  ///
  /// In fa, this message translates to:
  /// **'گروه‌بندی گردش'**
  String get reportsPageContentMessage10;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:648.
  ///
  /// In fa, this message translates to:
  /// **'روز'**
  String get reportsPageContentMessage11;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:649.
  ///
  /// In fa, this message translates to:
  /// **'ماه شمسی'**
  String get reportsPageContentMessage12;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:688.
  ///
  /// In fa, this message translates to:
  /// **'مقایسهٔ خالص گروه‌ها — {value1}'**
  String reportsPageContentMessage13(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:698.
  ///
  /// In fa, this message translates to:
  /// **'{value1}؛ خالص: {value2}'**
  String reportsPageContentMessage14(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:701.
  ///
  /// In fa, this message translates to:
  /// **'مقایسهٔ گردش گروه'**
  String get reportsPageContentMessage15;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:723.
  ///
  /// In fa, this message translates to:
  /// **'تسویه بر اساس سررسید نوبت و تطبیق‌های معتبر فعلی است؛ تاریخ پرداخت ممکن است خارج از بازه باشد.'**
  String get reportsPageContentMessage16;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:747.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ تسویه‌شده و باقی‌ماندهٔ تعهدات'**
  String get reportsPageContentTitle2;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:748.
  ///
  /// In fa, this message translates to:
  /// **'تعهدات'**
  String get reportsPageContentLabels;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:755.
  ///
  /// In fa, this message translates to:
  /// **'تسویه‌شده'**
  String get reportsPageFinancialDueStateSettled;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:756.
  ///
  /// In fa, this message translates to:
  /// **'باقی‌ماندهٔ تسویهٔ جزئی'**
  String get reportsPageFinancialDueStatePartial;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:757.
  ///
  /// In fa, this message translates to:
  /// **'در انتظار'**
  String get reportsPageFinancialDueStatePending;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:758.
  ///
  /// In fa, this message translates to:
  /// **'سررسیدگذشته'**
  String get reportsPageFinancialDueStateOverdue;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:781.
  ///
  /// In fa, this message translates to:
  /// **'تسویهٔ جزئی در انتظار'**
  String get reportsPageFinancialDueStatePartial2;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:779.
  ///
  /// In fa, this message translates to:
  /// **'{value1}: {value2} تعهد مالی'**
  String reportsPageContentMessage17(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:786.
  ///
  /// In fa, this message translates to:
  /// **'برنامه در برابر تسویه'**
  String get reportsPageContentMessage18;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:787.
  ///
  /// In fa, this message translates to:
  /// **'برنامه'**
  String get reportsPageContentMessage19;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:788.
  ///
  /// In fa, this message translates to:
  /// **'تطبیق'**
  String get reportsPageContentMessage20;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:789.
  ///
  /// In fa, this message translates to:
  /// **'باقی‌مانده'**
  String get reportsPageContentMessage21;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:792.
  ///
  /// In fa, this message translates to:
  /// **'برنامه: {value1}؛ تطبیق: {value2}؛ باقی‌مانده: {value3}'**
  String reportsPageContentMessage22(
    String value1,
    String value2,
    String value3,
  );

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:798.
  ///
  /// In fa, this message translates to:
  /// **'\nمازاد: {value1}'**
  String reportsPageContentSubtitle(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:798.
  ///
  /// In fa, this message translates to:
  /// **'{value1}؛ {value2}\nبرنامه: {value3}؛ باقی‌مانده: {value4}{value5}'**
  String reportsPageContentSubtitle2(
    String value1,
    String value2,
    String value3,
    String value4,
    String value5,
  );

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:811.
  ///
  /// In fa, this message translates to:
  /// **'انتظار مالی ثبت‌شده‌ای با این فیلترها وجود ندارد.'**
  String get reportsPageContentMessage23;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:819.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار دفتر تا پایان {value1}؛ تعداد برنامه‌ریزی‌شده و حضور، معادل مصرف اعتبار نیست.'**
  String reportsPageContentMessage24(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:824.
  ///
  /// In fa, this message translates to:
  /// **'{value1} — بسته از {value2}'**
  String reportsPageContentMessage25(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:827.
  ///
  /// In fa, this message translates to:
  /// **'مقایسهٔ اعتبار دفتر'**
  String get reportsPageContentTitle3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:830.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار'**
  String get reportsPageContentData;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:831.
  ///
  /// In fa, this message translates to:
  /// **'کسر دفتر'**
  String get reportsPageContentData2;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:842.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار تنظیم‌شدهٔ بسته: {value1} {value2}'**
  String reportsPageContentMessage26(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:846.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار: {value1}؛ کسر دفتر: {value2}؛ باقی‌مانده: {value3} {value4}'**
  String reportsPageContentMessage27(
    String value1,
    String value2,
    String value3,
    String value4,
  );

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:850.
  ///
  /// In fa, this message translates to:
  /// **'اعطای اعتبار در دفتر ثبت نشده است؛ باقی‌ماندهٔ قابل اتکا در دسترس نیست.'**
  String get reportsPageContentMessage28;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:853.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ تعیین نشده'**
  String get reportsPageContentMessage29;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:853.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار تا: {value1}'**
  String reportsPageContentMessage30(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:858.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ اعتبار گذشته است؛ باقی‌ماندهٔ دفتر به معنی امکان استفاده نیست.'**
  String get reportsPageContentMessage31;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:861.
  ///
  /// In fa, this message translates to:
  /// **'تعیین نشده'**
  String get reportsPageContentMessage32;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:861.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نشده'**
  String get reportsPageContentMessage33;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:861.
  ///
  /// In fa, this message translates to:
  /// **'پایان برنامه: {value1}؛ پایان واقعی: {value2}'**
  String reportsPageContentMessage34(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:864.
  ///
  /// In fa, this message translates to:
  /// **'در این بازه تغییری در دفتر اعتبار ثبت نشده است.'**
  String get reportsPageContentMessage35;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:871.
  ///
  /// In fa, this message translates to:
  /// **'؛ {value1}'**
  String reportsPageContentSubtitle3(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:878.
  ///
  /// In fa, this message translates to:
  /// **'بسته‌ای با این فیلترها وجود ندارد.'**
  String get reportsPageContentMessage36;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:884.
  ///
  /// In fa, this message translates to:
  /// **'برنامهٔ ثبت‌شده و پیش‌نمایش'**
  String get reportsPageContentTitle4;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:887.
  ///
  /// In fa, this message translates to:
  /// **'نوبت ثبت‌شده'**
  String get reportsPageContentData3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:892.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نمایش ذخیره‌نشده'**
  String get reportsPageContentData4;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:901.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌نمایش ذخیره‌نشده: {value1}'**
  String reportsPageContentMessage37(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:904.
  ///
  /// In fa, this message translates to:
  /// **'این نوبت‌ها هنوز ثبت نشده‌اند و در شمارش عملکرد، تسویه و مصرف اعتبار وارد نمی‌شوند.'**
  String get reportsPageContentMessage38;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:914.
  ///
  /// In fa, this message translates to:
  /// **'{value1}؛ پیش‌نمایش'**
  String reportsPageContentSubtitle4(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:923.
  ///
  /// In fa, this message translates to:
  /// **'جمع مالی بالا فقط انتظارات ثبت‌شده را شامل می‌شود؛ مبلغ نوبت‌های پیش‌نمایش در آن نیست.'**
  String get reportsPageContentMessage39;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:931.
  ///
  /// In fa, this message translates to:
  /// **'حجم موارد نیازمند پیگیری (گروه‌ها ممکن است هم‌پوشانی داشته باشند)'**
  String get reportsPageContentTitle5;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:934.
  ///
  /// In fa, this message translates to:
  /// **'نوبت نیازمند پیگیری'**
  String get reportsPageContentData5;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:939.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش نیازمند تعیین ارتباط'**
  String get reportsPageContentData6;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:948.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش‌های نیازمند تعیین ارتباط: {value1}'**
  String reportsPageContentMessage40(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:954.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش'**
  String get reportsPageContentTitle6;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:956.
  ///
  /// In fa, this message translates to:
  /// **'باقی‌مانده: {value1}؛ {value2}'**
  String reportsPageContentSubtitle5(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:970.
  ///
  /// In fa, this message translates to:
  /// **'موجودی از تمام دفتر حساب محاسبه می‌شود؛ هشتگ و جست‌وجو فقط ریز گردش را محدود می‌کنند. این موجودی الزاماً موجودی واقعی بانک نیست.'**
  String get reportsPageContentMessage41;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:976.
  ///
  /// In fa, this message translates to:
  /// **'تغییر موجودی از کل دفتر حساب'**
  String get reportsPageContentMessage42;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:977.
  ///
  /// In fa, this message translates to:
  /// **'ابتدای دوره'**
  String get reportsPageContentMessage43;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:978.
  ///
  /// In fa, this message translates to:
  /// **'خالص گردش کل دوره'**
  String get reportsPageContentMessage44;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:979.
  ///
  /// In fa, this message translates to:
  /// **'پایان دوره'**
  String get reportsPageContentMessage45;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:982.
  ///
  /// In fa, this message translates to:
  /// **'روند موجودی پایان روز از کل دفتر'**
  String get reportsPageContentTitle7;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:991.
  ///
  /// In fa, this message translates to:
  /// **'موجودی'**
  String get reportsPageContentSeries;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1001.
  ///
  /// In fa, this message translates to:
  /// **'ابتدای دوره: {value1}'**
  String reportsPageContentMessage46(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1003.
  ///
  /// In fa, this message translates to:
  /// **'خالص گردش کل دوره: {value1}'**
  String reportsPageContentMessage47(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1005.
  ///
  /// In fa, this message translates to:
  /// **'پایان دوره: {value1}'**
  String reportsPageContentMessage48(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1006.
  ///
  /// In fa, this message translates to:
  /// **'ریز گردش مطابق فیلترهای انتخاب‌شده:'**
  String get reportsPageContentMessage49;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1014.
  ///
  /// In fa, this message translates to:
  /// **'حسابی با این فیلترها وجود ندارد.'**
  String get reportsPageContentMessage50;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1030.
  ///
  /// In fa, this message translates to:
  /// **'مقایسه با بازهٔ هم‌طول قبلی: {value1} تا {value2}؛ همان فیلترها اعمال می‌شوند.'**
  String reportsPageResultMessage(String value1, String value2);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1041.
  ///
  /// In fa, this message translates to:
  /// **'مقایسهٔ دوره‌ها — {value1}'**
  String reportsPageCashChartsTitle(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1043.
  ///
  /// In fa, this message translates to:
  /// **'دورهٔ قبلی'**
  String get reportsPageCashChartsLabels;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1043.
  ///
  /// In fa, this message translates to:
  /// **'دورهٔ انتخاب‌شده'**
  String get reportsPageCashChartsLabels2;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1056.
  ///
  /// In fa, this message translates to:
  /// **'درآمد و هزینهٔ ماهانه — {value1}'**
  String reportsPageCashChartsTitle2(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1077.
  ///
  /// In fa, this message translates to:
  /// **'سهم منابع درآمد بر اساس دسته'**
  String get reportsPageCashChartsTitle3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1077.
  ///
  /// In fa, this message translates to:
  /// **'سهم دسته‌های هزینه'**
  String get reportsPageCashChartsTitle4;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1080.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ'**
  String get reportsPageCashChartsSeries;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1094.
  ///
  /// In fa, this message translates to:
  /// **'تعهدهای صریحاً تکرارشونده؛ مبنا سررسید و تطبیق فعلی است، نه اصل بدهی یا تاریخ پرداخت. آینده فقط شامل انتظارهای مالی ثبت‌شده است.'**
  String get reportsPageRecurringChartsMessage;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1097.
  ///
  /// In fa, this message translates to:
  /// **'روند هزینه‌های تکرارشونده و اقساط'**
  String get reportsPageRecurringChartsTitle;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1117.
  ///
  /// In fa, this message translates to:
  /// **'تطبیق واقعی'**
  String get reportsPageRecurringChartsSeries;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1156.
  ///
  /// In fa, this message translates to:
  /// **'\nنتیجهٔ واقعی ثبت نشده است.'**
  String get reportsPageOccurrenceTileSubtitle;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1157.
  ///
  /// In fa, this message translates to:
  /// **'\nتاریخ اولیه: {value1}'**
  String reportsPageOccurrenceTileSubtitle2(String value1);

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1158.
  ///
  /// In fa, this message translates to:
  /// **'؛ تعهد بایگانی‌شده'**
  String get reportsPageOccurrenceTileSubtitle3;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1155.
  ///
  /// In fa, this message translates to:
  /// **'{value1}؛ {value2}{value3}{value4}{value5}'**
  String reportsPageOccurrenceTileSubtitle4(
    String value1,
    String value2,
    String value3,
    String value4,
    String value5,
  );

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1167.
  ///
  /// In fa, this message translates to:
  /// **'{value1}؛ {value2}؛ {value3}\n{value4}'**
  String reportsPageMovementTileSubtitle(
    String value1,
    String value2,
    String value3,
    String value4,
  );

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1181.
  ///
  /// In fa, this message translates to:
  /// **'تسویه نشده'**
  String get reportsPageReportSettlementStateUnpaid;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1182.
  ///
  /// In fa, this message translates to:
  /// **'تسویهٔ جزئی'**
  String get reportsPageReportSettlementStatePartial;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1183.
  ///
  /// In fa, this message translates to:
  /// **'تسویه شده'**
  String get reportsPageReportSettlementStateSettled;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1184.
  ///
  /// In fa, this message translates to:
  /// **'تطبیق دارای مازاد'**
  String get reportsPageReportSettlementStateOverpaid;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1187.
  ///
  /// In fa, this message translates to:
  /// **'جلسه'**
  String get reportsPageEntitlementUnitTypeSession;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1188.
  ///
  /// In fa, this message translates to:
  /// **'ساعت'**
  String get reportsPageEntitlementUnitTypeHour;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1189.
  ///
  /// In fa, this message translates to:
  /// **'مراجعه'**
  String get reportsPageEntitlementUnitTypeVisit;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1190.
  ///
  /// In fa, this message translates to:
  /// **'واحد اعتبار'**
  String get reportsPageEntitlementUnitTypeCredit;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1193.
  ///
  /// In fa, this message translates to:
  /// **'اعطای اعتبار'**
  String get reportsPageEntitlementEntryTypeGrant;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1194.
  ///
  /// In fa, this message translates to:
  /// **'مصرف'**
  String get reportsPageEntitlementEntryTypeConsume;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1196.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح اعتبار'**
  String get reportsPageEntitlementEntryTypeAdjustment;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1197.
  ///
  /// In fa, this message translates to:
  /// **'انقضا'**
  String get reportsPageEntitlementEntryTypeExpire;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1198.
  ///
  /// In fa, this message translates to:
  /// **'بازپرداخت اعتبار'**
  String get reportsPageEntitlementEntryTypeRefund;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1201.
  ///
  /// In fa, this message translates to:
  /// **'انجام‌شده'**
  String get occurrenceCompleted;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1202.
  ///
  /// In fa, this message translates to:
  /// **'حضور'**
  String get reportsPageActualOutcomeAttended;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1203.
  ///
  /// In fa, this message translates to:
  /// **'لغو'**
  String get reportsPageActualOutcomeCancelled;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1204.
  ///
  /// In fa, this message translates to:
  /// **'ازدست‌رفته'**
  String get reportsPageActualOutcomeMissed;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1205.
  ///
  /// In fa, this message translates to:
  /// **'عدم حضور'**
  String get occurrenceSkipped;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1206.
  ///
  /// In fa, this message translates to:
  /// **'نتیجهٔ جزئی'**
  String get reportsPageActualOutcomePartial;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1207.
  ///
  /// In fa, this message translates to:
  /// **'بازگشایی‌شده'**
  String get reportsPageActualOutcomeReopened;

  /// Application copy. Original usage: lib/features/reports/presentation/reports_page.dart:1215.
  ///
  /// In fa, this message translates to:
  /// **'تعدیل'**
  String get reportsPageAccountEntryTypeAdjustment;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:55.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد / حضور داشت'**
  String get occurrenceActionsAvailableOccurrenceActionsLabel;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:56.
  ///
  /// In fa, this message translates to:
  /// **'این نوبت به‌عنوان انجام‌شده ثبت می‌شود.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:62.
  ///
  /// In fa, this message translates to:
  /// **'لغو توسط ارائه‌دهنده'**
  String get occurrenceActionsAvailableOccurrenceActionsLabel2;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:67.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار طبق سیاست ثبت می‌شود و جلسهٔ جبرانی لازم است.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence2;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:68.
  ///
  /// In fa, this message translates to:
  /// **'اعتبار طبق سیاست لغو ارائه‌دهنده ثبت می‌شود.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence3;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:75.
  ///
  /// In fa, this message translates to:
  /// **'لغو توسط من'**
  String get occurrenceActionsAvailableOccurrenceActionsLabel3;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:77.
  ///
  /// In fa, this message translates to:
  /// **'اثر لغو بر اعتبار به زمان اعلام و سیاست جلسه بستگی دارد.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence4;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:85.
  ///
  /// In fa, this message translates to:
  /// **'اثر عدم حضور بر اعتبار طبق سیاست جلسه ثبت می‌شود.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence5;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:92.
  ///
  /// In fa, this message translates to:
  /// **'جابه‌جایی زمان'**
  String get occurrenceActionsAvailableOccurrenceActionsLabel4;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:94.
  ///
  /// In fa, this message translates to:
  /// **'زمان این نوبت تغییر می‌کند و یادآوری‌ها باید بازسازی شوند.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence6;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:102.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی / بازگشایی'**
  String get occurrenceActionsAvailableOccurrenceActionsLabel5;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:103.
  ///
  /// In fa, this message translates to:
  /// **'این نوبت دوباره برای اقدام در دسترس قرار می‌گیرد.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence7;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:109.
  ///
  /// In fa, this message translates to:
  /// **'ساخت جلسهٔ جبرانی'**
  String get occurrenceActionsAvailableOccurrenceActionsLabel6;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'جلسهٔ جبرانی بدون حذف سابقه ساخته می‌شود.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence8;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:117.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی نتیجه'**
  String get occurrenceActionsAvailableOccurrenceActionsLabel7;

  /// Application copy. Original usage: lib/features/scheduling/application/occurrence_actions.dart:118.
  ///
  /// In fa, this message translates to:
  /// **'نتیجهٔ قبلی محفوظ می‌ماند و بازگشایی ثبت می‌شود. پرداخت و اعتبار جلسه تغییر نمی‌کند.'**
  String get occurrenceActionsAvailableOccurrenceActionsConsequence9;

  /// Application copy. Original usage: lib/features/scheduling/presentation/edit_schedule_dialog.dart:40.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش زمان نوبت'**
  String get editScheduleDialogBuildTitle;

  /// Application copy. Original usage: lib/features/scheduling/presentation/edit_schedule_dialog.dart:75.
  ///
  /// In fa, this message translates to:
  /// **'دامنهٔ تغییر'**
  String get editScheduleDialogBuildLabelText;

  /// Application copy. Original usage: lib/features/scheduling/presentation/edit_schedule_dialog.dart:79.
  ///
  /// In fa, this message translates to:
  /// **'فقط این نوبت'**
  String get editScheduleDialogBuildItems;

  /// Application copy. Original usage: lib/features/scheduling/presentation/edit_schedule_dialog.dart:84.
  ///
  /// In fa, this message translates to:
  /// **'این نوبت و نوبت‌های بعد'**
  String get editScheduleDialogBuildItems2;

  /// Application copy. Original usage: lib/features/scheduling/presentation/edit_schedule_dialog.dart:88.
  ///
  /// In fa, this message translates to:
  /// **'نوبت‌های آیندهٔ دورهٔ فعال'**
  String get editScheduleDialogBuildItems3;

  /// Application copy. Original usage: lib/features/scheduling/presentation/edit_schedule_dialog.dart:98.
  ///
  /// In fa, this message translates to:
  /// **'سوابق انجام‌شده و نوبت‌های دستی تغییر نمی‌کنند. پرداخت و اعتبار جلسه نیز تغییر نمی‌کند.'**
  String get editScheduleDialogBuildChildren;

  /// Application copy. Original usage: lib/features/scheduling/presentation/edit_schedule_dialog.dart:132.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ زمان'**
  String get editScheduleDialogBuildActions;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:54.
  ///
  /// In fa, this message translates to:
  /// **'ثبت نتیجهٔ نوبت'**
  String get occurrenceActionRowSelectedTitle;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:58.
  ///
  /// In fa, this message translates to:
  /// **'حضور داشتم'**
  String get occurrenceActionRowSelectedChildren;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:59.
  ///
  /// In fa, this message translates to:
  /// **'لغو شد'**
  String get occurrenceActionRowSelectedChildren2;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:61.
  ///
  /// In fa, this message translates to:
  /// **'بخشی انجام شد'**
  String get occurrenceActionRowSelectedChildren3;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:80.
  ///
  /// In fa, this message translates to:
  /// **'{value1}\nپرداخت و اعتبار جلسه تغییر نمی‌کند.'**
  String occurrenceActionRowConfirmedContent(String value1);

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:85.
  ///
  /// In fa, this message translates to:
  /// **'بازگشت'**
  String get occurrenceActionRowConfirmedActions;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:128.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت نوبت ثبت شد.'**
  String get occurrenceActionRowPerformContent;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:137.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت نوبت ثبت شد؛ هماهنگ‌سازی یادآوری هنوز انجام نشده است.'**
  String get occurrenceActionRowPerformContent2;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:146.
  ///
  /// In fa, this message translates to:
  /// **'ثبت وضعیت نوبت انجام نشد؛ دوباره تلاش کنید.'**
  String get occurrenceActionRowPerformContent3;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:163.
  ///
  /// In fa, this message translates to:
  /// **'سابقهٔ نتیجهٔ نوبت'**
  String get occurrenceActionRowShowHistoryTitle;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:170.
  ///
  /// In fa, this message translates to:
  /// **'خواندن سابقه انجام نشد؛ دوباره باز کنید.'**
  String get occurrenceActionRowShowHistoryBuilder;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:177.
  ///
  /// In fa, this message translates to:
  /// **'هنوز نتیجه‌ای ثبت نشده است.'**
  String get occurrenceActionRowShowHistoryBuilder2;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:186.
  ///
  /// In fa, this message translates to:
  /// **'حضور ثبت شد'**
  String get occurrenceActionRowActualOutcomeAttended;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:188.
  ///
  /// In fa, this message translates to:
  /// **'از دست رفت'**
  String get occurrenceActionRowActualOutcomeMissed;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:192.
  ///
  /// In fa, this message translates to:
  /// **'بازگشایی؛ نتیجهٔ قبلی محفوظ است'**
  String get occurrenceActionRowActualOutcomeReopened;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:230.
  ///
  /// In fa, this message translates to:
  /// **'نوبت برنامه‌ریزی‌شده'**
  String get occurrenceActionRowLabelMessage;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:244.
  ///
  /// In fa, this message translates to:
  /// **'{value1} — مشاهدهٔ سابقه'**
  String occurrenceActionRowBuildSubtitle(String value1);

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_action_row.dart:256.
  ///
  /// In fa, this message translates to:
  /// **'اقدامات نوبت'**
  String get occurrenceActionRowBuildTooltip;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_status_label.dart:4.
  ///
  /// In fa, this message translates to:
  /// **'برنامه‌ریزی‌شده'**
  String get occurrenceScheduled;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_status_label.dart:5.
  ///
  /// In fa, this message translates to:
  /// **'موعد رسیده'**
  String get occurrenceDue;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_status_label.dart:9.
  ///
  /// In fa, this message translates to:
  /// **'جابه‌جا شده'**
  String get occurrenceRescheduled;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_status_label.dart:10.
  ///
  /// In fa, this message translates to:
  /// **'عقب‌افتاده'**
  String get occurrenceOverdue;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_status_label.dart:11.
  ///
  /// In fa, this message translates to:
  /// **'موکول شده'**
  String get occurrenceDeferred;

  /// Application copy. Original usage: lib/features/scheduling/presentation/occurrence_status_label.dart:12.
  ///
  /// In fa, this message translates to:
  /// **'نیازمند تصمیم'**
  String get occurrencePendingDecision;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:37.
  ///
  /// In fa, this message translates to:
  /// **'درباره پلن‌اکت'**
  String get settingsAboutApp;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:53.
  ///
  /// In fa, this message translates to:
  /// **'نشان پلن‌اکت'**
  String get aboutPageBuildSemanticLabel;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:65.
  ///
  /// In fa, this message translates to:
  /// **'دستیار شخصی فارسی برای مدیریت تعهدها، برنامه‌ها و امور مالی روزمره؛ با تقویم شمسی و امکانات اصلی آفلاین.'**
  String get aboutPageBuildChildren;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:70.
  ///
  /// In fa, this message translates to:
  /// **'از برنامه تا واقعیت'**
  String get aboutPageBuildTitle;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:72.
  ///
  /// In fa, this message translates to:
  /// **'چه چیزی قرار بود اتفاق بیفتد؟ در واقعیت چه اتفاقی افتاد؟ اکنون چه چیزی نیاز به توجه دارد؟\nپلن‌اکت برنامه‌ریزی، زمان‌بندی، یادآوری، اقدام، ثبت نتیجه و تطبیق پرداخت‌ها را به هم پیوند می‌دهد تا بتوانید برنامه و عملکرد واقعی خود را کنار هم ببینید.'**
  String get aboutPageBuildText;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:76.
  ///
  /// In fa, this message translates to:
  /// **'بخش‌های برنامه'**
  String get aboutPageBuildTitle2;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:78.
  ///
  /// In fa, this message translates to:
  /// **'امروز: مرور کارهای پیش رو و موارد نیازمند توجه.\nتعهدها و تقویم: ثبت برنامه‌های یک‌باره و تکرارشونده، نمایش نوبت‌ها و ثبت نتیجهٔ آن‌ها.\nاعتبار جلسات: پیگیری اعتبار و مصرف جلسات بسته‌ها، جدا از زمان‌بندی.\nمالی: حساب‌ها، درآمد، هزینه، انتقال بین حساب‌ها و ارتباط پرداخت‌ها با تعهدها.\nگزارش‌ها: مرور برنامه و عملکرد، پرداخت‌ها و گردش مالی در بازهٔ انتخابی.\nصندوق ورودی: بررسی و تأیید پیشنهادهای استخراج‌شده از پیامک‌های بانکی.'**
  String get aboutPageBuildText2;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:86.
  ///
  /// In fa, this message translates to:
  /// **'حریم خصوصی و دسترسی‌ها'**
  String get aboutPageBuildTitle3;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:88.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات شخصی و مالی به‌صورت پیش‌فرض روی دستگاه شما نگهداری می‌شود. استفاده از امکانات اصلی به حساب ابری یا اینترنت نیاز ندارد.\nخواندن پیامک‌های بانکی با اجازهٔ شما و انتخاب محدودهٔ ورود انجام می‌شود؛ پیشنهادها پیش از ثبت مالی نیاز به بررسی و تأیید دارند.\nبرای دریافت یادآوری، دسترسی اعلان‌ها و تنظیمات دستگاه را بررسی کنید. قفل برنامه را می‌توانید در تنظیمات فعال کنید؛ دسترسی آن به امکانات احراز هویت دستگاه وابسته است.'**
  String get aboutPageBuildText3;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:95.
  ///
  /// In fa, this message translates to:
  /// **'از منوی «بیشتر» می‌توانید پشتیبان رمزگذاری‌شده تهیه کنید یا اطلاعات را بازیابی کنید. پشتیبان‌گیری با اقدام شما انجام می‌شود؛ نگهداری محلی به‌تنهایی جای پشتیبان را نمی‌گیرد.\nفایل پشتیبان و کلید بازیابی آن را جداگانه و در جای امن نگه دارید. برای بازیابی پشتیبان جدید روی دستگاه دیگر، هر دو لازم‌اند؛ بدون کلید، بازیابی ممکن نیست. فایل و کلید را در اختیار دیگران نگذارید.'**
  String get aboutPageBuildText4;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:99.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت توسعه'**
  String get aboutPageBuildTitle4;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:100.
  ///
  /// In fa, this message translates to:
  /// **'پلن‌اکت در حال توسعه است. وجود یک قابلیت در برنامه به معنی تکمیل همهٔ بررسی‌های انتشار نیست؛ یادآوری‌ها، بازیابی روی دستگاه جدید و دسترسی‌های بومی همچنان به بررسی روی دستگاه نیاز دارند.'**
  String get aboutPageBuildText5;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:113.
  ///
  /// In fa, this message translates to:
  /// **'نسخهٔ نصب‌شده'**
  String get aboutPageBuildChildren2;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:120.
  ///
  /// In fa, this message translates to:
  /// **'خواندن اطلاعات نسخه انجام نشد.'**
  String get aboutPageBuildChildren3;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:130.
  ///
  /// In fa, this message translates to:
  /// **'در حال خواندن اطلاعات نسخه…'**
  String get aboutPageBuildChildren4;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:133.
  ///
  /// In fa, this message translates to:
  /// **'نسخه: {value1}\nشمارهٔ ساخت: {value2}'**
  String aboutPageBuildChildren5(String value1, String value2);

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:143.
  ///
  /// In fa, this message translates to:
  /// **'سازنده و مجوز'**
  String get aboutPageBuildTitle5;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:145.
  ///
  /// In fa, this message translates to:
  /// **'حقوق اثر: Iarash، ۲۰۲۶\nمجوز پلن‌اکت: PolyForm Noncommercial 1.0.0\nاین مجوز دارای محدودیت استفادهٔ تجاری است. شرایط کامل مجوز برنامه و مجوز کتابخانه‌های به‌کاررفته را در بخش زیر بخوانید.'**
  String get aboutPageBuildText6;

  /// Application copy. Original usage: lib/features/settings/presentation/about_page.dart:153.
  ///
  /// In fa, this message translates to:
  /// **'مشاهدهٔ مجوزها'**
  String get aboutPageBuildLabel;

  /// Application copy. Original usage: lib/features/settings/presentation/app_lock_settings_card.dart:43.
  ///
  /// In fa, this message translates to:
  /// **'قفل برنامه فعال شد.'**
  String get appLockSettingsCardChangeMessage;

  /// Application copy. Original usage: lib/features/settings/presentation/app_lock_settings_card.dart:43.
  ///
  /// In fa, this message translates to:
  /// **'قفل برنامه غیرفعال شد.'**
  String get appLockSettingsCardChangeMessage2;

  /// Application copy. Original usage: lib/features/settings/presentation/app_lock_settings_card.dart:49.
  ///
  /// In fa, this message translates to:
  /// **'تغییر قفل انجام نشد. احراز هویت و قفل دستگاه را بررسی و دوباره تلاش کنید.'**
  String get appLockSettingsCardChangeMessage3;

  /// Application copy. Original usage: lib/features/settings/presentation/app_lock_settings_card.dart:63.
  ///
  /// In fa, this message translates to:
  /// **'قفل برنامه'**
  String get appLockSettingsCardBuildTitle;

  /// Application copy. Original usage: lib/features/settings/presentation/app_lock_settings_card.dart:65.
  ///
  /// In fa, this message translates to:
  /// **'در حال تأیید و ذخیره…'**
  String get appLockSettingsCardBuildSubtitle;

  /// Application copy. Original usage: lib/features/settings/presentation/app_lock_settings_card.dart:65.
  ///
  /// In fa, this message translates to:
  /// **'ورود و بازگشت به برنامه با اثر انگشت یا رمز قفل دستگاه؛ تغییر این گزینه نیز نیازمند تأیید هویت است.'**
  String get appLockSettingsCardBuildSubtitle2;

  /// Application copy. Original usage: lib/features/settings/presentation/money_unit_settings_card.dart:22.
  ///
  /// In fa, this message translates to:
  /// **'ذخیرهٔ واحد پول انجام نشد؛ دوباره انتخاب کنید.'**
  String get moneyUnitSettingsCardSelectMessage;

  /// Application copy. Original usage: lib/features/settings/presentation/money_unit_settings_card.dart:38.
  ///
  /// In fa, this message translates to:
  /// **'واحد نمایش و ورود پول'**
  String get moneyUnitSettingsCardBuildChildren;

  /// Application copy. Original usage: lib/features/settings/presentation/money_unit_settings_card.dart:42.
  ///
  /// In fa, this message translates to:
  /// **'مبالغ ایرانی با این واحد نمایش داده می‌شوند؛ مبالغ ذخیره‌شده تغییر نمی‌کنند. واحد هر فرم هنگام باز شدن مشخص می‌شود.'**
  String get moneyUnitSettingsCardBuildChildren2;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:64.
  ///
  /// In fa, this message translates to:
  /// **'حالت نمایش'**
  String get settingsAppearance;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:65.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب حالت روشن، تاریک یا هماهنگ با دستگاه'**
  String get settingsAppearanceDescription;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:73.
  ///
  /// In fa, this message translates to:
  /// **'دستگاه'**
  String get settingsThemeSystem;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:78.
  ///
  /// In fa, this message translates to:
  /// **'روشن'**
  String get settingsThemeLight;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:83.
  ///
  /// In fa, this message translates to:
  /// **'تاریک'**
  String get settingsThemeDark;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:95.
  ///
  /// In fa, this message translates to:
  /// **'امنیت'**
  String get settingsSecurity;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:104.
  ///
  /// In fa, this message translates to:
  /// **'درباره'**
  String get settingsAbout;

  /// Application copy. Original usage: lib/features/settings/presentation/settings_page.dart:110.
  ///
  /// In fa, this message translates to:
  /// **'معرفی برنامه، نسخه، حریم خصوصی و مجوزها'**
  String get settingsPageBuildSubtitle;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:48.
  ///
  /// In fa, this message translates to:
  /// **'تعیین وضعیت'**
  String get attentionEngineAttentionActionDetermineOccurrenceStatus;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:49.
  ///
  /// In fa, this message translates to:
  /// **'تطبیق پرداخت'**
  String get attentionEngineAttentionActionReconcilePayment;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:50.
  ///
  /// In fa, this message translates to:
  /// **'بررسی دریافت'**
  String get attentionEngineAttentionActionReviewExpectedIncoming;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:52.
  ///
  /// In fa, this message translates to:
  /// **'بازبینی تراکنش'**
  String get attentionEngineAttentionActionReviewInbox;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:53.
  ///
  /// In fa, this message translates to:
  /// **'حل مغایرت'**
  String get attentionEngineAttentionActionResolveReconciliation;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:148.
  ///
  /// In fa, this message translates to:
  /// **'اقدام'**
  String get attentionEngineActionLabelMessage;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:222.
  ///
  /// In fa, this message translates to:
  /// **'این نوبت عقب‌افتاده است؛ وضعیت آن را ثبت کنید.'**
  String get attentionEngineBuildActionCenterSubtitle;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:251.
  ///
  /// In fa, this message translates to:
  /// **'امروز؛ اقدام بعدی را انتخاب کنید.'**
  String get attentionEngineBuildActionCenterSubtitle2;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:265.
  ///
  /// In fa, this message translates to:
  /// **'در روزهای آینده؛ برای آن آماده شوید.'**
  String get attentionEngineBuildActionCenterSubtitle3;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:331.
  ///
  /// In fa, this message translates to:
  /// **'این تعهد سررسید شده و هنوز تکمیل نشده است.'**
  String get attentionEngineBuildExplanation;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:369.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت مورد انتظار سررسید شده و هنوز کامل تطبیق داده نشده است.'**
  String get attentionEngineBuildExplanation2;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:370.
  ///
  /// In fa, this message translates to:
  /// **'پرداخت مورد انتظار امروز سررسید می‌شود و هنوز کامل تطبیق داده نشده است.'**
  String get attentionEngineBuildExplanation3;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:386.
  ///
  /// In fa, this message translates to:
  /// **'دریافت مورد انتظار سررسید شده و هنوز با تراکنش تطبیق داده نشده است.'**
  String get attentionEngineBuildExplanation4;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:408.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش واردشده'**
  String get attentionEngineInboxTitle;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:409.
  ///
  /// In fa, this message translates to:
  /// **'یک تراکنش بانکی نیاز به بررسی دارد.'**
  String get attentionEngineInboxExplanation;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:457.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش نیازمند بررسی'**
  String get attentionEngineBuildTitle;

  /// Application copy. Original usage: lib/features/today/application/attention_engine.dart:458.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ باقی‌ماندهٔ این تراکنش نیازمند تعیین ارتباط است.'**
  String get attentionEngineBuildExplanation5;

  /// Application copy. Original usage: lib/features/today/presentation/today_page.dart:65.
  ///
  /// In fa, this message translates to:
  /// **'چه چیزی نیاز به توجه دارد؟'**
  String get todayPageContentChildren;

  /// Application copy. Original usage: lib/features/today/presentation/today_page.dart:117.
  ///
  /// In fa, this message translates to:
  /// **'آینده نزدیک'**
  String get todayPageContentTitle;

  /// Application copy. Original usage: lib/features/today/presentation/today_page.dart:177.
  ///
  /// In fa, this message translates to:
  /// **'{value1} مورد برای رسیدگی وجود دارد.'**
  String todayPageBuildMessage(String value1);

  /// Application copy. Original usage: lib/features/today/presentation/today_page.dart:178.
  ///
  /// In fa, this message translates to:
  /// **'{value1} مورد برای رسیدگی؛ {value2} مورد فوری است.'**
  String todayPageBuildMessage2(String value1, String value2);

  /// Application copy. Original usage: lib/features/today/presentation/today_page.dart:211.
  ///
  /// In fa, this message translates to:
  /// **'{value1} مورد'**
  String todayPageBuildSubtitle(String value1);

  /// Application copy. Original usage: lib/features/today/presentation/today_page.dart:306.
  ///
  /// In fa, this message translates to:
  /// **'همه‌چیز مرتب است؛ موردی نیاز به توجه ندارد.'**
  String get todayPageBuildMessage3;

  /// Application copy. Original usage: lib/features/today/presentation/today_page.dart:310.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تعهد جدید'**
  String get todayPageBuildLabel;

  /// Persistent entry route for resolved and archived commitment actions.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه و بایگانی تعهدها'**
  String get commitmentHistoryTitle;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی'**
  String get undoAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی آخرین تغییر وضعیت'**
  String get undoStatusAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی آخرین تغییر زمان‌بندی'**
  String get undoScheduleAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'تأیید بازگردانی'**
  String get undoConfirmTitle;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'آخرین تغییر ثبت‌شده بازگردانی می‌شود؛ سابقه محفوظ می‌ماند. اگر تغییر جدیدتری ثبت شده باشد، بازگردانی انجام نمی‌شود.'**
  String get undoConfirmMessage;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'تغییر بازگردانی شد؛ سابقه محفوظ است.'**
  String get undoSuccess;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'عملیات انجام نشد؛ ممکن است داده یا سابقه تغییر کرده باشد. بازخوانی کنید و دوباره تلاش کنید.'**
  String get undoConflict;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'تغییر ثبت شد.'**
  String get undoStateSaved;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'تغییر ثبت شد؛ بازخوانی صفحه انجام نشد. دوباره بازخوانی کنید.'**
  String get undoRefreshPending;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح تراکنش'**
  String get financeCorrectAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'دو سمت انتقال و کارمزد ثبت‌شدهٔ آن با ثبت‌های جبرانی خنثی می‌شوند. سابقه حذف نمی‌شود. ادامه می‌دهید؟'**
  String get financeCancelTransferMessage;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش اصلی با ثبت جبرانی خنثی و مبلغ اصلاح‌شده جداگانه ثبت می‌شود. ارتباط‌ها و برچسب‌های قبلی خودکار به تراکنش جدید منتقل نمی‌شوند.'**
  String get financeCorrectMessage;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'بایگانی حساب'**
  String get financeArchivedAccountAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی حساب'**
  String get financeRestoreAccountAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'حساب بایگانی می‌شود؛ موجودی و سابقهٔ مالی حفظ می‌شوند و حساب بعداً قابل بازگردانی است.'**
  String get financeArchiveAccountMessage;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'ارتباط‌های ثبت‌شده'**
  String get matchHistoryTitle;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'قطع ارتباط'**
  String get matchRemoveAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'اصلاح ارتباط'**
  String get matchCorrectAction;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'این ارتباط قطع می‌شود و مبلغ آن دوباره قابل بررسی خواهد بود. موجودی حساب تغییر نمی‌کند و سابقه محفوظ می‌ماند.'**
  String get matchRemoveMessage;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'سابقهٔ ارتباط قطع‌شده یا اصلاح‌شده'**
  String get matchHistoryResolved;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'نوبت مرتبط'**
  String get matchTargetLabel;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ تخصیص'**
  String get matchAmountLabel;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'مبلغ و مقصد تخصیص را اصلاح کنید؛ ارتباط قبلی در سابقه می‌ماند و موجودی حساب تغییر نمی‌کند.'**
  String get matchCorrectMessage;

  /// Explicit archive restore disclosure for legacy history absence.
  ///
  /// In fa, this message translates to:
  /// **'اگر وضعیت پیش از بایگانی ثبت شده باشد، همان وضعیت بازمی‌گردد. تعهدهای قدیمی بدون این سابقه به «فعال» بازگردانی می‌شوند. ادامه می‌دهید؟'**
  String get legacyArchiveRestoreMessage;

  /// Undo repair: explicit operation feedback and confirmation.
  ///
  /// In fa, this message translates to:
  /// **'نتیجه بازگشایی می‌شود و سابقه می‌ماند. این عملیات مبلغ، ارتباط مالی یا اعتبار مصرف‌شده را برنمی‌گرداند.'**
  String get actualReopenMessage;

  /// Visible app-unit proposal for an unresolved SMS amount; neither display nor cancellation persists it.
  ///
  /// In fa, this message translates to:
  /// **'{amount} {unit} (پیشنهاد پیش‌فرض برنامه)'**
  String inboxDefaultUnitProposalAmount(String amount, String unit);

  /// Amount and pinned unit shown for explicit financial confirmation.
  ///
  /// In fa, this message translates to:
  /// **'{amount} {unit}'**
  String inboxDefaultUnitAmount(String amount, String unit);

  /// Final confirmation explicitly accepts the visible, overridable unit proposal.
  ///
  /// In fa, this message translates to:
  /// **'واحد پیامک مشخص نیست؛ واحد پیش‌فرض برنامه پیشنهاد شده است. تأیید نهایی، مبلغ را با واحد انتخابی ثبت می‌کند.'**
  String get inboxDefaultUnitConfirmationNotice;

  /// Saving an SMS review accepts the visible unit; original source evidence is retained.
  ///
  /// In fa, this message translates to:
  /// **'واحد پیامک مشخص نیست؛ واحد پیش‌فرض برنامه پیشنهاد شده است. ذخیره، مبلغ را با واحد انتخابی ثبت می‌کند.'**
  String get inboxDefaultUnitEditorNotice;

  /// Unresolved Inbox draft can be reviewed directly in confirmation.
  ///
  /// In fa, this message translates to:
  /// **'واحد پیامک نامشخص است؛ واحد پیش‌فرض برنامه هنگام تأیید قابل تغییر است.'**
  String get inboxDefaultUnitReviewNotice;

  /// Domain guard against overwriting existing source/review currency evidence.
  ///
  /// In fa, this message translates to:
  /// **'واحد مبلغ قبلاً مشخص شده است.'**
  String get inboxCurrencyAlreadyResolved;

  /// Explicit opt-in for foreground ingestion of new SMS only.
  ///
  /// In fa, this message translates to:
  /// **'دریافت خودکار پیامک‌های جدید'**
  String get smsAutomaticTitle;

  /// Consent boundary, foreground triggers, and mandatory financial review; historical import is separate.
  ///
  /// In fa, this message translates to:
  /// **'با فعال‌سازی، فقط پیامک‌های دریافتی از همین لحظه هنگام بازشدن یا بازگشت به برنامه، دریافت پیامک و کشیدن صفحه به پایین بررسی می‌شوند. ثبت مالی با تأیید شماست. هنگام بسته‌بودن برنامه دریافت انجام نمی‌شود.'**
  String get smsAutomaticDescription;

  /// Retryable automatic SMS read, checkpoint or refresh error without sensitive details.
  ///
  /// In fa, this message translates to:
  /// **'بررسی پیامک‌های جدید کامل نشد؛ در صندوق بررسی دوباره تلاش کنید.'**
  String get smsAutomaticSyncFailed;

  /// Missing or revoked SMS access never prompts automatically or reads the provider.
  ///
  /// In fa, this message translates to:
  /// **'برای دریافت پیامک‌های جدید، دسترسی پیامک را در صندوق بررسی فعال کنید.'**
  String get smsAutomaticPermissionRequired;

  /// Failed durable consent write must not change the effective SMS synchronization setting.
  ///
  /// In fa, this message translates to:
  /// **'تنظیم دریافت خودکار ذخیره نشد؛ دوباره تلاش کنید.'**
  String get smsAutomaticSettingFailed;

  /// Expandable optional SMS permission recovery help in Inbox.
  ///
  /// In fa, this message translates to:
  /// **'راهنمای دسترسی پیامک در تنظیمات گوشی'**
  String get smsPermissionHelpTitle;

  /// Conditional guidance for restricted installations and ordinary denial. English strings are exact OS labels for identifying settings in supplied device screenshots; OEM placement is conditional. Permission is separate from import consent.
  ///
  /// In fa, this message translates to:
  /// **'اگر گوشی پیام «دسترسی برنامه به پیامک رد شد» یا «تنظیمات محدودشده» نشان می‌دهد، ممکن است دسترسی به‌دلیل روش نصب یا سیاست امنیتی گوشی محدود شده باشد.\n\n۱. تنظیمات همین برنامه (App info) را باز کنید.\n۲. فقط اگر به برنامه و منبع نصب آن اعتماد دارید، گزینهٔ «اجازهٔ تنظیمات محدودشده» (Allow restricted settings) را فعال کنید. در بعضی گوشی‌ها این گزینه در منوی سه‌نقطه و در شیائومی/پوکو ممکن است در پایین صفحه باشد.\n۳. سپس در «مجوزها» (App permissions)، «پیامک» (SMS) را روی «مجاز» (Allow) بگذارید و به برنامه برگردید.\n\nاگر این گزینه وجود ندارد، مجوز پیامک را در همان بخش مجوزها بررسی کنید یا به برنامه برگردید و دوباره درخواست دهید. محدودیت سازمانی یا گوشی ممکن است مانع باشد؛ برنامه نمی‌تواند آن را خودکار بردارد. سایر بخش‌ها و ورود دستی بدون این مجوز در دسترس‌اند. فعال‌شدن مجوز به‌تنهایی تاریخچه را وارد یا دریافت خودکار را روشن نمی‌کند.'**
  String get smsPermissionHelpBody;

  /// Explicit action opens this package's App info, never changes a permission.
  ///
  /// In fa, this message translates to:
  /// **'بازکردن تنظیمات همین برنامه'**
  String get smsPermissionOpenSettings;

  /// Denial or cancelled request; does not assert the cause is Restricted Settings.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی پیامک فعال نشد. می‌توانید دوباره درخواست دهید یا راهنمای تنظیمات گوشی را دنبال کنید.'**
  String get smsPermissionNotGranted;

  /// Bounded permission request timeout or native failure with recovery actions.
  ///
  /// In fa, this message translates to:
  /// **'درخواست دسترسی پیامک کامل نشد. وضعیت را تازه کنید، دوباره تلاش کنید یا تنظیمات همین برنامه را بررسی کنید.'**
  String get smsPermissionRequestFailed;

  /// Failed App info intent with retry and manual path.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات باز نشد؛ دوباره تلاش کنید یا از تنظیمات گوشی، برنامه‌ها، پلن‌اکت وارد شوید.'**
  String get smsPermissionSettingsFailed;

  /// Durable confirmation requires a reviewed revision before accepting a proposed unit.
  ///
  /// In fa, this message translates to:
  /// **'برای انتخاب واحد، ابتدا پیشنهاد را بازخوانی کنید.'**
  String get inboxCurrencyRevisionRequired;

  /// Label for notification/alarm selection.
  ///
  /// In fa, this message translates to:
  /// **'روش یادآوری'**
  String get reminderDeliveryLabel;

  /// Standard notification delivery choice.
  ///
  /// In fa, this message translates to:
  /// **'اعلان'**
  String get reminderDeliveryNotification;

  /// Audible alarm delivery choice.
  ///
  /// In fa, this message translates to:
  /// **'آلارم'**
  String get reminderDeliveryAlarm;

  /// Alarm behavior and permission disclosure.
  ///
  /// In fa, this message translates to:
  /// **'آلارم تا دو دقیقه زنگ می‌زند و قطع یا تعویق آن به معنی انجام تعهد نیست. به مجوز اعلان و آلارم دقیق نیاز دارد؛ برای فعال‌سازی یا تلاش دوباره به تنظیمات یادآورها بروید.'**
  String get reminderAlarmHelp;

  /// Private native alarm notification title.
  ///
  /// In fa, this message translates to:
  /// **'آلارم پلن‌اکت'**
  String get reminderAlarmTitle;

  /// Private native alarm notification body without personal data.
  ///
  /// In fa, this message translates to:
  /// **'زمان یادآوری رسیده است. قطع زنگ به معنی انجام تعهد نیست.'**
  String get reminderAlarmBody;

  /// Native alarm dismiss action.
  ///
  /// In fa, this message translates to:
  /// **'قطع'**
  String get reminderAlarmStop;

  /// Native alarm action with fixed ten-minute snooze.
  ///
  /// In fa, this message translates to:
  /// **'تعویق ۱۰ دقیقه'**
  String get reminderAlarmSnooze;

  /// Native alarm channel name.
  ///
  /// In fa, this message translates to:
  /// **'آلارم‌های تعهد'**
  String get reminderAlarmChannel;

  /// Alarm channel description.
  ///
  /// In fa, this message translates to:
  /// **'زنگ یادآورهای انتخاب‌شده؛ کنترل صدا از تنظیمات آلارم دستگاه است.'**
  String get reminderAlarmChannelDescription;

  /// Native scheduling/playback failure notification.
  ///
  /// In fa, this message translates to:
  /// **'اجرای آلارم ممکن نشد؛ مجوزها و تنظیمات یادآور را بررسی کنید.'**
  String get reminderAlarmRetry;

  /// Independent date-only calendar note action and type label.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get calendarNoteLabel;

  /// Note identity color picker label.
  ///
  /// In fa, this message translates to:
  /// **'رنگ یادداشت'**
  String get calendarNoteColorLabel;

  /// Explains note identity color use.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت در تقویم با این رنگ نمایش داده می‌شود.'**
  String get calendarNoteColorHint;

  /// Global Add note subtitle.
  ///
  /// In fa, this message translates to:
  /// **'عنوان و توضیحات روی تقویم، بدون اعلان'**
  String get calendarNoteAddSubtitle;

  /// Create note form title.
  ///
  /// In fa, this message translates to:
  /// **'افزودن یادداشت'**
  String get calendarNoteCreateTitle;

  /// Edit note form title.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش یادداشت'**
  String get calendarNoteEditTitle;

  /// Required note title field label.
  ///
  /// In fa, this message translates to:
  /// **'عنوان'**
  String get calendarNoteTitleField;

  /// Optional note description label.
  ///
  /// In fa, this message translates to:
  /// **'توضیحات (اختیاری)'**
  String get calendarNoteDescriptionField;

  /// Explicit Jalali note date picker action.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تاریخ'**
  String get calendarNoteChooseDate;

  /// Empty note title validation error.
  ///
  /// In fa, this message translates to:
  /// **'عنوان یادداشت را وارد کنید.'**
  String get calendarNoteTitleRequired;

  /// Missing note date validation error.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ یادداشت را انتخاب کنید.'**
  String get calendarNoteDateRequired;

  /// Save failed; input remains available for retry.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت ذخیره نشد. دوباره تلاش کنید.'**
  String get calendarNoteSaveFailed;

  /// Stale edit conflict; reopen to read fresh revision.
  ///
  /// In fa, this message translates to:
  /// **'این یادداشت تغییر کرده است. فرم را ببندید و دوباره باز کنید.'**
  String get calendarNoteStale;

  /// Explanation of note delivery semantics.
  ///
  /// In fa, this message translates to:
  /// **'این یادداشت فقط روی تقویم نمایش داده می‌شود و یادآور، آلارم یا اعلان ندارد.'**
  String get calendarNoteNoDelivery;

  /// Successful durable note save.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت ذخیره شد.'**
  String get calendarNoteSaved;

  /// Global search page title and shell accessibility label.
  ///
  /// In fa, this message translates to:
  /// **'جست‌وجو'**
  String get searchTitle;

  /// Accessible label for the global text query.
  ///
  /// In fa, this message translates to:
  /// **'عبارت جست‌وجو'**
  String get searchFieldLabel;

  /// Search all supported record types.
  ///
  /// In fa, this message translates to:
  /// **'همه'**
  String get searchAll;

  /// Commitment search filter and result type.
  ///
  /// In fa, this message translates to:
  /// **'تعهدات'**
  String get searchCommitments;

  /// Financial entry search filter and result type, including transfers and corrections.
  ///
  /// In fa, this message translates to:
  /// **'تراکنش‌ها'**
  String get searchTransactions;

  /// Independent calendar note search filter and result type.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت‌ها'**
  String get searchNotes;

  /// Financial account search filter and result type.
  ///
  /// In fa, this message translates to:
  /// **'حساب‌ها'**
  String get searchAccounts;

  /// Clear only the transient query, never records.
  ///
  /// In fa, this message translates to:
  /// **'پاک‌کردن عبارت جست‌وجو'**
  String get searchClear;

  /// Reload search data from durable local records.
  ///
  /// In fa, this message translates to:
  /// **'تازه‌سازی نتایج'**
  String get searchRefresh;

  /// Empty query guidance disclosing supported fields and historical coverage.
  ///
  /// In fa, this message translates to:
  /// **'برای جست‌وجو در عنوان، توضیحات، دسته و برچسب تعهدات و تراکنش‌ها، یادداشت‌ها و نام حساب‌ها، عبارتی بنویسید. موارد بایگانی‌شده هم جست‌وجو می‌شوند.'**
  String get searchGuidance;

  /// No text matches, with query/filter recovery guidance.
  ///
  /// In fa, this message translates to:
  /// **'موردی پیدا نشد. عبارت دیگری بنویسید یا فیلتر «همه» را انتخاب کنید.'**
  String get searchNoResults;

  /// Search snapshot read failure; paired with retry.
  ///
  /// In fa, this message translates to:
  /// **'خواندن اطلاعات جست‌وجو انجام نشد. دوباره تلاش کنید.'**
  String get searchReadError;

  /// Search result opening failure with recovery guidance.
  ///
  /// In fa, this message translates to:
  /// **'بازکردن مورد انجام نشد. نتایج را تازه کنید و دوباره آن را انتخاب کنید.'**
  String get searchOpenError;

  /// Historical cancelled commitment search status.
  ///
  /// In fa, this message translates to:
  /// **'لغوشده'**
  String get searchCancelled;

  /// Matching result count; count is a Persian-formatted integer.
  ///
  /// In fa, this message translates to:
  /// **'{count} نتیجه'**
  String searchResultCount(String count);

  /// Read-only financial search detail scope and existing management route.
  ///
  /// In fa, this message translates to:
  /// **'این جزئیات فقط برای مشاهده است. مدیریت تراکنش از بخش مالی انجام می‌شود.'**
  String get searchFinancialReadOnly;

  /// Accessible month day note summary, separate from commitment counts.
  ///
  /// In fa, this message translates to:
  /// **'{count} یادداشت: {titles}'**
  String calendarNoteDaySummary(String count, String titles);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
