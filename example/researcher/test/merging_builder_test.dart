import 'package:build_test/build_test.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:researcher_builder/researcher_builder.dart';
import 'package:test/test.dart';

import 'src/input/mock_assets.dart';

/// Tests if the builder generates the expected output file.
///
/// To run this program navigate to the top directory the package
/// [merging_builder] and use the command:
///
/// # pub run build_runner test -- -r expanded
void main() {
  final builder = MergingBuilder<List<String>, $Lib$>(
    generator: AddNamesGenerator(),
    inputFiles: 'lib/source_assets/researcher_*.dart',
    outputFile: 'lib/output/researchers.dart',
    header: AddNamesGenerator.header,
    footer: AddNamesGenerator.footer,
  );

  group('MergingBuilder', () {
    test('generate: researchers.dart', () async {
      await testBuilder(
        builder,
        sourceAssets,
        outputs: {
          '$pkgName|lib/output/researchers.dart': researchers_dot_dart,
        },
        rootPackage: 'researcher',
        reader: await PackageAssetReader.currentIsolate(
          rootPackage: pkgName,
        ),
      );
    });
    test('buildExtentions', () {
      expect(builder.buildExtensions, {
        r'lib/$lib$': ['lib/output/researchers.dart'],
      });
    });
  });
}
