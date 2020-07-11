import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:researcher/researcher.dart' show AddNames;
import 'package:source_gen/source_gen.dart';

/// Generates a standalone file.
class AssistantGenerator extends GeneratorForAnnotation<AddNames> {
  /// Portion of source code included at the top of the generated file.
  /// Should be specified as header when constructing the merging builder.
  static String get header {
    return '/// Assistant.';
  }

  /// Portion of source code included at the very bottom of the generated file.
  /// Should be specified as [footer] when constructing the merging builder.
  static String get footer {
    return '/// This is the footer.';
  }

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final List<String> result = [];
    if (element is ClassElement) {
      final nameObjects =
          element.getField('names')?.computeConstantValue()?.toListValue();

      for (final nameObj in nameObjects ?? []) {
        result.add(nameObj.toStringValue());
      }
      return 'final String assistants = \'${result.join(', ')}\';';
    }
    return null;
  }
}
