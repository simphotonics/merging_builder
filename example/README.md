# Merging Builder - Example

[![Dart](https://github.com/simphotonics/merging_builder/actions/workflows/dart.yml/badge.svg)](https://github.com/simphotonics/merging_builder/actions/workflows/dart.yml)


## Introduction

The library [`merging_builder`][merging_builder] includes the following
(synthetic input) builder classes:

* [`MergingBuilder`][MergingBuilder] reads *several input files*
and writes merged output to *one output file* to a custom location.

* [`StandaloneBuilder`][StandaloneBuilder] reads input files and
writes standalone files to a custom location. In this context, *standalone*
means the output files may be written to a *custom folder* and
not only the *extension* but the *name* of the output file can
be configured (as opposed to using part files).


## Build Setup

The project provided as an usage [example] contains two packages:
* The package [`researcher_builder`][researcher_builder] depends on
[`merging_builder`][merging_builder] in order to define the builder
[`add_names_builder`][add_names_builder] and the merging generator
[`add_names_generator`][add_names_generator].

* The package [`researcher`][researcher] depends on
[`researcher_builder`][researcher_builder], specified as a *dev_dependency*,
in order to access the builder [`add_names_builder`][add_names_builder]
 the build process.

Step by step instructions on how to set up and configure a
[`MergingBuilder`][MergingBuilder] are provided in
the section [usage].


## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[add_names_builder]: https://github.com/simphotonics/merging_builder_example/blob//researcher_builder/lib/builder.dart

[add_names_generator]: https://github.com/simphotonics/merging_builder_example/blob//researcher_builder/lib/generators/add_names_generator.dart

[builder]: https://github.com/dart-lang/build

[example]: https://github.com/simphotonics/merging_builder_example

[issue tracker]: https://github.com/simphotonics/merging_builder/issues

[merging_builder]: https://pub.dev/packages/merging_builder

[MergingBuilder]: https://pub.dev/documentation/merging_builder/latest/merging_builder/MergingBuilder-class.html

[researcher]: https://github.com/simphotonics/merging_builder_example/blob/researcher

[researcher_builder]: https://github.com/simphotonics/merging_builder_example/blob/researcher_builder

[StandaloneBuilder]: https://pub.dev/documentation/merging_builder/latest/merging_builder/StandaloneBuilder-class.html

[usage]: https://github.com/simphotonics/merging_builder#usage
