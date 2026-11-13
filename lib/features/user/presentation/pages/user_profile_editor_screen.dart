import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

class UserProfileEditorScreen extends StatefulWidget{
  const UserProfileEditorScreen({super.key,required this.apiClient});final ApiClient apiClient;
  @override State<UserProfileEditorScreen> createState()=>_UserProfileEditorScreenState();
}
class _UserProfileEditorScreenState extends State<UserProfileEditorScreen>{
  bool loading=true,busy=false;String? error,notice;Map<String,dynamic> profile={};
  final Map<String,List<Map<String,dynamic>>> options={};
  final Map<String,TextEditingController> fields={};
  static const keys=[
    'firstName','lastName','dateOfBirth','gender','timeOfBirth','birthPlace','birthCountryId','birthStateId','birthCityId','disabilityStatus','disabilityDetails','heightFeet','heightInches','weight',
    'religionId','casteId','subCasteId','community','motherTongue','motherTongueId',
    'education','qualification','course','occupation','profession','qualificationId','educationFieldId','courseId','occupationId','professionId','workType','yearlyIncome',
    'fatherName','motherName','brother','sister','marriedBrotherCount','marriedSisterCount','nanajiName','mosalSurname','maritalStatus',
    'countryId','stateId','cityId','pinCode','nativePlace','area','residenceType','areaInSqFt','roomCount','aboutMe'
  ];
  @override void initState(){super.initState();for(final k in keys){fields[k]=TextEditingController();}load();}
  @override void dispose(){for(final c in fields.values){c.dispose();}super.dispose();}
  String val(String key)=>fields[key]!.text.trim();
  String? str(String key)=>val(key).isEmpty?null:val(key);
  int? integer(String key)=>int.tryParse(val(key));
  num? number(String key)=>num.tryParse(val(key));
  @override Widget build(BuildContext context){if(loading)return const Center(child:CircularProgressIndicator(color:AppPalette.maroon));return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(14),children:[
    const Text('Your biodata',style:TextStyle(fontSize:22,color:AppPalette.darkMaroon)),
    if(error!=null)Card(child:Padding(padding:const EdgeInsets.all(10),child:Text(error!,style:const TextStyle(color:AppPalette.error)))),
    if(notice!=null)Card(child:Padding(padding:const EdgeInsets.all(10),child:Text(notice!,style:const TextStyle(color:AppPalette.maroon)))),
    section('Personal information',[
      field('First name','firstName'),field('Last name','lastName'),field('Date of birth (YYYY-MM-DD)','dateOfBirth'),field('Gender','gender'),field('Time of birth (HH:mm)','timeOfBirth'),field('Birth place','birthPlace'),
      field('Birth country ID','birthCountryId',numeric:true),field('Birth state ID','birthStateId',numeric:true),field('Birth city ID','birthCityId',numeric:true),
      field('Disability status (true/false)','disabilityStatus'),field('Disability details','disabilityDetails'),
      field('Height feet','heightFeet',numeric:true),field('Height inches','heightInches',numeric:true),field('Weight (kg)','weight',numeric:true),
    ],()=>savePersonal()),
    section('Religion & community',[
      field('Religion ID','religionId',numeric:true),field('Caste ID','casteId',numeric:true),field('Sub-caste ID','subCasteId',numeric:true),field('Community','community'),field('Mother tongue','motherTongue'),field('Mother tongue ID','motherTongueId',numeric:true),
    ],()=>saveCommunity()),
    section('Education & career',[
      field('Education','education'),field('Qualification','qualification'),field('Course','course'),field('Occupation','occupation'),field('Profession','profession'),field('Work type','workType'),
      field('Qualification ID','qualificationId',numeric:true),field('Education field ID','educationFieldId',numeric:true),field('Course ID','courseId',numeric:true),field('Occupation ID','occupationId',numeric:true),field('Profession ID','professionId',numeric:true),field('Yearly income','yearlyIncome',numeric:true),
    ],()=>saveCareer()),
    section('Family information',[
      field('Father name','fatherName'),field('Mother name','motherName'),field('Brothers','brother'),field('Sisters','sister'),field('Married brothers count','marriedBrotherCount',numeric:true),field('Married sisters count','marriedSisterCount',numeric:true),field('Nanaji name','nanajiName'),field('Mosal surname','mosalSurname'),field('Marital status','maritalStatus'),
    ],()=>saveFamily()),
    section('Location & residence',[
      field('Country ID','countryId',numeric:true),field('State ID','stateId',numeric:true),field('City ID','cityId',numeric:true),field('PIN code','pinCode'),field('Native place','nativePlace'),field('Area / locality','area'),field('Residence type','residenceType'),field('Area (sq ft)','areaInSqFt',numeric:true),field('Room count','roomCount',numeric:true),
    ],()=>saveLocation()),
    section('About me',[field('About me','aboutMe',lines:4)],()=>saveAbout()),
    Card(color:AppPalette.surface,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Review status: ${profile['approvalStatus']??'Unknown'}'),
      Text('Profile visibility: ${profile['visibilityStatus']??'Unknown'}'),
      if(profile['rejectionReason']!=null)Text('Review note: ${profile['rejectionReason']}',style:const TextStyle(color:AppPalette.error)),
      Wrap(spacing:8,children:[
        OutlinedButton(onPressed:busy?null:()=>run(() async { await widget.apiClient.patch('/user-profile/visibility',body:{'status':'Visible'},authenticated:true); }),child:const Text('Make visible')),
        OutlinedButton(onPressed:busy?null:()=>run(() async { await widget.apiClient.patch('/user-profile/visibility',body:{'status':'Hidden'},authenticated:true); }),child:const Text('Hide profile')),
      ]),
      SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:()=>run(() async { await widget.apiClient.post('/user-profile/submit-for-review',body:{},authenticated:true); }),child:const Text('Submit profile for review'))),
    ]))),
  ]));}
  Widget field(String label,String key,{bool numeric=false,int lines=1}) {
    if(key=='dateOfBirth')return Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:fields[key],readOnly:true,decoration:const InputDecoration(labelText:'Date of birth',filled:true,suffixIcon:Icon(Icons.calendar_month)),onTap:()async{
      final now=DateTime.now();final maxDate=DateTime(now.year-18,now.month,now.day);final existing=DateTime.tryParse(val(key));final initial=existing!=null&&existing.isBefore(maxDate)?existing:maxDate;
      final picked=await showDatePicker(context:context,initialDate:initial,firstDate:DateTime(1900),lastDate:maxDate);
      if(picked!=null)setState(()=>fields[key]!.text='${picked.year.toString().padLeft(4,'0')}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
    }));
    if(key=='timeOfBirth')return Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:fields[key],readOnly:true,decoration:const InputDecoration(labelText:'Time of birth',filled:true,suffixIcon:Icon(Icons.access_time)),onTap:()async{final picked=await showTimePicker(context:context,initialTime:TimeOfDay.now());if(picked!=null)setState(()=>fields[key]!.text='${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}');}));
    const choices=<String,List<String>>{'gender':['Male','Female','Other'],'disabilityStatus':['false','true'],'maritalStatus':['Single','Married','Divorced','Widowed'],'residenceType':['Owned','Rented','Family','Other']};
    if(choices.containsKey(key)){final values=choices[key]!;final current=val(key);return Padding(padding:const EdgeInsets.only(bottom:8),child:DropdownButtonFormField<String>(initialValue:values.contains(current)?current:null,isExpanded:true,decoration:InputDecoration(labelText:label,filled:true),items:values.map((v)=>DropdownMenuItem(value:v,child:Text(key=='disabilityStatus'?(v=='true'?'Yes':'No'):v))).toList(),onChanged:(v)=>setState(()=>fields[key]!.text=v??'')));}
    const ids={'religionId','casteId','subCasteId','motherTongueId','qualificationId','educationFieldId','courseId','occupationId','professionId','countryId','stateId','cityId','birthCountryId','birthStateId','birthCityId'};
    if(ids.contains(key))return selectField(label,key);
    return Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:fields[key],keyboardType:numeric?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,maxLines:lines,decoration:InputDecoration(labelText:label,filled:true)));
  }
  Widget selectField(String label,String key){
    final current=integer(key);final list=options[key]??const <Map<String,dynamic>>[];
    final value=list.any((x)=>(x['id'] as num?)?.toInt()==current)?current:null;
    return Padding(padding:const EdgeInsets.only(bottom:8),child:DropdownButtonFormField<int>(
      initialValue:value,isExpanded:true,decoration:InputDecoration(labelText:label,filled:true),
      items:list.map((x)=>DropdownMenuItem<int>(value:(x['id'] as num).toInt(),child:Text(x['name'].toString(),overflow:TextOverflow.ellipsis))).toList(),
      onChanged:(v)=>changeOption(key,v),
    ));
  }
  Future<void> fetchOptions(String key,String path)async{
    try{final r=await widget.apiClient.get(path,authenticated:true);final d=r['data'];options[key]=d is List?d.whereType<Map>().map((raw){final x=Map<String,dynamic>.from(raw);if(path.contains('/locations/countries'))return {'id':x['countryId'],'name':x['countryName']};if(path.contains('/locations/states'))return {'id':x['stateId'],'name':x['stateName']};if(path.contains('/locations/cities'))return {'id':x['cityId'],'name':x['cityName']};return x;}).toList():[];}catch(_){options[key]=[];}
  }
  Future<void> changeOption(String key,int? value)async{
    fields[key]!.text=value?.toString()??'';
    const nameFields=<String,String>{'motherTongueId':'motherTongue','qualificationId':'qualification','educationFieldId':'education','courseId':'course','occupationId':'occupation','professionId':'profession'};
    final nameKey=nameFields[key];
    if(nameKey!=null){String? selectedName;for(final option in options[key]??[]){if((option['id'] as num?)?.toInt()==value){selectedName=option['name']?.toString();break;}}fields[nameKey]!.text=selectedName??'';}
    final dependencies=<String,Map<String,String>>{
      'religionId':{'casteId':'/reference-data/castes?religionId=$value'},
      'casteId':{'subCasteId':'/reference-data/sub-castes?casteId=$value'},
      'educationFieldId':{'courseId':'/reference-data/courses?educationFieldId=$value'},
      'occupationId':{'professionId':'/reference-data/professions?occupationId=$value'},
      'countryId':{'stateId':'/locations/states?countryId=$value'},
      'stateId':{'cityId':'/locations/cities?stateId=$value'},
      'birthCountryId':{'birthStateId':'/locations/states?countryId=$value'},
      'birthStateId':{'birthCityId':'/locations/cities?stateId=$value'},
    };
    final clearChildren=<String,List<String>>{'religionId':['casteId','subCasteId'],'casteId':['subCasteId'],'educationFieldId':['courseId'],'occupationId':['professionId'],'countryId':['stateId','cityId'],'stateId':['cityId'],'birthCountryId':['birthStateId','birthCityId'],'birthStateId':['birthCityId']};
    for(final child in clearChildren[key]??const <String>[])fields[child]!.clear();
    for(final entry in dependencies[key]?.entries??const <MapEntry<String,String>>[]){await fetchOptions(entry.key,entry.value);}
    if(mounted)setState((){});
  }
  Widget section(String title,List<Widget> children,Future<void> Function() save)=>Card(color:AppPalette.surface,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14),side:const BorderSide(color:AppPalette.border)),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),const SizedBox(height:10),...children,
    SizedBox(width:double.infinity,child:OutlinedButton(onPressed:busy?null:()=>run(save),child:Text('Save $title'))),
  ])));
  Future<void> load()async{setState(() { loading=true; error=null; });try{final r=await widget.apiClient.get('/user-profile',authenticated:true);final d=r['data'];if(d is Map){profile=Map<String,dynamic>.from(d);for(final k in keys){fields[k]!.text=profile[k]?.toString()??'';}if(fields['dateOfBirth']!.text.startsWith('0001-'))fields['dateOfBirth']!.clear();await loadMasterData();}}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> loadMasterData()async{
    final base=<String,String>{
      'religionId':'/reference-data/religions','motherTongueId':'/reference-data/mother-tongues',
      'qualificationId':'/reference-data/qualifications','educationFieldId':'/reference-data/education-fields',
      'occupationId':'/reference-data/occupations','countryId':'/locations/countries','birthCountryId':'/locations/countries',
    };
    for(final e in base.entries){await fetchOptions(e.key,e.value);}
    final religion=integer('religionId'),caste=integer('casteId'),education=integer('educationFieldId'),occupation=integer('occupationId'),country=integer('countryId'),state=integer('stateId'),birthCountry=integer('birthCountryId'),birthState=integer('birthStateId');
    if(religion!=null)await fetchOptions('casteId','/reference-data/castes?religionId=$religion');
    if(caste!=null)await fetchOptions('subCasteId','/reference-data/sub-castes?casteId=$caste');
    if(education!=null)await fetchOptions('courseId','/reference-data/courses?educationFieldId=$education');
    if(occupation!=null)await fetchOptions('professionId','/reference-data/professions?occupationId=$occupation');
    if(country!=null)await fetchOptions('stateId','/locations/states?countryId=$country');
    if(state!=null)await fetchOptions('cityId','/locations/cities?stateId=$state');
    if(birthCountry!=null)await fetchOptions('birthStateId','/locations/states?countryId=$birthCountry');
    if(birthState!=null)await fetchOptions('birthCityId','/locations/cities?stateId=$birthState');
  }
  Future<void> run(Future<void> Function() fn)async{setState(() { busy=true; error=null; notice=null; });try{await fn();if(mounted)setState(()=>notice='Changes saved successfully.');await load();}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  Future<void> savePersonal()async{
    final dob=DateTime.tryParse(val('dateOfBirth'));final now=DateTime.now();
    final minDate=DateTime(now.year-18,now.month,now.day);
    if(str('firstName')==null||dob==null||str('gender')==null)throw Exception('First name, a valid date of birth and gender are required.');
    if(dob.isAfter(minDate))throw Exception('You must be at least 18 years old.');
    if(!const ['Male','Female','Other'].contains(val('gender')))throw Exception('Select a valid gender.');
    await widget.apiClient.patch('/user-profile/personal',body:{
      'personal':{'firstName':val('firstName'),'lastName':str('lastName'),'dateOfBirth':val('dateOfBirth'),'gender':val('gender'),'timeOfBirth':str('timeOfBirth'),'birthPlace':str('birthPlace'),'birthCountryId':integer('birthCountryId'),'birthStateId':integer('birthStateId'),'birthCityId':integer('birthCityId'),'disabilityStatus':val('disabilityStatus').toLowerCase()=='true','disabilityDetails':str('disabilityDetails')},
      'physical':{'heightFeet':integer('heightFeet'),'heightInches':integer('heightInches'),'weight':number('weight')},'rowVersion':profile['rowVersion']
    },authenticated:true);
  }
  Future<void> saveCommunity()async=>widget.apiClient.patch('/user-profile/community',body:{'religionId':integer('religionId'),'casteId':integer('casteId'),'subCasteId':integer('subCasteId'),'community':str('community'),'motherTongue':str('motherTongue'),'motherTongueId':integer('motherTongueId'),'rowVersion':profile['rowVersion']},authenticated:true);
  Future<void> saveCareer()async=>widget.apiClient.patch('/user-profile/education-career',body:{'education':str('education'),'qualification':str('qualification'),'course':str('course'),'occupation':str('occupation'),'profession':str('profession'),'workType':str('workType'),'yearlyIncome':number('yearlyIncome'),'qualificationId':integer('qualificationId'),'educationFieldId':integer('educationFieldId'),'courseId':integer('courseId'),'occupationId':integer('occupationId'),'professionId':integer('professionId'),'rowVersion':profile['rowVersion']},authenticated:true);
  Future<void> saveFamily()async=>widget.apiClient.patch('/user-profile/family',body:{'fatherName':str('fatherName'),'motherName':str('motherName'),'brother':str('brother'),'sister':str('sister'),'marriedBrotherCount':integer('marriedBrotherCount'),'marriedSisterCount':integer('marriedSisterCount'),'nanajiName':str('nanajiName'),'mosalSurname':str('mosalSurname'),'maritalStatus':str('maritalStatus'),'rowVersion':profile['rowVersion']},authenticated:true);
  Future<void> saveLocation()async=>widget.apiClient.patch('/user-profile/location-residence',body:{'countryId':integer('countryId'),'stateId':integer('stateId'),'cityId':integer('cityId'),'pinCode':str('pinCode'),'nativePlace':str('nativePlace'),'area':str('area'),'residenceType':str('residenceType'),'areaInSqFt':number('areaInSqFt'),'roomCount':integer('roomCount'),'rowVersion':profile['rowVersion']},authenticated:true);
  Future<void> saveAbout()async=>widget.apiClient.patch('/user-profile/about',body:{'aboutMe':str('aboutMe'),'rowVersion':profile['rowVersion']},authenticated:true);
}
