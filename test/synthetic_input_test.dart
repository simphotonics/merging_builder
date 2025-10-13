import 'package:exception_templates/exception_templates.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:test/test.dart';

/// Tests class `SyntheticInput`.
void main() {
  final lib = BuildLocation.lib;
  final package = BuildLocation.package;

  group('BuildLocation:', () {
    test('isValidPath<\$Lib\$>(\'lib/*.dart\') => true', () {
      expect(lib.isValidPath('lib/*.dart'), true);
    });
    test('isValidPath<\$Lib\$>(\'test/*.dart\') => false', () {
      expect(lib.isValidPath('test/*.dart'), false);
    });
    test('validatePath<\$Lib\$>(\'test/*.dart\') | throws BuilderError', () {
      try {
        lib.validatePath('test/*.dart');
      } catch (e) {
        expect(e, isA<ErrorOf<BuildLocation>>());
      }
    });
  });
  group(r'LibDir:', () {
    test('baseDirectory', () {
      expect(lib.baseDirectory, 'lib');
    });
    test('value', () {
      expect(lib.value, r'lib/$lib$');
    });
  });
  group(r'PackageDir:', () {
    test('baseDirectory', () {
      expect(package.baseDirectory, '');
    });
    test('value', () {
      expect(package.value, r'$package$');
    });
  });
}
