import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Where recordings are kept: a folder of the app's own, not visible in the
/// Files app and not shared with anything. Only file names are stored in
/// the database, so the folder can move with the app.
class RecordingFiles {
  RecordingFiles(this._directory);

  final Future<Directory> Function() _directory;

  Future<Directory> _folder() async {
    final folder = Directory('${(await _directory()).path}/recordings');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  /// The full path of the recording named [fileName].
  Future<String> pathOf(String fileName) async =>
      '${(await _folder()).path}/$fileName';

  /// The audio of the recording named [fileName], or null if it is not
  /// there.
  Future<Uint8List?> read(String fileName) async {
    final file = File(await pathOf(fileName));
    return await file.exists() ? file.readAsBytes() : null;
  }

  /// Writes [bytes] as the recording named [fileName], replacing it.
  Future<void> write(String fileName, Uint8List bytes) async {
    await File(await pathOf(fileName)).writeAsBytes(bytes, flush: true);
  }

  /// Deletes the recording named [fileName], if it is there.
  Future<void> delete(String fileName) async {
    final file = File(await pathOf(fileName));
    if (await file.exists()) await file.delete();
  }
}

final recordingFilesProvider = Provider<RecordingFiles>(
  (ref) => RecordingFiles(getApplicationSupportDirectory),
);
