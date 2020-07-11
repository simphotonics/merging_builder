import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:researcher/researcher.dart' show AddNumbers;
import 'package:source_gen/source_gen.dart';

/// Reads numbers from annotated classes and emits the sum.
class AddNumbersGenerator extends MergingGenerator<num, AddNumbers> {
  /// Portion of source code included at the top of the generated file.
  /// Should be specified as header when constructing the merging builder.
  static String get header {
    return '/// Added numbers';
  }

  /// Portion of source code included at the very bottom of the generated file.
  /// Should be specified as [footer] when constructing the merging builder.
  static String get footer {
    return '/// This is the footer.';
  }

  @override
  num generateStreamItemForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is ClassElement) {
      return element.getField('number')?.computeConstantValue()?.toIntValue();
    }
    return null;
  }

  /// Returns merged content.
  @override
  FutureOr<String> generateMergedContent(Stream<num> stream) async {
    final b = StringBuffer();
    int i = 0;
    num sum = 0;
    // Iterate over stream:
    await for (final number in stream) {
      b.writeln('final num number$i = $number;');
      sum += number;
    }
    b.writeln('final num sum = $sum;');
    return b.toString();
  }
}
