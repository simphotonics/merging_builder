
# Merging Builder


## Introduction

Source code generation has become an integral software development tool when building and maintaining a large number of data models, data access object, widgets, etc. Setting up the build system initially takes time and effort but
subsequent maintenance is often easier, less error prone, and certainly less
repetitive compared to applying manual modifications.

The library [merging_builder] provides a Dart builder that reads **several input files** and writes the merged output to **one output file**. The builder has support for specifying a header and footer to be placed at the very top and the very bottom of the output file.


## Usage

To set up a build system using this library the following steps are required:

1. Include [merging_builder], and [source_gen] as *dependencies* in the file `pubspec.yaml` of the package **containing** the builder. In our example this package is called `sqlite_builder`.

2. Create an instance of [MergingBuilder]. Following the example of [source_gen], builders are typically placed in a file called: `builders.dart` located in the `lib` folder of the builder package.

   <details> <summary> Show details. </summary>

    ```Dart
       import 'package:build/build.dart';
       import 'package:source_gen/source_gen.dart';
       import 'package:merging_builder/merging_builder.dart';

      Builder sqliteInitBuilder(BuilderOptions options) => MergingBuilder(
          generator: SqliteInitGenerator(),
          inputFiles: 'lib/*.dart',
          outputFile: 'lib/init.dart',
          header: SqliteInitGenerator.header,
          footer: SqliteInitGenerator.footer,
        );
    ```

   </details>


3. Add the builder configuration to `build.yaml`, a file located in the top folder of the package **containing** the builder (along with `lib` and `pubspec.yaml`).
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

4. In the package **using** the builder add `sqlite_init_builder` to the list of known builders. The file `build.yaml` is shown below.

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

5. Add the package **containing** the builder, in this example `sqlite_builder`, as a dev_dependency to the file `pubspec.yaml` of the package **using** the builder (called
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

6. Initiate the build process by using the command:
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
