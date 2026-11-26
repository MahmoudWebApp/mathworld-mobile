import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../widgets/mathworld_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_routes.dart';
import '../../config/constants.dart';
import '../../config/design_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stages_provider.dart';
import '../../providers/social_link_status_provider.dart';
import '../../services/google_identity_service.dart';
import '../../core/utils/error_message.dart';
import '../../core/errors/app_exception.dart';
import '../../utils/layout_utils.dart';
import '../../widgets/mobile_section.dart';
import '../../widgets/app_states.dart';
import '../../widgets/math_background.dart';
import '../../widgets/account_password_dialog.dart';
import '../../widgets/platform_contact_card.dart';

/// Displays appearance, language, legal, and account preferences.
class SettingsScreen extends ConsumerWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentUser = ref.watch(authProvider.select((state) => state.user));
    final googleLinkState = GoogleIdentityService.available && currentUser?.role == 'Student'
        ? ref.watch(googleLinkedProvider)
        : null;
    final stages = ref.watch(stagesProvider).valueOrNull ?? [];
    final stage = stages.where((stage) => stage.id == currentUser?.currentStageId);
    final selectedStage = stage.isNotEmpty
        ? stage.first.getName(context.locale.languageCode)
        : null;

    final ar=context.locale.languageCode=='ar';
    final primary=Theme.of(context).colorScheme.primary;
    final student=currentUser?.role=='Student';
    final premium=currentUser?.subscriptionType.toLowerCase()=='premium';
    String tr(String a,String e)=>ar?a:e;
    Widget group(String title,List<Widget> rows)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      MobileSectionTitle(title:title),const SizedBox(height:8),
      MobilePanel(padding:EdgeInsets.zero,child:Column(children:[
        for(var i=0;i<rows.length;i++)...[if(i>0)const Divider(height:1,indent:16,endIndent:16),rows[i]],
      ])),
    ]);
    final content=MathBackground(showSymbols:false,child:SafeArea(bottom:false,child:ListView(
      padding:const EdgeInsets.all(16),children:[
        if(embedded)MobileSectionTitle(title:'settings'.tr()),
        if(currentUser!=null)...[
          const SizedBox(height:16),
          MobilePanel(child:Row(children:[
            CircleAvatar(radius:26,backgroundColor:primary.withValues(alpha:.12),foregroundColor:primary,child:const Icon(Icons.person_outline)),
            const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(currentUser.fullName,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
              Text(currentUser.email,style:Theme.of(context).textTheme.bodySmall,overflow:TextOverflow.ellipsis,maxLines:2),
              Text([if(selectedStage!=null)selectedStage,premium?'Premium':'Free'].join(' · '),style:TextStyle(color:premium?AppColors.pointsGold(context):primary,fontWeight:FontWeight.w700)),
            ])),
          ])),
        ],
        const SizedBox(height:24),
        if(student)...[
          group(tr('الحساب والتعلّم','Account & learning'),[
            MobileActionRow(icon:Icons.school_outlined,color:primary,title:'learning_stage'.tr(),subtitle:selectedStage??tr('اختيار المرحلة','Choose a stage'),onTap:()=>Navigator.pushNamed(context,AppRoutes.learningStage)),
            MobileActionRow(icon:Icons.workspace_premium_outlined,color:AppColors.pointsGold(context),title:tr('إدارة الاشتراك','Account benefits'),subtitle:tr('المميزات ورمز التفعيل','Benefits and activation code'),onTap:()=>Navigator.pushNamed(context,AppRoutes.premiumBenefits)),
            MobileActionRow(icon:Icons.auto_stories_outlined,color:primary,title:'error_notebook'.tr(),subtitle:'error_notebook_settings_desc'.tr(),onTap:()=>Navigator.pushNamed(context,AppRoutes.errorNotebook)),
            MobileActionRow(icon:Icons.bar_chart_rounded,color:primary,title:tr('تقاريري الشخصية','Personal reports'),subtitle:tr('إحصائيات المحاولات والنقاط والفئات','Attempts, points and category progress'),onTap:()=>Navigator.pushNamed(context,premium?AppRoutes.premiumAnalytics:AppRoutes.premiumBenefits)),
          ]),
          const SizedBox(height:24),
          group(tr('أمان الحساب','Account security'),[
            if(GoogleIdentityService.available&&googleLinkState?.valueOrNull!=true)
              ListTile(
                  leading: Icon(
                    googleLinkState?.valueOrNull == true
                        ? Icons.verified_rounded
                        : Icons.account_circle_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(googleLinkState?.valueOrNull == true
                      ? (context.locale.languageCode == 'ar'
                          ? 'Google مرتبط بالحساب'
                          : 'Google account connected')
                      : 'link_google'.tr()),
                  subtitle: Text(googleLinkState?.hasError == true
                      ? (context.locale.languageCode == 'ar'
                          ? 'تعذّر التأكد من الربط. اضغط لإعادة المحاولة.'
                          : 'Could not verify. Tap to retry.')
                      : googleLinkState?.isLoading == true
                          ? (context.locale.languageCode == 'ar'
                              ? 'جاري التحقق من الربط…'
                              : 'Checking connection…')
                          : googleLinkState?.valueOrNull == true
                              ? (context.locale.languageCode == 'ar'
                                  ? 'ما في حاجة لإعادة ربط الحساب.'
                                  : 'No need to connect again.')
                              : 'link_google_desc'.tr()),
                  trailing: googleLinkState?.isLoading == true
                      ? const SizedBox.square(
                          dimension: 18,
                          child: AppInlineLoader(size:18),
                        )
                      : Icon(googleLinkState?.valueOrNull == true
                          ? Icons.check_circle_rounded
                          : googleLinkState?.hasError == true
                              ? Icons.refresh_rounded
                              : Icons.link_rounded),
                  onTap: googleLinkState?.valueOrNull == true ||
                          googleLinkState?.isLoading == true
                      ? null
                      : () async {
                          if (googleLinkState?.hasError == true) {
                            ref.invalidate(googleLinkedProvider);
                            return;
                          }
                          try {
                            await ref.read(authProvider.notifier).linkGoogle();
                            ref.invalidate(googleLinkedProvider);
                            if (!context.mounted) return;
                            showMathWorldNotice(context,'google_linked'.tr(),kind:MathWorldNoticeKind.success);
                          } catch (error) {
                            if (!context.mounted) return;
                            if (error is AppException &&
                                error.type == AppExceptionType.cancelled) return;
                            showMathWorldNotice(context,localizedErrorMessage(error),kind:MathWorldNoticeKind.error);
                          }
                        },
                ),
            MobileActionRow(icon:Icons.lock_outline_rounded,color:primary,title:tr('تغيير كلمة المرور','Change password'),onTap:()async{
              final changed=await showDialog<bool>(context:context,barrierDismissible:false,builder:(_)=>const AccountPasswordDialog());
              if(changed!=true||!context.mounted)return;
              Navigator.pushNamedAndRemoveUntil(context,AppRoutes.login,(_)=>false);
              showMathWorldNotice(context,tr('تم تغيير كلمة المرور. سجّل الدخول مجدداً.','Password changed. Please sign in again.'),kind:MathWorldNoticeKind.success);
            }),
          ]),
          const SizedBox(height:24),
        ],
        group(tr('المظهر واللغة','Appearance & language'),[
          ListTile(leading:Icon(Icons.palette_outlined,color:primary),title:Text('appearance'.tr()),subtitle:Text(switch(settings.themeMode){ThemeMode.system=>'theme_system'.tr(),ThemeMode.light=>'theme_light'.tr(),ThemeMode.dark=>'theme_dark'.tr()}),trailing:LayoutUtils.forwardIcon(context),onTap:()=>showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(sheet)=>SafeArea(child:RadioGroup<ThemeMode>(groupValue:settings.themeMode,onChanged:(value){
            if(value!=null){ref.read(settingsProvider.notifier).setThemeMode(value);Navigator.pop(sheet);}
          },child:const Column(mainAxisSize:MainAxisSize.min,children:[
            _ThemeTile(value:ThemeMode.system,titleKey:'theme_system',icon:Icons.settings_suggest_outlined),
            _ThemeTile(value:ThemeMode.light,titleKey:'theme_light',icon:Icons.light_mode_outlined),
            _ThemeTile(value:ThemeMode.dark,titleKey:'theme_dark',icon:Icons.dark_mode_outlined),
          ]))))),
          ListTile(leading:Icon(Icons.translate_rounded,color:primary),title:Text('language'.tr()),subtitle:Text(settings.languageCode=='ar'?'language_arabic'.tr():'language_english'.tr()),trailing:LayoutUtils.forwardIcon(context),onTap:()=>showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(sheet)=>SafeArea(child:RadioGroup<String>(groupValue:settings.languageCode,onChanged:(value)async{
            if(value==null)return;
            Navigator.pop(sheet);
            await ref.read(settingsProvider.notifier).setLanguage(value);
            if(context.mounted)await context.setLocale(Locale(value));
          },child:Column(mainAxisSize:MainAxisSize.min,children:[
            RadioListTile<String>(value:'ar',title:Text('language_arabic'.tr()),secondary:const Icon(Icons.translate_rounded)),
            RadioListTile<String>(value:'en',title:Text('language_english'.tr()),secondary:const Icon(Icons.language_rounded)),
          ]))))),
        ]),
        const SizedBox(height:24),
        group('about_and_legal'.tr(),[
          MobileActionRow(icon:Icons.shield_outlined,color:primary,title:'privacy'.tr(),onTap:()=>Navigator.pushNamed(context,AppRoutes.privacy)),
          MobileActionRow(icon:Icons.info_outline_rounded,color:primary,title:'about'.tr(),subtitle:'app_version_value'.tr(namedArgs:{'version':AppConstants.appVersion})),
        ]),
        const SizedBox(height:12),
        const PlatformContactCard(),
        const SizedBox(height:24),
        OutlinedButton.icon(style:OutlinedButton.styleFrom(foregroundColor:AppColors.error,side:const BorderSide(color:AppColors.error)),icon:const Icon(Icons.logout_rounded),label:Text('logout'.tr()),onPressed:()async{
          await ref.read(authProvider.notifier).logout();
          if(context.mounted)Navigator.pushNamedAndRemoveUntil(context,AppRoutes.login,(_)=>false);
        }),
        const SizedBox(height:16),
      ],
    )));
    return embedded?content:Scaffold(appBar:AppBar(title:Text('settings'.tr())),body:content);
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode value;
  final String titleKey;
  final IconData icon;

  const _ThemeTile({
    required this.value,
    required this.titleKey,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      value: value,
      title: Text(titleKey.tr()),
      secondary: Icon(icon),
    );
  }
}

