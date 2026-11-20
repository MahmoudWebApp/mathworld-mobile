import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The same sixteen SVG assets are versioned in MathWorld Web and Flutter.
/// A later admin upload replaces the mw: key with the uploaded image URL.
class CategoryBrandIcon extends StatelessWidget {
  final String? icon;
  final double size;
  const CategoryBrandIcon({super.key, this.icon, this.size = 38});

  static const _keys = <String>{
    'arithmetic','algebra','geometry','statistics','exponents','functions',
    'proportions','proofs','equations','trigonometry','calculus','probability',
    'multivariable','matrices','differential','analysis',
  };

  @override
  Widget build(BuildContext context) {
    final value = icon?.trim() ?? '';
    if (value.startsWith('mw:')) {
      final key = value.substring(3);
      if (_keys.contains(key)) {
        return SvgPicture.asset(
          'assets/category_icons/mathworld-$key.svg',
          width: size, height: size, fit: BoxFit.contain,
        );
      }
    }
    if (value.startsWith('https://')) {
      return Image.network(value, width: size, height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(Icons.functions_rounded,
          size: size * 0.75, color: Theme.of(context).colorScheme.primary));
    }
    if (value.isNotEmpty && value.runes.length <= 4 &&
        !value.contains('/') && !value.contains('\\')) {
      return Text(value, style: TextStyle(fontSize: size * 0.6));
    }
    return Icon(Icons.functions_rounded, size: size * 0.75,
      color: Theme.of(context).colorScheme.primary);
  }
}
