import 'package:planact/features/calendar/domain/holiday_data_package.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';

abstract interface class HolidayPackageStore {
  Future<List<String>> load();
  Future<void> save(HolidayDataPackage package);
}

abstract interface class HolidayPackageFileSource {
  Future<String?> pick();
}

class HolidayPackageService {
  HolidayPackageService(this.store, this.files);
  final HolidayPackageStore store;
  final HolidayPackageFileSource files;
  List<HolidayDataPackage> _packages = const [];
  bool _installing = false;
  String? loadError;

  List<HolidayDataPackage> get packages => List.unmodifiable(_packages);
  IranianHolidayProvider get provider => IranianHolidayProvider(
    annualOverrides: {
      for (final package in _packages) package.year: package.holidays,
    },
  );

  Future<void> load() async {
    try {
      await _loadVerified();
      loadError = null;
    } catch (_) {
      loadError = 'دادهٔ واردشدهٔ تعطیلات قابل بررسی نیست. دادهٔ قبلی حفظ شده است؛ برای بازیابی فایل با پشتیبانی تماس بگیرید.';
      rethrow;
    }
  }

  Future<void> _loadVerified() async {
    final verified = <HolidayDataPackage>[];
    for (final encoded in await store.load()) {
      verified.add(await HolidayDataPackage.verify(encoded));
    }
    if (verified.map((p) => p.year).toSet().length != verified.length ||
        verified.map((p) => p.publisherKey).toSet().length > 1) {
      throw const HolidayPackageException(
        'دادهٔ ذخیره‌شدهٔ تعطیلات معتبر نیست. بسته‌ها را از منبع مورد اعتماد دوباره وارد کنید.',
      );
    }
    _packages = List.unmodifiable(verified);
  }

  Future<HolidayDataPackage?> prepare() async {
    final encoded = await files.pick();
    if (encoded == null) return null;
    final package = await HolidayDataPackage.verify(encoded);
    _validateReplacement(package);
    return package;
  }

  bool needsPublisherApproval(HolidayDataPackage package) => _packages.isEmpty;

  void _validateReplacement(HolidayDataPackage package) {
    if (loadError != null) {
      throw HolidayPackageException(loadError!);
    }
    if (_packages.isNotEmpty &&
        _packages.first.publisherKey != package.publisherKey) {
      throw const HolidayPackageException(
        'امضای این بسته با ناشر مورد اعتماد شما یکسان نیست.',
      );
    }
    for (final current in _packages) {
      if (current.year == package.year &&
          current.revision >= package.revision) {
        throw const HolidayPackageException(
          'این نسخه یا نسخهٔ جدیدتر این سال قبلاً نصب شده است.',
        );
      }
    }
  }

  Future<void> install(
    HolidayDataPackage package, {
    required bool publisherApproved,
  }) async {
    if (_installing) {
      throw const HolidayPackageException('ورود بستهٔ دیگری در حال انجام است.');
    }
    if (needsPublisherApproval(package) && !publisherApproved) {
      throw const HolidayPackageException(
        'اعتماد به ناشر باید به‌صورت صریح تأیید شود.',
      );
    }
    _validateReplacement(package);
    _installing = true;
    try {
      await store.save(package);
      _packages = List.unmodifiable([
        ..._packages.where((p) => p.year != package.year),
        package,
      ]);
    } finally {
      _installing = false;
    }
  }
}
