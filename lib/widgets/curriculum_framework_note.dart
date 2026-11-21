import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/design_tokens.dart';

/// Explains MathWorld's independent curriculum references to learners.
class CurriculumFrameworkNote extends StatelessWidget {
  const CurriculumFrameworkNote({super.key});
  static const _officialSources = <String, String>{
    'Cambridge': 'https://www.cambridgeinternational.org/programmes-and-qualifications/maths/',
    'Common Core': 'https://corestandards.org/mathematics-standards/',
    'OECD PISA': 'https://www.oecd.org/en/publications/pisa-2022-assessment-and-analytical-framework_dfe0bf9c-en/full-report/component-3.html',
    'MSC2020': 'https://mathscinet.ams.org/msc/msc.html',
  };

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md,
        ),
        leading: Icon(Icons.menu_book_rounded, color: colors.primary),
        title: Text(
          ar ? 'كيف ننظّم تعلمك في الرياضيات؟'
             : 'How do we organize mathematics learning?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          ar ? 'فئات حسب الموضوع وتدريب متنوع حسب المهارة، بدون عدد ثابت أو تكرار بلا فائدة.'
             : 'Focused topics and varied practice by skill, not fixed question quotas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Text(
            ar ? 'نسترشد بـCambridge وCommon Core لترتيب مهارات الرياضيات المدرسية، وPISA للتفكير والتطبيق، وMSC2020 لتصنيف الموضوعات الجامعية. عدد الفئات والمسائل يعتمد على أهداف التعلم، ونتابع تقدمك من محاولاتك وحلولك الفعلية.'
               : 'We draw on Cambridge and Common Core for school skill progression, PISA for mathematical reasoning, and MSC2020 for university subjects. Question volume follows learning goals; your progress uses actual attempts and solutions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ar ? 'هذه مراجع نسترشد بها، وليست اعتماداً أو شراكة رسمية مع الجهات المذكورة.'
               : 'These are reference frameworks, not official endorsement or partnership.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: AppSpacing.xs,
              children: _officialSources.entries.map((item) => TextButton.icon(
                onPressed: () async {
                  await launchUrl(Uri.parse(item.value), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(item.key),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
