import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:directed_graph/directed_graph.dart';
import 'package:exception_templates/exception_templates.dart';
import 'package:glob/glob.dart';

import 'formatter.dart';
import 'synthetic_input.dart';

/// Base class of a builder that uses synthetic input.
///
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
abstract class SyntheticBuilder<S extends SyntheticInput> implements Builder {
  /// Super constructor of an object of type `SyntheticBuilder`.
  /// * `inputFiles`: Path to the input files relative to the
  /// package root directory. Glob-style syntax is
  /// allowed for example: `lib/*.dart`.
  /// * `header`: `String` that will be inserted at the top of the
  /// generated file below the 'DO NOT EDIT' warning message.
  /// * `footer`: String that will be inserted at the very bottom of the
  /// generated file.
  /// * `formatter`: A function with signature `String Function(String input)`
  /// that is used to format the generated source code.
  /// The default formatter is: `DartFormatter().format`.
  /// To disable formatting one may pass a closure returning the
  /// input: `(input) => input` as argument for `formatter`.
  SyntheticBuilder({
    required this.inputFiles,
    this.header = '',
    this.footer = '',
    Formatter? formatter,
  })  : formatter = formatter ??
            DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
                .format,
        syntheticInput = SyntheticInput.instance<S>();

  /// Input files. Specify the complete path relative to the
  /// root directory.
  ///
  /// For example: `lib/*.dart` includes all Dart files in
  /// the projects `lib` directory.
  final String inputFiles;

  /// String that will be inserted at the top of the
  /// generated file below the 'DO NOT EDIT' warning message.
  final String header;

  /// String that will be inserted at the very bottom of the
  /// generated file.
  final String footer;

  /// A function with signature `String Function(String input)`.
  /// Defaults to `DartFormatter().format`.
  ///
  /// Is used to format the merged output.
  /// To disable formatting one may pass a closure returning the
  /// input: `(input) => input` as argument for `formatter`.
  final Formatter formatter;

  /// The synthetic input used by this builder.
  final S syntheticInput;

  /// Returns the generated source code
  /// after adding the header and footer.
  ///
  /// The final output is formatted using the
  /// function provided as constructor argument for `formatter`.
  String arrangeContent(String source, {String generatedBy = ''}) {
    // Add header to buffer.
    // Expand header:
    final buffer = StringBuffer(
        '// GENERATED CODE. DO NOT MODIFY. $generatedBy \n\n $header');
    buffer.writeln();

    source.trim();
    buffer.writeln(source);
    buffer.writeln();

    // Add footer.
    buffer.writeln(footer);

    // Format output.
    return formatter(buffer.toString());
  }

  /// Returns a list of unordered library asset ids.
  /// * All non-library inputs (e.g. part files) are skipped.
  Future<List<AssetId>> libraryAssetIds(BuildStep buildStep) async {
    final result = <AssetId>[];
    // Access libraries
    await for (final input in buildStep.findAssets(Glob(inputFiles))) {
      // Check if input file is a library.
      if (await buildStep.resolver.isLibrary(input)) {
        result.add(input);
      }
    }
    return result;
  }

  /// Returns a ordered set of library asset ids ordered in reverse topological
  /// dependency order.
  /// * If a file B includes a file A, then A will be appear
  /// before B.
  /// * Throws [ErrorOf] if a dependency cycle is detected.
  Future<Set<AssetId>> orderedLibraryAssetIds(BuildStep buildStep) async {
    final assetGraph =
        DirectedGraph<AssetId>({}, comparator: ((v1, v2) => -v1.compareTo(v2)));

    // An assetId map of all input libraries with the uri as key.
    final assetMap = <Uri, AssetId>{};

    // Access libraries
    await for (final input in buildStep.findAssets(Glob(inputFiles))) {
      // Check if input file is a library.
      if (await buildStep.resolver.isLibrary(input)) {
        assetMap[input.uri] = input;
        assetGraph.addEdges(assetMap[input.uri]!, {});
      }
    }

    for (final assetId in assetGraph) {
      final importedAsseIds = <AssetId>{};

      // Read library.
      final library = await buildStep.resolver.libraryFor(assetId);
      // Get dependencies
      for (final import in library.importedLibraries) {
        final uri = Uri.parse(import.source.uri.toString());
        // Skip if uri scheme is not "package" or "asset".
        if (uri.scheme == 'package' ||
            uri.scheme == 'asset' ||
            uri.scheme == '') {
          // Normalise uri to handle relative and package import directives.
          final importedAssetId = AssetId.resolve(uri, from: assetId);
          // Add vertex matching import directive.
          if (assetMap[importedAssetId.uri] != null) {
            importedAsseIds.add(assetMap[importedAssetId.uri]!);
          }
        }
      }
      assetGraph.addEdges(assetId, importedAsseIds);
    }

    final topologicalOrdering = assetGraph.sortedTopologicalOrdering;

    if (topologicalOrdering == null) {
      // Find the first cycle
      final cycle = assetGraph.cycle;

      throw ErrorOf<SyntheticBuilder>(
          message: 'Circular dependency detected.',
          expectedState: 'Input files must not include each other. '
              'Alternatively, set constructor parameter "sortAssets: false".',
          invalidState: 'File ${cycle.join(' imports ')}.');
    }

    // Return reversed topological ordering of asset ids.
    return topologicalOrdering;
  }
}
