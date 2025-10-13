import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:directed_graph/directed_graph.dart';
import 'package:exception_templates/exception_templates.dart';
import 'package:glob/glob.dart';

import 'formatter.dart';
import '../enum/build_location.dart';

/// Base class of a builder that uses synthetic input.
abstract class SyntheticBuilder implements Builder {
  /// Super constructor of an object that extends [SyntheticBuilder].
  /// * [inputFiles]: Path to the input files relative to the
  /// package root directory. Glob-style syntax is
  /// allowed for example: `lib/*.dart`.
  /// * [header]: [String] that will be inserted at the top of the
  /// generated file below the 'DO NOT EDIT' warning message.
  /// * [footer]: String that will be inserted at the very bottom of the
  /// generated file.
  /// * [formatter]: A function with signature `String Function(String input)`
  /// that is used to format the generated source code.
  /// The default formatter is: `DartFormatter().format`.
  /// To disable formatting one may pass a closure returning the
  /// input: `(input) => input` as argument for `formatter`.
  SyntheticBuilder({
    required this.buildLocation,
    required this.inputFiles,
    this.header = '',
    this.footer = '',
    Formatter? formatter,
  }) : formatter =
           formatter ??
           DartFormatter(
             languageVersion: DartFormatter.latestLanguageVersion,
           ).format;

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
  final BuildLocation buildLocation;

  /// Returns the generated source code
  /// after adding the header and footer.
  ///
  /// The final output is formatted using the
  /// function provided as constructor argument for `formatter`.
  String arrangeContent(String source, {String generatedBy = ''}) {
    // Add header to buffer.
    // Expand header:
    final buffer = StringBuffer(
      '// GENERATED CODE. DO NOT MODIFY. $generatedBy \n\n $header',
    );
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
  /// * All non-library inputs are skipped.
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

  /// Recursively adds an [AssetId] representing a library to a graph.
  /// If the library imports other
  /// libraries then the respective asset ids will be added as graph edges.
  ///
  /// ---
  /// Note: The graph is acyclic only if no library imports itself (indirectly).
  Future<void> _addAssetVertex({
    required DirectedGraph<AssetId> assetGraph,
    required AssetId assetId,
    required Set<AssetId> scannedAssetIds,
    required BuildStep buildStep,
  }) async {
    scannedAssetIds.add(assetId);
    final library = await buildStep.resolver.libraryFor(assetId);
    for (final fragment in library.fragments) {
      for (final importedLibrary in fragment.importedLibraries) {
        final uri = importedLibrary.uri;
        switch (uri.scheme) {
          case 'package' || 'asset':
            final importedAssetId = AssetId.resolve(uri, from: assetId);
            assetGraph.addEdges(assetId, {importedAssetId});
            // Recursive call. Check if assetId exists!
            if (!scannedAssetIds.contains(importedAssetId)) {
              // log.fine('recursive call: $importedAssetId');
              await _addAssetVertex(
                assetGraph: assetGraph,
                assetId: importedAssetId,
                buildStep: buildStep,
                scannedAssetIds: scannedAssetIds,
              );
            }
            break;
          default:
          // log.finer(
          //   'Info: In \'SyntheticBuilder\' could not resolve '
          //   'library ${importedLibrary.displayName} '
          //   'with uri.scheme: ${uri.scheme}.',
          // );
        }
      }
    }
  }

  /// Returns an ordered set of library asset ids ordered in reverse topological
  /// dependency order.
  /// * If a file B includes a file A, then A will be appear
  /// before B.
  /// * Throws [ErrorOf] if a dependency cycle is detected and at least
  /// two input files import each other (directly or indirectly).
  Future<Set<AssetId>> orderedLibraryAssetIds(BuildStep buildStep) async {
    final assetGraph = DirectedGraph<AssetId>(
      {},
      comparator: ((v1, v2) => v1.compareTo(v2)),
    );

    final scannedAssetIds = <AssetId>{};

    /// The assetIds representing the libraries that will be processed by the
    /// builder.
    final assetIds = <AssetId>{};

    // Access libraries
    await for (final assetId in buildStep.findAssets(Glob(inputFiles))) {
      // Check if input file is a library.
      if (await buildStep.resolver.isLibrary(assetId)) {
        await _addAssetVertex(
          assetGraph: assetGraph,
          assetId: assetId,
          buildStep: buildStep,
          scannedAssetIds: scannedAssetIds,
        );
        assetIds.add(assetId);
      }
    }
    final result = assetGraph.reverseQuasiTopologicalOrdering(
      assetIds,
      sorted: true,
    );

    if (result != null) {
      return result;
    } else {
      // Find relevant cycle
      var invalidState = '';
      for (final assetId in assetIds) {
        final cycle = assetGraph.shortestPath(assetId, assetId);
        if (cycle.isNotEmpty) {
          invalidState = cycle.join(' imports ');
          break;
        }
      }

      throw ErrorOf<SyntheticBuilder>(
        message: 'Circular dependency detected.',
        expectedState:
            'Input files must not include each other. '
            'Alternatively, consider setting builder parameter '
            '<sortAssets: false>. See builder.yaml.',
        invalidState: invalidState,
      );
    }
  }
}
