import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../auth/data/models/auth_models.dart';

class UserDashboardScreen extends StatefulWidget {
 const UserDashboardScreen({super.key,required this.apiClient,required this.session,required this.onSignOut,required this.onNavigate});
 final ApiClient apiClient; final AuthSession session; final Future<void> Function() onSignOut; final ValueChanged<int> onNavigate;
 @override State<UserDashboardScreen> createState()=>_UserDashboardScreenState();
}
class _UserDashboardScreenState extends State<UserDashboardScreen>{
 bool _loading=true; String? _error; Map<String,dynamic>? _profile;
 List<dynamic> _photos=[],_shortlist=[],_notifications=[]; int _referenceCount=0;
 @override void initState(){super.initState();_load();}
 Future<void> _load() async{
 setState((){_loading=true;_error=null;});
 try{
 final r=await Future.wait([
 widget.apiClient.get('/user-profile',authenticated:true),
 widget.apiClient.get('/user-profile/photos',authenticated:true),
 widget.apiClient.get('/shortlists',authenticated:true),
 widget.apiClient.get('/notifications?take=4',authenticated:true),
 widget.apiClient.get('/user-references',authenticated:true),
 ]);
 if(!mounted)return;
 _profile=r[0]['data'] is Map<String,dynamic>?r[0]['data'] as Map<String,dynamic>:null;
 _photos=r[1]['data'] is List?r[1]['data'] as List:[];
 _shortlist=r[2]['data'] is List?r[2]['data'] as List:[];
 _notifications=r[3]['data'] is List?r[3]['data'] as List:[];
 _referenceCount=r[4]['data'] is List?(r[4]['data'] as List).length:0;
 }catch(e){if(mounted)_error=e.toString().replaceFirst('ApiException: ','');}
 finally{if(mounted)setState(()=>_loading=false);}
 }
 bool _filled(Map<String,dynamic> p,List<String> keys)=>keys.every((k)=>p[k]!=null&&p[k].toString().trim().isNotEmpty);
 int get _done{final p=_profile;if(p==null)return 0;var n=0;
 if(_filled(p,['firstName','dateOfBirth','gender']))n++;
 if(_filled(p,['religionId','casteId','motherTongue']))n++;
 if(_filled(p,['education','profession']))n++;
 if(_filled(p,['heightFeet','heightInches','weight']))n++;
 if(_filled(p,['fatherName','motherName']))n++;
 if(_referenceCount>=3)n++;
 if(_filled(p,['countryId','stateId','cityId']))n++;
 if(_filled(p,['pinCode']))n++;
 if(_filled(p,['aboutMe']))n++;
 if(_photos.isNotEmpty)n++;return n;}
 int _age(dynamic raw){final d=DateTime.tryParse(raw?.toString()??'');if(d==null)return 0;final now=DateTime.now();var a=now.year-d.year;if(now.month<d.month||(now.month==d.month&&now.day<d.day))a--;return a;}
 String get _name{final n='${_profile?['firstName']??''} ${_profile?['lastName']??''}'.trim();return n.isEmpty?widget.session.userName:n;}
 String get _greeting{final h=DateTime.now().hour;return h<12?'GOOD MORNING':h<17?'GOOD AFTERNOON':'GOOD EVENING';}
 String _ago(dynamic raw){final d=DateTime.tryParse(raw?.toString()??'');if(d==null)return '';final m=DateTime.now().difference(d.toLocal()).inMinutes;if(m<1)return 'Just now';if(m<60)return '$m m ago';final h=(m/60).round();if(h<24)return '$h h ago';return '${(h/24).round()}d ago';}
 @override Widget build(BuildContext context){
 final p=_profile;final done=_done;final percent=done*10;final unread=_notifications.where((x)=>x is Map&&x['isRead']!=true).length;
 return Scaffold(backgroundColor:AppPalette.background,appBar:AppBar(backgroundColor:AppPalette.background,elevation:0,title:const Text('VEDICVIVAH',style:TextStyle(color:AppPalette.darkMaroon,letterSpacing:2,fontSize:15,fontWeight:FontWeight.w700)),actions:[
 IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded,color:AppPalette.maroon)),
 IconButton(onPressed:widget.onSignOut,icon:const Icon(Icons.logout_rounded,color:AppPalette.maroon)),
 ]),
 body:RefreshIndicator(color:AppPalette.maroon,onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(18,8,18,34),children:[
 Text(_greeting,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,letterSpacing:2,color:AppPalette.gold,fontFamily:'sans-serif')),
 const SizedBox(height:7),Text('Namaste, ${_name.split(' ').first}',style:const TextStyle(fontSize:31,color:AppPalette.darkMaroon,height:1.08)),
 const SizedBox(height:6),const Text('Your journey towards a meaningful bond begins here.',style:TextStyle(fontSize:13,color:AppPalette.secondary,fontFamily:'sans-serif')),
 const SizedBox(height:18),if(_error!=null)_errorCard(),
 _hero(p),const SizedBox(height:15),_strength(percent,done),const SizedBox(height:15),
 Row(children:[Expanded(child:_stat('SHORTLISTED',_shortlist.length,Icons.favorite_border,()=>widget.onNavigate(2))),const SizedBox(width:9),Expanded(child:_stat('UNREAD UPDATES',unread,Icons.notifications_none,()=>widget.onNavigate(1))),const SizedBox(width:9),Expanded(child:_stat('PHOTOS',_photos.length,Icons.photo_camera_back_outlined,()=>widget.onNavigate(6)))]),
 const SizedBox(height:14),_quickActions(),
 const SizedBox(height:23),_heading('Latest updates','Recent account activity'),const SizedBox(height:9),_notificationsCard(),
 const SizedBox(height:22),_heading('Your shortlist','Profiles saved for later'),const SizedBox(height:9),_shortlistCard(),
 if(_loading)const Padding(padding:EdgeInsets.only(top:22),child:Center(child:CircularProgressIndicator(color:AppPalette.maroon))),
 ])));
 }
 Widget _hero(Map<String,dynamic>? p){
 final complete=p?['isProfileComplete']==true;final status=p?['approvalStatus']?.toString()??'Pending';
 final age=p?['dateOfBirth']==null?null:_age(p?['dateOfBirth']);
 final sub=[if(age!=null&&age>0)'$age yrs',p?['profession']?.toString(),p?['cityName']?.toString()].where((x)=>x!=null&&x.isNotEmpty).join(' · ');
 final label=p==null||!complete?'BIODATA INCOMPLETE':status=='Approved'?'PROFILE LIVE':status=='Rejected'?'CHANGES REQUESTED':'UNDER REVIEW';
 return Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[AppPalette.darkMaroon,AppPalette.maroon],begin:Alignment.topLeft,end:Alignment.bottomRight),boxShadow:[BoxShadow(color:AppPalette.darkMaroon.withValues(alpha:.15),blurRadius:20,offset:const Offset(0,9))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[Container(width:56,height:56,decoration:BoxDecoration(shape:BoxShape.circle,color:AppPalette.champagne.withValues(alpha:.18),border:Border.all(color:AppPalette.gold)),child:Center(child:Text(_name[0].toUpperCase(),style:const TextStyle(color:AppPalette.champagne,fontSize:24)))),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_name,style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w600)),if(sub.isNotEmpty)Text(sub,style:const TextStyle(color:AppPalette.champagne,fontSize:11,fontFamily:'sans-serif'))]))]),
 const SizedBox(height:15),Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.13),borderRadius:BorderRadius.circular(24)),child:Text(label,style:const TextStyle(color:AppPalette.champagne,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:1,fontFamily:'sans-serif'))),
 if(status=='Rejected'&&(p?['rejectionReason']?.toString().isNotEmpty??false))Padding(padding:const EdgeInsets.only(top:10),child:Text('Reason: ${p?['rejectionReason']}',style:const TextStyle(color:Colors.white70,fontSize:12))),
 const SizedBox(height:14),const Text('A thoughtful introduction is the beginning of every lasting relationship.',style:TextStyle(color:Colors.white70,fontSize:12,height:1.5,fontFamily:'sans-serif')),
 ]));
 }
 Widget _strength(int percent,int done)=>_panel(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[const Expanded(child:Text('BIODATA STRENGTH',style:TextStyle(color:AppPalette.gold,fontSize:11,fontWeight:FontWeight.w700,letterSpacing:1.4,fontFamily:'sans-serif'))),Text('$percent%',style:const TextStyle(color:AppPalette.maroon,fontSize:22,fontWeight:FontWeight.w700))]),
 const SizedBox(height:10),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:percent/100,minHeight:8,backgroundColor:AppPalette.champagne,color:AppPalette.maroon)),
 const SizedBox(height:9),Text('$done of 10 sections complete',style:const TextStyle(color:AppPalette.secondary,fontSize:12,fontFamily:'sans-serif')),
 if(percent<100)const Padding(padding:EdgeInsets.only(top:8),child:Text('Complete your biodata to help families understand you better.',style:TextStyle(color:AppPalette.secondary,fontSize:12,height:1.4,fontFamily:'sans-serif'))),
 ]));
 Widget _stat(String title,int value,IconData icon,VoidCallback onTap)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:_panel(Column(children:[Icon(icon,color:AppPalette.gold,size:20),const SizedBox(height:7),Text(value.toString(),style:const TextStyle(color:AppPalette.darkMaroon,fontSize:20,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(title,textAlign:TextAlign.center,style:const TextStyle(color:AppPalette.secondary,fontSize:9,fontWeight:FontWeight.w700,letterSpacing:.3,fontFamily:'sans-serif'))]),padding:const EdgeInsets.symmetric(vertical:13,horizontal:5)));
 Widget _quickActions()=>_panel(Wrap(spacing:8,runSpacing:8,children:[
  OutlinedButton.icon(onPressed:()=>widget.onNavigate(10),icon:const Icon(Icons.search),label:const Text('Find matches')),
  OutlinedButton.icon(onPressed:()=>widget.onNavigate(11),icon:const Icon(Icons.person_outline),label:const Text('Edit biodata')),
  OutlinedButton.icon(onPressed:()=>widget.onNavigate(5),icon:const Icon(Icons.favorite_outline),label:const Text('Interests')),
  OutlinedButton.icon(onPressed:()=>widget.onNavigate(14),icon:const Icon(Icons.chat_bubble_outline),label:const Text('Messages')),
 ]));
 Widget _heading(String title,String sub)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:AppPalette.darkMaroon,fontSize:21,fontWeight:FontWeight.w600)),Text(sub,style:const TextStyle(color:AppPalette.secondary,fontSize:12,fontFamily:'sans-serif'))]);
 Widget _notificationsCard(){if(_notifications.isEmpty)return _empty('You are all caught up. New updates will appear here.');return _panel(Column(children:_notifications.take(4).map((raw){final x=raw as Map<String,dynamic>;return ListTile(dense:true,leading:Icon(x['isRead']==true?Icons.notifications_none:Icons.notifications_active_outlined,color:AppPalette.gold),title:Text(x['title']?.toString()??'Update',style:const TextStyle(fontSize:13,color:AppPalette.ink,fontWeight:FontWeight.w600)),subtitle:Text(x['message']?.toString()??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,color:AppPalette.secondary)),trailing:Text(_ago(x['createdAtUtc']),style:const TextStyle(fontSize:10,color:AppPalette.secondary)));}).toList()));}
 Widget _shortlistCard(){if(_shortlist.isEmpty)return _empty('Save profiles with the heart icon and they will appear here.');return _panel(Column(children:_shortlist.take(4).map((raw){final x=raw as Map<String,dynamic>;final name='${x['firstName']??''} ${x['lastName']??''}'.trim();final detail=[x['profession'],x['cityName']].where((v)=>v!=null&&v.toString().isNotEmpty).join(' · ');return ListTile(dense:true,leading:CircleAvatar(backgroundColor:AppPalette.champagne,foregroundColor:AppPalette.darkMaroon,child:Text(name.isEmpty?'V':name[0].toUpperCase())),title:Text(name.isEmpty?'VedicVivah member':name,style:const TextStyle(fontSize:13,color:AppPalette.ink,fontWeight:FontWeight.w600)),subtitle:Text(detail,style:const TextStyle(fontSize:11,color:AppPalette.secondary)),trailing:const Icon(Icons.favorite,color:AppPalette.maroon,size:17));}).toList()));}
 Widget _empty(String message)=>_panel(Row(children:[const Icon(Icons.auto_awesome_outlined,color:AppPalette.gold),const SizedBox(width:10),Expanded(child:Text(message,style:const TextStyle(color:AppPalette.secondary,fontSize:12,height:1.4,fontFamily:'sans-serif')))]));
 Widget _panel(Widget child,{EdgeInsets padding=const EdgeInsets.all(16)})=>Container(padding:padding,decoration:BoxDecoration(color:AppPalette.surface,borderRadius:BorderRadius.circular(17),border:Border.all(color:AppPalette.border)),child:child);
 Widget _errorCard()=>Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppPalette.error.withValues(alpha:.07),borderRadius:BorderRadius.circular(13),border:Border.all(color:AppPalette.error.withValues(alpha:.25))),child:Row(children:[const Icon(Icons.error_outline,color:AppPalette.error),const SizedBox(width:8),Expanded(child:Text(_error!,style:const TextStyle(color:AppPalette.error,fontSize:12))),TextButton(onPressed:_load,child:const Text('Retry'))]));
}