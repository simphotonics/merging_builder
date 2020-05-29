
# Merging Builder


## Introduction

Source code generation has become an integral software development tool when building and maintaining a large number of data models, data access object, widgets, etc.

The library [merging_builder] provides a generic Dart builder that reads **several input files** and writes the merged output to **one output file**. The builder has support for specifying a header and footer to be placed at the top and bottom of the output file.


## Usage

The builder and generator classes provided by [merging_builder] are typically included in
a package that builds libraries in other packages.

To set up a build system the following steps are required:

1. Include [merging_builder], and [source_gen] as *dependencies* in the file `pubspec.yaml` of the package **defining** the builder. In our example this package is called `sqlite_builder`.

2. In the package **defining** the builder, create a custom generator that extends [MergingGenerator]. Note that [MergingGenerator] is a generic class with type parameters
`T` and `A`. `T` is arbitrary and can be a `String` or other objects that pass useful information to the function generating the merged content. The type parameter `A` represents an annotation used to annotate classes that are read during the build process.
   <details> <summary> Show details. </summary>

    ```Dart
    import 'dart:async';
    import 'package:analyzer/dart/element/element.dart';
    import 'package:build/src/builder/build_step.dart';
    import 'package:merging_builder/merging_builder.dart';
    import 'package:quote_buffer/quote_buffer.dart';
    import 'package:source_gen/source_gen.dart';
    import 'package:sqlite_builder/src/readers/reader.dart';
    import 'package:sqlite_builder/src/writers/sqlite_init_writer.dart';
    import 'package:sqlite_entity/sqlite_entity.dart';

    class SqliteInitGenerator extends MergingGenerator<String, GenerateSqliteInit> {
      /// Returns the Sqlite command that initializes the table specified by
      /// an object of type [TableDefinition] annotated with [GenerateSqliteInit].
      ///
      /// This fct is called for every class that is annotated with [GenerateSqliteInit].
      @override
      String generateStreamItemForAnnotatedElement(
        Element element,
        ConstantReader annotation,
        BuildStep buildStep,
      ) {
        final sqliteInitWriter = SqliteInitWriter(
          element: element,
          annotation: annotation,
          reader: reader,
        );
        return sqliteInitWriter.tableInitMapEntry;
      }

      /// Returns source code representing a variable of
      /// type [Map<String, String>].
      ///
      /// Called once before the builder writes the merged output.
      @override
      FutureOr<String> mergedContent(Stream<String> stream) async {
        final b = QuoteBuffer();
        b.writeln('library sqlite_init;');
        b.writeln('final init = Map<String, String>.unmodifiable({');
        // Iterate over stream:
        await for (var mapEntry in stream) {
          b.writeln(mapEntry);
        }
        b.writeln('});');
        return b.toString();
      }

      /// Portion of source code included at the top of the generated file.
      /// Should be specified as header when constructing the merging builder.
      static String get header {
        return '/// The header';
      }

      /// Portion of source code included at the very bottom of the generated file.
      /// Should be specified as [footer] when constructing the merging builder.
      static String get footer {
        return '/// This is the footer.';
      }
    }
    ```

   </details>

3. Create an instance of [MergingBuilder]. Following the example of [source_gen], builders are typically placed in a file called: `builders.dart` located in the `lib` folder of the builder package.

   <details> <summary> Show details. </summary>

    ```Dart
       import 'package:build/build.dart';
       import 'package:source_gen/source_gen.dart';
       import 'package:merging_builder/merging_builder.dart';

      Builder sqliteInitBuilder(BuilderOptions options) => MergingBuilder<String>(
          generator: SqliteInitGenerator(),
          inputFiles: 'lib/*.dart',
          outputFile: 'lib/init.dart',
          header: SqliteInitGenerator.header,
          footer: SqliteInitGenerator.footer,
        );
    ```

   </details>


4. Add the builder configuration to `build.yaml`, a file located in the top folder of the package **defining** the builder (along with `lib` and `pubspec.yaml`).
Note, that in this example the builder is called `sqlite_init_builder`.

   <details> <summary> Show details. </summary>

    ```Yaml
    builders:
      sqlite_init_builder:
        import: "package:sqlite_builder/builder.dart"
        builder_factories: ["sqliteInitBuilder"]
        build_extensions: {"$lib$": ["*.dart"]}
        auto_apply: root_package
        build_to: source
    ```

</details>

5. In the package **using** the builder add `sqlite_init_builder` to the list of known builders. The file `build.yaml` is shown below.

   <details> <summary> Show details. </summary>

    ```Yaml
    targets:
      $default:
        builders:
            sqlite_builder|sqlite_init_builder:
            enabled: true
            # generate_for:
            #   include:
            #     - lib/*.dart
            #   exclude:
            #     - lib/*.g.dart
    ```

   </details>

6. Add the package **defining** the builder, in this example `sqlite_builder`, as a dev_dependency to the file `pubspec.yaml` of the package **using** the builder (called
`sqlite_builder_example`.)

   <details> <summary> Show details. </summary>

    ```Yaml
    name: sqlite_builder_example
    description:
      Demonstrates how to define and build data model classes
      using the library sqlite_builder.

    version: 0.0.1

    environment:
      sdk: '>=2.6.0 <3.0.0'

    dependencies:
      directed_graph: ^0.1.2

    dev_dependencies:
      build_runner: ^1.9.0
      # The merging builder
      sqlite_builder:
        path: ../sqlite_builder
    ```

   </details>

7. Initiate the build process by using the command:
   ```console
   # pub run build_runner build --delete-conflicting-outputs --verbose
   ```

## Examples

For further information on how to use [MergingBuilder] see [example].

## Features and bugs

Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[example]: example

[Generator]: https://pub.dev/documentation/source_gen/latest/source_gen/Generator-class.html

[GeneratorForAnnotation]: https://pub.dev/documentation/source_gen/latest/source_gen/GeneratorForAnnotation-class.html

[MergingBuilder]: https://pub.dev/packages/merging_builder

[merging_builder]: https://pub.dev/packages/merging_builder


[source_gen]: https://pub.dev/packages/source_gen

[source_gen_test]: https://pub.dev/packages/source_gen_test
