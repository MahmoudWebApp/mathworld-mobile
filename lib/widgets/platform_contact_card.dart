import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/platform_contact_provider.dart';
import 'glass_card.dart';

class PlatformContactCard extends ConsumerWidget {
  const PlatformContactCard({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        context.locale.languageCode == 'ar' ? 'تعذّر فتح الرابط.' : 'Could not open the link.',
      )));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = context.locale.languageCode == 'ar';
    final brand = ref.watch(platformContactProvider);
    return brand.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (p) {
        final address = ar ? p.addressAr : p.addressEn;
        return GlassCard(padding: EdgeInsets.zero, child: Column(
          children: [
            ListTile(title: Text(ar ? p.nameAr : p.nameEn),
              subtitle: Text(ar ? 'التواصل مع المنصة' : 'Platform contact'),
              leading: const Icon(Icons.info_outline_rounded)),
            if (p.website != null) ListTile(
              leading: const Icon(Icons.language), title: Text(ar ? 'الموقع الرسمي' : 'Official website'),
              onTap: () => _open(context, p.website!)),
            if (p.email != null) ListTile(
              leading: const Icon(Icons.mail_outline), title: Text(p.email!),
              onTap: () => _open(context, Uri(scheme: 'mailto', path: p.email!))),
            if (p.phone != null) ListTile(leading: const Icon(Icons.phone_outlined), title: Text(p.phone!, textDirection: TextDirection.ltr)),
            if (address != null) ListTile(leading: const Icon(Icons.location_on_outlined), title: Text(address)),
            for (final link in p.links) ListTile(
              leading: const Icon(Icons.open_in_new), title: Text(ar ? link.labelAr : link.labelEn),
              onTap: () => _open(context, link.url)),
          ],
        ));
      },
    );
  }
}
