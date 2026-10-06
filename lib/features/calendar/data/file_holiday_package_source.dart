import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';

class FileHolidayPackageSource implements HolidayPackageFileSource {
  @override
  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'انتخاب بستهٔ تعطیلات',
      withData: false,
    );
    if (result == null) return null;
    final path = result.files.single.path;
    if (path == null) {
      throw const HolidayPackageException('فایل انتخاب‌شده در دسترس نیست.');
    }
    final file = File(path);
    if (await file.length() > HolidayDataPackage.maxBytes) {
      throw const HolidayPackageException('حجم بسته بیش از حد مجاز است.');
    }
    final reader = await file.open();
    try {
      final bytes = await reader.read(HolidayDataPackage.maxBytes + 1);
      if (bytes.length > HolidayDataPackage.maxBytes) {
        throw const HolidayPackageException('حجم بسته بیش از حد مجاز است.');
      }
      return utf8.decode(bytes);
    } finally {
      await reader.close();
    }
  }
}
