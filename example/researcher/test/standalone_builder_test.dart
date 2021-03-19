import 'package:build_test/build_test.dart';
import 'package:researcher_builder/researcher_builder.dart';
import 'package:test/test.dart';

import 'src/input/mock_assets.dart';
import 'src/mock_builders/mock_standalone_builder.dart';

/// Tests if the builder generates the expected output file.
///
/// To run this program navigate to the top directory the package
/// [merging_builder] and use the command:
///
/// # pub run build_runner test -- -r expanded
void main() {
  // Builder instance.
  final builder = MockStandaloneBuilder(
    generator: AssistantGenerator(),
    inputFiles: 'lib/source_assets/researcher_*.dart',
    outputFiles: 'lib/output/assistant_(*).dart',
  );

  final outputs = <String, String>{
    '$pkgName|lib/output/assistant_researcher_a.dart':
        assistant_researcher_a_dot_dart,
    '$pkgName|lib/output/assistant_researcher_b.dart':
        assistant_researcher_b_dot_dart,
  };

  group('StandaloneBuilder<\$Lib\$>', () {
    test('generate: assistant_(*).dart', () async {
      await testBuilder(
        builder,
        sourceAssets,
        outputs: outputs,
        rootPackage: pkgName,
        reader: await PackageAssetReader.currentIsolate(rootPackage: pkgName),
        //reader: InMemoryAssetReader(),
      );
    });
    test('buildExtentions', () {
      expect(builder.buildExtensions, {
        'lib/\$lib\$': [
          'lib/output/assistant_researcher_a.dart',
          'lib/output/assistant_researcher_b.dart'
        ]
      });
    });
  });
}
