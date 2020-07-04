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

  /// Returns an instance of [Lib] or [Package].
  ///
  /// Note: Returns [null] is T does not extend [Synthetic].
  static SyntheticInput instance<T extends SyntheticInput>() {
    if (T == Lib) return Lib();
    if (T == Package) return Package();
    return null;
  }
}

/// Synthetic input representing files under the [lib] directory.
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
@sealed
class Lib extends SyntheticInput {
  const Lib._(String value) : super._(value);

  static Lib _instance;

  factory Lib() {
    return _instance ?? Lib._(r'lib/$lib$');
  }

  @override
  String get baseDirectory => 'lib';
}

/// Synthetic input representing files under the [root] directory.
/// For more information about synthetic input see:
/// [Writing an Aggregate Builder](https://github.com/dart-lang/build/blob/master/docs/writing_an_aggregate_builder.md#writing-the-builder-using-a-synthetic-input).
@sealed
class Package extends SyntheticInput {
  const Package._(String value) : super._(value);

  static Package _instance;

  factory Package() {
    return _instance ?? Package._(r'$package$');
  }

  @override
  String get baseDirectory => '';
}
