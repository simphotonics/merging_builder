/// Typedef of a function that can be provided to the [StandAloneBuilder]
/// constructor in the form of the parameter [formatOutput].
/// The function is used to format the output before it is
/// written to a stand-alone file.
typedef String Formatter(String input);