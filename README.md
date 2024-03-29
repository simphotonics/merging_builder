
# Merging Builder

[![Dart](https://github.com/simphotonics/merging_builder/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/merging_builder/actions/workflows/dart.yml)

## Introduction

Source code generation has become an important software development tool when building and maintaining a large number of data models, data access object, widgets, etc.

The premise of *source code generation* is that we can specify
(hopefully few) details and flesh out the rest of the classes, and methods during the build process.

The build process consists of scannig the appropriate files, extracting the required information,
generating the source code, and writing the source code to certain files. The build process
also entails keeping track of files changes, delete conflicting files, reporting issues and progress, etc.

Source code generation using Dart relies heavily on *constants* known at compile time.
Dart's static [`analyzer`][analyzer] provides access to libraries, classes,
class fields, class methods, functions, variables, etc in the form of [`Elements`][Elements].
Compile-time constant expressions are represented by a [`DartObject`][DartObject] and can be accessed by using [`computeConstantValue()`][computeConstantValue()] a method available for elements representing a variable.

In practice, we mark constant constant classes with annotations and instruct the builder to processes only
the annotated objects.


The library [`merging_builder`][merging_builder] includes the following (synthetic input) builder classes:

* [`MergingBuilder`][class-merging-builder] reads **several input files** and writes merged output to **one output file**. The builder provides the option to sort the processing order of the input files in reverse topological order.

* [`StandaloneBuilder`][StandaloneBuilder] reads one or several input files and writes standalone files to a custom location. In this context, **standalone** means the output files may be written to a **custom folder** and not only the **extension** but the **name** of the output file can be configured (as opposed to using part files).


## Usage

Following the example of [`source_gen`][source_gen], it is common practice to separate *builders* and *generators* from the code using those builders.

In the [example] provided with this library, the package defining a new builder is called `researcher_builder` and the package using this builder is called `researcher`. To set up a build system the following steps are required:

1. Include [`merging_builder`][merging_builder], [`build`][build] as *dependencies* in the file `pubspec.yaml` of the package **defining** the builder. In the [example] mentioned here, the generator also requires the packages [`analyzer`][analyzer] and [`source_gen`][source_gen].

2. In the package **defining** the custom builder, create a custom generator that extends [`MergingGenerator`][MergingGenerator]. Users will have to implement the methods `generateItemForAnnotatedElement` and `generateMergedContent`. In the example shown below `generateItemForAnnotatedElement` reads a list of strings while `generateMergedContent` merges the data and generates output that is written to [researchers.dart].


   <details> <summary> Show details. </summary>

    ```Dart

    import 'dart:async';

    import 'package:analyzer/dart/element/element.dart';
    import 'package:build/build.dart' show BuildStep;
    import 'package:merging_builder/merging_builder.dart';
    import 'package:quote_buffer/quote_buffer.dart';

    import 'package:source_gen/source_gen.dart' show ConstantReader;

    import '../annotations/add_names.dart';


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
    ```

   </details>

3. Create an instance of [`MergingBuilder`][MergingBuilder]. Following the example of [`source_gen`][source_gen], builders are typically placed in a file called: `builder.dart` located in the `lib` folder of the builder package.
   * The generator `AddNamesGenerator` shown below extends `MergingGenerator<List<String>, AddNames>` (see step 2).
   * Input sources may be specified using wildcard characters supported by [`Glob`][Glob].
   * The builder definition shown below honours the *options* `input_files`, `output_file`, `header`, `footer`, and `sort_assets` that can be set in the file `build.yaml`  located in the package `researcher` (see step 5).

    ```Dart
     import 'package:build/build.dart';
     import 'package:merging_builder/merging_builder.dart';

     import 'src/generators/add_names_generator.dart';
     import 'src/generators/assistant_generator.dart';

     /// Defines a merging builder.
     /// Honours the options: `input_files`, `output_file`, `header`, `footer`,
     /// and `sort_assets` that can be set in `build.yaml`.
     Builder addNamesBuilder(BuilderOptions options) {
       BuilderOptions defaultOptions = BuilderOptions({
         'input_files': 'lib/*.dart',
         'output_file': 'lib/output.dart',
         'header': AddNamesGenerator.header,
         'footer': AddNamesGenerator.footer,
         'sort_assets': true,
       });

       // Apply user set options.
       options = defaultOptions.overrideWith(options);
       return MergingBuilder<List<String>, LibDir>(
         generator: AddNamesGenerator(),
         inputFiles: options.config['input_files'],
         outputFile: options.config['output_file'],
         header: options.config['header'],
         footer: options.config['footer'],
         sortAssets: options.config['sort_assets'],
       );
     }

     /// Defines a standalone builder.
     Builder assistantBuilder(BuilderOptions options) {
       BuilderOptions defaultOptions = BuilderOptions({
         'input_files': 'lib/*.dart',
         'output_files': 'lib/output/assistant_(*).dart',
         'header': AssistantGenerator.header,
         'footer': AssistantGenerator.footer,
         'root': ''
       });
       options = defaultOptions.overrideWith(options);
       return StandaloneBuilder<LibDir>(
           generator: AssistantGenerator(),
           inputFiles: options.config['input_files'],
           outputFiles: options.config['output_files'],
           root: options.config['root']);
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
        build_extensions: {"lib/$lib$": ["lib/output.dart"]}
        auto_apply: root_package
        build_to: source
      assistant_builder:
        import: "package:researcher_builder/builder.dart"
        builder_factories: ["assistantBuilder"]
        build_extensions: {"lib/$lib$": ["*.dart"]}
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
             # Only run this builder on the specified input.
             enabled: true
             # generate_for:
             #   - lib/*.dart
             options:
               input_files: 'lib/input/*.dart'
               output_file: 'lib/output/researchers.dart'
               sort_assets: false
               header: '// Header specified in build.yaml.'
               footer: '// Footer specified in build.yaml.'
           researcher_builder|assistant_builder:
             enabled: true
             options:
               input_files: 'lib/input/*.dart'
               output_files: 'lib/output/assistant_(*).dart'
               root: ''
    ```

6. In the package **using** the builder, `researcher`, add `researcher_builder`
and [`build_runner`][build_runner] as *dev_dependencies* in the file `pubspec.yaml`.

    ```Yaml
    name: researcher
      description:
        Example demonstrating how to use the library merging_builder.

      environment:
        sdk: '>=2.17.0 <3.0.0'

      dev_dependencies:
        build_runner: ^1.10.0
        researcher_builder:
          path: ../researcher_builder
    ```

7. Initiate the build process by using the command:
   ```console
   # dart run build_runner build --delete-conflicting-outputs --verbose
   [INFO] Entrypoint:Generating build script...
   [INFO] Entrypoint:Generating build script completed, took 802ms

   [INFO] BuildDefinition:Initializing inputs
   [INFO] BuildDefinition:Reading cached asset graph...
   [INFO] BuildDefinition:Reading cached asset graph completed, took 99ms

   [INFO] BuildDefinition:Checking for updates since last build...
   [INFO] BuildDefinition:Checking for updates since last build completed, took 772ms

   [INFO] Build:Running build...
   [FINE] researcher_builder:add_names_builder on lib/$lib$:Running AddNamesGenerator on: lib/input/researcher_b.dart.
   [FINE] researcher_builder:add_names_builder on lib/$lib$:Running AddNamesGenerator on: lib/input/researcher_a.dart.
   [FINE] researcher_builder:assistant_builder on lib/$lib$:Running AssistantGenerator on: lib/input/researcher_b.dart.
   [FINE] researcher_builder:assistant_builder on lib/$lib$:Running AssistantGenerator on: lib/input/researcher_a.dart.
   [INFO] Build:Running build completed, took 886ms

   [INFO] Build:Caching finalized dependency graph...
   [INFO] Build:Caching finalized dependency graph completed, took 70ms

   [INFO] Build:Succeeded after 973ms with 3 outputs (2 actions)
   ```

To view the content of the generated files please click below:
<details> <summary> lib/output/assistant_researcher_a.dart </summary>

 ```Dart
 // GENERATED CODE. DO NOT MODIFY. Generated by AssistantGenerator.
 final String assistants = 'Thomas, Mayor';
 ```

</details>

<details> <summary> lib/output/assistant_researcher_b.dart </summary>

 ```Dart
 // GENERATED CODE. DO NOT MODIFY. Generated by AssistantGenerator.
 final String assistants = 'Philip, Martens';
 ```

</details>
<details> <summary> lib/output/researchers.dart </summary>

 ```Dart
 // GENERATED CODE. DO NOT MODIFY. Generated by AddNamesGenerator.

 // Header specified in build.yaml.
 final name0 = ['Philip', 'Martens'];
 final name1 = ['Thomas', 'Mayor'];

 final List<List<String>> names = [
     ['Philip', 'Martens'],
     ['Thomas', 'Mayor'],
 ];

 // Footer specified in build.yaml.
 ```

</details>

## Implementation Details

The classes [`MergingBuilder<T, S extends SyntheticInput>`][class-merging-builder]
and [`StandaloneBuilder<S extends SyntheticInput>`][class-standalone-builder]
use *synthetic input* which must be specified
by choosing either [`LibDir`][LibDir] or [`PackageDir`][PackageDir] as type parameter `S`.

[`LibDir`][LibDir] indicates that input and output files are located in the package directory `lib` or a subfolder thereof. For more information
about *synthetic input* see:
[Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).

### Class - Merging Builder

[`MergingBuilder`][MergingBuilder] reads **several input files** and writes merged output to **one output file**.
The builder provides the option to sort the input files in reverse topological order. If the input file `a.dart` includes file `b.dart` then `a.dart` will be listed *after* `b.dart`. This option may be useful when
generating code that needs to list variables or call functions in order of dependence. To enable topological sorting set the constructor parameter `sortAsset: true`. Note: If sorting of input assets is enabled, input files must not include each other directly or indirectly.

A conventional builder typically calls the generator method `generate` from within its `build` method to retrieve the generated source-code. [`MergingBuilder`][MergingBuilder] calls the [`MergingGenerator`][MergingGenerator] method `generateStream`. It allows the generator to pass a stream of data-type `T` to the builder, one stream item for each annotated element processed to the generator method `generateStreamItemForAnnotatedElement`.

The private builder method `_combineStreams` combines the streams received for each processed input file and calls the generator method `generateMergedContent`. As a result, this method has access to all stream items of type `T` generated for each annotated element in each input file. It is the task of this method to generate the merged source-code output.

The figure below shows the flow of data between the builder and the generator. The data type is indicated by the starting point of the connectors. Dotted connectors represent a stream of data.


![Directed Graph Image](https://raw.githubusercontent.com/simphotonics/merging_builder/master/images/merging_builder.svg?sanitize=true)

### Class - Standalone Builder

[`StandaloneBuilder`][StandaloneBuilder] reads one or several input files and writes standalone files to a custom location.
*Standalone* means the output files may be written to a custom folder and not only the extension but the
name of the output file can be configured.

The input file path (constructor parameter `inputFiles`) may include
wild-card notation supported by [`Glob`][Glob].

Output files are specified by using the custom symbol
`(*)`. For example, the output path `output\assistant_(*).dart` is interpreted such that `(*)` is replaced with the input file name (excluding the file extension). For more details, see the file [`example\researcher_builder\builder.dart`][builder.dart].

Limitations: For builders extending [`StandaloneBuilder`][StandaloneBuilder] it is recommended to initiate the build command (see point 7 in the next section) from the root directory of the package the build is applied to.
## Examples

For further information on how to use [`MergingBuilder`][MergingBuilder] see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/merging_builder/issues

[analyzer]: https://pub.dev/packages/analyzer

[build]: https://pub.dev/packages/build

[build_runner]: https://pub.dev/packages/build_runner

[builder.dart]: https://github.com/simphotonics/merging_builder_example/blob/researcher_builder/lib/builder.dart

[Elements]: https://pub.dev/documentation/analyzer/latest/dart_element_element/dart_element_element-library.html

[computeConstantValue()]: https://pub.dev/documentation/analyzer/latest/dart_element_element/VariableElement/computeConstantValue.html

[ConstantReader]: https://pub.dev/documentation/source_gen/latest/source_gen/ConstantReader-class.html

[class-merging-builder]: https://github.com/simphotonics/merging_builder#class-merging-builder

[class-standalone-builder]: https://github.com/simphotonics/merging_builder#class-standalone-builder

[example]: https://github.com/simphotonics/merging_builder_example

[DartObject]: https://pub.dev/documentation/analyzer/latest/dart_constant_value/DartObject-class.html

[Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html

[GeneratorForAnnotation]: https://pub.dev/documentation/source_gen/latest/source_gen/GeneratorForAnnotation-class.html

[Glob]: https://pub.dev/packages/glob

[LibDir]: https://pub.dev/documentation/merging_builder/latest/merging_builder/LibDir-class.html

[MergingBuilder]: https://pub.dev/documentation/merging_builder/latest/merging_builder/MergingBuilder-class.html

[merging_builder]: https://pub.dev/packages/merging_builder

[MergingGenerator]: https://pub.dev/documentation/merging_builder/latest/merging_builder/MergingGenerator-class.html

[PackageDir]: https://pub.dev/documentation/merging_builder/latest/merging_builder/PackageDir-class.html

[researchers.dart]: https://github.com/simphotonics/merging_builder_example/blob/main/researcher/lib/output/researchers.dart

[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test

[StandaloneBuilder]: https://pub.dev/documentation/merging_builder/latest/merging_builder/StandaloneBuilder-class.html

[Writing a Builder using a synthetic input]: https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input
