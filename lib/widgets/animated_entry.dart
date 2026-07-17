import 'dart:async';
import 'package:flutter/material.dart';

/// Creates a delayed staggered fade and slide entrance animation.
class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Offset beginOffset;
  const AnimatedEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.beginOffset = const Offset(0, 0.08),
  });
  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  Timer? _delayTimer;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disabled) {
      _controller.value = 1;
      return;
    }
    _delayTimer = Timer(Duration(milliseconds: widget.index * 70), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              widget.beginOffset.dx * 80 * (1 - value),
              widget.beginOffset.dy * 80 * (1 - value),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
