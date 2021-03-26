/// Typedef of a function that can be provided to
/// [MergingBuilder] and [StandAloneBuilder]
/// constructors in the form of the parameter `formatter`.
/// * The function is used to format the builder output before it
/// is written to a file.
typedef Formatter = String Function(String input);
