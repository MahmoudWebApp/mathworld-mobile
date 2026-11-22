import 'package:flutter/material.dart';

import '../config/app_routes.dart';

import '../services/premium_api_service.dart';
import '../models/problem.dart';
import 'rich_math_text.dart';

/// Drop-in student action for problem details. The server enforces Premium
/// access; hiding this button is only a presentation decision.
class PremiumSolutionPanel extends StatefulWidget {
  const PremiumSolutionPanel({
    super.key,
    required this.problemId,
    required this.service,
    required this.isArabic,
    this.options = const [],
  });

  final int problemId;
  final PremiumApiService service;
  final bool isArabic;
  final List<Option> options;

  @override
  State<PremiumSolutionPanel> createState() => _PremiumSolutionPanelState();
}

class _PremiumSolutionPanelState extends State<PremiumSolutionPanel> {
  late Future<StudentEntitlement> _entitlement;
  PremiumSolution? _solution;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entitlement = widget.service.getEntitlement();
  }

  @override
  void didUpdateWidget(covariant PremiumSolutionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.problemId != widget.problemId ||
        oldWidget.service != widget.service) {
      _solution = null;
      _error = null;
      _loading = false;
      _entitlement = widget.service.getEntitlement();
    }
  }

  Future<void> _reveal() async {
    if (_loading || widget.problemId <= 0) return;
    final requestedId = widget.problemId;
    setState(() {
      _loading = true;
      _error = null;
      _solution = null;
    });
    try {
      final solution = await widget.service.getSolution(requestedId);
      if (!mounted || widget.problemId != requestedId) return;
      setState(() => _solution = solution.problemId == requestedId
          ? solution
          : null);
    } catch (_) {
      if (!mounted || widget.problemId != requestedId) return;
      setState(() => _error = widget.isArabic
          ? 'تعذّر تحميل الحل. حاول مجدداً.'
          : 'Could not load the solution. Please retry.');
    } finally {
      if (mounted && widget.problemId == requestedId) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentEntitlement>(
      future: _entitlement,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        if (snapshot.hasError) {
          return OutlinedButton.icon(
            onPressed: () => setState(() {
              _entitlement = widget.service.getEntitlement();
            }),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(widget.isArabic ? 'تعذّر تحميل صلاحيات الحساب' : 'Retry account access'),
          );
        }
        if (snapshot.data?.canRevealSolutionBeforeAnswer != true) {
          return OutlinedButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (sheetContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.isArabic ? 'طريقة الحل' : 'Solution method',
                        style: Theme.of(sheetContext).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(widget.isArabic
                        ? 'طريقة الحل ميزة من حساب Premium. يمكنك متابعة حل المسائل المفتوحة بحساب Free.'
                        : 'Solution methods are a Premium benefit. You can continue practicing Free topics.'),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pushNamed(context, AppRoutes.premiumBenefits);
                        },
                        child: Text(widget.isArabic ? 'مميزات الحساب' : 'Account benefits'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(widget.isArabic ? 'طريقة الحل' : 'Solution method'),
          );
        }
        final solution = _solution;
        Option? correctOption;
        if (solution?.correctOptionId != null) {
          for (final option in widget.options) {
            if (option.id == solution!.correctOptionId) {
              correctOption = option;
              break;
            }
          }
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _loading ? null : _reveal,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_outlined),
                  label: Text(widget.isArabic
                      ? 'طريقة الحل'
                      : 'Solution method'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                if (solution != null) ...[
                  if (solution.detailedSolution?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichMathText(
                        text: solution.detailedSolution!,
                        isArabic: widget.isArabic,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  if (correctOption != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isArabic
                                ? 'الإجابة الصحيحة:'
                                : 'Correct answer:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          RichMathText(
                            text: correctOption.latexCode,
                            isArabic: widget.isArabic,
                            inline: true,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
