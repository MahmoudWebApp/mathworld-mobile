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
                  style: IconButton.styleFrom(backgroundColor:Theme.of(context).colorScheme.primary.withValues(alpha:.10), foregroundColor:Theme.of(context).colorScheme.primary, minimumSize:const Size(48,48)),
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
      artwork='<path d="M23.5 6.2A3 3 0 0 0 21.4 4C19.5 3.5 12 3.5 12 3.5S4.5 3.5 2.6 4A3 3 0 0 0 .5 6.2C0 8.1 0 12 0 12s0 3.9.5 5.8A3 3 0 0 0 2.6 20c1.9.5 9.4.5 9.4.5s7.5 0 9.4-.5a3 3 0 0 0 2.1-2.2c.5-1.9.5-5.8.5-5.8s0-3.9-.5-5.8ZM9.5 15.6V8.4l6.3 3.6z" fill-rule="evenodd"/>';
    }else if(matches('facebook.com')||matches('fb.com')){
      artwork='<path d="M14 24V14h3.4l.5-4H14V7.5c0-1.2.4-2 2-2h2V2a23 23 0 0 0-3-.2C11.6 1.8 9.5 4 9.5 7.5V10H6v4h3.5v10z"/>';
    }else if(matches('instagram.com')){
      artwork='<rect x="2" y="2" width="20" height="20" rx="6" fill="none" stroke="black" stroke-width="2"/><circle cx="12" cy="12" r="4" fill="none" stroke="black" stroke-width="2"/><circle cx="18" cy="6" r="1.2"/>';
    }else if(matches('tiktok.com')){
      artwork='<path d="M14 2h3c.3 2 1.7 3.7 4 4v3c-1.5 0-2.9-.5-4-1.4V16a6 6 0 1 1-6-6h1v3h-1a3 3 0 1 0 3 3V2Z"/>';
    }else if(matches('x.com')||matches('twitter.com')){
      artwork='<path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25h6.914l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>';
    }else if(matches('linkedin.com')){
      artwork='<path d="M2 8h4v14H2zM4 1a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5zM9 8h4v2c1-2 3-2.5 5-2.5 4 0 4 3 4 6v8.5h-4v-8c0-2-1-3-2.5-3S13 12 13 14v8H9z"/>';
    }
    if(artwork==null)return const Icon(Icons.open_in_new);
    return SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">$artwork</svg>',width:22,height:22,colorFilter:ColorFilter.mode(Theme.of(context).colorScheme.primary,BlendMode.srcIn));
  }
}
