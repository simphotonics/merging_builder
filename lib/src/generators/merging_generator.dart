import 'dart:async';
import 'package:analyzer/dart/element/element.dart' show Element;
import 'package:build/src/builder/build_step.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:source_gen/source_gen.dart';

/// Generic class that extends [GeneratorForAnnotation<A>]. The generator
/// method [generateStream] is used to pass a stream of objects of type
/// [T] to a builder of type [MergingBuilder].
///
/// [T] is a generic type and [A] is an annotation.
abstract class MergingGenerator<T, A> extends GeneratorForAnnotation<A> {
  /// Const constructor used to instantiate an object of type [MergingGenerator].
  const MergingGenerator();

  /// Generates a stream of objects of type [T]. Each value of [T] is
  /// calculated by calling [generateStreamItemForAnnotatedElement].
  Stream<T> generateStream(
    LibraryReader library,
    BuildStep buildStep,
  ) async* {
    for (final annotatedElement in library.annotatedWith(typeChecker)) {
      yield generateStreamItemForAnnotatedElement(
        annotatedElement.element,
        annotatedElement.annotation,
        buildStep,
      );
    }
  }

  /// Returns an object of type [T] that will be added to the [Stream<T>]
  /// emitted by [generateStream<T>].
  /// It is a generalization of [generateForAnnotatedElement].
  ///
  /// Override this method in classes extending [MergingGenerator].
  T generateStreamItemForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  );

  /// Returns the merged content that will be written to the output file by
  /// the [MergingBuilder].
  ///
  /// Override this method in classes extending [MergingGenerator].
  ///
  /// Note: The [stream] contains objects generated for all annotated elements
  /// found in all files that match the input [Glob] of the [MergingBuilder].
  FutureOr<String> generateMergedContent(Stream<T> stream);

  /// Portion of source code included at the top of the generated file.
  /// Should be specified as header when constructing the merging builder.
  static String get header => null;

  /// Portion of source code included at the very bottom of the generated file.
  /// Should be specified as [footer] when constructing the merging builder.
  static String get footer => null;

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    return null;
  }
}
