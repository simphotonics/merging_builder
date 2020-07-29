import 'package:exception_templates/exception_templates.dart';
import 'package:meta/meta.dart';

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

  /// Returns an instance of [LibDir] or [PackageDir].
  static T instance<T extends SyntheticInput>() {
    return (T == LibDir) ? LibDir() : PackageDir();
  }

  /// Returns `true` if [path] is a valid input or output path.
  ///
  /// Note: Synthetic input [LibDir] supports only input/output files located
  /// below the package directory `lib`.
  static bool isValidPath<T extends SyntheticInput>(String path) {
    if (T == LibDir && path.substring(0, 'lib'.length) != 'lib') {
      return false;
    } else {
      return true;
    }
  }

  /// Validates an input/output path.
  ///
  /// Throws [ErrorOf] if the synthetic input is specified as
  /// usign the type parameter [LibDir]) and the path does not start with `lib`.
  static void validatePath<T extends SyntheticInput>(String path) {
    if (!SyntheticInput.isValidPath<T>(path)) {
      throw ErrorOf<SyntheticInput>(
          message: 'Invalid file path found.',
          expectedState: 'A path starting with \'lib\'.'
              'To access files outside \'lib\' change the builder '
              'type parameter to [PackageDir].',
          invalidState: 'The actual path is: $path.');
    }
  }
}

/// Synthetic input representing files under the `lib` directory.
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
@sealed
class LibDir extends SyntheticInput {
  const LibDir._(String value) : super._(value);

  static LibDir _instance;

  factory LibDir() {
    return _instance ??= LibDir._(r'lib/$lib$');
  }

  @override
  String get baseDirectory => 'lib';
}

/// Synthetic input representing files under the `root` directory.
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
@sealed
class PackageDir extends SyntheticInput {
  const PackageDir._(String value) : super._(value);

  static PackageDir _instance;

  factory PackageDir() {
    return _instance ??= PackageDir._(r'$package$');
  }

  @override
  String get baseDirectory => '';
}
