import 'package:merging_builder/merging_builder.dart';
import 'package:source_gen/source_gen.dart';

/// StandaloneBuilder for testing purposes with
/// hardcoded buildExtensions.
class MockStandaloneBuilder extends StandaloneBuilder<LibDir> {
  MockStandaloneBuilder({
    String inputFiles = 'lib/*.dart',
    String outputFiles = 'lib/standalone_(*).dart',
    required Generator generator,
    String header = '',
    String footer = '',
  }) : super(
          inputFiles: inputFiles,
          outputFiles: outputFiles,
          generator: generator,
          header: header,
          footer: footer,
          root: '',
        );

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      syntheticInput.value: [
        'lib/output/assistant_researcher_a.dart',
        'lib/output/assistant_researcher_b.dart'
      ]
    };
  }
}
