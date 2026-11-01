import 'package:file_picker_ohos/file_picker_ohos.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilePickerOhos', () {
    test('registers instance', () {
      FilePickerOhos.registerWith();
      expect(FilePickerPlatform.instance, isA<FilePickerOhos>());
    });

    test('getDirectoryPath is not implemented', () {
      final platform = FilePickerOhos();
      expect(() => platform.getDirectoryPath(), throwsUnimplementedError);
    });

    test(
      'OhosPlatformFile derives name from path if name is empty',
      () {
        final file = OhosPlatformFile.fromMap({'path': '/tmp/test_file.txt'});
        expect(file.name, equals('test_file.txt'));
        expect(file.path, equals(Uri.file('/tmp/test_file.txt').toFilePath()));
      },
    );

    test(
      'OhosPlatformFile throws ArgumentError on empty path and identifier',
      () {
        expect(() => OhosPlatformFile.fromMap({}), throwsArgumentError);
      },
    );

    test('OhosPlatformFile equality and hashCode work correctly', () {
      final file1 = OhosPlatformFile(
        name: 'test.txt',
        uri: Uri.file('/tmp/test.txt'),
      );
      final file2 = OhosPlatformFile(
        name: 'test.txt',
        uri: Uri.file('/tmp/test.txt'),
      );
      expect(file1, equals(file2));
      expect(file1.hashCode, equals(file2.hashCode));
    });
  });
}
