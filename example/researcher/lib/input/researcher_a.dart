
import 'package:merging_builder/src/annotations/add_integers.dart';
import 'package:merging_builder/src/annotations/add_names.dart';
import 'package:merging_builder/src/annotations/add_numbers.dart';

/// Const class for testing purposes.
@AddNames()
@AddNumbers()
@AddIntegers()
class ResearcherA {
  const ResearcherA();

  final List<String> names = const ['Thomas', 'Mayor'];

  final List<int> integers = const [47, 91];

  final num number = 19;

  final String title = 'ResearcherA';
}
