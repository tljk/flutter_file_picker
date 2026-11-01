import 'dart:async';

import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ohos_platform_file.dart';

/// An implementation of [FilePickerPlatform] for OpenHarmony.
class FilePickerOhos extends FilePickerPlatform {
  /// Registers this class as the default instance of [FilePickerPlatform].
  static void registerWith() {
    FilePickerPlatform.instance = FilePickerOhos();
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
    StandardMethodCodec(),
  );

  /// The event channel used to receive real-time updates from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel(
    'miguelruivo.flutter.plugins.filepickerevent',
  );

  StreamSubscription? _eventSubscription;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final files = await _pickFilesInternal(
      allowMultiple: false,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
    );
    return files.firstOrNull;
  }

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return _pickFilesInternal(
      allowMultiple: true,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
    );
  }

  Future<List<PlatformFile>> _pickFilesInternal({
    required bool allowMultiple,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
  }) async {
    final String typeName = type.name;

    try {
      if (onFileLoading != null) {
        _eventSubscription = eventChannel.receiveBroadcastStream().listen((
          data,
        ) {
          if (data is! bool) return;
          onFileLoading(
            data ? FilePickerStatus.picking : FilePickerStatus.done,
          );
        }, onError: (error) => throw Exception(error));
      }

      final List<Object?>? result = await methodChannel.invokeListMethod(
        typeName,
        {
          'allowMultipleSelection': allowMultiple,
          'allowedExtensions': allowedExtensions,
          'compressionQuality': compressionQuality,
        },
      );

      if (result == null) {
        return [];
      }

      final platformFiles = <PlatformFile>[];
      for (final Object? platformFileMap in result) {
        platformFiles.add(
          OhosPlatformFile.fromMap(platformFileMap as Map<Object?, Object?>),
        );
      }

      return platformFiles;
    } catch (e) {
      rethrow;
    } finally {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
    }
  }

  @override
  Future<List<String>> pickFileAndDirectoryPaths({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    final files = await pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
    );
    return files.map((e) => e.uri.path).toList();
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    throw UnimplementedError(
      'getDirectoryPath() is not implemented on OpenHarmony.',
    );
  }

  @override
  Future<void> clearTemporaryFiles() async {
    await methodChannel.invokeMethod<void>('clear');
  }

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    try {
      if (onFileSaving != null) {
        onFileSaving(FilePickerStatus.picking);
        _eventSubscription = eventChannel.receiveBroadcastStream().listen((
          data,
        ) {
          if (data is! bool) return;
          onFileSaving(data ? FilePickerStatus.picking : FilePickerStatus.done);
        }, onError: (error) => throw Exception(error));
      }

      final String? savedPath = await methodChannel.invokeMethod<String>(
        'save',
        {
          'fileName': fileName,
          'fileType': mimeType,
          'initialDirectory': initialDirectory,
          'bytes': bytes,
        },
      );

      if (onFileSaving != null) {
        onFileSaving(FilePickerStatus.done);
      }

      if (savedPath == null) return null;
      return Uri.tryParse(savedPath) ?? Uri.file(savedPath);
    } catch (e) {
      rethrow;
    } finally {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
    }
  }
}
