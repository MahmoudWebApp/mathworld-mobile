import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/design_tokens.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/math_background.dart';

/// Displays the localized privacy policy inside the mobile application.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('privacy'.tr())),
      body: MathBackground(
        showSymbols: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 38),
                  const SizedBox(height: 16),
                  Text(
                    'privacy_title'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'privacy_intro'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...[
              (
                'privacy_data_title',
                'privacy_data_body',
                Icons.storage_outlined
              ),
              (
                'privacy_usage_title',
                'privacy_usage_body',
                Icons.insights_outlined
              ),
              (
                'privacy_security_title',
                'privacy_security_body',
                Icons.lock_outline_rounded
              ),
              (
                'privacy_rights_title',
                'privacy_rights_body',
                Icons.manage_accounts_outlined
              ),
              (
                'privacy_contact_title',
                'privacy_contact_body',
                Icons.mail_outline_rounded
              ),
            ].map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(section.$3,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(section.$1.tr(),
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(section.$2.tr()),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
