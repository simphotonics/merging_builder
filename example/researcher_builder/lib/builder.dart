import 'package:build/build.dart';
import 'package:merging_builder/merging_builder.dart';

import 'src/generators/add_names_generator.dart';
import 'src/generators/assistant_generator.dart';

/// Defines a merging builder.
/// Honours the options: `input_files`, `output_file`, `header`, `footer`,
/// and `sort_assets` that can be set in `build.yaml`.
Builder addNamesBuilder(BuilderOptions options) {
  final defaultOptions = BuilderOptions({
    'input_files': 'lib/*.dart',
    'output_file': 'lib/output.dart',
    'header': AddNamesGenerator.header,
    'footer': AddNamesGenerator.footer,
    'sort_assets': true,
  });

  // Apply user set options.
  options = defaultOptions.overrideWith(options);
  return MergingBuilder<List<String>, $Lib$>(
    generator: AddNamesGenerator(),
    inputFiles: options.config['input_files'],
    outputFile: options.config['output_file'],
    header: options.config['header'],
    footer: options.config['footer'],
    sortAssets: options.config['sort_assets'],
  );
}

/// Defines a standalone builder.
Builder assistantBuilder(BuilderOptions options) {
  final defaultOptions = BuilderOptions({
    'input_files': 'lib/*.dart',
    'output_files': 'lib/output/assistant_(*).dart',
    'header': AssistantGenerator.header,
    'footer': AssistantGenerator.footer,
    'root': ''
  });
  options = defaultOptions.overrideWith(options);
  return StandaloneBuilder<$Lib$>(
      generator: AssistantGenerator(),
      inputFiles: options.config['input_files'],
      outputFiles: options.config['output_files'],
      root: options.config['root']);
}
