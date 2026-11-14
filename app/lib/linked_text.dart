import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

final _url = RegExp(r'https://\S+');
const _trailingPunctuation = '.,;:!?)"\'';

typedef TextRun = ({String text, bool link});

/// Splits [text] into plain and URL runs. Sentence punctuation right after a
/// URL stays in the plain run.
List<TextRun> splitLinks(String text) {
  final runs = <TextRun>[];
  var start = 0;
  for (final match in _url.allMatches(text)) {
    var end = match.end;
    while (end > match.start && _trailingPunctuation.contains(text[end - 1])) {
      end--;
    }
    if (match.start > start) {
      runs.add((text: text.substring(start, match.start), link: false));
    }
    runs.add((text: text.substring(match.start, end), link: true));
    start = end;
  }
  if (start < text.length) runs.add((text: text.substring(start), link: false));
  return runs;
}

/// Text whose URLs are underlined, tappable links.
class LinkedText extends StatefulWidget {
  const LinkedText(this.text, {super.key, required this.onOpen, this.style});

  final String text;
  final void Function(Uri uri) onOpen;
  final TextStyle? style;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  late List<TextRun> _runs;
  final _recognizers = <int, TapGestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    _split();
  }

  @override
  void didUpdateWidget(LinkedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _split();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _split() {
    _disposeRecognizers();
    _runs = splitLinks(widget.text);
    for (final (i, run) in _runs.indexed) {
      if (!run.link) continue;
      _recognizers[i] = TapGestureRecognizer()
        ..onTap = () => widget.onOpen(Uri.parse(run.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final (i, run) in _runs.indexed)
            TextSpan(
              text: run.text,
              recognizer: _recognizers[i],
              style: run.link
                  ? const TextStyle(decoration: TextDecoration.underline)
                  : null,
            ),
        ],
      ),
    );
  }
}
