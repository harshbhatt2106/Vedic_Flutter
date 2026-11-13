import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

enum UserToolKind { notifications, shortlist, blocked, reports }

class UserToolsScreen extends StatefulWidget {
  const UserToolsScreen({super.key, required this.apiClient, required this.kind, required this.onOpenMenu});
  final ApiClient apiClient;
  final UserToolKind kind;
  final VoidCallback onOpenMenu;

  @override
  State<UserToolsScreen> createState() => _UserToolsScreenState();
}

class _UserToolsScreenState extends State<UserToolsScreen> {
  bool _loading = true;
  bool _working = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  String get _title => switch (widget.kind) {
    UserToolKind.notifications => 'Notifications',
    UserToolKind.shortlist => 'Your shortlist',
    UserToolKind.blocked => 'Blocked profiles',
    UserToolKind.reports => 'My reports',
  };

  String get _endpoint => switch (widget.kind) {
    UserToolKind.notifications => '/notifications?take=100',
    UserToolKind.shortlist => '/shortlists',
    UserToolKind.blocked => '/blocks',
    UserToolKind.reports => '/reports/my',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.apiClient.get(_endpoint, authenticated: true);
      final raw = response['data'];
      if (!mounted) return;
      setState(() {
        _items = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _read(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return '';
  }

  String _itemId(Map<String, dynamic> item) => switch (widget.kind) {
    UserToolKind.notifications => _read(item, ['notificationId', 'id']),
    UserToolKind.shortlist => _read(item, ['shortlistedUserId']),
    UserToolKind.blocked => _read(item, ['blockedUserId']),
    UserToolKind.reports => _read(item, ['id']),
  };

  Future<void> _viewShortlistedProfile(Map<String,dynamic> item) async {
    final userId=_read(item,['shortlistedUserId']);if(userId.isEmpty)return;
    try{
      final response=await widget.apiClient.get('/user-profile/$userId',authenticated:true);
      final p=response['data'] is Map?Map<String,dynamic>.from(response['data']):<String,dynamic>{};
      Uint8List? avatar;try{avatar=await widget.apiClient.getBytes('/user-profile/$userId/primary-photo',authenticated:true);}catch(_){}
      if(!mounted)return;
      final dob=DateTime.tryParse(p['dateOfBirth']?.toString()??'');String age='';
      if(dob!=null){final now=DateTime.now();var years=now.year-dob.year;if(now.month<dob.month||(now.month==dob.month&&now.day<dob.day))years--;age='$years yrs';}
      final sections=<String,Map<String,dynamic>>{
        'Personal information':{'Date of birth':age,'Gender':p['gender'],'Time of birth':p['timeOfBirth'],'Birth place':p['birthPlace'],'Disability':p['disabilityStatus']==true?'Yes':'No','Disability details':p['disabilityDetails']},
        'Religion & community':{'Religion':p['religionName'],'Caste':p['casteName'],'Sub-caste':p['subCasteName'],'Mother tongue':p['motherTongue']},
        'Education & career':{'Education':p['education'],'Course':p['course'],'Qualification':p['qualification'],'Occupation':p['occupation'],'Profession':p['profession'],'Work type':p['workType'],'Yearly income':p['yearlyIncome']},
        'Physical':{'Height':p['heightFeet']==null?'':'${p['heightFeet']} ft ${p['heightInches']??0} in','Weight':p['weight']},
        'Family':{'Marital status':p['maritalStatus'],'Father':p['fatherName'],'Mother':p['motherName'],'Brother':p['brother'],'Sister':p['sister'],'Married brothers':p['marriedBrotherCount'],'Married sisters':p['marriedSisterCount'],'Nanaji':p['nanajiName'],'Mosal surname':p['mosalSurname']},
        'Location & residence':{'Country':p['countryName'],'State':p['stateName'],'City':p['cityName'],'Pin code':p['pinCode'],'Native place':p['nativePlace'],'Area':p['area'],'Residence':p['residenceType'],'Area (sq.ft.)':p['areaInSqFt'],'Rooms':p['roomCount']},
        'About':{'About me':p['aboutMe']},
      };
      await showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:SizedBox(height:MediaQuery.of(ctx).size.height*.84,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[CircleAvatar(radius:30,backgroundColor:AppPalette.champagne,backgroundImage:avatar==null?null:MemoryImage(avatar),child:avatar==null?const Icon(Icons.person,color:AppPalette.maroon):null),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${p['firstName']??'VedicVivah'} ${p['lastName']??'member'}',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),Text([age,p['gender']?.toString()].where((x)=>x!=null&&x.toString().isNotEmpty).join(' · '),style:const TextStyle(color:AppPalette.secondary))]))]),
        const SizedBox(height:12),
        Expanded(child:ListView(children:sections.entries.map((section)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Card(color:AppPalette.surface,elevation:0,child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(section.key,style:const TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
          const SizedBox(height:6),
          ...section.value.entries.where((e)=>e.value!=null&&e.value.toString().trim().isNotEmpty).map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Text('${e.key}: ${e.value}'))),
        ]))))).toList())),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))),
      ])))));
    }catch(e){if(mounted)setState(()=>_error=e.toString());}
  }

  Future<void> _action(Map<String, dynamic> item) async {
    final id = _itemId(item);
    if (id.isEmpty) return;
    if (widget.kind == UserToolKind.notifications) {
      setState(() => _working = true);
      try { await widget.apiClient.put('/notifications/' + id + '/read', body: {}, authenticated: true); await _load(); }
      catch (error) { if (mounted) setState(() => _error = error.toString().replaceFirst('ApiException: ', '')); }
      finally { if (mounted) setState(() => _working = false); }
      return;
    }
    final prompt = switch (widget.kind) {
      UserToolKind.notifications => 'Mark this notification as read?',
      UserToolKind.shortlist => 'Remove this profile from your shortlist?',
      UserToolKind.blocked => 'Unblock this profile?',
      UserToolKind.reports => '',
    };
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Confirm action'),
      content: Text(prompt),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
      ],
    ));
    if (yes != true) return;
    setState(() => _working = true);
    try {
      if (widget.kind == UserToolKind.notifications) {
        await widget.apiClient.put('/notifications/' + id + '/read', body: {}, authenticated: true);
      } else if (widget.kind == UserToolKind.shortlist) {
        await widget.apiClient.delete('/shortlists/' + id, authenticated: true);
      } else if (widget.kind == UserToolKind.blocked) {
        await widget.apiClient.delete('/blocks/' + id, authenticated: true);
      }
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _working = true);
    try {
      await widget.apiClient.put('/notifications/read-all', body: {}, authenticated: true);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _date(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return '';
    return date.day.toString().padLeft(2, '0') + '/' + date.month.toString().padLeft(2, '0') + '/' + date.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => e['isRead'] != true).length;
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        leading: IconButton(tooltip: 'Open navigation menu', onPressed: widget.onOpenMenu, icon: const Icon(Icons.menu_rounded, color: AppPalette.maroon)),
        backgroundColor: AppPalette.background,
        title: Text(_title, style: const TextStyle(color: AppPalette.darkMaroon)),
        actions: [
          if (widget.kind == UserToolKind.notifications && unread > 0)
            TextButton(onPressed: _working ? null : _markAllRead, child: const Text('Mark all read')),
          IconButton(onPressed: _loading || _working ? null : _load, icon: const Icon(Icons.refresh, color: AppPalette.maroon)),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppPalette.maroon))
        : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: AppPalette.error, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ])))
          : _items.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(switch (widget.kind) {
                UserToolKind.notifications => 'You are all caught up.',
                UserToolKind.shortlist => 'Profiles you save will appear here.',
                UserToolKind.blocked => 'You have not blocked any profiles.',
                UserToolKind.reports => 'You have not submitted any reports.',
              }, textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.secondary))))
            : RefreshIndicator(
                color: AppPalette.maroon,
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _card(_items[index]),
                ),
              ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final title = switch (widget.kind) {
      UserToolKind.notifications => _read(item, ['title']).isEmpty ? 'Notification' : _read(item, ['title']),
      UserToolKind.shortlist || UserToolKind.blocked => (_read(item, ['firstName']) + ' ' + _read(item, ['lastName'])).trim(),
      UserToolKind.reports => _read(item, ['reportedUserName']),
    };
    final detail = switch (widget.kind) {
      UserToolKind.notifications => _read(item, ['message']),
      UserToolKind.shortlist => [_read(item, ['profession']), _read(item, ['cityName']), _read(item, ['religionName']), _read(item, ['casteName'])].where((e) => e.isNotEmpty).join(' · '),
      UserToolKind.blocked => [_read(item, ['gender']), _read(item, ['cityName']), _read(item, ['reason'])].where((e) => e.isNotEmpty).join(' · '),
      UserToolKind.reports => 'Reason: ' + _read(item, ['reason']),
    };
    final date = _date(item['createdAtUtc']);
    final canAct = widget.kind != UserToolKind.reports && (widget.kind != UserToolKind.notifications || item['isRead'] != true);
    final icon = switch (widget.kind) {
      UserToolKind.notifications => item['isRead'] == true ? Icons.notifications_none : Icons.notifications_active_outlined,
      UserToolKind.shortlist => Icons.favorite,
      UserToolKind.blocked => Icons.block,
      UserToolKind.reports => Icons.flag_outlined,
    };
    return Card(
      color: AppPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppPalette.border)),
      child: ListTile(
        onTap: widget.kind == UserToolKind.shortlist ? () => _viewShortlistedProfile(item) : widget.kind == UserToolKind.notifications && item['isRead'] != true ? () => _action(item) : null,
        leading: CircleAvatar(backgroundColor: AppPalette.champagne, child: Icon(icon, color: AppPalette.maroon)),
        title: Text(title.isEmpty ? 'VedicVivah member' : title, style: const TextStyle(color: AppPalette.darkMaroon, fontWeight: FontWeight.w600)),
        subtitle: Text([detail, date].where((e) => e.isNotEmpty).join('\n')),
        trailing: canAct ? IconButton(
          onPressed: _working ? null : () => _action(item),
          icon: Icon(widget.kind == UserToolKind.notifications ? Icons.done : Icons.close, color: AppPalette.maroon),
        ) : null,
      ),
    );
  }
}
