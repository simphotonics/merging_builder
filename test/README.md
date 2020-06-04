# Merging Builder - Test
[![Build Status](https://travis-ci.com/simphotonics/merging_builder.svg?branch=master)](https://travis-ci.com/simphotonics/merging_builder)

## Introduction

The library [merging_builder] provides a Dart builder that reads **several input files** and writes the merged output to **one output file**.

This part of the library contains tests designed to verify
that [`MergingBuilder`][MergingBuilder] and [`MergingGenerator`][MergingGenerator] behave as expected.

The folder [src](src) contains sample input classes, generators, and a mock-merging-builder defined for testing purposes.

## Running the tests

The tests may be run in a terminal by navigating to the base folder of a local copy of the library and using the command:
```Console
$ pub run build_runner test -- -r expanded
```

## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[merging_builder]: https://pub.dev/packages/merging_builder
[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html
[MergingBuilder]: https://pub.dev/documentation/merging_builder/latest/merging_builder/MergingBuilder-class.html
[MergingGenerator]: https://pub.dev/documentation/merging_builder/latest/merging_builder/MergingGenerator-class.html
