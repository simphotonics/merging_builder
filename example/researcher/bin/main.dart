import 'package:build/build.dart';

import 'package:researcher_builder/builder.dart';

/// Checking if the buildExtensions are resolved correctly.
/// To run the program use: dart bin/main.dart
/// from the root directory of `researcher`.
void main(List<String> args) {
  //final AssetId asset = AssetId('researcher', 'lib/input/researcher_a.dart');
  final map = <String, dynamic>{};
  final options = BuilderOptions(map);

  final addNamesBuilderVar = addNamesBuilder(options);
  final assistantBuilderVar = assistantBuilder(options);

  print('AddNamesBuilder: buildExtensions');
  print(addNamesBuilderVar.buildExtensions);
  print('');
  print('AssistantBuilder: buildExtensions');
  print(assistantBuilderVar.buildExtensions);
}
