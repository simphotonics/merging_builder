# Merging Builder - Test
[![Build Status](https://travis-ci.com/simphotonics/merging_builder.svg?branch=master)](https://travis-ci.com/simphotonics/merging_builder)

## Introduction

The library [merging_builder] provides a Dart builder that reads **several input files** and writes the merged output to **one output file**.

This part of the library contains tests designed to verify
that [merging_builder] behaves as expected.

The folder [src](src) contains sample input classes, generators, and a mock-merging-builder defined for testing purposes. The content of the input files is accessed via a [LibraryReader].


## Running the tests

The tests may be run in a terminal by navigating to the base folder of a local copy of the library and using the command:
```Shell
$ pub run test -r expanded --test-randomize-ordering-seed=random
```

## Features and bugs
Please file feature requests and bugs at the [issue tracker].

[issue tracker]: https://github.com/simphotonics/generic_reader/issues

[merging_builder]: https://pub.dev/packages/merging_builder
[LibraryReader]: https://pub.dev/documentation/source_gen/latest/source_gen/LibraryReader-class.html
