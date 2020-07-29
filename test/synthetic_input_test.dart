import 'package:exception_templates/exception_templates.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:test/test.dart';

/// Tests class `SyntheticInput`.
void main() {
  final lib = LibDir();
  final package = PackageDir();

  group('SyntheticInput:', () {
    test(r'instance<LibDir>()', () {
      expect(SyntheticInput.instance<LibDir>(), lib);
    });
    test(r'instance<PackageDir>()', () {
      expect(SyntheticInput.instance<PackageDir>(), package);
    });

    test('instance()', () {
      expect(SyntheticInput.instance(), package);
    });
    test('isValidPath<\$Lib\$>(\'lib/*.dart\') => true', () {
      expect(SyntheticInput.isValidPath<LibDir>('lib/*.dart'), true);
    });
    test('isValidPath<\$Lib\$>(\'test/*.dart\') => false', () {
      expect(SyntheticInput.isValidPath<LibDir>('test/*.dart'), false);
    });
    test('validatePath<\$Lib\$>(\'test/*.dart\') | throws BuilderError', () {
      try {
        SyntheticInput.validatePath<LibDir>('test/*.dart');
      } catch (e) {
        expect(e, isA<ErrorOf<SyntheticInput>>());
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
