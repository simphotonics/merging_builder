import 'package:meta/meta.dart';

import '../errors/builder_error.dart';

/// Base class representing synthetic builder input.
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
abstract class SyntheticInput {
  const SyntheticInput._(this.value);

  /// String value.
  final String value;

  /// Returns the base directory.
  String get baseDirectory;

  @override
  String toString() => value;

  /// Returns an instance of [$Lib$] or [$Package$].
  ///
  /// Note: Returns [null] is T does not extend [Synthetic].
  static SyntheticInput instance<T extends SyntheticInput>() {
    return (T == $Lib$) ? $Lib$() : $Package$();
  }

  /// Returns [true] if [path] is a valid input or output path.
  ///
  /// Note: Synthetic input [$Lib$] supports only input/output files located
  /// below the package directory `lib`.
  static bool isValidPath<T extends SyntheticInput>(String path) {
    if (T == $Lib$ && path.substring(0, 'lib'.length) != 'lib') {
      return false;
    } else {
      return true;
    }
  }

  /// Validates an input/output path.
  ///
  /// Throws [BuilderError] if the synthetic input is `r\lib/$lib$'\'`
  /// (type parameter is [$Lib$]) and the path does not start with `lib`.
  static void validatePath<T extends SyntheticInput>(String path) {
    if (!SyntheticInput.isValidPath<T>(path)) {
      throw BuilderError(
          message: 'Invalid file path found.',
          expectedState: 'A path starting with \'lib\'.'
              'To access files outside \'lib\' change the builder type parameter to [Package].',
          invalidState: 'The actual path is: $path.');
    }
  }
}

/// Synthetic input representing files under the [lib] directory.
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
@sealed
class $Lib$ extends SyntheticInput {
  const $Lib$._(String value) : super._(value);

  static $Lib$ _instance;

  factory $Lib$() {
    return _instance ??= $Lib$._(r'lib/$lib$');
  }

  @override
  String get baseDirectory => 'lib';
}

/// Synthetic input representing files under the [root] directory.
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
@sealed
class $Package$ extends SyntheticInput {
  const $Package$._(String value) : super._(value);

  static $Package$ _instance;

  factory $Package$() {
    return _instance ??= $Package$._(r'$package$');
  }

  @override
  String get baseDirectory => '';
}
