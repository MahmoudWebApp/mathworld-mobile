import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/providers/platform_contact_provider.dart';
import 'package:mathworld_mobile/widgets/account_password_dialog.dart';

void main() {
  test('password byte limit and confirmation', () {
    expect(validNewAccountPassword('correct-length-password','correct-length-password'), isTrue);
    expect(validNewAccountPassword('short','short'), isFalse);
    expect(validNewAccountPassword('correct-length-password','another-password'), isFalse);
    final arabic72 = List.filled(36, 'ش').join();
    final arabic74 = List.filled(37, 'ش').join();
    expect(validNewAccountPassword(arabic72,arabic72), isTrue);
    expect(validNewAccountPassword(arabic74,arabic74), isFalse);
  });
  test('contact settings expose only enabled safe published links', () {
    final contact = PlatformContact.fromJson({
      'WebsiteUrl':'https://math-world-frontend.vercel.app',
      'Profile':{'NameAr':'MathWorld','NameEn':'MathWorld','SocialLinks':[
        {'IsEnabled':false,'LabelAr':'مخفي','LabelEn':'Hidden','Url':'https://example.com'},
        {'IsEnabled':true,'LabelAr':'رابط','LabelEn':'Link','Url':'https://example.com/math','DisplayOrder':2},
        {'IsEnabled':true,'LabelAr':'خطأ','LabelEn':'Invalid','Url':'javascript:alert(1)'}
      ]}
    });
    expect(contact.email,isNull);
    expect(contact.links.length,1);
    expect(contact.links.single.labelEn,'Link');
    expect(safeBrandLink('https://user@evil.example/'),isNull);
  });
}
