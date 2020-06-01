import 'package:build/build.dart';
import 'package:merging_builder/merging_builder.dart';

import 'generators/add_names_generator.dart';

/// Defines a merging builder.
Builder addNamesBuilder(BuilderOptions options) =>
    MergingBuilder<List<String>>(
      generator: AddNamesGenerator(),
      inputFiles: 'lib/input/*.dart',
      outputFile: 'lib/researchers.dart',
      header: AddNamesGenerator.header,
      footer: AddNamesGenerator.footer,
      sortAssets: false,
    );
