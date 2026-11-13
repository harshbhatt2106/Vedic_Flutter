import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import 'user_photos_screen.dart';
import '../../../../core/storage/session_store.dart';
import 'user_contacts_mentor_screen.dart';
import 'user_profile_editor_screen.dart';
import '../../data/chat_realtime_service.dart';

class UserWorkspaceScreen extends StatefulWidget {
  const UserWorkspaceScreen({super.key, required this.apiClient, this.initialTab = 0, this.subscriptionExpired = false, this.approvalRestricted = false, this.onSubscriptionCheck});
  final ApiClient apiClient;
  final int initialTab;
  final bool subscriptionExpired,approvalRestricted;
  final VoidCallback? onSubscriptionCheck;
  @override
  State<UserWorkspaceScreen> createState() => _UserWorkspaceScreenState();
}
class _UserWorkspaceScreenState extends State<UserWorkspaceScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  @override void initState(){super.initState();tabs=TabController(length:9,initialIndex:widget.initialTab.clamp(0,8).toInt(),vsync:this)..addListener(_handleTabChange);}
  void _handleTabChange(){if(!tabs.indexIsChanging&&tabs.index==6)widget.onSubscriptionCheck?.call();}
  @override void didUpdateWidget(covariant UserWorkspaceScreen oldWidget){super.didUpdateWidget(oldWidget);if(oldWidget.initialTab!=widget.initialTab)tabs.animateTo(widget.initialTab.clamp(0,8).toInt());}
  @override void dispose(){tabs.removeListener(_handleTabChange);tabs.dispose();super.dispose();}
  Widget _tab(String kind,Widget child){
    final blocked=(widget.subscriptionExpired&&const {'discover','preferences','messages','mentor'}.contains(kind))||
      (widget.approvalRestricted&&const {'discover','preferences','messages','plans','mentor'}.contains(kind));
    if(!blocked)return child;
    final expired=widget.subscriptionExpired;
    return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Icon(Icons.lock_outline,size:42,color:AppPalette.maroon),
      const SizedBox(height:12),
      Text(expired?'Your subscription has expired.':'Your profile is awaiting approval.',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),
      const SizedBox(height:8),
      Text(expired?'Renew your plan to continue discovering profiles and messaging.':'This section becomes available after your profile is approved.',textAlign:TextAlign.center),
      if(expired)TextButton(onPressed:()=>tabs.animateTo(6),child:const Text('View plans')),
    ])));
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppPalette.background,
    appBar:AppBar(backgroundColor:AppPalette.background,title:const Text('Your account',style:TextStyle(color:AppPalette.darkMaroon)),
      bottom:TabBar(controller:tabs,isScrollable:true,labelColor:AppPalette.maroon,unselectedLabelColor:AppPalette.secondary,indicatorColor:AppPalette.gold,
        tabs:const [Tab(text:'Find matches'),Tab(text:'Profile'),Tab(text:'Photos'),Tab(text:'Preferences'),Tab(text:'Messages'),Tab(text:'Support'),Tab(text:'Plans'),Tab(text:'References'),Tab(text:'Mentor')])),
    body:TabBarView(controller:tabs,children:[
      _tab('discover',_WorkspaceTab(api:widget.apiClient,kind:'discover')),
      UserProfileEditorScreen(apiClient:widget.apiClient),
      UserPhotosScreen(apiClient:widget.apiClient),
      _tab('preferences',_WorkspaceTab(api:widget.apiClient,kind:'preferences')),
      _tab('messages',_WorkspaceTab(api:widget.apiClient,kind:'messages')),
      _WorkspaceTab(api:widget.apiClient,kind:'support'),
      _tab('plans',_WorkspaceTab(api:widget.apiClient,kind:'plans')),
      UserReferencesScreen(apiClient:widget.apiClient),
      _tab('mentor',UserMentorScreen(apiClient:widget.apiClient)),
    ]),
  );
}

