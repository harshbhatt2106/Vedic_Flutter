import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

class UserReferencesScreen extends StatefulWidget {
  const UserReferencesScreen({super.key,required this.apiClient});
  final ApiClient apiClient;
  @override State<UserReferencesScreen> createState()=>_UserReferencesScreenState();
}
class _UserReferencesScreenState extends State<UserReferencesScreen>{
  bool loading=true,busy=false;String? error;List<Map<String,dynamic>> refs=[];List<Map<String,dynamic>> countries=[],states=[],cities=[];int? selectedCountryId,selectedStateId,selectedCityId;
  final name=TextEditingController(),phone=TextEditingController(),city=TextEditingController(),relation=TextEditingController();
  String? editingId;
  @override void initState(){super.initState();load();}
  @override void dispose(){for(final c in [name,phone,city,relation]){c.dispose();}super.dispose();}
  Future<void> load()async{setState(() { loading=true; error=null; });try{final results=await Future.wait([widget.apiClient.get('/user-references',authenticated:true),widget.apiClient.get('/locations/countries',authenticated:true)]);final d=results[0]['data'],countryData=results[1]['data'];refs=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];countries=countryData is List?countryData.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> selectCountry(int? value)async{selectedCountryId=value;selectedStateId=null;selectedCityId=null;city.clear();states=[];cities=[];if(value!=null){final r=await widget.apiClient.get('/locations/states?countryId=$value',authenticated:true);final d=r['data'];states=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];}if(mounted)setState((){});}
  Future<void> selectState(int? value)async{selectedStateId=value;selectedCityId=null;city.clear();cities=[];if(value!=null){final r=await widget.apiClient.get('/locations/cities?stateId=$value',authenticated:true);final d=r['data'];cities=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];}if(mounted)setState((){});}
  Widget locationSelectors()=>Column(children:[
    DropdownButtonFormField<int>(initialValue:selectedCountryId,decoration:const InputDecoration(labelText:'Country',filled:true),items:countries.map((x)=>DropdownMenuItem<int>(value:(x['countryId'] as num).toInt(),child:Text(x['countryName'].toString()))).toList(),onChanged:selectCountry),
    const SizedBox(height:8),
    DropdownButtonFormField<int>(initialValue:selectedStateId,decoration:const InputDecoration(labelText:'State',filled:true),items:states.map((x)=>DropdownMenuItem<int>(value:(x['stateId'] as num).toInt(),child:Text(x['stateName'].toString()))).toList(),onChanged:selectedCountryId==null?null:selectState),
    const SizedBox(height:8),
    DropdownButtonFormField<int>(initialValue:selectedCityId,decoration:const InputDecoration(labelText:'City',filled:true),items:cities.map((x)=>DropdownMenuItem<int>(value:(x['cityId'] as num).toInt(),child:Text(x['cityName'].toString()))).toList(),onChanged:(v)=>setState(() { selectedCityId=v; city.text=v?.toString()??''; })),
  ]);
  Future<void> save()async{final cityId=selectedCityId??int.tryParse(city.text.trim());if(name.text.trim().isEmpty||phone.text.trim().length<7||phone.text.trim().length>15||cityId==null||relation.text.trim().isEmpty){setState(()=>error='Enter a name, valid phone number, country, state, city and relationship.');return;}if(editingId==null&&refs.length>=3){setState(()=>error='You can add a maximum of 3 reference contacts.');return;}setState(()=>busy=true);try{final body={'name':name.text.trim(),'phoneNumber':phone.text.trim(),'cityId':cityId,'relationshipWithUser':relation.text.trim()};if(editingId==null){await widget.apiClient.post('/user-references',body:body,authenticated:true);}else{await widget.apiClient.put('/user-references/$editingId',body:body,authenticated:true);}name.clear();phone.clear();city.clear();relation.clear();editingId=null;selectedCountryId=null;selectedStateId=null;selectedCityId=null;states=[];cities=[];await load();}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  Future<void> edit(Map<String,dynamic> item)async{
    final cityId=(item['cityId'] as num?)?.toInt();
    setState(() { editingId=item['referenceId']?.toString(); name.text=item['name']?.toString()??''; phone.text=item['phoneNumber']?.toString()??''; city.text=cityId?.toString()??''; relation.text=item['relationshipWithUser']?.toString()??'';selectedCountryId=null;selectedStateId=null;selectedCityId=null;states=[];cities=[];busy=true; });
    try{
      // The reference API stores CityId only. Resolve its parent selectors exactly as the web editor does.
      for(final countryItem in countries){
        final countryId=(countryItem['countryId'] as num?)?.toInt();if(countryId==null)continue;
        final stateResponse=await widget.apiClient.get('/locations/states?countryId=$countryId',authenticated:true);
        final stateData=stateResponse['data'];
        final stateItems=stateData is List?stateData.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
        for(final stateItem in stateItems){
          final stateId=(stateItem['stateId'] as num?)?.toInt();if(stateId==null)continue;
          final cityResponse=await widget.apiClient.get('/locations/cities?stateId=$stateId',authenticated:true);
          final cityData=cityResponse['data'];
          final cityItems=cityData is List?cityData.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
          if(cityItems.any((x)=>(x['cityId'] as num?)?.toInt()==cityId)){
            if(mounted)setState((){selectedCountryId=countryId;selectedStateId=stateId;selectedCityId=cityId;states=stateItems;cities=cityItems;});
            return;
          }
        }
      }
      if(mounted)setState(()=>error='Could not resolve this contact city. Select country, state and city again.');
    }catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  void clearForm(){setState(() { editingId=null;selectedCountryId=null;selectedStateId=null;selectedCityId=null;states=[];cities=[]; });name.clear();phone.clear();city.clear();relation.clear();}
  Future<void> remove(String id)async{final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Delete reference?'),content:const Text('This reference contact will be removed.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete'))]));if(yes!=true)return;try{await widget.apiClient.delete('/user-references/$id',authenticated:true);await load();}catch(e){setState(()=>error=e.toString());}}
  Widget field(String label,TextEditingController c,{TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c,keyboardType:keyboard,decoration:InputDecoration(labelText:label,filled:true)));
  @override Widget build(BuildContext context){if(loading)return const Center(child:CircularProgressIndicator());return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
    const Text('Reference contacts',style:TextStyle(fontSize:22,color:AppPalette.darkMaroon)),
    if(error!=null)Text(error!,style:const TextStyle(color:AppPalette.error)),
    Card(color:AppPalette.surface,child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
      Text('${refs.length}/3 reference contacts',style:const TextStyle(color:AppPalette.secondary)),
      field('Full name',name),field('Phone number',phone,keyboard:TextInputType.phone),locationSelectors(),field('Relationship with you',relation),
      SizedBox(width:double.infinity,child:FilledButton(onPressed:busy||(editingId==null&&refs.length>=3)?null:save,child:Text(busy?'Please wait...':editingId==null?'Add reference':'Update reference'))),
      if(editingId!=null)TextButton(onPressed:busy?null:clearForm,child:const Text('Cancel editing')),
    ]))),
    if(refs.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('No reference contacts added yet.')),
    ...refs.map((r){final id=r['referenceId']?.toString()??'';return Card(color:AppPalette.surface,child:ListTile(title:Text(r['name']?.toString()??''),subtitle:Text('${r['relationshipWithUser']??''} · ${r['phoneNumber']??''} · ${r['cityName']??''}'),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(r);if(v=='delete')remove(id);},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))])));}),
  ]));}
}

