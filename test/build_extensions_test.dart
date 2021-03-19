import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:exception_templates/exception_templates.dart';
import 'dart:async';

import 'package:merging_builder/merging_builder.dart';
import 'package:source_gen/src/constants/reader.dart';
import 'package:test/test.dart';

class MockAnnotation {
  const MockAnnotation();
}

class MockMergingGenerator
    extends MergingGenerator<List<double>, MockAnnotation> {
  @override
  FutureOr<String> generateMergedContent(Stream<List<double>> stream) {
    throw UnimplementedError();
  }

  @override
  List<double> generateStreamItemForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    throw UnimplementedError();
  }
}

/// Tests if the builder generates the expected buildExtensions.
void main() {
  final libBuilder = MergingBuilder<List<double>, LibDir>(
    generator: MockMergingGenerator(),
    inputFiles: 'lib/input/*.dart',
    outputFile: 'lib/output/output.dart',
  );

  final packageBuilder = MergingBuilder<List<double>, PackageDir>(
    generator: MockMergingGenerator(),
    inputFiles: 'test/input/*.dart',
    outputFile: 'test/output/output.dart',
  );

  final misconfiguredlibBuilder = MergingBuilder<List<double>, LibDir>(
    generator: MockMergingGenerator(),
    inputFiles: 'web/input/*.dart',
    outputFile: 'web/output/output.dart',
  );

  group('buildExtensions', () {
    test(r'LibDir', () {
      expect(libBuilder.buildExtensions, {
        r'lib/$lib$': ['lib/output/output.dart'],
      });
    });
    test(r'PackageDir', () {
      expect(packageBuilder.buildExtensions, {
        r'$package$': ['test/output/output.dart'],
      });
    });
    test(r'LibDir throws', () {
      try {
        final buildExtensions = misconfiguredlibBuilder.buildExtensions;
        buildExtensions.clear();
      } catch (e) {
        expect(e, isA<ErrorOf<SyntheticInput>>());
      }
    });
  });
}
