import 'package:exception_templates/exception_templates.dart' show ErrorOf;

/// Enumeration with instances [lib] and [package], representing the
/// `lib` directory, and the root directory, respectively.
enum BuildLocation({
  required final String baseDirectory,
  required final String value,
}) {
  /// Synthetic input representing files under the `lib` directory.
  lib(baseDirectory: 'lib', value: r'lib/$lib$'),

  /// Synthetic input representing files under the `root` directory.
  package(baseDirectory: '', value: r'$package$');

  //new({required this.baseDirectory, required this.value});

  /// Returns `false` if the build location
  /// is [BuildLocation.lib] and the path does start with `lib`.
  /// Returns `true` otherwise.
  bool isValidPath(String path) => switch (this) {
    lib when path.substring(0, 3) != 'lib' => false,
    _ => true,
  };

  /// Throws an [ErrorOf] with type argument [BuildLocation]
  /// if the build location is
  /// [BuildLocation.lib] and the path does not start
  /// with `lib`.
  void validatePath(String path) {
    if (isValidPath(path)) {
      return;
    } else {
      throw ErrorOf<BuildLocation>(
        message: 'Invalid file path found.',
        expectedState:
            'A path starting with \'lib\'.'
            'To access files outside \'lib\' '
            'use the build location: "BuildLocation.package".',
        invalidState: 'The invalid path is: $path.',
      );
    }
  }
}