class _WorkspaceTab extends StatefulWidget {
  const _WorkspaceTab({required this.api,required this.kind});
  final ApiClient api; final String kind;
  @override State<_WorkspaceTab> createState()=>_WorkspaceTabState();
}
class _WorkspaceTabState extends State<_WorkspaceTab> {
  bool loading=true,working=false; String? error,notice;
  List<Map<String,dynamic>> items=[]; List<Map<String,dynamic>> connections=[]; Map<String,dynamic> data={};
  final a=TextEditingController(),b=TextEditingController(),c=TextEditingController(),d=TextEditingController(),e=TextEditingController();
  final Map<String,List<Map<String,dynamic>>> prefOptions={};
  final Map<String,TextEditingController> prefFields={for(final k in ['minHeightFeet','minHeightInches','maxHeightFeet','maxHeightInches','religionId','casteId','subCasteId','motherTongue','educationFieldId','courseId','qualificationId','occupationId','professionId','workType','minYearlyIncome','maxYearlyIncome','countryId','stateId','cityId'])k:TextEditingController()};
  bool _discoveryOptionsLoaded=false,_discoverPreferencesLoaded=false;
  final Map<String,List<Map<String,dynamic>>> discoveryOptions={};
  final Set<String> shortlistedIds={};
  final Map<String,String> interestStatuses={};
  final Map<String,Uint8List> discoveryAvatars={};
  StateSetter? _discoverModalSetState;
  String? filterValidationError;
  final Map<String,TextEditingController> filters={for(final k in ['religionId','casteId','subCasteId','preferredGender','maritalStatus','motherTongue','education','profession','minYearlyIncome','maxYearlyIncome','minHeightFeet','minHeightInches','maxHeightFeet','maxHeightInches','countryId','stateId','cityId','educationFieldId','courseId','qualificationId','occupationId','professionId','workType'])k:TextEditingController()};
  int discoverPage=1,totalPages=1;
  String choice='',marital='';
  @override void initState(){super.initState();load();}
  @override void dispose(){for(final x in [a,b,c,d,e,...filters.values,...prefFields.values]){x.dispose();}super.dispose();}
  String get title=>switch(widget.kind){'discover'=>'Find matches','profile'=>'Your biodata','preferences'=>'Partner preferences','messages'=>'Messages','support'=>'Help & support',_=>'Membership plans'};
  Future<void> load() async {
    setState(() { loading=true; error=null; });
    try {
      if(widget.kind=='discover'){
        if(!_discoverPreferencesLoaded)await _loadSavedDiscoverPreferences();
        final params=<String,String>{'pageNumber':discoverPage.toString(),'pageSize':'20'};
        for(final entry in {'search':a,'minAge':b,'maxAge':c}.entries){if(entry.value.text.trim().isNotEmpty)params[entry.key]=entry.value.text.trim();}
        for(final entry in filters.entries){if(entry.value.text.trim().isNotEmpty)params[entry.key]=entry.value.text.trim();}
        final query=Uri(queryParameters:params).query;
        final r=await widget.api.get('/user-profile/discover?'+query,authenticated:true);
        final raw=r['data']; final list=raw is Map?raw['items']:raw;
        final next=list is List?list.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
        items=next;
        totalPages=(raw is Map?(raw['totalPages'] as num?)?.toInt():null)??1;
        if(!_discoveryOptionsLoaded){
          await _loadDiscoveryOptions();_discoveryOptionsLoaded=true;
          try{final shortlist=await widget.api.get('/shortlists',authenticated:true);final values=shortlist['data'];if(values is List){shortlistedIds.addAll(values.whereType<Map>().map((x)=>(x['shortlistedUserId']??'').toString()).where((x)=>x.isNotEmpty));}}catch(_){}
        }
        await Future.wait(next.map((profile)async{
          final userId=(profile['userId']??profile['id']??'').toString();if(userId.isEmpty)return;
          try{final status=await widget.api.get('/interests/status/$userId',authenticated:true);if(status['data']!=null)interestStatuses[userId]=status['data'].toString();}catch(_){}
          try{discoveryAvatars[userId]=await widget.api.getBytes('/user-profile/$userId/primary-photo',authenticated:true);}catch(_){}
        }));
      } else if(widget.kind=='profile'){
        final r=await widget.api.get('/user-profile',authenticated:true); final raw=r['data'];
        if(raw is Map){data=Map<String,dynamic>.from(raw);a.text=data['firstName']?.toString()??'';b.text=data['lastName']?.toString()??'';c.text=data['dateOfBirth']?.toString().split('T').first??'';d.text=data['gender']?.toString()??'';e.text=data['aboutMe']?.toString()??'';}
      } else if(widget.kind=='preferences'){
        final results=await Future.wait([
          widget.api.get('/partner-preferences',authenticated:true),
          widget.api.get('/user-profile',authenticated:true).catchError((_) => <String,dynamic>{'data':null}),
        ]);
        final raw=results[0]['data'],profile=results[1]['data'];
        final ownGender=profile is Map?profile['gender']?.toString():'';
        final opposite=ownGender=='Male'?'Female':ownGender=='Female'?'Male':'';
        choice=raw is Map?(raw['preferredGender']?.toString()??opposite):opposite;
        if(raw is Map){data=Map<String,dynamic>.from(raw);marital=data['maritalStatus']?.toString()??'';
          final age=data['age'];if(age is Map){final min=(age['minAge'] as num?)?.toInt(),max=(age['maxAge'] as num?)?.toInt();a.text=min==21&&max==35?'':min?.toString()??'';b.text=min==21&&max==35?'':max?.toString()??'';}
          c.text=data['additionalRequirements']?.toString()??'';
          for(final group in ['height','community','career','location']){final value=data[group];if(value is Map){for(final entry in value.entries){if(prefFields.containsKey(entry.key))prefFields[entry.key]!.text=entry.value?.toString()??'';}}}final height=data['height'];if(height is Map){prefFields['minHeightFeet']!.text=height['minFeet']?.toString()??'';prefFields['minHeightInches']!.text=height['minInches']?.toString()??'';prefFields['maxHeightFeet']!.text=height['maxFeet']?.toString()??'';prefFields['maxHeightInches']!.text=height['maxInches']?.toString()??'';}}
        await _loadPreferenceOptions();
      } else if(widget.kind=='messages'){
        final r=await widget.api.get('/conversations',authenticated:true);final raw=r['data'];
        items=raw is List?raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];
      } else if(widget.kind=='support'){
        final r=await widget.api.get('/support/tickets',authenticated:true);final raw=r['data'];
        items=raw is List?raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];
      } else {
        final r=await Future.wait([widget.api.get('/subscription-plans',authenticated:true),widget.api.get('/subscription-plans/my-subscription',authenticated:true)]);
        final raw=r[0]['data'];items=raw is List?raw.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];
        final sub=r[1]['data'];data=sub is Map?Map<String,dynamic>.from(sub):{};
      }
    } catch(ex){error=ex.toString().replaceFirst('ApiException: ','');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> refresh() async { if(widget.kind=='discover'){discoverPage=1;} await load(); }
  Future<void> run(Future<void> Function() action) async {
    setState(() { working=true; error=null; notice=null; });
    try{await action();}
    catch(ex){if(mounted)setState(()=>error=ex.toString().replaceFirst('ApiException: ',''));}
    finally{if(mounted)setState(()=>working=false);}
  }
  Widget field(String label,TextEditingController controller,{int lines=1,TextInputType? keyboard})=>Padding(
    padding:const EdgeInsets.only(bottom:11),
    child:TextField(controller:controller,maxLines:lines,keyboardType:keyboard,decoration:InputDecoration(labelText:label,filled:true)));
  Widget panel(Widget child)=>Card(color:AppPalette.surface,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14),side:const BorderSide(color:AppPalette.border)),child:Padding(padding:const EdgeInsets.all(14),child:child));
  Widget button(String label,VoidCallback fn)=>SizedBox(width:double.infinity,child:FilledButton(onPressed:working?null:fn,child:working?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Text(label)));
  Widget get alerts=>Column(children:[if(error!=null)panel(Text(error!,style:const TextStyle(color:AppPalette.error))),if(notice!=null)panel(Text(notice!,style:const TextStyle(color:AppPalette.maroon)))]);
  @override Widget build(BuildContext context){
    if(loading)return const Center(child:CircularProgressIndicator(color:AppPalette.maroon));
    return RefreshIndicator(color:AppPalette.maroon,onRefresh:refresh,child:ListView(padding:const EdgeInsets.all(15),children:[
      Text(title,style:const TextStyle(fontSize:22,color:AppPalette.darkMaroon)),const SizedBox(height:9),alerts,
      if(widget.kind=='discover')...discover(),
      if(widget.kind=='profile')...profile(),
      if(widget.kind=='preferences')...preferences(),
      if(widget.kind=='messages')...messages(),
      if(widget.kind=='support')...support(),
      if(widget.kind=='plans')...plans(),
    ]));
  }
  Widget filterField(String label,String key,{bool numeric=false}){
    const ids={'religionId','casteId','subCasteId','educationFieldId','courseId','qualificationId','occupationId','professionId','countryId','stateId','cityId'};
    if(ids.contains(key)){
      final list=discoveryOptions[key]??const <Map<String,dynamic>>[];final current=int.tryParse(filters[key]!.text);final value=list.any((x)=>(x['id'] as num?)?.toInt()==current)?current:null;
      return SizedBox(width:150,child:DropdownButtonFormField<int>(initialValue:value,isExpanded:true,decoration:InputDecoration(labelText:label,filled:true,isDense:true),items:list.map((x)=>DropdownMenuItem<int>(value:(x['id'] as num).toInt(),child:Text(x['name'].toString(),overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>_changeDiscoverFilter(key,v?.toString())));
    }
    if(key=='motherTongue'){
      final list=discoveryOptions[key]??const <Map<String,dynamic>>[];final current=filters[key]!.text;
      return SizedBox(width:150,child:DropdownButtonFormField<String>(initialValue:list.any((x)=>x['name']?.toString()==current)?current:null,isExpanded:true,decoration:InputDecoration(labelText:label,filled:true,isDense:true),items:list.map((x)=>DropdownMenuItem<String>(value:x['name'].toString(),child:Text(x['name'].toString(),overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>_changeDiscoverFilter(key,v)));
    }
    if(key=='preferredGender'||key=='maritalStatus'){
      final choices=key=='preferredGender'?['Male','Female','Any']:['Never Married','Divorced','Widowed','Any'];
      final current=filters[key]!.text;return SizedBox(width:150,child:DropdownButtonFormField<String>(initialValue:choices.contains(current)?current:null,isExpanded:true,decoration:InputDecoration(labelText:label,filled:true,isDense:true),items:choices.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>_changeDiscoverFilter(key,v)));
    }
    return SizedBox(width:150,child:TextField(controller:filters[key],keyboardType:numeric?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:label,filled:true,isDense:true)));
  }
  Future<void> _loadSavedDiscoverPreferences({bool force=false})async{
    if(_discoverPreferencesLoaded&&!force)return;
    if(force){for(final controller in [a,b,c,...filters.values]){controller.clear();}}
    try{
      final results=await Future.wait([
        widget.api.get('/partner-preferences',authenticated:true),
        widget.api.get('/user-profile',authenticated:true).catchError((_) => <String,dynamic>{'data':null}),
      ]);
      final pref=results[0]['data'],profile=results[1]['data'];
      final ownGender=profile is Map?profile['gender']?.toString():'';
      final opposite=ownGender=='Male'?'Female':ownGender=='Female'?'Male':'';
      final values=pref is Map?Map<String,dynamic>.from(pref):<String,dynamic>{};
      filters['preferredGender']!.text=values['preferredGender']?.toString()??opposite;
      filters['maritalStatus']!.text=values['maritalStatus']?.toString()??'';
      final age=values['age'];
      if(age is Map){final min=(age['minAge'] as num?)?.toInt(),max=(age['maxAge'] as num?)?.toInt();if(!(min==21&&max==35)){b.text=min?.toString()??'';c.text=max?.toString()??'';}}
      final height=values['height'];
      if(height is Map){filters['minHeightFeet']!.text=height['minFeet']?.toString()??'';filters['minHeightInches']!.text=height['minInches']?.toString()??'';filters['maxHeightFeet']!.text=height['maxFeet']?.toString()??'';filters['maxHeightInches']!.text=height['maxInches']?.toString()??'';}
      final community=values['community'];
      if(community is Map){for(final key in ['religionId','casteId','subCasteId','motherTongue']){filters[key]!.text=community[key]?.toString()??'';}}
      final career=values['career'];
      if(career is Map){for(final key in ['educationFieldId','courseId','qualificationId','occupationId','professionId','workType','minYearlyIncome','maxYearlyIncome']){filters[key]!.text=career[key]?.toString()??'';}}
      final location=values['location'];
      if(location is Map){for(final key in ['countryId','stateId','cityId']){filters[key]!.text=location[key]?.toString()??'';}}
    }catch(_){}
    _discoverPreferencesLoaded=true;
  }
  Future<void> _fetchDiscoverOptions(String key,String path)async{
    try{final r=await widget.api.get(path,authenticated:true);final d=r['data'];discoveryOptions[key]=d is List?d.whereType<Map>().map((raw){final x=Map<String,dynamic>.from(raw);if(path.contains('/locations/countries'))return {'id':x['countryId'],'name':x['countryName']};if(path.contains('/locations/states'))return {'id':x['stateId'],'name':x['stateName']};if(path.contains('/locations/cities'))return {'id':x['cityId'],'name':x['cityName']};return x;}).toList():[];}catch(_){discoveryOptions[key]=[];}
  }
  Future<void> _loadDiscoveryOptions()async{
    for(final e in {'religionId':'/reference-data/religions','motherTongue':'/reference-data/mother-tongues','educationFieldId':'/reference-data/education-fields','qualificationId':'/reference-data/qualifications','occupationId':'/reference-data/occupations','countryId':'/locations/countries'}.entries){await _fetchDiscoverOptions(e.key,e.value);}
    final religion=int.tryParse(filters['religionId']!.text),caste=int.tryParse(filters['casteId']!.text),education=int.tryParse(filters['educationFieldId']!.text),occupation=int.tryParse(filters['occupationId']!.text),country=int.tryParse(filters['countryId']!.text),state=int.tryParse(filters['stateId']!.text);
    if(religion!=null)await _fetchDiscoverOptions('casteId','/reference-data/castes?religionId=$religion');
    if(caste!=null)await _fetchDiscoverOptions('subCasteId','/reference-data/sub-castes?casteId=$caste');
    if(education!=null)await _fetchDiscoverOptions('courseId','/reference-data/courses?educationFieldId=$education');
    if(occupation!=null)await _fetchDiscoverOptions('professionId','/reference-data/professions?occupationId=$occupation');
    if(country!=null)await _fetchDiscoverOptions('stateId','/locations/states?countryId=$country');
    if(state!=null)await _fetchDiscoverOptions('cityId','/locations/cities?stateId=$state');
  }
  Future<void> _changeDiscoverFilter(String key,String? value)async{
    filters[key]!.text=value??'';
    const clear={'religionId':['casteId','subCasteId'],'casteId':['subCasteId'],'educationFieldId':['courseId'],'occupationId':['professionId'],'countryId':['stateId','cityId'],'stateId':['cityId']};
    for(final child in clear[key]??const <String>[]){filters[child]!.clear();discoveryOptions[child]=[];}
    final id=int.tryParse(value??'');
    final next=<String,String>{'religionId':'casteId','casteId':'subCasteId','educationFieldId':'courseId','occupationId':'professionId','countryId':'stateId','stateId':'cityId'};
    final child=next[key];if(child!=null&&id!=null){final route=switch(key){'religionId'=>'/reference-data/castes?religionId=$id','casteId'=>'/reference-data/sub-castes?casteId=$id','educationFieldId'=>'/reference-data/courses?educationFieldId=$id','occupationId'=>'/reference-data/professions?occupationId=$id','countryId'=>'/locations/states?countryId=$id',_=>'/locations/cities?stateId=$id'};await _fetchDiscoverOptions(child,route);}
    if(mounted){setState((){});_discoverModalSetState?.call((){});}
  }
  String? validateDiscoverFilters(){
    final minAge=b.text.trim().isEmpty?null:int.tryParse(b.text.trim());
    final maxAge=c.text.trim().isEmpty?null:int.tryParse(c.text.trim());
    if(b.text.trim().isNotEmpty&&minAge==null||c.text.trim().isNotEmpty&&maxAge==null)return 'Enter valid minimum and maximum ages.';
    if((minAge!=null&&minAge<18)||(maxAge!=null&&maxAge<18))return 'Age must be 18 or above.';
    if(minAge!=null&&maxAge!=null&&minAge>maxAge)return 'Minimum age cannot exceed maximum age.';
    final minIncome=filters['minYearlyIncome']!.text.trim().isEmpty?null:num.tryParse(filters['minYearlyIncome']!.text.trim());
    final maxIncome=filters['maxYearlyIncome']!.text.trim().isEmpty?null:num.tryParse(filters['maxYearlyIncome']!.text.trim());
    if(filters['minYearlyIncome']!.text.trim().isNotEmpty&&minIncome==null||filters['maxYearlyIncome']!.text.trim().isNotEmpty&&maxIncome==null)return 'Enter valid yearly income values.';
    if(minIncome!=null&&maxIncome!=null&&minIncome>maxIncome)return 'Minimum income cannot exceed maximum income.';
    int? feet(String key)=>filters[key]!.text.trim().isEmpty?null:int.tryParse(filters[key]!.text.trim());
    int? inches(String key)=>filters[key]!.text.trim().isEmpty?null:int.tryParse(filters[key]!.text.trim());
    for(final key in ['minHeightFeet','maxHeightFeet']){final value=feet(key);if(filters[key]!.text.trim().isNotEmpty&&(value==null||value<4||value>7))return 'Height in feet must be between 4 and 7.';}
    for(final key in ['minHeightInches','maxHeightInches']){final value=inches(key);if(filters[key]!.text.trim().isNotEmpty&&(value==null||value<0||value>11))return 'Height inches must be between 0 and 11.';}
    final minTotal=feet('minHeightFeet')==null?null:feet('minHeightFeet')!*12+(inches('minHeightInches')??0);
    final maxTotal=feet('maxHeightFeet')==null?null:feet('maxHeightFeet')!*12+(inches('maxHeightInches')??0);
    if(minTotal!=null&&maxTotal!=null&&minTotal>maxTotal)return 'Minimum height cannot exceed maximum height.';
    return null;
  }
  Future<void> clearDiscoverFilters()async{
    for(final controller in [a,b,c,...filters.values]){controller.clear();}
    filterValidationError=null;discoverPage=1;items=[];await load();
  }
  int get activeDiscoverFilterCount=>[a,b,c,...filters.values].where((x)=>x.text.trim().isNotEmpty).length;
  Future<void> openDiscoverFilters()async{
    filterValidationError=null;
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,backgroundColor:AppPalette.background,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModalState){
      _discoverModalSetState=setModalState;
      return Padding(padding:EdgeInsets.fromLTRB(16,16,16,MediaQuery.of(ctx).viewInsets.bottom+16),child:SizedBox(height:MediaQuery.of(ctx).size.height*.82,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Expanded(child:Text('Filter matches',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close))]),
        Expanded(child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          field('Name or keyword',a),
          Row(children:[Expanded(child:field('Minimum age',b,keyboard:TextInputType.number)),const SizedBox(width:8),Expanded(child:field('Maximum age',c,keyboard:TextInputType.number))]),
          const Text('Religion & community',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
          Wrap(spacing:8,runSpacing:8,children:[filterField('Religion','religionId'),filterField('Caste','casteId'),filterField('Sub-caste','subCasteId'),filterField('Mother tongue','motherTongue')]),
          const SizedBox(height:10),const Text('Personal preferences',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
          Wrap(spacing:8,runSpacing:8,children:[filterField('Preferred gender','preferredGender'),filterField('Marital status','maritalStatus'),filterField('Min height feet','minHeightFeet',numeric:true),filterField('Min height inches','minHeightInches',numeric:true),filterField('Max height feet','maxHeightFeet',numeric:true),filterField('Max height inches','maxHeightInches',numeric:true)]),
          const SizedBox(height:10),const Text('Education & career',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
          Wrap(spacing:8,runSpacing:8,children:[filterField('Education field','educationFieldId'),filterField('Course','courseId'),filterField('Qualification','qualificationId'),filterField('Occupation','occupationId'),filterField('Profession','professionId'),filterField('Education','education'),filterField('Profession text','profession'),filterField('Work type','workType'),filterField('Min yearly income','minYearlyIncome',numeric:true),filterField('Max yearly income','maxYearlyIncome',numeric:true)]),
          TextButton.icon(onPressed:()async{await _loadSavedDiscoverPreferences(force:true);setModalState((){});},icon:const Icon(Icons.refresh),label:const Text('Use saved preferences')),
          const SizedBox(height:10),const Text('Location',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
          Wrap(spacing:8,runSpacing:8,children:[filterField('Country','countryId'),filterField('State','stateId'),filterField('City','cityId')]),
        ]))),
        if(filterValidationError!=null)Padding(padding:const EdgeInsets.only(bottom:8),child:Text(filterValidationError!,style:const TextStyle(color:AppPalette.error))),
        Row(children:[
          Expanded(child:OutlinedButton(onPressed:(){Navigator.pop(ctx);clearDiscoverFilters();},child:const Text('Clear all'))),
          const SizedBox(width:10),
          Expanded(child:FilledButton(onPressed:(){final issue=validateDiscoverFilters();if(issue!=null){setModalState(()=>filterValidationError=issue);return;}Navigator.pop(ctx);discoverPage=1;load();},child:const Text('Apply filters'))),
        ]),
      ])));
    }));
    _discoverModalSetState=null;
  }
  List<Widget> discover()=>[
    panel(Row(children:[
      const Expanded(child:Text('Find profiles that match your preferences.',style:TextStyle(color:AppPalette.secondary))),
      OutlinedButton.icon(onPressed:working?null:openDiscoverFilters,icon:const Icon(Icons.tune),label:Text(activeDiscoverFilterCount==0?'Filters':'Filters ($activeDiscoverFilterCount)')),
    ])),
    if(items.isEmpty)panel(const Text('No profiles found. Complete your profile and try again.')),
    if(totalPages>1)Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      OutlinedButton(onPressed:working||discoverPage<=1?null:(){discoverPage--;load();},child:const Text('Previous')),
      Text('Page $discoverPage of $totalPages',style:const TextStyle(color:AppPalette.secondary)),
      FilledButton(onPressed:working||discoverPage>=totalPages?null:(){discoverPage++;load();},child:const Text('Next')),
    ]),
    ...items.map((p){
       final id=(p['userId']??p['id']??'').toString();
       final name=(''+(p['firstName']??'').toString()+' '+(p['lastName']??'').toString()).trim();
       final details=[p['profession'],p['education'],p['cityName'],p['religionName'],p['casteName']].where((x)=>x!=null&&x.toString().isNotEmpty).join(' · ');
       final status=interestStatuses[id]??'';final avatar=discoveryAvatars[id];
       return Padding(padding:const EdgeInsets.only(bottom:9),child:panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
         Row(children:[CircleAvatar(radius:25,backgroundColor:AppPalette.champagne,backgroundImage:avatar==null?null:MemoryImage(avatar),child:avatar==null?const Icon(Icons.person,color:AppPalette.maroon):null),const SizedBox(width:10),Expanded(child:Text(name.isEmpty?'VedicVivah member':name,style:const TextStyle(fontWeight:FontWeight.w700,color:AppPalette.darkMaroon,fontSize:16)))]),
         if(details.isNotEmpty)Text(details,style:const TextStyle(color:AppPalette.secondary,fontSize:12)),
         if((p['aboutMe']??'').toString().isNotEmpty)Text(p['aboutMe'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),
         TextButton.icon(onPressed:working||id.isEmpty?null:()=>_viewProfile(id),icon:const Icon(Icons.person_search),label:const Text('View full profile')),
         Row(children:[
           Expanded(child:TextButton(onPressed:working||id.isEmpty?null:()=>_toggleShortlist(id),child:Text(shortlistedIds.contains(id)?'Remove shortlist':'Shortlist'))),
           Expanded(child:FilledButton(onPressed:working||id.isEmpty||status=='Pending'||status=='Accepted'?null:()=>_sendInterest(id,name),child:Text(status=='Accepted'?'Connected':status=='Pending'?'Interest sent':'Send interest'))),
         ]),
         Wrap(spacing:8,children:[
           TextButton(onPressed:working||id.isEmpty?null:()=>_report(id),child:const Text('Report')),
           TextButton(onPressed:working||id.isEmpty?null:()=>_block(id),child:const Text('Block')),
         ]),
       ])));
     }),
  ];
  Future<void> _viewProfile(String userId) async {
    try{
      setState(()=>working=true);
      final response=await widget.api.get('/user-profile/$userId',authenticated:true);
      final p=response['data'] is Map?Map<String,dynamic>.from(response['data']):<String,dynamic>{};
      var accepted=false;
      try{final status=await widget.api.get('/interests/status/$userId',authenticated:true);accepted=status['data']?.toString()=='Accepted';}catch(_){}
      final photoBytes=<Uint8List>[];
      if(accepted){
        try{
          final photoResponse=await widget.api.get('/user-profile/$userId/photos',authenticated:true);
          final list=photoResponse['data'];
          if(list is List){
            for(final item in list.whereType<Map>()){
              final photoId=item['id']?.toString()??'';
              if(photoId.isEmpty)continue;
              try{photoBytes.add(await widget.api.getBytes('/user-profile/$userId/photos/$photoId/content',authenticated:true));}catch(_){}
            }
          }
        }catch(_){}
      }
      if(!mounted)return;
      final dob=DateTime.tryParse(p['dateOfBirth']?.toString()??'');
      String age='';if(dob!=null){final now=DateTime.now();var years=now.year-dob.year;if(now.month<dob.month||(now.month==dob.month&&now.day<dob.day))years--;age='$years years';}
      await showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:SizedBox(height:MediaQuery.of(ctx).size.height*.82,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${p['firstName']??'VedicVivah'} ${p['lastName']??'member'}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),
        const SizedBox(height:10),
        Expanded(child:ListView(children:[
          if(photoBytes.isNotEmpty)SizedBox(height:190,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:photoBytes.length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(context,index)=>ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.memory(photoBytes[index],width:150,height:180,fit:BoxFit.cover)))),
          if(accepted&&photoBytes.isEmpty)const Text('No profile photos available.'),
          if(!accepted)const Text('Profile photos become available after the interest is accepted.',style:TextStyle(color:AppPalette.secondary)),
          ...<String,String>{'Age':age,'Gender':p['gender']?.toString()??'','Time of birth':p['timeOfBirth']?.toString()??'','Birth place':p['birthPlace']?.toString()??'','Disability':p['disabilityStatus']==true?'Yes':'No','Disability details':p['disabilityDetails']?.toString()??'','Religion':p['religionName']?.toString()??'','Caste':p['casteName']?.toString()??'','Sub-caste':p['subCasteName']?.toString()??'','Mother tongue':p['motherTongue']?.toString()??'','Education':p['education']?.toString()??'','Course':p['course']?.toString()??'','Qualification':p['qualification']?.toString()??'','Occupation':p['occupation']?.toString()??'','Profession':p['profession']?.toString()??'','Work type':p['workType']?.toString()??'','Yearly income':p['yearlyIncome']?.toString()??'','Height':p['heightFeet']==null?'':'${p['heightFeet']} ft ${p['heightInches']??0} in','Weight':p['weight']?.toString()??'','Marital status':p['maritalStatus']?.toString()??'','Father':p['fatherName']?.toString()??'','Mother':p['motherName']?.toString()??'','Brother':p['brother']?.toString()??'','Sister':p['sister']?.toString()??'','Married brothers':p['marriedBrotherCount']?.toString()??'','Married sisters':p['marriedSisterCount']?.toString()??'','Nanaji':p['nanajiName']?.toString()??'','Mosal surname':p['mosalSurname']?.toString()??'','Country':p['countryName']?.toString()??'','State':p['stateName']?.toString()??'','Location':p['cityName']?.toString()??'','Pin code':p['pinCode']?.toString()??'','Native place':p['nativePlace']?.toString()??'','Area':p['area']?.toString()??'','Residence type':p['residenceType']?.toString()??'','Area (sq.ft.)':p['areaInSqFt']?.toString()??'','Rooms':p['roomCount']?.toString()??'','About':p['aboutMe']?.toString()??''}.entries.where((e)=>e.value.isNotEmpty).map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Text('${e.key}: ${e.value}'))),
        ])),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))),
      ])))));
    }catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('ApiException: ',''));}
    finally{if(mounted)setState(()=>working=false);}
  }
  Future<void> _toggleShortlist(String userId)async{
    await run(()async{
      if(shortlistedIds.contains(userId)){await widget.api.delete('/shortlists/$userId',authenticated:true);shortlistedIds.remove(userId);setState(()=>notice='Profile removed from shortlist.');}
      else{await widget.api.post('/shortlists/$userId',body:{},authenticated:true);shortlistedIds.add(userId);setState(()=>notice='Profile added to shortlist.');}
    });
  }
  Future<void> _sendInterest(String userId,String displayName)async{
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Send interest?'),content:Text('Send an interest to $displayName?'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Send interest'))]));
    if(confirmed!=true)return;
    await run(()async{await widget.api.post('/interests/$userId',body:{},authenticated:true);interestStatuses[userId]='Pending';setState(()=>notice='Interest sent successfully.');});
  }
  Future<void> _report(String userId) async {
    final reason=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Report profile'),content:TextField(controller:reason,maxLength:2000,maxLines:4,decoration:const InputDecoration(hintText:'Describe the issue in detail (at least 10 characters).')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Submit report'))]));
    if(ok==true){
      await run(()async{final value=reason.text.trim();if(value.length<10)throw Exception('Please provide at least 10 characters of detail.');await widget.api.post('/reports/'+userId,body:{'reason':value},authenticated:true);setState(()=>notice='Report submitted.');});
    }
    reason.dispose();
  }
  Future<void> _block(String userId) async {
    const reasons=['Not interested','Inappropriate content','Harassment or abusive behavior','Fake or suspicious profile','Other'];
    String selected=reasons.first;
    final reason=await showDialog<String>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(title:const Text('Block profile'),content:Column(mainAxisSize:MainAxisSize.min,children:[const Text('You will no longer see this profile in your matches.'),const SizedBox(height:12),DropdownButtonFormField<String>(value:selected,decoration:const InputDecoration(labelText:'Reason',filled:true),items:reasons.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setDialog(()=>selected=v??selected))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,selected),child:const Text('Block'))])));
    if(reason==null)return;
    await run(()async{await widget.api.post('/blocks/'+userId,body:{'reason':reason},authenticated:true);setState(()=>notice='Profile blocked.');await load();});
  }
  List<Widget> profile()=>[
    panel(Column(children:[
      field('First name',a),field('Last name',b),field('Date of birth (YYYY-MM-DD)',c),field('Gender',d),field('About me',e,lines:4),
      button('Save personal information',()=>run(()async{
        final r=await widget.api.patch('/user-profile/personal',body:{'personal':{'firstName':a.text.trim(),'lastName':b.text.trim().isEmpty?null:b.text.trim(),'dateOfBirth':c.text.trim(),'gender':d.text.trim(),'timeOfBirth':data['timeOfBirth'],'birthPlace':data['birthPlace'],'birthCountryId':data['birthCountryId'],'birthStateId':data['birthStateId'],'birthCityId':data['birthCityId'],'disabilityStatus':data['disabilityStatus']??false,'disabilityDetails':data['disabilityDetails']},'physical':null,'rowVersion':data['rowVersion']},authenticated:true);
        if(r['success']==false)throw Exception(r['message']??'Unable to save.');
        setState(()=>notice='Personal information saved.');await load();
      })),
      const SizedBox(height:8),
      button('Save About Me',()=>run(()async{await widget.api.patch('/user-profile/about',body:{'aboutMe':e.text.trim(),'rowVersion':data['rowVersion']},authenticated:true);setState(()=>notice='About Me saved.');await load();})),
      const SizedBox(height:8),
      Text('Profile status: '+(data['approvalStatus']??'Unknown').toString()),
      Text('Visibility: '+(data['visibilityStatus']??'Unknown').toString()),
      Wrap(spacing:8,children:[
        OutlinedButton(onPressed:working?null:()=>run(()async{await widget.api.patch('/user-profile/visibility',body:{'status':'Visible'},authenticated:true);setState(()=>notice='Profile visible.');await load();}),child:const Text('Visible')),
        OutlinedButton(onPressed:working?null:()=>run(()async{await widget.api.patch('/user-profile/visibility',body:{'status':'Hidden'},authenticated:true);setState(()=>notice='Profile hidden.');await load();}),child:const Text('Hidden')),
      ]),
      button('Submit for review',()=>run(()async{await widget.api.post('/user-profile/submit-for-review',body:{},authenticated:true);setState(()=>notice='Profile submitted for review.');await load();})),
    ])),
  ];
  Widget prefField(String label,String key){
    if(key=='motherTongue'){
      final list=prefOptions[key]??const <Map<String,dynamic>>[];final current=prefFields[key]!.text;
      return Padding(padding:const EdgeInsets.only(bottom:8),child:DropdownButtonFormField<String>(initialValue:list.any((x)=>x['name']?.toString()==current)?current:null,isExpanded:true,decoration:InputDecoration(labelText:label,filled:true),items:list.map((x)=>DropdownMenuItem<String>(value:x['name'].toString(),child:Text(x['name'].toString(),overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>setState(()=>prefFields[key]!.text=v??'')));
    }
    const ids={'religionId','casteId','subCasteId','educationFieldId','courseId','qualificationId','occupationId','professionId','countryId','stateId','cityId'};
    if(!ids.contains(key))return Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:prefFields[key],keyboardType:key.contains('Income')?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,decoration:InputDecoration(labelText:label,filled:true)));
    final list=prefOptions[key]??const <Map<String,dynamic>>[];final current=int.tryParse(prefFields[key]!.text);final value=list.any((x)=>(x['id'] as num?)?.toInt()==current)?current:null;
    return Padding(padding:const EdgeInsets.only(bottom:8),child:DropdownButtonFormField<int>(initialValue:value,isExpanded:true,decoration:InputDecoration(labelText:label,filled:true),items:list.map((x)=>DropdownMenuItem<int>(value:(x['id'] as num).toInt(),child:Text(x['name'].toString(),overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>_changePreferenceOption(key,v)));
  }
  Future<void> _fetchPrefOptions(String key,String path)async{
    try{final r=await widget.api.get(path,authenticated:true);final d=r['data'];prefOptions[key]=d is List?d.whereType<Map>().map((raw){final x=Map<String,dynamic>.from(raw);if(path.contains('/locations/countries'))return {'id':x['countryId'],'name':x['countryName']};if(path.contains('/locations/states'))return {'id':x['stateId'],'name':x['stateName']};if(path.contains('/locations/cities'))return {'id':x['cityId'],'name':x['cityName']};return x;}).toList():[];}catch(_){prefOptions[key]=[];}
  }
  Future<void> _loadPreferenceOptions()async{
    final base=<String,String>{'religionId':'/reference-data/religions','motherTongue':'/reference-data/mother-tongues','qualificationId':'/reference-data/qualifications','educationFieldId':'/reference-data/education-fields','occupationId':'/reference-data/occupations','countryId':'/locations/countries'};
    for(final e in base.entries){await _fetchPrefOptions(e.key,e.value);}
    final religion=int.tryParse(prefFields['religionId']!.text),caste=int.tryParse(prefFields['casteId']!.text),education=int.tryParse(prefFields['educationFieldId']!.text),occupation=int.tryParse(prefFields['occupationId']!.text),country=int.tryParse(prefFields['countryId']!.text),state=int.tryParse(prefFields['stateId']!.text);
    if(religion!=null)await _fetchPrefOptions('casteId','/reference-data/castes?religionId=$religion');
    if(caste!=null)await _fetchPrefOptions('subCasteId','/reference-data/sub-castes?casteId=$caste');
    if(education!=null)await _fetchPrefOptions('courseId','/reference-data/courses?educationFieldId=$education');
    if(occupation!=null)await _fetchPrefOptions('professionId','/reference-data/professions?occupationId=$occupation');
    if(country!=null)await _fetchPrefOptions('stateId','/locations/states?countryId=$country');
    if(state!=null)await _fetchPrefOptions('cityId','/locations/cities?stateId=$state');
  }
  Future<void> _changePreferenceOption(String key,int? value)async{
    prefFields[key]!.text=value?.toString()??'';
    const clearChildren={'religionId':['casteId','subCasteId'],'casteId':['subCasteId'],'educationFieldId':['courseId'],'occupationId':['professionId'],'countryId':['stateId','cityId'],'stateId':['cityId']};
    for(final child in clearChildren[key]??const <String>[]){prefFields[child]!.clear();prefOptions[child]=[];}
    final next=<String,String>{'religionId':'casteId','casteId':'subCasteId','educationFieldId':'courseId','occupationId':'professionId','countryId':'stateId','stateId':'cityId'};
    final child=next[key];if(child!=null&&value!=null){final route=switch(key){'religionId'=>'/reference-data/castes?religionId=$value','casteId'=>'/reference-data/sub-castes?casteId=$value','educationFieldId'=>'/reference-data/courses?educationFieldId=$value','occupationId'=>'/reference-data/professions?occupationId=$value','countryId'=>'/locations/states?countryId=$value',_=>'/locations/cities?stateId=$value'};await _fetchPrefOptions(child,route);}
    if(mounted)setState((){});
  }
  List<Widget> preferences()=>[
    panel(Column(children:[
Align(alignment:Alignment.centerLeft,child:Text('Match gender: ${choice.isEmpty?'All members':'${choice} profiles'}',style:const TextStyle(color:AppPalette.secondary))),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(initialValue:marital,decoration:const InputDecoration(labelText:'Preferred marital status'),items:const [
        DropdownMenuItem(value:'',child:Text('Any status')),
        DropdownMenuItem(value:'Never Married',child:Text('Never Married')),
        DropdownMenuItem(value:'Divorced',child:Text('Divorced')),
        DropdownMenuItem(value:'Widowed',child:Text('Widowed')),
        DropdownMenuItem(value:'Awaiting Divorce',child:Text('Awaiting Divorce')),
      ],onChanged:(x)=>setState(()=>marital=x??'')),
      const SizedBox(height:10),field('Minimum age',a,keyboard:TextInputType.number),field('Maximum age',b,keyboard:TextInputType.number),field('Additional requirements',c,lines:3),
      const Divider(),const Align(alignment:Alignment.centerLeft,child:Text('Height range',style:TextStyle(fontWeight:FontWeight.w700))),
      prefField('Minimum height (feet)','minHeightFeet'),prefField('Minimum height (inches)','minHeightInches'),prefField('Maximum height (feet)','maxHeightFeet'),prefField('Maximum height (inches)','maxHeightInches'),
      const Divider(),const Align(alignment:Alignment.centerLeft,child:Text('Community preferences',style:TextStyle(fontWeight:FontWeight.w700))),
      prefField('Religion ID','religionId'),prefField('Caste ID','casteId'),prefField('Sub-caste ID','subCasteId'),prefField('Mother tongue','motherTongue'),
      const Divider(),const Align(alignment:Alignment.centerLeft,child:Text('Education & career preferences',style:TextStyle(fontWeight:FontWeight.w700))),
      prefField('Education field ID','educationFieldId'),prefField('Course ID','courseId'),prefField('Qualification ID','qualificationId'),prefField('Occupation ID','occupationId'),prefField('Profession ID','professionId'),prefField('Work type','workType'),prefField('Minimum yearly income','minYearlyIncome'),prefField('Maximum yearly income','maxYearlyIncome'),
      const Divider(),const Align(alignment:Alignment.centerLeft,child:Text('Location preferences',style:TextStyle(fontWeight:FontWeight.w700))),
      prefField('Country ID','countryId'),prefField('State ID','stateId'),prefField('City ID','cityId'),
      button('Save preferences',()=>run(()async{
        final lo=int.tryParse(a.text),hi=int.tryParse(b.text);
        if(lo!=null&&hi!=null&&lo>hi)throw Exception('Minimum partner age cannot exceed maximum age.');
        if((lo!=null&&lo<18)||(hi!=null&&hi<18))throw Exception('Minimum partner age is 18.');
        final minIncome=num.tryParse(prefFields['minYearlyIncome']!.text),maxIncome=num.tryParse(prefFields['maxYearlyIncome']!.text);
        if(minIncome!=null&&maxIncome!=null&&minIncome>maxIncome)throw Exception('Minimum income cannot exceed maximum income.');
        for(final key in ['minHeightFeet','maxHeightFeet']){final value=int.tryParse(prefFields[key]!.text);if(value!=null&&(value<4||value>7))throw Exception('Height in feet must be between 4 and 7.');}
        for(final key in ['minHeightInches','maxHeightInches']){final value=int.tryParse(prefFields[key]!.text);if(value!=null&&(value<0||value>11))throw Exception('Height inches must be between 0 and 11.');}
        await widget.api.put('/partner-preferences',body:{
          'preferredGender':choice.isEmpty?null:choice,'maritalStatus':marital.isEmpty?null:marital,'additionalRequirements':c.text.trim().isEmpty?null:c.text.trim(),'rowVersion':data['rowVersion'],
          'age':{'minAge':lo,'maxAge':hi},
          'height':{'minFeet':int.tryParse(prefFields['minHeightFeet']!.text),'minInches':int.tryParse(prefFields['minHeightInches']!.text),'maxFeet':int.tryParse(prefFields['maxHeightFeet']!.text),'maxInches':int.tryParse(prefFields['maxHeightInches']!.text)},
          'community':{'religionId':int.tryParse(prefFields['religionId']!.text),'casteId':int.tryParse(prefFields['casteId']!.text),'subCasteId':int.tryParse(prefFields['subCasteId']!.text),'motherTongue':prefFields['motherTongue']!.text.trim().isEmpty?null:prefFields['motherTongue']!.text.trim()},
          'career':{'educationFieldId':int.tryParse(prefFields['educationFieldId']!.text),'courseId':int.tryParse(prefFields['courseId']!.text),'qualificationId':int.tryParse(prefFields['qualificationId']!.text),'occupationId':int.tryParse(prefFields['occupationId']!.text),'professionId':int.tryParse(prefFields['professionId']!.text),'workType':prefFields['workType']!.text.trim().isEmpty?null:prefFields['workType']!.text.trim(),'minYearlyIncome':minIncome,'maxYearlyIncome':maxIncome},
          'location':{'countryId':int.tryParse(prefFields['countryId']!.text),'stateId':int.tryParse(prefFields['stateId']!.text),'cityId':int.tryParse(prefFields['cityId']!.text)},
        },authenticated:true);
        setState(()=>notice='Partner preferences saved.');await load();
      })),
    ])),
    panel(const Text('Existing advanced community, career, height and location preference values are retained when saving this form.',style:TextStyle(color:AppPalette.secondary,fontSize:12))),
  ];
  Future<void> searchConnections()async{
    if(!mounted)return;
    if(b.text.trim().isEmpty){setState(()=>connections=[]);return;}
    try{
      final r=await widget.api.get('/interests/connections/search?q='+Uri.encodeQueryComponent(b.text.trim()),authenticated:true);
      if(!mounted)return;
      final d=r['data'];
      setState(()=>connections=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[]);
    }catch(e){
      if(mounted)setState(()=>error=e.toString());
    }
  }
  Future<void> startChat(Map<String,dynamic> user)async{final userId=(user['userId']??'').toString();if(userId.isEmpty)return;await run(()async{await widget.api.post('/conversations/$userId',body:{},authenticated:true);await load();});}
  List<Widget> messages()=>[
    field('Search conversations',a),
    panel(Column(children:[field('Search accepted connections',b),button('Find connections',searchConnections)])),
    ...connections.map((u)=>panel(ListTile(title:Text('${u['firstName']??''} ${u['lastName']??''}'),subtitle:Text([u['profession'],u['cityName']].where((x)=>x!=null&&x.toString().isNotEmpty).join(' · ')),trailing:TextButton(onPressed:working?null:()=>startChat(u),child:const Text('Message'))))),
    if(items.where((c)=>(c['otherUserName']??'').toString().toLowerCase().contains(a.text.toLowerCase())).isEmpty)panel(const Text('No conversations found.')),
    ...items.where((c)=>(c['otherUserName']??'').toString().toLowerCase().contains(a.text.toLowerCase())).map((c)=>panel(ListTile(onTap:()=>openConversation(c),leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(c['otherUserName']?.toString()??'Member'),subtitle:Text(c['lastMessage']?.toString()??''),trailing:Row(mainAxisSize:MainAxisSize.min,children:[if(((c['unreadCount'] as num?)?.toInt()??0)>0)CircleAvatar(radius:11,backgroundColor:AppPalette.maroon,child:Text((c['unreadCount'] as num).toInt().toString(),style:const TextStyle(color:Colors.white,fontSize:10))),PopupMenuButton<String>(onSelected:(v)=>deleteConversation(c['id'].toString()),itemBuilder:(_)=>const [PopupMenuItem(value:'delete',child:Text('Delete conversation'))])])))),
  ];
  Future<void> deleteConversation(String id)async{
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Delete conversation?'),content:const Text('This removes the conversation from your inbox.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete'))]));
    if(yes!=true)return;
    await run(()async{await widget.api.delete('/conversations/$id',authenticated:true);await load();});
  }
  Future<void> openConversation(Map<String,dynamic> c)async{
    await showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>_ConversationSheet(api:widget.api,conversation:c));
    if(mounted)await load();
  }
  List<Widget> support()=>[
    panel(Column(children:[
      field('Describe your question or issue',a,lines:4),
      button('Send query',()=>run(()async{if(a.text.trim().isEmpty)throw Exception('Please enter your query.');await widget.api.post('/support/tickets',body:{'message':a.text.trim()},authenticated:true);a.clear();setState(()=>notice='Your query has been sent.');await load();})),
    ])),
    const Text('My queries',style:TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),
    if(items.isEmpty)panel(const Text('No queries yet.')),
    ...items.map((t)=>panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t['status']?.toString()??'Open',style:const TextStyle(color:AppPalette.gold,fontWeight:FontWeight.w700)),Text(t['message']?.toString()??''),if(t['adminReply']!=null)Text('Admin reply: '+t['adminReply'].toString())]))),
  ];
  String _dateLabel(dynamic raw){final date=DateTime.tryParse(raw?.toString()??'');if(date==null)return 'Not available';return '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}';}
  List<Widget> plans()=>[
    panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(data.isEmpty?'No current subscription.':'Current plan: ${data['planName']??'Free'} · ${data['isExpired']==true?'Expired':'Active'}',style:const TextStyle(fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),
      if(data['expiresAtUtc']!=null)Text('Expires: ${_dateLabel(data['expiresAtUtc'])}'),
      if(data['expiresAtUtc']!=null&&data['isExpired']!=true)Text('${DateTime.tryParse(data['expiresAtUtc'].toString())?.difference(DateTime.now()).inDays.clamp(0,9999)??0} days remaining'),
    ])),
    if(items.isEmpty)panel(const Text('No active plans are currently available.')),
    ...items.map((p)=>panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(p['name']?.toString()??'Plan',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),
      Text('₹'+(p['price']??'').toString()+' / '+(p['durationMonths']??'').toString()+' months',style:const TextStyle(color:AppPalette.gold,fontWeight:FontWeight.w700)),
      Text(p['shortDescription']?.toString()??''),
      if((p['description']??'').toString().trim().isNotEmpty)Text(p['description'].toString()),
      if(p['features'] is List)...(p['features'] as List).map((f)=>Text('• '+f.toString())),
      const Text('Payment gateway is not available in the current Web User Panel. Contact Support to activate a plan.',style:TextStyle(fontSize:12,color:AppPalette.secondary)),
    ]))),
  ];
}

