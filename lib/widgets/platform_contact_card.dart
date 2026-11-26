import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      error: (error, stackTrace) => const SizedBox.shrink(),
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
            if(p.links.isNotEmpty) Padding(padding:const EdgeInsets.fromLTRB(12,4,12,12),child:Wrap(
              alignment:WrapAlignment.center,spacing:8,runSpacing:8,
              children:[for(final link in p.links) IconButton(
                tooltip:ar?link.labelAr:link.labelEn,
                onPressed:()=>_open(context,link.url),
                icon:_SocialBrandIcon(link:link),
              )],
            )),
          ],
        ));
      },
    );
  }
}

class _SocialBrandIcon extends StatelessWidget {
  final PublishedContactLink link;
  const _SocialBrandIcon({required this.link});
  @override Widget build(BuildContext context){
    final host=link.url.host.toLowerCase();
    bool matches(String domain)=>host==domain||host.endsWith('.$domain');
    String? artwork;
    if(matches('youtube.com')||matches('youtu.be')){
      artwork='<rect x="1" y="4" width="22" height="16" rx="5" fill="#FF0000"/><path d="M10 8L16 12L10 16Z" fill="#FFFFFF"/>';
    }else if(matches('tiktok.com')){
      final ink=Theme.of(context).colorScheme.onSurface.toARGB32().toRadixString(16).padLeft(8,'0').substring(2);
      artwork='<path d="M14 2h4c.3 3 2 4.7 5 5v4c-2 0-3.5-.7-5-1.8v8a6.7 6.7 0 1 1-6.7-6.7h1.1v4h-1.1a2.7 2.7 0 1 0 2.7 2.7Z" fill="#$ink"/>';
    }else if(matches('facebook.com')||matches('fb.com')||matches('fb.me')){
      artwork='<circle cx="12" cy="12" r="11" fill="#1877F2"/><path d="M13.5 23V14h3l.5-3.5h-3.5V8.3c0-1 .3-1.7 1.8-1.7H17V3.5c-.6-.1-1.6-.2-2.6-.2-2.8 0-4.6 1.7-4.6 4.7v2.5H7V14h2.8v9Z" fill="#FFFFFF"/>';
    }else if(matches('instagram.com')){
      artwork='<rect x="2" y="2" width="20" height="20" rx="6" fill="#D62976"/><rect x="5" y="5" width="14" height="14" rx="4" fill="none" stroke="#FFFFFF" stroke-width="1.7"/><circle cx="12" cy="12" r="3.5" fill="none" stroke="#FFFFFF" stroke-width="1.7"/><circle cx="16.5" cy="7.5" r="1" fill="#FFFFFF"/>';
    }
    return artwork==null?const Icon(Icons.open_in_new):SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">$artwork</svg>',width:27,height:27);
  }
}
