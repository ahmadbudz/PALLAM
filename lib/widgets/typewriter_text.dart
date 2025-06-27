// lib/widgets/typewriter_text.dart

import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final VoidCallback? onComplete;      // 1) add this

  const TypewriterText({
    Key? key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 50),
    this.onComplete,                   // 2) expose it
  }) : super(key: key);

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayed = '';
  late Timer _timer;
  int _pos = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.charDelay, (t) {
      if (_pos < widget.text.length) {
        setState(() => _displayed += widget.text[_pos++]);
      } else {
        t.cancel();
        widget.onComplete?.call();     // 3) trigger your callback here
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed, style: widget.style);
  }
}
