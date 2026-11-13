import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import 'user_photos_screen.dart';
import '../../../../core/storage/session_store.dart';
import 'user_contacts_mentor_screen.dart';
import 'user_profile_editor_screen.dart';
import '../../data/chat_realtime_service.dart';

class UserWorkspaceScreen extends StatefulWidget {
  const UserWorkspaceScreen({super.key, required this.apiClient, this.initialTab = 0});
  final ApiClient apiClient;
  final int initialTab;
  @override
  State<UserWorkspaceScreen> createState() => _UserWorkspaceScreenState();
}
class _UserWorkspaceScreenState extends State<UserWorkspaceScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs;
  @override void initState(){super.initState();tabs=TabController(length:9,initialIndex:widget.initialTab.clamp(0,8).toInt(),vsync:this);}
  @override void didUpdateWidget(covariant UserWorkspaceScreen oldWidget){super.didUpdateWidget(oldWidget);if(oldWidget.initialTab!=widget.initialTab)tabs.animateTo(widget.initialTab.clamp(0,8).toInt());}
  @override void dispose(){tabs.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppPalette.background,
    appBar:AppBar(backgroundColor:AppPalette.background,title:const Text('Your account',style:TextStyle(color:AppPalette.darkMaroon)),
      bottom:TabBar(controller:tabs,isScrollable:true,labelColor:AppPalette.maroon,unselectedLabelColor:AppPalette.secondary,indicatorColor:AppPalette.gold,
        tabs:const [Tab(text:'Find matches'),Tab(text:'Profile'),Tab(text:'Photos'),Tab(text:'Preferences'),Tab(text:'Messages'),Tab(text:'Support'),Tab(text:'Plans'),Tab(text:'References'),Tab(text:'Mentor')])),
    body:TabBarView(controller:tabs,children:[
      _WorkspaceTab(api:widget.apiClient,kind:'discover'),
      UserProfileEditorScreen(apiClient:widget.apiClient),
      UserPhotosScreen(apiClient:widget.apiClient),
      _WorkspaceTab(api:widget.apiClient,kind:'preferences'),
      _WorkspaceTab(api:widget.apiClient,kind:'messages'),
      _WorkspaceTab(api:widget.apiClient,kind:'support'),
      _WorkspaceTab(api:widget.apiClient,kind:'plans'),
      UserReferencesScreen(apiClient:widget.apiClient),
      UserMentorScreen(apiClient:widget.apiClient),
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
  final Map<String,TextEditingController> prefFields={for(final k in ['minHeightFeet','minHeightInches','maxHeightFeet','maxHeightInches','religionId','casteId','subCasteId','motherTongue','educationFieldId','courseId','qualificationId','occupationId','professionId','workType','minYearlyIncome','maxYearlyIncome','countryId','stateId','cityId'])k:TextEditingController()};
  final Map<String,TextEditingController> filters={for(final k in ['subCasteId','preferredGender','maritalStatus','motherTongue','education','profession','minYearlyIncome','maxYearlyIncome','minHeightFeet','minHeightInches','maxHeightFeet','maxHeightInches','countryId','stateId','cityId','educationFieldId','courseId','qualificationId','occupationId','professionId','workType'])k:TextEditingController()};
  int discoverPage=1,totalPages=1;
  String choice='Female',marital='Never Married';
  @override void initState(){super.initState();load();}
  @override void dispose(){for(final x in [a,b,c,d,e,...filters.values]){x.dispose();}super.dispose();}
  String get title=>switch(widget.kind){'discover'=>'Find matches','profile'=>'Your biodata','preferences'=>'Partner preferences','messages'=>'Messages','support'=>'Help & support',_=>'Membership plans'};
  Future<void> load() async {
    setState(() { loading=true; error=null; });
    try {
      if(widget.kind=='discover'){
        final params=<String,String>{'pageNumber':discoverPage.toString(),'pageSize':'20'};
        for(final entry in {'search':a,'minAge':b,'maxAge':c,'religionId':d,'casteId':e}.entries){if(entry.value.text.trim().isNotEmpty)params[entry.key]=entry.value.text.trim();}
        for(final entry in filters.entries){if(entry.value.text.trim().isNotEmpty)params[entry.key]=entry.value.text.trim();}
        final query=Uri(queryParameters:params).query;
        final r=await widget.api.get('/user-profile/discover?'+query,authenticated:true);
        final raw=r['data']; final list=raw is Map?raw['items']:raw;
        final next=list is List?list.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
        items=discoverPage>1?[...items,...next]:next;
        totalPages=(raw is Map?(raw['totalPages'] as num?)?.toInt():null)??1;
      } else if(widget.kind=='profile'){
        final r=await widget.api.get('/user-profile',authenticated:true); final raw=r['data'];
        if(raw is Map){data=Map<String,dynamic>.from(raw);a.text=data['firstName']?.toString()??'';b.text=data['lastName']?.toString()??'';c.text=data['dateOfBirth']?.toString().split('T').first??'';d.text=data['gender']?.toString()??'';e.text=data['aboutMe']?.toString()??'';}
      } else if(widget.kind=='preferences'){
        final r=await widget.api.get('/partner-preferences',authenticated:true); final raw=r['data'];
        if(raw is Map){data=Map<String,dynamic>.from(raw);choice=data['preferredGender']?.toString()??choice;marital=data['maritalStatus']?.toString()??marital;final age=data['age'];if(age is Map){a.text=age['minAge']?.toString()??'';b.text=age['maxAge']?.toString()??'';}
          c.text=data['additionalRequirements']?.toString()??'';
          for(final group in ['height','community','career','location']){final value=data[group];if(value is Map){for(final entry in value.entries){if(prefFields.containsKey(entry.key))prefFields[entry.key]!.text=entry.value?.toString()??'';}}}}
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
    return RefreshIndicator(color:AppPalette.maroon,onRefresh:load,child:ListView(padding:const EdgeInsets.all(15),children:[
      Text(title,style:const TextStyle(fontSize:22,color:AppPalette.darkMaroon)),const SizedBox(height:9),alerts,
      if(widget.kind=='discover')...discover(),
      if(widget.kind=='profile')...profile(),
      if(widget.kind=='preferences')...preferences(),
      if(widget.kind=='messages')...messages(),
      if(widget.kind=='support')...support(),
      if(widget.kind=='plans')...plans(),
    ]));
  }
  Widget filterField(String label,String key,{bool numeric=false})=>SizedBox(width:150,child:TextField(controller:filters[key],keyboardType:numeric?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:label,filled:true,isDense:true)));
  List<Widget> discover()=>[
    panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      field('Name or keyword',a),
      Row(children:[Expanded(child:field('Min age',b,keyboard:TextInputType.number)),const SizedBox(width:8),Expanded(child:field('Max age',c,keyboard:TextInputType.number))]),
      Row(children:[Expanded(child:field('Religion ID',d,keyboard:TextInputType.number)),const SizedBox(width:8),Expanded(child:field('Caste ID',e,keyboard:TextInputType.number))]),
      const Text('More filters',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      Wrap(spacing:8,runSpacing:8,children:[
        filterField('Sub-caste ID','subCasteId',numeric:true),filterField('Preferred gender','preferredGender'),filterField('Marital status','maritalStatus'),
        filterField('Mother tongue','motherTongue'),filterField('Education','education'),filterField('Profession','profession'),
        filterField('Min yearly income','minYearlyIncome',numeric:true),filterField('Max yearly income','maxYearlyIncome',numeric:true),
        filterField('Min height feet','minHeightFeet',numeric:true),filterField('Min height inches','minHeightInches',numeric:true),
        filterField('Max height feet','maxHeightFeet',numeric:true),filterField('Max height inches','maxHeightInches',numeric:true),
        filterField('Country ID','countryId',numeric:true),filterField('State ID','stateId',numeric:true),filterField('City ID','cityId',numeric:true),
        filterField('Education field ID','educationFieldId',numeric:true),filterField('Course ID','courseId',numeric:true),filterField('Qualification ID','qualificationId',numeric:true),
        filterField('Occupation ID','occupationId',numeric:true),filterField('Profession ID','professionId',numeric:true),filterField('Work type','workType'),
      ]),
      button('Apply filters',(){ discoverPage=1; load(); }),
    ])),
    if(items.isEmpty)panel(const Text('No profiles found. Complete your profile and try again.')),
    if(discoverPage<totalPages)button('Load more profiles',(){ discoverPage++; load(); }),
    ...items.map((p){final id=(p['userId']??p['id']??'').toString();final name=(''+(p['firstName']??'').toString()+' '+(p['lastName']??'').toString()).trim();
      final details=[p['profession'],p['education'],p['cityName'],p['religionName'],p['casteName']].where((x)=>x!=null&&x.toString().isNotEmpty).join(' · ');
      return Padding(padding:const EdgeInsets.only(bottom:9),child:panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(name.isEmpty?'VedicVivah member':name,style:const TextStyle(fontWeight:FontWeight.w700,color:AppPalette.darkMaroon,fontSize:16)),
        if(details.isNotEmpty)Text(details,style:const TextStyle(color:AppPalette.secondary,fontSize:12)),
        if((p['aboutMe']??'').toString().isNotEmpty)Text(p['aboutMe'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),
        TextButton.icon(onPressed:working||id.isEmpty?null:()=>_viewProfile(id),icon:const Icon(Icons.person_search),label:const Text('View full profile')), 
        Row(children:[Expanded(child:TextButton(onPressed:working||id.isEmpty?null:()=>run(()async{await widget.api.post('/shortlists/'+id,body:{},authenticated:true);setState(()=>notice='Profile added to shortlist.');}),child:const Text('Shortlist'))),Expanded(child:FilledButton(onPressed:working||id.isEmpty?null:()=>run(()async{await widget.api.post('/interests/'+id,body:{},authenticated:true);setState(()=>notice='Interest sent.');}),child:const Text('Send interest')))]),
        Wrap(spacing:8,children:[
          TextButton(onPressed:working||id.isEmpty?null:()=>_report(id),child:const Text('Report')),
          TextButton(onPressed:working||id.isEmpty?null:()=>_block(id),child:const Text('Block')),
        ]),
      ])));
    }),
  ];
  Future<void> _viewProfile(String userId) async {
    showModalBottomSheet(context:context,isScrollControlled:true,builder:(ctx)=>FutureBuilder<Map<String,dynamic>>(
      future:widget.api.get('/user-profile/$userId',authenticated:true).then((r)=>r['data'] is Map?Map<String,dynamic>.from(r['data']):<String,dynamic>{}),
      builder:(context,snapshot){
        if(snapshot.connectionState!=ConnectionState.done)return const SizedBox(height:260,child:Center(child:CircularProgressIndicator()));
        if(snapshot.hasError)return SizedBox(height:220,child:Center(child:Text(snapshot.error.toString())));
        final p=snapshot.data??{};
        final fields=<String,String>{'Age':p['dateOfBirth']?.toString()??'','Gender':p['gender']?.toString()??'','Religion':p['religionName']?.toString()??'','Caste':p['casteName']?.toString()??'','Sub-caste':p['subCasteName']?.toString()??'','Education':p['education']?.toString()??'','Profession':p['profession']?.toString()??'','Location':p['cityName']?.toString()??'','Marital status':p['maritalStatus']?.toString()??'','About':p['aboutMe']?.toString()??''};
        return SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${p['firstName']??'VedicVivah'} ${p['lastName']??'member'}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),
          const SizedBox(height:12),Flexible(child:ListView(shrinkWrap:true,children:fields.entries.where((e)=>e.value.isNotEmpty).map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Text('${e.key}: ${e.value}'))).toList())),
          SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Close'))),
        ])));
      },
    ));
  }
  Future<void> _report(String userId) async {
    final reason=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Report profile'),content:TextField(controller:reason,maxLines:3,decoration:const InputDecoration(hintText:'Describe the issue')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Submit'))]));
    if(ok!=true)return;
    await run(()async{if(reason.text.trim().isEmpty)throw Exception('Please enter a reason.');await widget.api.post('/reports/'+userId,body:{'reason':reason.text.trim()},authenticated:true);setState(()=>notice='Report submitted.');});
    reason.dispose();
  }
  Future<void> _block(String userId) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Block profile'),content:const Text('You will no longer see this profile in your matches.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Block'))]));
    if(ok!=true)return;
    await run(()async{await widget.api.post('/blocks/'+userId,body:{'reason':'Blocked from profile discovery'},authenticated:true);setState(()=>notice='Profile blocked.');await load();});
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
  Widget prefField(String label,String key)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:prefFields[key],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:label,filled:true)));
  List<Widget> preferences()=>[
    panel(Column(children:[
      DropdownButtonFormField<String>(value:choice,decoration:const InputDecoration(labelText:'Preferred gender'),items:['Female','Male','Any'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>choice=x??choice)),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:marital,decoration:const InputDecoration(labelText:'Marital status'),items:['Never Married','Divorced','Widowed','Any'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>marital=x??marital)),
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
        await widget.api.put('/partner-preferences',body:{
          'preferredGender':choice,'maritalStatus':marital,'additionalRequirements':c.text.trim().isEmpty?null:c.text.trim(),'rowVersion':data['rowVersion'],
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
  Future<void> searchConnections()async{if(b.text.trim().isEmpty){setState(()=>connections=[]);return;}try{final r=await widget.api.get('/interests/connections/search?q='+Uri.encodeQueryComponent(b.text.trim()),authenticated:true);final d=r['data'];setState(()=>connections=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[]);}catch(e){setState(()=>error=e.toString());}}
  Future<void> startChat(Map<String,dynamic> user)async{final userId=(user['userId']??'').toString();if(userId.isEmpty)return;await run(()async{await widget.api.post('/conversations/$userId',body:{},authenticated:true);await load();});}
  List<Widget> messages()=>[
    field('Search conversations',a),
    panel(Column(children:[field('Search accepted connections',b),button('Find connections',searchConnections)])),
    ...connections.map((u)=>panel(ListTile(title:Text('${u['firstName']??''} ${u['lastName']??''}'),subtitle:Text([u['profession'],u['cityName']].where((x)=>x!=null&&x.toString().isNotEmpty).join(' · ')),trailing:TextButton(onPressed:working?null:()=>startChat(u),child:const Text('Message'))))),
    if(items.where((c)=>(c['otherUserName']??'').toString().toLowerCase().contains(a.text.toLowerCase())).isEmpty)panel(const Text('No conversations found.')),
    ...items.where((c)=>(c['otherUserName']??'').toString().toLowerCase().contains(a.text.toLowerCase())).map((c)=>panel(ListTile(onTap:()=>openConversation(c),leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(c['otherUserName']?.toString()??'Member'),subtitle:Text(c['lastMessage']?.toString()??''),trailing:PopupMenuButton<String>(onSelected:(v)=>deleteConversation(c['id'].toString()),itemBuilder:(_)=>const [PopupMenuItem(value:'delete',child:Text('Delete conversation'))])))),
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
  List<Widget> plans()=>[
    panel(Text(data.isEmpty?'No current subscription.':'Current plan: '+(data['planName']??'Free').toString()+' · '+(data['isExpired']==true?'Expired':'Active'))),
    if(items.isEmpty)panel(const Text('No active plans are currently available.')),
    ...items.map((p)=>panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(p['name']?.toString()??'Plan',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),
      Text('₹'+(p['price']??'').toString()+' / '+(p['durationMonths']??'').toString()+' months',style:const TextStyle(color:AppPalette.gold,fontWeight:FontWeight.w700)),
      Text(p['shortDescription']?.toString()??''),
      if(p['features'] is List)...(p['features'] as List).map((f)=>Text('• '+f.toString())),
      const Text('Payment gateway is not available yet. Contact Support to activate this plan.',style:TextStyle(fontSize:12,color:AppPalette.secondary)),
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
  @override void initState(){super.initState();realtime=ChatRealtimeService(onMessage:_onRealtimeMessage,onMessageDeleted:_onRealtimeDelete);load();realtime.connect().then((_)=>realtime.joinConversation(id)).catchError((_){});}
  @override void dispose(){unawaited(realtime.dispose());text.dispose();super.dispose();}
  void _onRealtimeMessage(Map<String,dynamic> message){if(message['conversationId']?.toString()!=id||!mounted)return;setState(() { if(!messages.any((m)=>m['id']==message['id'])) { messages.add(message); } });unawaited(widget.api.put('/conversations/$id/read',body:{},authenticated:true));}
  void _onRealtimeDelete(String messageId,String conversationId){if(conversationId!=id||!mounted)return;setState(()=>messages.removeWhere((m)=>m['id']?.toString()==messageId));}
  Future<void> load()async{try{final r=await widget.api.get('/conversations/'+id+'/messages?take=50',authenticated:true);final d=r['data'];messages=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];await widget.api.put('/conversations/'+id+'/read',body:{},authenticated:true);}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> loadOlder()async{
    if(messages.isEmpty)return;
    final before=messages.first['id']?.toString();if(before==null)return;
    try{final r=await widget.api.get('/conversations/$id/messages?take=50&before=$before',authenticated:true);final d=r['data'];final older=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];if(mounted)setState(()=>messages=[...older,...messages]);}
    catch(e){if(mounted)setState(()=>error=e.toString());}
  }
  Future<void> send()async{if(text.text.trim().isEmpty)return;setState(()=>sending=true);try{await widget.api.post('/conversations/'+id+'/messages',body:{'content':text.text.trim()},authenticated:true);text.clear();await load();}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>sending=false);}}
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
