import 'package:flutter/material.dart';

/// Same small icon + actual API result count used in the web learner dashboard.
/// Does not infer zero during loading; parent calls this only with loaded data.
class CompactProblemCount extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color accent;

  const CompactProblemCount({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900, color: accent)),
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
