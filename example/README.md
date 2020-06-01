# Merging Builder - Example

## Introduction

The library [merging_builder] provides a Dart builder that reads **several input files** and writes the merged output to **one output file**.

The example presented in this folder contains two packages. The package [researcher_builder] depends on [merging_builder] in order to define the builder [add_names_builder] and the merging generator [add_names_generator].

The package [researcher] depends on [researcher_builder], specified as a *dev_dependency*, in order to access the builder [add_names_builder] during the build process.

## Build Setup

Step by step instructions on how to set up and configure a [merging_builder] are provided in here.


## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[builder]: https://github.com/dart-lang/build
[researcher_builder]:
[add_names_builder]:
[researcher]:

[issue tracker]: https://github.com/simphotonics/directed_graph/issues

[initializeLibraryReaderForDirectory]: https://pub.dev/documentation/source_gen_test/latest/source_gen_test/initializeLibraryReaderForDirectory.html

[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html

[directed_graph]: https://github.com/simphotonics/directed_graph/

[source_gen]: https://pub.dev/packages/source_gen
[source_gen_test]: https://pub.dev/packages/source_gen_test

[SqliteType]: https://github.com/simphotonics/generic_reader/blob/master/lib/src/test_types/sqlite_type.dart

[merging_builder]: https://pub.dev/packages/merging_builder
