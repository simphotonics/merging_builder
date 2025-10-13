import 'package:exception_templates/exception_templates.dart' show ErrorOf;

/// Enumeration with instances [lib] and [package], representing the
/// `lib` directory, and the root directory, respectively.
enum BuildLocation {
  /// Synthetic input representing files under the `lib` directory.
  lib(baseDirectory: 'lib', value: r'lib/$lib$'),

  /// Synthetic input representing files under the `root` directory.
  package(baseDirectory: '', value: r'$package$');

  const BuildLocation({required this.baseDirectory, required this.value});

  final String baseDirectory;

  final String value;

  bool isValidPath(String path) => switch (this) {
    lib when path.substring(0, 3) != 'lib' => false,
    _ => true,
  };

  void validatePath(String path) {
    if (isValidPath(path)) {
      return;
    } else {
      throw ErrorOf<BuildLocation>(
        message: 'Invalid file path found.',
        expectedState:
            'A path starting with \'lib\'.'
            'To access files outside \'lib\' change the builder '
            'parameter <syntheticInput> to <SyntheticInput.package>.',
        invalidState: 'The invalid path is: $path.',
      );
    }
  }
}
