import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders normal text mixed with inline `$...$` and block `$$...$$` LaTeX.
///
/// Arabic prose inside `\\text{...}` is rendered with Flutter text instead of
/// the math font because math fonts do not shape Arabic letters correctly.
class RichMathText extends StatelessWidget {
  final String text;
  final bool? isArabic;
  final bool inline;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final bool assumeMath;

  const RichMathText({
    super.key,
    required this.text,
    this.isArabic,
    this.inline = false,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.assumeMath = false,
  });

  static final RegExp _latexPattern =
      RegExp(r'(\$\$[\s\S]+?\$\$|\$[^\n$]+?\$)');
  static final RegExp _arabicPattern = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _textCommandPattern = RegExp(r'\\text\s*\{([^{}]*)\}');
  static final RegExp _arabicRunPattern = RegExp(
    r'[\u0600-\u06FF]+(?:[\u0600-\u06FF\s،؛؟!.]*[\u0600-\u06FF]+)?',
  );
  static final RegExp _pureTextCommandPattern =
      RegExp(r'^\s*\\text\s*\{([^{}]*)\}\s*$');

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeInput(text.trim());
    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    final usesArabic = isArabic ?? _arabicPattern.hasMatch(normalized);
    final baseStyle =
        style ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final direction = usesArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final alignment =
        textAlign ?? (usesArabic ? TextAlign.right : TextAlign.left);
    final tokens = _tokenize(normalized);

    // Use Flutter's native Text widget for prose-only content. This keeps
    // Arabic shaping, accessibility semantics, selection, and widget tests
    // predictable instead of routing normal prose through a math renderer.
    if (tokens.length == 1 && tokens.first.type == _MathTokenType.text) {
      return Directionality(
        textDirection: direction,
        child: Text(
          tokens.first.value,
          textAlign: alignment,
          maxLines: maxLines,
          overflow: overflow,
          style: baseStyle,
        ),
      );
    }

    final containsBlock =
        tokens.any((token) => token.type == _MathTokenType.blockMath);

    if (inline || !containsBlock) {
      return Directionality(
        textDirection: direction,
        child: RichText(
          textAlign: alignment,
          maxLines: maxLines,
          overflow: overflow,
          text: TextSpan(
            style: baseStyle,
            children: tokens
                .map((token) => _inlineSpan(context, token, baseStyle))
                .toList(),
          ),
        ),
      );
    }

    final sections = <Widget>[];
    final buffer = <_MathToken>[];

    void flushBuffer() {
      if (buffer.isEmpty) {
        return;
      }
      sections.add(
        RichText(
          textAlign: alignment,
          text: TextSpan(
            style: baseStyle,
            children: buffer
                .map((token) => _inlineSpan(context, token, baseStyle))
                .toList(),
          ),
        ),
      );
      buffer.clear();
    }

