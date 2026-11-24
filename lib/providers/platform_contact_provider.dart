import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../core/network/api_envelope.dart';
import 'repositories_provider.dart';

Uri? safeBrandLink(dynamic value) {
  if (value is! String || value.trim() != value || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
      !uri.host.contains('.') || uri.userInfo.isNotEmpty || uri.port != 443) return null;
  return uri;
}

class PublishedContactLink {
  final String labelAr, labelEn;
  final Uri url;
  final int order;
  const PublishedContactLink(this.labelAr, this.labelEn, this.url, this.order);
}

class PlatformContact {
  final String nameAr, nameEn;
  final String? email, phone, addressAr, addressEn;
  final Uri? website;
  final List<PublishedContactLink> links;
  const PlatformContact({required this.nameAr, required this.nameEn, this.email,
    this.phone, this.addressAr, this.addressEn, this.website, required this.links});

  factory PlatformContact.fromJson(Map<String, dynamic> data) {
    final raw = data['Profile'];
    final p = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    String? text(dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final links = <PublishedContactLink>[];
    final social = p['SocialLinks'];
    if (social is List) {
      for (final item in social) {
        if (item is! Map || item['IsEnabled'] != true) continue;
        final url = safeBrandLink(item['Url']);
        final ar = text(item['LabelAr']);
        final en = text(item['LabelEn']);
        if (url != null && ar != null && en != null) {
          links.add(PublishedContactLink(ar, en, url,
              item['DisplayOrder'] is int ? item['DisplayOrder'] as int : 0));
        }
      }
    }
    links.sort((a,b) => a.order.compareTo(b.order));
    final email = text(p['SupportEmail']);
    return PlatformContact(
      nameAr: text(p['NameAr']) ?? 'MathWorld', nameEn: text(p['NameEn']) ?? 'MathWorld',
      email: email != null && RegExp(r'^[^\s@?&#]+@[^\s@?&#]+\.[^\s@?&#]+$').hasMatch(email) ? email : null,
      phone: text(p['Phone']), addressAr: text(p['ContactAddressAr']), addressEn: text(p['ContactAddressEn']),
      website: safeBrandLink(data['WebsiteUrl']), links: List.unmodifiable(links),
    );
  }
}

final platformContactProvider = FutureProvider.autoDispose<PlatformContact>((ref) async {
  final response = await ref.watch(apiClientProvider).get(
    ApiConstants.platformBrand, handleUnauthorized: false,
  );
  return PlatformContact.fromJson(ApiEnvelope.map(response.data));
});
