import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders normal text mixed with inline `$...$` and block `$$...$$` LaTeX.
class RichMathText extends StatelessWidget {
  final String text;
  final bool? isArabic;
  final bool inline;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  const RichMathText({
    super.key,
    required this.text,
    this.isArabic,
    this.inline = false,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });
  static final RegExp _latexPattern =
      RegExp(r'(\$\$[\s\S]+?\$\$|\$[^\n$]+?\$)');
  static final RegExp _arabicPattern = RegExp(r'[\u0600-\u06FF]');
  @override
  Widget build(BuildContext context) {
    final normalized = text.trim();
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
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
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
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
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
      ),
    );
  }

  Widget _mathWidget(
    BuildContext context,
    String latex,
    MathStyle mathStyle,
    TextStyle textStyle,
  ) {
    return Math.tex(
      latex,
      mathStyle: mathStyle,
      textStyle: textStyle,
      onErrorFallback: (_) => Text(
        'latex_render_error'.tr(),
        style: textStyle.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
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

class _MathToken {
  final _MathTokenType type;
  final String value;
  const _MathToken(this.type, this.value);
}