    for (final token in tokens) {
      if (token.type == _MathTokenType.blockMath) {
        flushBuffer();
        sections.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _mathWidget(
                  context,
                  token.value,
                  MathStyle.display,
                  baseStyle.copyWith(
                    fontSize: (baseStyle.fontSize ?? 16) + 3,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        buffer.add(token);
      }
    }
    flushBuffer();

    return Directionality(
      textDirection: direction,
      child: Column(
        crossAxisAlignment:
            usesArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  InlineSpan _inlineSpan(
    BuildContext context,
    _MathToken token,
    TextStyle baseStyle,
  ) {
    if (token.type == _MathTokenType.text) {
      return TextSpan(text: token.value, style: baseStyle);
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: _mathWidget(
          context,
          token.value,
          token.type == _MathTokenType.blockMath
              ? MathStyle.display
              : MathStyle.text,
          baseStyle,
        ),
      ),
    );
  }

  Widget _mathWidget(
    BuildContext context,
    String latex,
    MathStyle mathStyle,
    TextStyle textStyle,
  ) {
    final pureText = _pureTextCommandPattern.firstMatch(latex);
    if (pureText != null) {
      final value = pureText.group(1)?.trim() ?? '';
      if (_arabicPattern.hasMatch(value)) {
        return Text(
          value,
          textDirection: ui.TextDirection.rtl,
          textAlign: TextAlign.right,
          style: textStyle,
        );
      }
    }

    if (_arabicPattern.hasMatch(latex)) {
      return _mixedArabicMathWidget(
        context,
        latex,
        mathStyle,
        textStyle,
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Math.tex(
        latex,
        mathStyle: mathStyle,
        textStyle: textStyle,
        onErrorFallback: (_) => Text(
          latex,
          textDirection: _arabicPattern.hasMatch(latex)
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          style: textStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _mixedArabicMathWidget(
    BuildContext context,
    String latex,
    MathStyle mathStyle,
    TextStyle textStyle,
  ) {
    final segments = <_ArabicMathSegment>[];
    final commandMatches = _textCommandPattern
        .allMatches(latex)
        .where((match) => _arabicPattern.hasMatch(match.group(1) ?? ''))
        .toList();

    for (final match in commandMatches) {
      segments.add(
        _ArabicMathSegment(
          start: match.start,
          end: match.end,
          text: match.group(1)?.trim() ?? '',
        ),
      );
    }

    for (final match in _arabicRunPattern.allMatches(latex)) {
      final overlapsCommand = commandMatches.any(
        (command) => match.start < command.end && match.end > command.start,
      );
      if (!overlapsCommand) {
        segments.add(
          _ArabicMathSegment(
            start: match.start,
            end: match.end,
            text: match.group(0)?.trim() ?? '',
          ),
        );
      }
    }

    segments.sort((first, second) => first.start.compareTo(second.start));
    if (segments.isEmpty) {
      return Text(
        latex,
        textDirection: ui.TextDirection.rtl,
        style: textStyle,
      );
    }

    final children = <Widget>[];
    var cursor = 0;

    void addMathPart(String value) {
      final mathPart = value.trim();
      if (mathPart.isEmpty) {
        return;
      }
      children.add(
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Math.tex(
            mathPart,
            mathStyle: mathStyle,
            textStyle: textStyle,
            onErrorFallback: (_) => Text(
              mathPart,
              textDirection: ui.TextDirection.ltr,
              style: textStyle,
            ),
          ),
        ),
      );
    }

    for (final segment in segments) {
      if (segment.start < cursor) {
        continue;
      }
      if (segment.start > cursor) {
        addMathPart(latex.substring(cursor, segment.start));
      }
      if (segment.text.isNotEmpty) {
        children.add(
          Text(
            segment.text,
            textDirection: ui.TextDirection.rtl,
            style: textStyle,
          ),
        );
      }
      cursor = segment.end;
    }

    if (cursor < latex.length) {
      addMathPart(latex.substring(cursor));
    }

    return Wrap(
      spacing: 3,
      runSpacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  String _normalizeInput(String input) {
    if (input.isEmpty) {
      return input;
    }

    final pureProse = _extractPureArabicProse(input);
    if (pureProse != null) {
      return pureProse;
    }

    if (input.contains(r'$')) {
      return input;
    }

    if (assumeMath) {
      return r'$' + input + r'$';
    }

    final hasLatexCommand = RegExp(
      r'\\(frac|sqrt|text|cdot|times|div|pm|leq|geq|neq|alpha|beta|theta|pi|sin|cos|tan|log|ln|sum|int|lim|left|right|begin|end)\b',
    ).hasMatch(input);
    final hasArabicProse = _arabicPattern.hasMatch(input);
    final hasMathSyntax = RegExp(
      r'[A-Za-z0-9)]\s*(?:\^|_|=|\+|-|\*|/|<|>)|(?:\^|_|=|\+|\*|/|<|>)\s*[A-Za-z0-9(]',
    ).hasMatch(input);

    if (!hasArabicProse && (hasLatexCommand || hasMathSyntax)) {
      return r'$' + input + r'$';
    }

    return input;
  }

  String? _extractPureArabicProse(String input) {
    var value = input.trim();
    var hadMathDelimiters = false;
    if (value.startsWith(r'$$') && value.endsWith(r'$$') && value.length >= 4) {
      value = value.substring(2, value.length - 2).trim();
      hadMathDelimiters = true;
    } else if (value.startsWith(r'$') &&
        value.endsWith(r'$') &&
        value.length >= 2) {
      value = value.substring(1, value.length - 1).trim();
      hadMathDelimiters = true;
    }

    final commandMatch = _pureTextCommandPattern.firstMatch(value);
    final commandContent = commandMatch?.group(1)?.trim();
    if (commandContent != null && _arabicPattern.hasMatch(commandContent)) {
      return commandContent;
    }

    if (!hadMathDelimiters || !_arabicPattern.hasMatch(value)) {
      return null;
    }

    // Content authors sometimes wrap a prose-only Arabic option in `$...$`.
    // Rendering that through a math font breaks Arabic shaping, so unwrap it
    // only when it contains no actual mathematical syntax.
    final hasMathSyntax = RegExp(
      r'[\\^_{}=+*/<>]|\\[A-Za-z]+|[A-Za-z0-9]',
    ).hasMatch(value);
    return hasMathSyntax ? null : value;
  }

  List<_MathToken> _tokenize(String input) {
    final tokens = <_MathToken>[];
    var cursor = 0;
    for (final match in _latexPattern.allMatches(input)) {
      if (match.start > cursor) {
        tokens.add(
          _MathToken(
            _MathTokenType.text,
            input.substring(cursor, match.start),
          ),
        );
      }
      final raw = match.group(0)!;
      if (raw.startsWith(r'$$') && raw.endsWith(r'$$')) {
        tokens.add(
          _MathToken(
            _MathTokenType.blockMath,
            raw.substring(2, raw.length - 2).trim(),
          ),
        );
      } else {
        tokens.add(
          _MathToken(
            _MathTokenType.inlineMath,
            raw.substring(1, raw.length - 1).trim(),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < input.length) {
      tokens.add(
        _MathToken(_MathTokenType.text, input.substring(cursor)),
      );
    }
    if (tokens.isEmpty) {
      tokens.add(_MathToken(_MathTokenType.text, input));
    }
    return tokens;
  }
}

enum _MathTokenType { text, inlineMath, blockMath }

class _ArabicMathSegment {
  final int start;
  final int end;
  final String text;

  const _ArabicMathSegment({
    required this.start,
    required this.end,
    required this.text,
  });
}

class _MathToken {
  final _MathTokenType type;
  final String value;

  const _MathToken(this.type, this.value);
}
