import 'dart:async';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:directed_graph/directed_graph.dart';
import 'package:glob/glob.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:merging_builder/src/errors/builder_error.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart' show LibraryReader;

import 'formatter.dart';

/// Builder that merges its output into one file.
/// Input files must be specified using [Glob] syntax.
///
/// The builder constructor requires a generator extending [MergingGenerator<T, A>].
///
/// The builder calls the generator method [Stream<T> generateStream(library, buildStep)]
/// which emits an object of type [T] for each (input) element annotated with [A].
///
/// The merged output is returned to the builder via the generator method
/// [FutureOr<String> mergedOutput(Stream<T> stream)].
class MergingBuilder<T, S extends SyntheticInput> implements Builder {
  /// Constructs a [MergingBuilder] object.
  ///
  /// The parameter [generator] is required.
  ///
  /// The parameter [inputFiles] defaults to `'lib/*.dart'`.
  ///
  /// The parameter [outputFile] defaults to `'lib/merged_output.dart'`.
  MergingBuilder({
    this.inputFiles = 'lib/*.dart',
    this.outputFile = 'lib/merged_output.dart',
    @required this.generator,
    this.header = '',
    this.footer = '',
    this.sortAssets = false,
  })  : this.formatOutput = DartFormatter().format,
        this.syntheticInput = SyntheticInput.instance<S>();

  /// Input files. Specify the complete path relative to the
  /// root directory.
  ///
  /// For example: `lib/*.dart` includes all Dart files in
  /// the projects `lib` directory.
  final String inputFiles;

  /// Path to output file relative to the package root directory.
  /// Example: `lib/merged_output.dart`
  final String outputFile;

  /// Class extending [MergingGenerator<T,A>].
  final MergingGenerator<T, dynamic> generator;

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

  /// Set to true to have assets sorted in reverse topological order of
  /// dependency. If a file B includes a file A, then A will be appear
  /// before B.
  ///
  /// Defaults to false;
  ///
  /// Note: A [BuilderError] is thrown if [sortAssets] is `true` and
  /// a dependency cycle is detected (e.g. File A depends on file B, and
  /// file B depends on A, even indirectly).
  final bool sortAssets;

  /// The synthetic input used by this builder.
  final S syntheticInput;

  /// Returns the output file name.
  String get outputFileName => path.basename(outputFile);

  /// Returns the output directory name.
  String get outputDirectoryName => path.dirname(outputFile);

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
    if (S == Lib && outputFile.substring(0, 'lib'.length) != 'lib') {
      throw BuilderError(
          message: 'Invalid output file path found.',
          expectedState:
              'Type parameter: [Lib] => A path starting with \'lib\'.'
              'Alternatively, change the type parameter to [Package].',
          invalidState: 'The actual output path is: $outputFile.');
    }
  }

  @override
  Map<String, List<String>> get buildExtensions {
    if (syntheticInput == null) {
      throw BuilderError(
          message: 'Generic type parameter missing.',
          expectedState:
              'MergingBuilder<...,Lib> or MergingBuilder<..., Package>.',
          invalidState: 'MergingBuilder defined without type parameter [U].');
    }
    validate(outputFile);
    return {
      syntheticInput.value: [outputFile]
    };
  }

  /// Writes the merged content to the stand-alone file
  /// specified by [outputFile].
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    await buildStep.writeAsString(
      AssetId(
        buildStep.inputId.package,
        this.outputFile,
      ),
      _arrangeMergedContent(buildStep),
    );
  }

  /// Returns the merged content generated by [generator.generateMergedContent]
  /// after adding the header and footer. The final output is formatted using the
  /// function provided as constructor argument [formatOutput].
  Future<String> _arrangeMergedContent(BuildStep buildStep) async {
    // Add header to buffer.
    // Expand header:
    final _header = '// GENERATED CODE. DO NOT MODIFY. '
            'Generated by ${generator.runtimeType}. \n\n' +
        header;
    final buffer = StringBuffer(_header);
    buffer.writeln();

    // Call generator function responsible for creating merged content.
    final source =
        await generator.generateMergedContent(this._combineStreams(buildStep));
    source.trim();
    buffer.writeln(source);
    buffer.writeln();

    // Add footer.
    buffer.writeln(this.footer);

    // Format output.
    return this.formatOutput(buffer.toString());
  }

  /// Returns a stream of objects of type [T]. Combines the streams
  /// generated by [generator.generateStream]
  /// by iterating over each library file asset.
  Stream<T> _combineStreams(BuildStep buildStep) async* {
    final List<AssetId> libAssetIds = (this.sortAssets)
        ? await orderedLibraryAssetIds(buildStep)
        : await libraryAssetIds(buildStep);

    // [libAssetIds] can be null if (sortAssets == true)
    // and there is a circular dependency (files including
    // each other directly or indirectly).
    if (libAssetIds == null) {
      throw BuilderError(
          message: 'Circular dependency detected. Check the import statements'
              'of ${Glob(this.inputFiles)}');
    }

    // Accessing libraries.
    for (final libAssetId in libAssetIds) {
      final library = LibraryReader(
        await buildStep.resolver.libraryFor(libAssetId),
      );

      // Calling generator.generateStream. An object of type [T] is
      // emitted for each class defined in library that is annotated with [A].
      log.fine('Running ${generator.runtimeType} on: ${libAssetId.path}.');
      Stream<T> streamOfT = await generator.generateStream(library, buildStep);

      // Combining all objects of type [T] into a stream.
      await for (final T t in streamOfT) {
        yield t;
      }
    }
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

  /// Returns a list of library asset ids ordered in reverse topological
  /// dependency order. If a file B includes a file A, then A will be appear
  /// before B.
  ///
  /// Returns [null] if a dependency cycle is detected.
  Future<List<AssetId>> orderedLibraryAssetIds(BuildStep buildStep) async {
    // Find matching input files.
    final Stream<AssetId> inputs = await buildStep.findAssets(
      Glob(this.inputFiles),
    );
    // An assetId map with the [String] uri as key.
    final Map<String, AssetId> assetMap = {};

    // Access libraries
    await for (final input in inputs) {
      // Check if input file is a library.
      bool isLibrary = await buildStep.resolver.isLibrary(input);
      if (!isLibrary) continue;
      assetMap['${input.uri}'] = input;
    }

    final Map<AssetId, Vertex<AssetId>> vertices = {};
    final assetGraph = DirectedGraph<AssetId>({},
        comparator: ((v1, v2) => -v1.data.compareTo(v2.data)));

    for (final libId in assetMap.values) {
      // Add current assetId to map of vertices:
      vertices[libId] ??= Vertex<AssetId>(libId);
      // Retrieve library.
      final library = await buildStep.resolver.libraryFor(libId);
      // Get dependencies
      final List<Vertex<AssetId>> edgeVertices = [];

      for (var import in library.imports) {
        // Dart core libraries have uri null.
        if (import.uri == null) continue;
        final importedAssetId = assetMap[import.uri];
        // Continue if import does not refer to a file in [this.inputFiles].
        if (importedAssetId == null) continue;

        //final asset = await AssetId.resolve(import.uri);
        //print(asset == assetMap[import.uri]);

        // Add vertex of importedAssetId if it does not exist yet.
        vertices[importedAssetId] ??= Vertex<AssetId>(importedAssetId);
        edgeVertices.add(vertices[importedAssetId]);
      }
      assetGraph.addEdges(vertices[libId], edgeVertices);
    }

    return assetGraph.topologicalOrdering?.reversed
        ?.expand<AssetId>((item) => [item.data])
        ?.toList();
  }
}
