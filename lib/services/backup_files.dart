import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Saving and opening backup files. A seam so widget tests can replace the
/// platform dialogs.
abstract class BackupFiles {
  /// Saves [text] as [fileName]. Returns false when the user cancelled.
  /// On web this starts a download and always returns true.
  Future<bool> save(String fileName, String text);

  /// Lets the user pick a file and returns its text, or null if cancelled.
  Future<String?> open();
}

class FilePickerBackupFiles implements BackupFiles {
  @override
  Future<bool> save(String fileName, String text) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: 'application/json',
      dialogTitle: '백업 저장',
    );
    // The web implementation downloads and returns null; elsewhere null
    // means the user closed the dialog.
    return kIsWeb || uri != null;
  }

  @override
  Future<String?> open() async {
    final file = await FilePicker.pickFile(
      dialogTitle: '백업 파일 선택',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}

/// Replaced in tests.
BackupFiles backupFiles = FilePickerBackupFiles();
