import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

class UserAccountPrivacyScreen extends StatefulWidget {
  const UserAccountPrivacyScreen({super.key,required this.apiClient});
  final ApiClient apiClient;
  @override State<UserAccountPrivacyScreen> createState()=>_UserAccountPrivacyScreenState();
}
class _UserAccountPrivacyScreenState extends State<UserAccountPrivacyScreen> with SingleTickerProviderStateMixin{
  late final TabController tabs;
  @override void initState(){super.initState();tabs=TabController(length:2,vsync:this);}
  @override void dispose(){tabs.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:AppPalette.background,
    appBar:AppBar(backgroundColor:AppPalette.background,title:const Text('Account & privacy',style:TextStyle(color:AppPalette.darkMaroon)),
      bottom:TabBar(controller:tabs,labelColor:AppPalette.maroon,unselectedLabelColor:AppPalette.secondary,indicatorColor:AppPalette.gold,tabs:const [Tab(text:'Account settings'),Tab(text:'Privacy policies')])),
    body:TabBarView(controller:tabs,children:[_AccountSettingsTab(api:widget.apiClient),_PrivacyPoliciesTab(api:widget.apiClient)]),
  );
}

class _AccountSettingsTab extends StatefulWidget{const _AccountSettingsTab({required this.api});final ApiClient api;@override State<_AccountSettingsTab> createState()=>_AccountSettingsTabState();}
class _AccountSettingsTabState extends State<_AccountSettingsTab>{
  bool loading=true,busy=false;String? error,notice;String email='',verificationId='';
  final first=TextEditingController(),last=TextEditingController(),username=TextEditingController(),newEmail=TextEditingController(),current=TextEditingController(),newPassword=TextEditingController(),otp=TextEditingController();
  @override void initState(){super.initState();load();}
  @override void dispose(){for(final c in [first,last,username,newEmail,current,newPassword,otp]){c.dispose();}super.dispose();}
  Future<void> load()async{setState(() { loading=true; error=null; });try{final r=await widget.api.get('/account',authenticated:true);final d=r['data'];if(d is Map){first.text=d['firstName']?.toString()??'';last.text=d['lastName']?.toString()??'';username.text=d['userName']?.toString()??'';email=d['email']?.toString()??'';newEmail.text=email;}}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> run(Future<void> Function() fn)async{setState(() { busy=true; error=null; notice=null; });try{await fn();}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('ApiException: ',''));}finally{if(mounted)setState(()=>busy=false);}}
  Widget field(String label,TextEditingController c,{bool secret=false})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,obscureText:secret,decoration:InputDecoration(labelText:label,filled:true)));
  Widget panel(Widget c)=>Card(color:AppPalette.surface,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14),side:const BorderSide(color:AppPalette.border)),child:Padding(padding:const EdgeInsets.all(14),child:c));
  Widget action(String label,VoidCallback fn)=>SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:fn,child:Text(label)));
  @override Widget build(BuildContext context){if(loading)return const Center(child:CircularProgressIndicator());return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(15),children:[
    if(error!=null)panel(Text(error!,style:const TextStyle(color:AppPalette.error))),if(notice!=null)panel(Text(notice!,style:const TextStyle(color:AppPalette.maroon))),
    panel(Column(children:[
      const Text('Personal details',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      field('First name',first),field('Last name',last),
      action('Update name',()=>run(()async{if(first.text.trim().isEmpty)throw Exception('First name is required.');await widget.api.put('/account/name',body:{'firstName':first.text.trim(),'lastName':last.text.trim().isEmpty?null:last.text.trim()},authenticated:true);setState(()=>notice='Name updated.');})),
    ])),
    panel(Column(children:[
      const Text('Username',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      field('Username',username),
      action('Check availability',()=>run(()async{final r=await widget.api.get('/account/username-availability?username='+Uri.encodeQueryComponent(username.text.trim()),authenticated:true);final d=r['data'];setState(()=>notice=d is Map&&d['available']==true?'Username is available.':'Username is not available.');})),
      action('Update username',()=>run(()async{final value=username.text.trim();if(!RegExp(r'^[a-zA-Z0-9._]{3,30}$').hasMatch(value))throw Exception('Use 3–30 letters, numbers, dots or underscores.');await widget.api.put('/account/username',body:{'username':value},authenticated:true);setState(()=>notice='Username updated.');})),
    ])),
    panel(Column(children:[
      const Text('Change email',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      Text('Current email: '+email),field('New email address',newEmail),field('Current password',current,secret:true),
      action('Send verification code',()=>run(()async{final r=await widget.api.post('/account/email-change',body:{'newEmail':newEmail.text.trim(),'currentPassword':current.text},authenticated:true);final d=r['data'];if(d is Map)verificationId=d['verificationId']?.toString()??'';if(verificationId.isEmpty)throw Exception('The server did not return a verification ID.');setState(()=>notice='Verification code sent. Enter the code below.');})),
      field('6-digit verification code',otp),
      action('Verify email change',()=>run(()async{if(otp.text.trim().length!=6)throw Exception('Enter the 6-digit code.');await widget.api.post('/account/email-change/verify',body:{'verificationId':verificationId,'newEmail':newEmail.text.trim(),'otp':otp.text.trim()},authenticated:true);setState(() { notice='Email updated successfully.'; email=newEmail.text.trim(); verificationId=''; otp.clear(); current.clear(); });})),
    ])),
    panel(Column(children:[
      const Text('Change password',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      field('Current password',current,secret:true),field('New password',newPassword,secret:true),
      action('Update password',()=>run(()async{if(newPassword.text.length<8)throw Exception('New password must be at least 8 characters.');await widget.api.put('/account/password',body:{'currentPassword':current.text,'newPassword':newPassword.text},authenticated:true);setState(() { notice='Password changed.'; current.clear(); newPassword.clear(); });})),
    ])),
    panel(const Text('Profile photo upload and account deactivation/deletion are not included here yet. They need file-upload and confirmation-flow implementation.',style:TextStyle(fontSize:12,color:AppPalette.secondary))),
  ]));}
}

class _PrivacyPoliciesTab extends StatefulWidget{const _PrivacyPoliciesTab({required this.api});final ApiClient api;@override State<_PrivacyPoliciesTab> createState()=>_PrivacyPoliciesTabState();}
class _PrivacyPoliciesTabState extends State<_PrivacyPoliciesTab>{
  bool loading=true,bottom=false,confirmed=false,busy=false;String? error,notice;List<Map<String,dynamic>> policies=[];
  @override void initState(){super.initState();load();}
  Future<void> load()async{setState(() { loading=true; error=null; bottom=false; confirmed=false; });try{final r=await widget.api.get('/privacy-policy/pending-acceptance',authenticated:true);final d=r['data'];policies=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():[];}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> accept()async{setState(()=>busy=true);try{await widget.api.post('/privacy-policy/accept-all',body:{},authenticated:true);await load();if(mounted)setState(()=>notice='Required policies accepted.');}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
  @override Widget build(BuildContext context){if(loading)return const Center(child:CircularProgressIndicator());if(error!=null)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!),TextButton(onPressed:load,child:const Text('Retry'))]));if(policies.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('You have accepted all current privacy policies and terms.',textAlign:TextAlign.center)));
    return Column(children:[
      Padding(padding:const EdgeInsets.all(14),child:Text('Read all required policies to the end before accepting.')),
      Expanded(child:NotificationListener<ScrollNotification>(onNotification:(n){if(n.metrics.pixels>=n.metrics.maxScrollExtent-2&&!bottom)setState(()=>bottom=true);return false;},child:ListView(padding:const EdgeInsets.symmetric(horizontal:14),children:policies.map((p)=>Card(color:AppPalette.surface,child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p['title']?.toString()??'Policy',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:AppPalette.darkMaroon)),const SizedBox(height:8),Text(p['details']?.toString()??'')])))).toList()))),
      CheckboxListTile(value:confirmed,onChanged:bottom? (v)=>setState(()=>confirmed=v??false):null,title:const Text('I have read and agree to all required policies.')),
      Padding(padding:const EdgeInsets.all(14),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:busy||!bottom||!confirmed?null:accept,child:Text(busy?'Submitting...':'Accept all policies')))),
    ]);
  }
}
