import 'package:merging_builder/merging_builder.dart';
import 'package:merging_builder/src/errors/builder_error.dart';
import 'package:test/test.dart';

/// Tests class `SyntheticInput`.
main() {
  final lib = $Lib$();
  final package = $Package$();

  group('SyntheticInput:', () {
    test(r'instance<$Lib$>()', () {
      expect(SyntheticInput.instance<$Lib$>(), lib);
    });
    test(r'instance<$Package$>()', () {
      expect(SyntheticInput.instance<$Package$>(), package);
    });

    test('instance()', () {
      expect(SyntheticInput.instance(), package);
    });
    test('isValidPath<\$Lib\$>(\'lib/*.dart\') => true', () {
      expect(SyntheticInput.isValidPath<$Lib$>('lib/*.dart'), true);
    });
    test('isValidPath<\$Lib\$>(\'test/*.dart\') => false', () {
      expect(SyntheticInput.isValidPath<$Lib$>('test/*.dart'), false);
    });
    test('validatePath<\$Lib\$>(\'test/*.dart\') | throws BuilderError', () {
      try {
        SyntheticInput.validatePath<$Lib$>('test/*.dart');
      } catch (e) {
        expect(e, isA<BuilderError>());
      }
    });
  });
  group(r'$Lib$:', () {
    test('baseDirectory', () {
      expect(lib.baseDirectory, 'lib');
    });
    test('value', () {
      expect(lib.value, r'lib/$lib$');
    });
  });
  group(r'$Package$:', () {
    test('baseDirectory', () {
      expect(package.baseDirectory, '');
    });
    test('value', () {
      expect(package.value, r'$package$');
    });
  });
}
