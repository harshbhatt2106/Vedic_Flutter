import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

class UserProfileEditorScreen extends StatefulWidget{
  const UserProfileEditorScreen({super.key,required this.apiClient});final ApiClient apiClient;
  @override State<UserProfileEditorScreen> createState()=>_UserProfileEditorScreenState();
}
class _UserProfileEditorScreenState extends State<UserProfileEditorScreen>{
  bool loading=true,busy=false;String? error,notice;Map<String,dynamic> profile={};
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
  Widget field(String label,String key,{bool numeric=false,int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:fields[key],keyboardType:numeric?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,maxLines:lines,decoration:InputDecoration(labelText:label,filled:true)));
  Widget section(String title,List<Widget> children,Future<void> Function() save)=>Card(color:AppPalette.surface,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14),side:const BorderSide(color:AppPalette.border)),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),const SizedBox(height:10),...children,
    SizedBox(width:double.infinity,child:OutlinedButton(onPressed:busy?null:()=>run(save),child:Text('Save $title'))),
  ])));
  Future<void> load()async{setState(()=>{loading=true,error=null});try{final r=await widget.apiClient.get('/user-profile',authenticated:true);final d=r['data'];if(d is Map){profile=Map<String,dynamic>.from(d);for(final k in keys){fields[k]!.text=profile[k]?.toString()??'';}if(fields['dateOfBirth']!.text.startsWith('0001-'))fields['dateOfBirth']!.clear();}}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> run(Future<void> Function() fn)async{setState(()=>{busy=true,error=null,notice=null});try{await fn();if(mounted)setState(()=>notice='Changes saved successfully.');await load();}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  Future<void> savePersonal()async{
    if(str('firstName')==null||str('dateOfBirth')==null||str('gender')==null)throw Exception('First name, date of birth and gender are required.');
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
