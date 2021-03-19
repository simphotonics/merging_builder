import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' show BuildStep;
import 'package:merging_builder/merging_builder.dart';
import 'package:quote_buffer/quote_buffer.dart';
import 'package:researcher/researcher.dart' show AddNames;
import 'package:source_gen/source_gen.dart';

/// Reads a field element of type [List<String] and generates the merged content.
class AddNamesGenerator extends MergingGenerator<List<String>, AddNames> {
  /// Portion of source code included at the top of the generated file.
  /// Should be specified as header when constructing the merging builder.
  static String get header {
    return '/// Added names.';
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
    final result = <String>[];
    if (element is ClassElement) {
      final nameObjects =
          element.getField('names')?.computeConstantValue()?.toListValue();
      for (final nameObj in nameObjects ?? []) {
        result.add(nameObj.toStringValue());
      }
      return result;
    }
    return <String>['Could not read name'];
  }

  /// Returns the merged content.
  @override
  FutureOr<String> generateMergedContent(Stream<List<String>> stream) async {
    final b = StringBuffer();
    var i = 0;
    final allNames = <List<String>>[];
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
