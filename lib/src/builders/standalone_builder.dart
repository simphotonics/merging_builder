import 'dart:async';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:lazy_evaluation/lazy_evaluation.dart';
import 'package:merging_builder/src/builders/synthetic_input.dart';
import 'package:merging_builder/src/errors/builder_error.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart' show Generator, LibraryReader;

import 'formatter.dart';

/// Builder that creates one output file for each input file.
/// Input files must be specified using [Glob] syntax.
/// The output path must be specified.
///
/// The type parameter represents the synthetic input used by the builder.
/// Valid types are [Lib] and [Package] both extending [SyntheticInput].
class StandaloneBuilder<S extends SyntheticInput> implements Builder {
  /// Constructs a [StandAloneBuilder] object.
  ///
  /// The parameter [generator] is required.
  ///
  /// The parameter [inputFiles] defaults to `'lib/*.dart'`.
  ///
  /// The parameter [outputFiles] defaults to `'lib/standalone_(*).dart'`.
  StandaloneBuilder({
    this.inputFiles = 'lib/*.dart',
    this.outputFiles = 'lib/standalone_(*).dart',
    @required this.generator,
    this.header = '',
    this.footer = '',
  })  : this.formatOutput = DartFormatter().format,
        this.syntheticInput = SyntheticInput.instance<S>() {
    _resolvedOutputFiles = Lazy(_outputFileNames);
  }

  /// Input files. Specify the complete path relative to the
  /// root directory.
  ///
  /// For example: `lib/*.dart` includes all Dart files in
  /// the projects `lib` directory.
  final String inputFiles;

  /// Path to output files.
  /// The symbol `(*)` will be replaced with the corresponding input file name
  /// (omitting the extension).
  /// 
  /// Example: `lib/standalone_(*).dart`
  final String outputFiles;

  /// Class extending [MergingGenerator<T,A>].
  final Generator generator;

  /// String that will be inserted at the top of the
  /// generated file below the 'DO NOT EDIT' warning message.
  final String header;

  /// String that will be inserted at the very bottom of the
  /// generated file.
  final String footer;

  /// A function with signature [String Function(String input)].
  /// Defaults to [DartFormatter().format].
  ///
  /// Is used to format the merged output.
  /// To disable formatting one may pass a closure returning the
  /// input: `(input) => input;` as argument for [formatOutput].
  final Formatter formatOutput;

  /// The synthetic input used by this builder.
  final S syntheticInput;

  /// Lazily computes the output file names by replacing the
  /// placeholder `(*)` in [outputFiles] with the input file basename.
  Lazy<List<String>> _resolvedOutputFiles;

  /// Returns the output file name.
  String get outputPath => path.basename(outputFiles);

  /// Returns the output directory name.
  String get outputDirectory => path.dirname(outputFiles);

  /// Returns the input file name(s).
  String get inputFileNames => path.basename(inputFiles);

  /// Returns the input file directory.
  String get inputDirectory => path.dirname(inputFiles);

  /// Validates input and output path.
  void validate(String path) {
    if (S == Lib && inputFiles.substring(0, 'lib'.length) != 'lib') {
      throw BuilderError(
          message: 'Invalid input file path found.',
          expectedState:
              'Type parameter: [Lib] => A path starting with \'lib\'.'
              'Alternatively, change the type parameter to [Package].',
          invalidState: 'The actual input path is: $inputFiles.');
    }
    if (S == Lib && outputFiles.substring(0, 'lib'.length) != 'lib') {
      throw BuilderError(
          message: 'Invalid output file path found.',
          expectedState:
              'Type parameter: [Lib] => A path starting with \'lib\'.'
              'Alternatively, change the type parameter to [Package].',
          invalidState: 'The actual output path is: $outputFiles.');
    }
  }

  /// Returns a list of output file paths.
  List<String> _outputFileNames() {
    final List<String> result = [];
    validate(inputFiles);
    validate(outputFiles);
    final resolvedInputFiles = Glob(inputFiles);
    for (final inputEntity in resolvedInputFiles.listSync()) {
      final basename = path.basenameWithoutExtension(inputEntity.path);
      String outputFileName = outputFiles.replaceAll(
        RegExp(r'\(\*\)'),
        basename,
      );
      // Check if output clashes with input files.
      if (path.equals(outputFileName,inputEntity.path)) {
        throw BuilderError(
            message: 'Output file clashes with input file!',
            expectedState: 'Output files must not overwrite input files. '
            'Check the [StandaloneBuilder] constructor argument [outputFiles].',
            invalidState: 'Output: $outputFileName is also an input file.');
      }
      result.add(outputFileName);
    }
    return result;
  }

  /// Returns a map of type `<String, List<String>>`
  /// with content {synthetic input: list of output files}.
  ///
  /// The builder uses the synthetic input specified by the
  /// type parameter [T extends SyntheticInput].
  @override
  Map<String, List<String>> get buildExtensions {
    if (syntheticInput == null) {
      throw BuilderError(
          message: 'Generic type parameter missing.',
          expectedState:
              'StandaloneBuilder<Lib> or StandaloneBuilder<Package>.',
          invalidState: 'StandaloneBuilder defined without type parameter.');
    }
    return {
      syntheticInput.value: _resolvedOutputFiles.value,
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final List<AssetId> libAssetIds = await libraryAssetIds(buildStep);
    // Accessing libraries.
    for (final libAssetId in libAssetIds ?? []) {
      final library = LibraryReader(
        await buildStep.resolver.libraryFor(libAssetId),
      );
      // Calling generator.generate.
      log.fine('Running ${generator.runtimeType} on: ${libAssetId.path}.');
      // Create output file name.

      await buildStep.writeAsString(
        AssetId(
          buildStep.inputId.package,
          _outputFile(libAssetId),
        ),
        _arrangeContent(library, buildStep),
      );
    }
  }

  /// Returns path of the output file for a given input file [assetId].
  String _outputFile(AssetId assetId) {
    final String basename = path.basenameWithoutExtension(assetId.path);
    return outputFiles.replaceAll(RegExp(r'\(\*\)'), basename);
  }

  /// Returns the content generated by [generator.generate]
  /// after adding the header and footer. The final output is formatted using the
  /// function provided as constructor argument [formatOutput].
  Future<String> _arrangeContent(
    LibraryReader library,
    BuildStep buildStep,
  ) async {
    // Add header to buffer.
    // Expand header:
    final _header = '// GENERATED CODE. DO NOT MODIFY. '
            'Generated by ${generator.runtimeType}. \n\n' +
        header;
    final buffer = StringBuffer(_header);
    buffer.writeln();

    // Call generator function responsible for creating content.
    final source = await generator.generate(library, buildStep);
    source.trim();
    buffer.writeln(source);
    buffer.writeln();

    // Add footer.
    buffer.writeln(this.footer);

    // Format output.
    return this.formatOutput(buffer.toString());
  }

  /// Returns a list of unordered library asset ids.
  /// All non-library inputs (e.g. part files) are skipped.
  Future<List<AssetId>> libraryAssetIds(BuildStep buildStep) async {
    final List<AssetId> result = [];
    // Find matching input files.
    final Stream<AssetId> inputs = await buildStep.findAssets(
      Glob(this.inputFiles),
    );
    // Access libraries
    await for (final input in inputs) {
      // Check if input file is a library.
      bool isLibrary = await buildStep.resolver.isLibrary(input);
      if (isLibrary) {
        result.add(input);
      }
    }
    return result;
  }
}