class UserMentorScreen extends StatefulWidget{
  const UserMentorScreen({super.key,required this.apiClient});final ApiClient apiClient;
  @override State<UserMentorScreen> createState()=>_UserMentorScreenState();
}
class _UserMentorScreenState extends State<UserMentorScreen>{
  bool loading=true,busy=false;String? error;List<Map<String,dynamic>> mentors=[];Map<String,dynamic>? current,suggestion;
  @override void initState(){super.initState();load();}
  Future<void> load()async{setState(() { loading=true; error=null; });try{final r=await Future.wait([widget.apiClient.get('/user/mentors',authenticated:true),widget.apiClient.get('/user/mentor',authenticated:true),widget.apiClient.get('/user/mentor/suggestion',authenticated:true)]);final m=r[0]['data'];mentors=m is List?m.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];current=r[1]['data'] is Map?Map<String,dynamic>.from(r[1]['data']):null;suggestion=r[2]['data'] is Map?Map<String,dynamic>.from(r[2]['data']):null;}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> select(String id)async{setState(()=>busy=true);try{await widget.apiClient.post('/user/mentor',body:{'mentorUserId':id},authenticated:true);await load();}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context){if(loading)return const Center(child:CircularProgressIndicator());return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
    const Text('Your mentor',style:TextStyle(fontSize:22,color:AppPalette.darkMaroon)),
    if(error!=null)Text(error!,style:const TextStyle(color:AppPalette.error)),
    Card(color:AppPalette.surface,child:ListTile(leading:const CircleAvatar(child:Icon(Icons.support_agent)),title:Text(current==null?'No mentor selected':'${current!['firstName']??''} ${current!['lastName']??''}'),subtitle:const Text('Currently assigned mentor'))),
    if(suggestion!=null)Card(color:AppPalette.surface,child:ListTile(title:const Text('Suggested mentor'),subtitle:Text('${suggestion!['firstName']??''} ${suggestion!['lastName']??''}'),trailing:TextButton(onPressed:busy?null:()=>select(suggestion!['mentorUserId'].toString()),child:const Text('Select')))),
    const Padding(padding:EdgeInsets.symmetric(vertical:10),child:Text('Available mentors',style:TextStyle(fontWeight:FontWeight.w700))),
    if(mentors.isEmpty)const Text('No mentors are currently available in your location. Contact the VedicVivah team for assistance.'),
    ...mentors.map((m){final id=m['mentorUserId']?.toString()??'';return Card(color:AppPalette.surface,child:ListTile(title:Text('${m['firstName']??''} ${m['lastName']??''}'),trailing:TextButton(onPressed:busy||id.isEmpty?null:()=>select(id),child:const Text('Select'))));}),
  ]));}
}
