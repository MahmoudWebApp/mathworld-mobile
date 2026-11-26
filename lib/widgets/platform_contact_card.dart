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
            if(p.links.isNotEmpty)Padding(
              padding:const EdgeInsets.all(12),
              child:Wrap(alignment:WrapAlignment.center,spacing:8,runSpacing:8,children:[
                for(final link in p.links) IconButton(
                  tooltip:ar?link.labelAr:link.labelEn,
                  onPressed:()=>_open(context,link.url),
                  icon:_SocialIcon(url:link.url),
                ),
              ]),
            ),
          ],
        ));
      },
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final Uri url;
  const _SocialIcon({required this.url});
  @override
  Widget build(BuildContext context) {
    final host=url.host.toLowerCase();
    bool matches(String domain)=>host==domain||host.endsWith('.$domain');
    String? artwork;
    if(matches('youtube.com')||matches('youtu.be')){
      artwork='<rect x="1" y="4" width="22" height="16" rx="5" fill="#FF0000"/><path d="M10 8l7 4-7 4z" fill="white"/>';
    }else if(matches('facebook.com')||matches('fb.com')){
      artwork='<circle cx="12" cy="12" r="12" fill="#1877F2"/><path d="M13.8 24V14h3.4l.5-4h-3.9V7.5c0-1.2.4-2 2-2H18V2a23 23 0 0 0-3-.2C11.6 1.8 9.5 4 9.5 7.5V10H6v4h3.5v10z" fill="white"/>';
    }else if(matches('instagram.com')){
      artwork='<defs><linearGradient id="g" x1="0" y1="1" x2="1" y2="0"><stop stop-color="#FEDA75"/><stop offset=".5" stop-color="#D62976"/><stop offset="1" stop-color="#4F5BD5"/></linearGradient></defs><rect width="24" height="24" rx="6" fill="url(#g)"/><rect x="5" y="5" width="14" height="14" rx="4" fill="none" stroke="white" stroke-width="1.7"/><circle cx="12" cy="12" r="3.5" fill="none" stroke="white" stroke-width="1.7"/><circle cx="16.5" cy="7.5" r="1" fill="white"/>';
    }else if(matches('tiktok.com')){
      const note='M14 3h3c.3 2.6 1.8 4.1 4 4.5v3a10 10 0 0 1-4-1.5v7a6 6 0 1 1-6-6v3a3 3 0 1 0 3 3z';
      artwork='<rect width="24" height="24" rx="6" fill="#161823"/><path d="$note" fill="#25F4EE" transform="translate(-.6 .4)"/><path d="$note" fill="#FE2C55" transform="translate(.6 .7)"/><path d="$note" fill="white"/>';
    }
    if(artwork==null)return const Icon(Icons.open_in_new);
    return SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">$artwork</svg>',width:28,height:28);
  }
}
