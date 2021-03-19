import 'package:build/build.dart';

import 'package:researcher_builder/builder.dart';

/// Checking if the buildExtensions are resolved correctly.
/// To run the program use: dart bin/main.dart
/// from the root directory of `researcher`.
void main(List<String> args) {
  //final AssetId asset = AssetId('researcher', 'lib/input/researcher_a.dart');
  final map = <String, dynamic>{};
  final options = BuilderOptions(map);

  final _addNamesBuilder = addNamesBuilder(options);
  final _assistantBuilder = assistantBuilder(options);

  print('AddNamesBuilder: buildExtensions');
  print(_addNamesBuilder.buildExtensions);
  print('');
  print('AssistantBuilder: buildExtensions');
  print(_assistantBuilder.buildExtensions);
}
