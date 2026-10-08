/// Founder command parser — deterministic allowlist, never an LLM.
/// Owner actions must never depend on AI interpretation.
library;

class ParsedCommand {
  const ParsedCommand({
    required this.action,
    required this.args,
    required this.reply,
  });

  /// One of: run_vitals, toggle_flag, help, unknown.
  final String action;
  final Map<String, String> args;
  final String reply;
}

abstract final class FounderCommandParser {
  static ParsedCommand parse(String raw) {
    final String input = raw.trim().toLowerCase();
    if (input.isEmpty) {
      return const ParsedCommand(
          action: 'unknown', args: <String, String>{}, reply: 'Say a command, or "help".');
    }
    if (input == 'help' || input == 'commands') {
      return const ParsedCommand(
        action: 'help',
        args: <String, String>{},
        reply: 'Commands:\n'
            '• "run health check" — run all probes now\n'
            '• "toggle academy" — flip the Academy flag\n'
            '• "help" — this list',
      );
    }
    if (input == 'run health check' ||
        input == 'run vitals' ||
        input == 'check health' ||
        input == 'health') {
      return const ParsedCommand(
          action: 'run_vitals',
          args: <String, String>{},
          reply: 'Running all probes…');
    }
    final RegExp toggle = RegExp(r'^toggle (\w+)$');
    final RegExpMatch? m = toggle.firstMatch(input);
    if (m != null) {
      final String flag = m.group(1)!;
      if (flag == 'academy') {
        return ParsedCommand(
          action: 'toggle_flag',
          args: <String, String>{'flag': 'ar.flag.academy'},
          reply: 'Toggling Academy…',
        );
      }
      return ParsedCommand(
        action: 'unknown',
        args: <String, String>{},
        reply: 'Unknown flag "$flag". Known flags: academy.',
      );
    }
    return ParsedCommand(
      action: 'unknown',
      args: <String, String>{},
      reply: 'I only understand my command list — type "help". '
          'Anything else goes to your build engineer, not to me.',
    );
  }
}
