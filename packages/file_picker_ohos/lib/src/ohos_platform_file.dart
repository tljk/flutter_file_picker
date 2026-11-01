import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:path/path.dart' as p;

/// A [PlatformFile] implementation for OpenHarmony.
base class OhosPlatformFile extends PlatformFile {
  OhosPlatformFile({
    required this.name,
    required this.uri,
    XFile? xFile,
    int? bytesLength,
  }) : _xFile = xFile,
       _bytesLength = bytesLength;

  factory OhosPlatformFile.fromMap(Map<Object?, Object?> data) {
    final String path = data['path'] as String? ?? '';
    final String? identifier = data['identifier'] as String?;
    final String rawName = data['name'] as String? ?? '';
    final String name = rawName.isNotEmpty
        ? rawName
        : (path.isNotEmpty ? p.basename(path) : '');

    if (path.isEmpty && (identifier == null || identifier.isEmpty)) {
      throw ArgumentError(
        'path or identifier cannot be empty when creating OhosPlatformFile',
      );
    }
    if (name.isEmpty) {
      throw ArgumentError(
        'name cannot be empty when creating OhosPlatformFile',
      );
    }

    final Uri uri = path.isNotEmpty
        ? Uri.file(path)
        : (Uri.tryParse(identifier!) ?? Uri.file(identifier));

    final Uint8List? bytes = data['bytes'] as Uint8List?;

    return OhosPlatformFile(
      name: name,
      uri: uri,
      xFile: path.isNotEmpty ? XFile(path, name: name, bytes: bytes) : null,
      bytesLength: bytes?.lengthInBytes ?? (data['size'] as int?),
    );
  }

  @override
  final String name;

  @override
  final Uri uri;

  final XFile? _xFile;
  final int? _bytesLength;

  @override
  XFile get xFile {
    final file = _xFile;
    if (file != null) return file;
    if (uri.scheme == 'file') {
      return XFile(uri.toFilePath(), name: name);
    }
    return XFile(uri.toString(), name: name);
  }

  @override
  Future<int> length() async {
    final len = _bytesLength;
    if (len != null && len > 0) return len;
    try {
      return await xFile.length();
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Uint8List> readAsBytes() async {
    return xFile.readAsBytes();
  }

  @override
  Stream<Uint8List> readAsByteStream() {
    return xFile.openRead();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OhosPlatformFile && other.name == name && other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(name, uri);

  @override
  String toString() {
    return 'OhosPlatformFile(name: $name, uri: $uri)';
  }
}
