import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:merging_builder/merging_builder.dart';
import 'package:merging_builder/src/annotations/add_names.dart';
import 'package:source_gen/source_gen.dart';
import 'package:quote_buffer/quote_buffer.dart';

/// Reads numbers from annotated classes and emits the sum.
class AddNamesGenerator extends MergingGenerator<List<String>, AddNames> {
  /// Portion of source code included at the top of the generated file.
  /// Should be specified as header when constructing the merging builder.
  static String get header {
    return '/// Added names. (Specified as header.)';
  }

  /// Portion of source code included at the very bottom of the generated file.
  /// Should be specified as [footer] when constructing the merging builder.
  static String get footer {
    return '/// This is the footer.';
  }

  @override
  List<String> generateStreamItemForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final List<String> result = [];
    if (element is ClassElement) {
      final nameObjects =
          element.getField('names')?.computeConstantValue()?.toListValue();
      if (nameObjects != null) {
        for (final nameObj in nameObjects) {
          result.add(nameObj.toStringValue());
        }
        return result;
      }
    }
    return null;
  }

  /// Returns merged content.
  @override
  FutureOr<String> mergedContent(Stream<List<String>> stream) async {
    final b = QuoteBuffer();
    int i = 0;
    final List<List<String>> allNames = [];
    // Iterate over stream:
    await for (final names in stream) {
      b.write('final name$i = [');
      b.writelnAllQ(names, separator2: ',');
      b.writeln('];');
      ++i;
      allNames.add(names);
    }

    b.writeln('');
    b.writeln('final List<List<String>> names = [');
    for (var names in allNames) {
      b.writeln('  [');
      b.writelnAllQ(names, separator2: ',');
      b.writeln('  ],');
    }
    b.writeln('];');
    return b.toString();
  }
}
