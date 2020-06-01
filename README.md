
# Merging Builder


## Introduction

Source code generation has become an integral software development tool when building and maintaining a large number of data models, data access object, widgets, etc.

The library [merging_builder] provides a Dart builder that reads **several input files** and writes the merged output to **one output file**. [MergingBuilder] is a parameterized class that supports passing data of arbitrary type from the generator function that is called for each annotated class to a generator
function that creates the *merged output*.

The builder has support for specifying a header and footer to be placed at the top and bottom of the output file.


## Usage

Following the guidelines of [source_gen], it is common practice to separate *builders* and *generators* from the code using those builders. The classes provided by [merging_builder] are typically used in
a package that defines builders and generators.

In the example below the package defining a new builder is called `researcher_builder` and the package using this builder is called `researcher`. To set up a build system the following steps are required:

1. Include [merging_builder] and [build] as *dependencies* in the file `pubspec.yaml` of the package **defining** the builder. (In the example show here, the generator also requires the packages [analyzer] and [source_gen].)

2. In the package **defining** the builder, create a custom generator that extends [MergingGenerator]. Users will have to implement the methods `generateItemForAnnotatedElement` and `mergedContent`. In the example shown below `generateItemForAnnotatedElement` reads a list of strings while `mergedContent` merges the data and generates output that is writen to [].
   <details> <summary> Show details. </summary>

    ```Dart
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
    ```

   </details>

3. Create an instance of [MergingBuilder]. Following the example of [source_gen], builders are typically placed in a file called: `builder.dart` located in the `lib` folder of the builder package. The generator `AddNamesGenerator` extends `MergingGenerator<List<String>, AddNames>` (see step 2).

    ```Dart
     import 'package:build/build.dart';
     import 'package:merging_builder/merging_builder.dart';

     import 'generators/add_names_generator.dart';

     Builder addNamesBuilder(BuilderOptions options) =>
       MergingBuilder<List<String>>(
         generator: AddNamesGenerator(),
         inputFiles: 'lib/input/*.dart',
         outputFile: 'lib/researchers.dart',
         header: AddNamesGenerator.header,
         footer: AddNamesGenerator.footer,
         sortAssets: false,
       );
    ```

4. In the package defining the builder, add the builder configuration for the builder `add_names_builder` (see below). The build extensions for [MergingBuilder] must be specified using the notation available for synthetic input. For example, `"$lib$"` indicates that the
input files are located in the folder `lib` or a subfolder thereof.
For more information consult the section: [Writing a Builder using a synthetic input]
found in the documentation of the Dart package [build].

    ```Yaml
    builders:
      add_names_builder:
        import: "package:researcher_builder/builder.dart"
        builder_factories: ["addNamesBuilder"]
        build_extensions: {"$lib$": ["*.dart"]}
        auto_apply: root_package
        build_to: source
        builders:
    ```

5. In the package **using** the builder, `researcher`, add `add_names_builder` to the list of known builders. The file `build.yaml` is shown below.

    ```Yaml
     targets:
       $default:
         builders:
           # Configure the builder `pkg_name|builder_name`
           researcher_builder|add_names_builder:
             enabled: true
             # Only run this builder on the specified input.
             # generate_for:
             #   - lib/*.dart
    ```

6. In the package **using** the builder, `researcher`, add `researcher_builder` and [build_runner] as dev_dependencies in the file `pubspec.yaml`.

    ```Yaml
    name: researcher
      description:
        Example demonstrating how to use the library merging_builder.

      environment:
        sdk: '>=2.8.1 <3.0.0'

      dev_dependencies:
        build_runner: ^1.10.0
        researcher_builder:
          path: ../researcher_builder
    ```

7. Initiate the build process by using the command:
   ```console
   # pub run build_runner build --delete-conflicting-outputs --verbose
   ```

## Examples

For further information on how to use [MergingBuilder] see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[analyzer]: https://pub.dev/packages/analyzer

[build]: https://pub.dev/packages/build

[build_runner]: https://pub.dev/packages/build_runner

[example]: example

[Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html

[GeneratorForAnnotation]: https://pub.dev/documentation/source_gen/latest/source_gen/GeneratorForAnnotation-class.html

[MergingBuilder]: https://pub.dev/packages/merging_builder

[merging_builder]: https://pub.dev/packages/merging_builder


[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test

[Writing a Builder using a synthetic input]: https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input