class _ConversationSheet extends StatefulWidget {
  const _ConversationSheet({required this.api,required this.conversation});
  final ApiClient api;final Map<String,dynamic> conversation;
  @override State<_ConversationSheet> createState()=>_ConversationSheetState();
}
class _ConversationSheetState extends State<_ConversationSheet>{
  bool loading=true,sending=false;List<Map<String,dynamic>> messages=[];final text=TextEditingController();String? error;late final ChatRealtimeService realtime;
  String get id=>widget.conversation['id'].toString();
  @override void initState(){
    super.initState();
    realtime=ChatRealtimeService(api:widget.api,onMessage:_onRealtimeMessage,onMessageDeleted:_onRealtimeDelete);
    load();
    _connectRealtime();
  }
  @override void dispose(){unawaited(realtime.dispose());text.dispose();super.dispose();}
  Future<void> _connectRealtime()async{
    try{
      await realtime.connect();
      await realtime.joinConversation(id);
    }catch(e){
      if(mounted)setState(()=>error='Live chat is unavailable right now. You can still send messages; reopen the conversation to reconnect.');
    }
  }
  Future<void> _markConversationRead()async{
    try{
      await widget.api.put('/conversations/$id/read',body:{},authenticated:true);
    }catch(e){
      if(mounted)setState(()=>error='Message received, but the read status could not be updated.');
    }
  }
  void _onRealtimeMessage(Map<String,dynamic> message){
    if(message['conversationId']?.toString()!=id||!mounted)return;
    setState(() {
      if(!messages.any((m)=>m['id']==message['id']))messages.add(message);
    });
    unawaited(_markConversationRead());
  }
  void _onRealtimeDelete(String messageId,String conversationId){if(conversationId!=id||!mounted)return;setState(()=>messages.removeWhere((m)=>m['id']?.toString()==messageId));}
  Future<void> load()async{try{final r=await widget.api.get('/conversations/'+id+'/messages?take=50',authenticated:true);final d=r['data'];messages=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];await widget.api.put('/conversations/'+id+'/read',body:{},authenticated:true);}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> loadOlder()async{
    if(messages.isEmpty)return;
    final before=messages.first['id']?.toString();if(before==null)return;
    try{final r=await widget.api.get('/conversations/$id/messages?take=50&before=$before',authenticated:true);final d=r['data'];final older=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];if(mounted)setState(()=>messages=[...older,...messages]);}
    catch(e){if(mounted)setState(()=>error=e.toString());}
  }
  Future<void> send()async{
    if(!mounted||text.text.trim().isEmpty)return;
    setState(()=>sending=true);
    try{
      await widget.api.post('/conversations/'+id+'/messages',body:{'content':text.text.trim()},authenticated:true);
      if(!mounted)return;
      text.clear();
      await load();
    }catch(e){
      if(mounted)setState(()=>error=e.toString());
    }finally{
      if(mounted)setState(()=>sending=false);
    }
  }
  Future<void> deleteMessage(String messageId)async{try{await widget.api.delete('/conversations/$id/messages/$messageId',authenticated:true);await load();}catch(e){if(mounted)setState(()=>error=e.toString());}}
  bool isOwnMessage(Map<String,dynamic> message)=>message['senderUserId']?.toString()==SessionStore.instance.current?.userId;
  @override Widget build(BuildContext context)=>SafeArea(child:SizedBox(height:MediaQuery.of(context).size.height*.8,child:Column(children:[
    ListTile(title:Text(widget.conversation['otherUserName']?.toString()??'Conversation'),trailing:IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close))),
    if(error!=null)Text(error!,style:const TextStyle(color:AppPalette.error)),
    if(messages.length>=50)TextButton(onPressed:loading?null:loadOlder,child:const Text('Load older messages')),
    Expanded(child:loading?const Center(child:CircularProgressIndicator()):ListView(reverse:true,padding:const EdgeInsets.all(12),children:messages.reversed.map((m)=>GestureDetector(onLongPress:isOwnMessage(m)?()=>deleteMessage(m['id'].toString()):null,child:Card(color:AppPalette.surface,child:Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(m['senderUserName']?.toString()??'',style:const TextStyle(fontSize:11,color:AppPalette.gold)),Text(m['content']?.toString()??''),if(isOwnMessage(m))const Text('Long press to delete your message',style:TextStyle(fontSize:9,color:AppPalette.secondary))]))))).toList())),
    Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:text,decoration:const InputDecoration(hintText:'Write a message'))),IconButton(onPressed:sending?null:send,icon:const Icon(Icons.send,color:AppPalette.maroon))])),
  ])));
}
