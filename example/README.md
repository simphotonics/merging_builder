# Merging Builder - Example
[![Build Status](https://travis-ci.com/simphotonics/merging_builder.svg?branch=master)](https://travis-ci.com/simphotonics/merging_builder)

## Introduction

The library [merging_builder] provides a Dart builder that reads **several input files** and writes the merged output to **one output file**.

The [example] presented in this folder contains two packages. The package [researcher_builder] depends on [merging_builder] in order to define the builder [add_names_builder] and the merging generator [add_names_generator].

The package [researcher] depends on [researcher_builder], specified as a *dev_dependency*, in order to access the builder [add_names_builder] during the build process.

## Build Setup

Step by step instructions on how to set up and configure a [merging_builder] are provided in
the section [usage].


## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[add_names_builder]: https://github.com/simphotonics/merging_builder/blob/master/example/researcher_builder/lib/builder.dart

[add_names_generator]: https://github.com/simphotonics/merging_builder/blob/master/example/researcher_builder/lib/generators/add_names_generator.dart

[builder]: https://github.com/dart-lang/build

[example]: /example

[issue tracker]: https://github.com/simphotonics/merging_builder/issues

[merging_builder]: https://pub.dev/packages/merging_builder

[researcher]: https://github.com/simphotonics/merging_builder/tree/master/example/researcher

[researcher_builder]: https://github.com/simphotonics/merging_builder/tree/master/example/researcher_builder

[usage]: https://github.com/simphotonics/merging_builder#usage
