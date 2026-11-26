import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/design_tokens.dart';
import '../../core/utils/error_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/notification_api_service.dart';
import '../../widgets/app_states.dart';
import '../../widgets/math_background.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final owner=ref.watch(authProvider.select((state)=>state.user?.id));
    return owner==null?const Scaffold():_ManagedInbox(key:ValueKey(owner),owner:owner);
  }
}

class _ManagedInbox extends ConsumerStatefulWidget {
  const _ManagedInbox({super.key,required this.owner});
  final int owner;
  @override ConsumerState<_ManagedInbox> createState()=>_ManagedInboxState();
}
class _ManagedInboxState extends ConsumerState<_ManagedInbox>{
  final _scroll=ScrollController();
  final _items=<UserNotice>[];
  final _selected=<int>{};
  final _read=<int>{};
  NotificationInbox? _page;
  bool _all=false,_busy=false;
  String? _error;
  bool get _active=>mounted&&ref.read(authProvider).user?.id==widget.owner;
  bool get _ar=>context.locale.languageCode=='ar';
  String tr(String ar,String en)=>_ar?ar:en;
  int get _count=>_all?(_page?.totalCount??0):_selected.length;
  NotificationApiService get _api=>ref.read(notificationApiServiceProvider);
  @override void initState(){
    super.initState();
    _scroll.addListener(_nearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_){if(_active)_refresh();});
  }
  @override void dispose(){_scroll.dispose();super.dispose();}
  void _nearEnd(){
    if(_scroll.hasClients&&_scroll.position.extentAfter<80&&_page?.hasMore==true&&!_busy&&_error==null){_more();}
  }
  void _invalidate(){
    ref.invalidate(notificationInboxProvider);
    ref.invalidate(notificationsUnreadCountProvider);
    ref.invalidate(notificationPageProvider);
  }
  Future<void> _run(Future<void> Function() action) async {
    if(!_active||_busy)return;
    setState((){_busy=true;_error=null;});
    try{await action();}
    catch(e){if(_active)setState(()=>_error=localizedErrorMessage(e));}
    finally{if(_active)setState(()=>_busy=false);}
  }
  Future<void> _reset() async {
    final p=await _api.managed();
    if(!_active)return;
    setState((){
      _page=p;_items..clear()..addAll(p.items);
      _all=false;_selected.clear();_read.clear();
    });
    if(_scroll.hasClients)_scroll.jumpTo(0);
  }
  Future<void> _refresh()=>_run(() async{await _reset();if(_active)_invalidate();});
  Future<void> _more()=>_run(() async{
    final p=_page;
    if(p==null||!p.hasMore||_items.isEmpty)return;
    final next=await _api.managed(snapshotId:p.snapshotId,before:_items.last);
    if(!_active)return;
    final known=_items.map((n)=>n.id).toSet();
    setState((){_page=next;_items.addAll(next.items.where((n)=>known.add(n.id)));});
  });
  Future<void> _delete() async {
    if(!_active||_busy||_count==0||_page==null)return;
    final all=_all,snapshot=_page!.snapshotId,ids=_selected.toList();
    final approved=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
      title:Text(tr('حذف الإشعارات','Delete notifications')),
      content:Text(tr('هل تريد حذف الإشعارات المحددة نهائياً؟','Permanently delete the selected notifications?')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dialog,false),child:Text(tr('إلغاء','Cancel'))),
        FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:Text(tr('حذف','Delete'))),
      ],
    ));
    if(approved!=true||!_active)return;
    await _run(() async {
      await _api.deleteSelection(all:all,snapshotId:snapshot,ids:ids);
      if(!_active)return;
      setState((){_items.clear();_page=null;_selected.clear();_all=false;});
      _invalidate();
      await _reset();
    });
  }
  Future<void> _readAll()=>_run(() async {
    await _api.markAllRead();
    if(!_active)return;
    setState(()=>_read.addAll(_items.map((n)=>n.id)));
    _invalidate();
  });
  Future<void> _open(UserNotice notice)=>_run(() async {
    if(notice.isUnread&&!_read.contains(notice.id)){
      await _api.markRead(notice.id);
      if(!_active)return;
      setState(()=>_read.add(notice.id));_invalidate();
    }
    if(!_active)return;
    final path=notice.targetPath;
    if(path=='/dashboard/daily-challenge'||path=='/dashboard/sessions/daily'){
      Navigator.pop(context,'daily-challenge');
    }else if(path=='/dashboard'){Navigator.maybePop(context);}
  });
  @override Widget build(BuildContext context){
    final scheme=Theme.of(context).colorScheme;
    return Scaffold(
      appBar:AppBar(title:Text(tr('الإشعارات','Notifications')),actions:[
        IconButton(onPressed:_busy?null:_refresh,tooltip:tr('تحديث','Refresh'),icon:const Icon(Icons.refresh)),
      ]),
      body:MathBackground(showSymbols:false,child:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.symmetric(horizontal:AppSpacing.md),child:Wrap(
          spacing:8,runSpacing:4,crossAxisAlignment:WrapCrossAlignment.center,children:[
            Row(mainAxisSize:MainAxisSize.min,children:[
              Checkbox(value:_all,onChanged:_busy||(_page?.totalCount??0)==0?null:(v)=>setState((){_all=v==true;_selected.clear();})),
              Text(tr('تحديد الكل','Select all')),
            ]),
            Text('$_count '+tr('محدد','selected')),
            TextButton.icon(onPressed:_busy||_count==0?null:_delete,icon:Icon(Icons.delete_outline,color:scheme.error),label:Text(tr('حذف','Delete'),style:TextStyle(color:scheme.error))),
            TextButton.icon(onPressed:_busy||_items.isEmpty?null:_readAll,icon:const Icon(Icons.done_all),label:Text(tr('قراءة الكل','Read all'))),
          ],
        )),
        if(_error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(_error!,style:TextStyle(color:scheme.error))),
        Expanded(child:_page==null&&(_busy||_error==null)?const AppContentSkeleton():_page==null?AppErrorView(message:_error,onRetry:_refresh):
          RefreshIndicator(onRefresh:_refresh,child:ListView.separated(
            controller:_scroll,physics:const AlwaysScrollableScrollPhysics(),
            padding:const EdgeInsets.all(AppSpacing.md),
            itemCount:_items.length+1,
            separatorBuilder:(_,__)=>const Divider(height:1,indent:16,endIndent:16),
            itemBuilder:(context,index){
              if(index==_items.length){
                if(_page?.hasMore==true)return Padding(padding:const EdgeInsets.all(12),child:Center(child:_busy?const AppInlineLoader():TextButton(onPressed:_more,child:Text(tr('عرض المزيد','Load more')))));
                return Padding(padding:const EdgeInsets.all(16),child:Center(child:Text(_items.isEmpty?tr('لا توجد إشعارات','No notifications'):tr('نهاية إشعارات آخر 30 يوماً','End of 30-day notifications'))));
              }
              final n=_items[index],unread=n.isUnread&&!_read.contains(n.id);
              return Material(key:ValueKey(n.id),color:unread?scheme.primaryContainer.withValues(alpha:.25):scheme.surface,child:ListTile(
                leading:Checkbox(value:_all||_selected.contains(n.id),onChanged:_busy||_all?null:(v)=>setState((){if(v==true){_selected.add(n.id);}else{_selected.remove(n.id);}})),
                title:Text(_ar?n.titleAr:n.titleEn,style:TextStyle(fontWeight:unread?FontWeight.w800:FontWeight.w600)),
                subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  const SizedBox(height:6),Text(_ar?n.bodyAr:n.bodyEn),const SizedBox(height:6),
                  Text(MaterialLocalizations.of(context).formatMediumDate(n.createdAtUtc.toLocal()),style:Theme.of(context).textTheme.bodySmall),
                ]),
                onTap:_busy?null:()=>_open(n),
              ));
            },
          )),
        ),
      ]))),
    );
  }
}
