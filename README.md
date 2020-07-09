
# Merging Builder
[![Build Status](https://travis-ci.com/simphotonics/merging_builder.svg?branch=master)](https://travis-ci.com/simphotonics/merging_builder)


## Introduction

Source code generation has become an integral software development tool when building and maintaining a large number of data models, data access object, widgets, etc.

The library [`merging_builder`][merging_builder] includes the classes
[`MergingBuilder`][MergingBuilder] and [`StandaloneBuilder`][StandaloneBuilder]. Both builders use *synthetic input* which must be specified
by choosing either [`$Lib$`][$Lib$] or [`$Package$`][$Package] as type parameter `S` (see figure below).

[`$Lib$`][$Lib$] indicates that input and output files are located in the package directory `lib` or a subfolder thereof. For more information
about *synthetic input* see:
[Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).

### Merging Builder

[MergingBuilder] reads **several input files** and writes merged output to **one output file**.

A conventional builder typically calls the generator method `generate` from within its `build` method to retrieve the generated source-code. [`MergingBuilder`][MergingBuilder] calls the [`MergingGenerator`][MergingGenerator] method `generateStream`. It allows the generator to pass a stream of data-type `T` to the builder, one stream item for each annotated element processed to the generator method `generateStreamItemForAnnotatedElement`.

The private builder method `_combineStreams` combines the streams received for each processed input file and calls the generator method `generateMergedContent`. As a result, this method has access to all stream items of type `T` generated for each annotated element in each input file. It is the task of this method to generate the merged source-code output.

The figure below shows the flow of data between the builder and the generator. The data type is indicated by the starting point of the connectors. Dotted connectors represent a stream of data.


![Directed Graph Image](https://raw.githubusercontent.com/simphotonics/merging_builder/master/images/merging_builder.svg?sanitize=true)

### Standalone Builder

[StandaloneBuilder] reads one or several input files and writes standalone files to a custom location.
*Standalone* means the output files may be written to a custom folder and not only the extension but the
name of the output file can be configured.

The input file path (constructor parameter `inputFiles`) may include
wild-card notation supported by [`Glob`][Glob].

Output files are specified by using the custom symbol
`(*)`. For example, the output path `output\assistant_(*).dart` is interpreted such that `(*)` is replaced with the input file name (excluding the file extension). For more details, see the files [`example\researcher_builder\builder.dart`][builder.dart].

## Usage

Following the example of [`source_gen`][source_gen], it is common practice to separate *builders* and *generators* from the code using those builders.

In the [example] provided with this library, the package defining a new builder is called `researcher_builder` and the package using this builder is called `researcher`. To set up a build system the following steps are required:

1. Include [`merging_builder`][merging_builder] and [`build`][build] as *dependencies* in the file `pubspec.yaml` of the package **defining** the builder. (In the [example] mentioned here, the generator also requires the packages [`analyzer`][analyzer] and [`source_gen`][source_gen].)

2. In the package **defining** the custom builder, create a custom generator that extends [`MergingGenerator`][MergingGenerator]. Users will have to implement the methods `generateItemForAnnotatedElement` and `generateMergedContent`. In the example shown below `generateItemForAnnotatedElement` reads a list of strings while `generateMergedContent` merges the data and generates output that is written to [researchers.dart].
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
      FutureOr<String> generateMergedContent(Stream<List<String>> stream) async {
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

3. Create an instance of [`MergingBuilder`][MergingBuilder]. Following the example of [`source_gen`][source_gen], builders are typically placed in a file called: `builder.dart` located in the `lib` folder of the builder package. The generator `AddNamesGenerator` extends `MergingGenerator<List<String>, AddNames>` (see step 2). Input sources may be specified using wildcard characters supported by [`Glob`][Glob]. The builder definition shown below honours the *options* `input_files`, `output_file`, `header`, `footer`,
and `sort_assets` that can be set in the file `build.yaml` located in the package `researcher` (see step 5).

    ```Dart
     import 'package:build/build.dart';
     import 'package:merging_builder/merging_builder.dart';

     import 'generators/add_names_generator.dart';

     /// Defines a merging builder.
     /// Honours the options: `input_files`, `output_file`, `header`, `footer`,
     /// and `sort_assets` that can be set in `build.yaml`.
     Builder addNamesBuilder(BuilderOptions options) {
       BuilderOptions defaultOptions = BuilderOptions({
         'input_files': 'lib/*.dart',
         'output_file': 'lib/output.dart',
         'header': AddNamesGenerator.header,
         'footer': AddNamesGenerator.footer,
         'sort_assets': false,
       });

       // Apply user set options.
       options = defaultOptions.overrideWith(options);
       return MergingBuilder<List<String>>(
         generator: AddNamesGenerator(),
         inputFiles: options.config['input_files'],
         outputFile: options.config['output_file'],
         header: options.config['header'],
         footer: options.config['footer'],
         sortAssets: options.config['sort_assets'],
       );
     }
    ```

4. In the package **defining** the builder, add the builder configuration for the builder `add_names_builder` (see below). The build extensions for
[`MergingBuilder`][MergingBuilder] must be specified using the notation available for **synthetic input**. For example, `"$lib$"` indicates that the
input files are located in the folder `lib` or a subfolder thereof.
For more information consult the section: [Writing a Builder using a synthetic input]
found in the documentation of the Dart package [`build`][build].

    ```Yaml
    builders:
      add_names_builder:
        import: "package:researcher_builder/builder.dart"
        builder_factories: ["addNamesBuilder"]
        build_extensions: {"lib/$lib$": ["lib/researchers.dart"]}
        auto_apply: root_package
        build_to: source
    ```

5. In the package **using** the custom builder, `researcher`, add `add_names_builder` to the list of known builders. The file `build.yaml` is shown below.

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
             options:
              input_files: 'lib/input/*.dart'
              output_file: 'lib/researchers.dart'
              sort_assets: true
              header: '// Header specified in build.yaml.'
              footer: '// Footer specified in build.yaml.'
    ```

6. In the package **using** the builder, `researcher`, add `researcher_builder` and [`build_runner`][build_runner] as *dev_dependencies* in the file `pubspec.yaml`.

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

For further information on how to use [`MergingBuilder`][MergingBuilder] see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[analyzer]: https://pub.dev/packages/analyzer

[build]: https://pub.dev/packages/build

[build_runner]: https://pub.dev/packages/build_runner

[builder.dart]: https://github.com/simphotonics/merging_builder/blob/master/example/researcher_builder/lib/builder.dart

[example]: example

[Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html

[GeneratorForAnnotation]: https://pub.dev/documentation/source_gen/latest/source_gen/GeneratorForAnnotation-class.html

[Glob]: https://pub.dev/packages/glob

[MergingBuilder]: https://pub.dev/documentation/merging_builder/latest/merging_builder/MergingBuilder-class.html

[merging_builder]: https://pub.dev/packages/merging_builder

[MergingGenerator]: https://pub.dev/documentation/merging_builder/latest/merging_builder/MergingGenerator-class.html

[researchers.dart]: https://github.com/simphotonics/merging_builder/blob/master/example/researcher/lib/researchers.dart

[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test

[StandaloneBuilder]: https://pub.dev/documentation/merging_builder/latest/merging_builder/StandaloneBuilder-class.html

[Writing a Builder using a synthetic input]: https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input
