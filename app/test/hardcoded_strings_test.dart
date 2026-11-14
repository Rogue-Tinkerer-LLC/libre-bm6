import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A string literal where a user-visible string goes: a `Text` widget's
/// first argument, or a named argument that is shown or read aloud. The
/// whitespace between the opening token and the literal may span lines,
/// which is how `dart format` wraps a long literal.
final _literal = RegExp(
  r'''\b(?:Text|SelectableText)\(\s*r?['"]|'''
  r'''\b(?:text|tooltip|label|labelText|hintText|helperText|semanticLabel|'''
  r'''semanticsLabel|title|message|applicationName|content)\s*:\s*r?['"]''',
);

List<String> findLiterals(String source) => [
  for (final match in _literal.allMatches(source))
    '${_lineOf(source, match.start)}: ${_firstLine(match.group(0)!)}',
];

int _lineOf(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

String _firstLine(String text) => text.split('\n').first.trim();

void main() {
  test('the scan catches hard-coded strings', () {
    expect(findLiterals("Text('Hello')"), hasLength(1));
    expect(findLiterals('Tooltip(message: "Hi")'), hasLength(1));
    expect(findLiterals('Text(l.devicesTitle)'), isEmpty);
    expect(findLiterals("Text(\n  'A long sentence',\n)"), hasLength(1));
    expect(findLiterals("TextSpan(text: 'Hello')"), hasLength(1));
    expect(findLiterals("Foo(\n  label:\n    'Hi',\n)"), hasLength(1));
  });

  test('app/lib has no hard-coded user-visible strings', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('${Platform.pathSeparator}l10n')) continue;
      for (final hit in findLiterals(file.readAsStringSync())) {
        offenders.add('${file.path}:$hit');
      }
    }
    expect(offenders, isEmpty);
  });

  test('the support email address appears nowhere in the app', () {
    final address = RegExp(r'[\w.+-]+@roguetinkerer\.com');
    final hits = [
      for (final dir in ['lib', 'test', 'android/app/src'])
        for (final file in Directory(dir).listSync(recursive: true))
          if (file is File &&
              RegExp(r'\.(dart|arb|xml|kt|kts)$').hasMatch(file.path) &&
              address.hasMatch(file.readAsStringSync()))
            file.path,
    ];
    expect(hits, isEmpty);
  });
}
