import 'package:planact/core/localization/persian_copy.g.dart';

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/domain/holiday_data_package.dart';

class FileHolidayPackageSource implements HolidayPackageFileSource {
  @override
  Future<String?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: PersianCopy.fileHolidayPackageSourceResultDialogTitle,
      withData: false,
    );
    if (result == null) return null;
    final path = result.files.single.path;
    if (path == null) {
      throw const HolidayPackageException(
        PersianCopy.fileHolidayPackageSourcePickMessage,
      );
    }
    final file = File(path);
    if (await file.length() > HolidayDataPackage.maxBytes) {
      throw const HolidayPackageException(
        PersianCopy.fileHolidayPackageSourcePickMessage2,
      );
    }
    final reader = await file.open();
    try {
      final bytes = await reader.read(HolidayDataPackage.maxBytes + 1);
      if (bytes.length > HolidayDataPackage.maxBytes) {
        throw const HolidayPackageException(
          PersianCopy.fileHolidayPackageSourcePickMessage2,
        );
      }
      return utf8.decode(bytes);
    } finally {
      await reader.close();
    }
  }
}
