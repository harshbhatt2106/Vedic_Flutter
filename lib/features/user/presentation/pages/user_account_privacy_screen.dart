import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/session_store.dart';
import '../../../auth/data/models/auth_models.dart';

class UserAccountPrivacyScreen extends StatefulWidget {
  const UserAccountPrivacyScreen({super.key,required this.apiClient,required this.onSignOut});
  final ApiClient apiClient;
  final Future<void> Function() onSignOut;
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
    body:TabBarView(controller:tabs,children:[_AccountSettingsTab(api:widget.apiClient,onSignOut:widget.onSignOut),_PrivacyPoliciesTab(api:widget.apiClient)]),
  );
}

class _AccountSettingsTab extends StatefulWidget{const _AccountSettingsTab({required this.api,required this.onSignOut});final ApiClient api;final Future<void> Function() onSignOut;@override State<_AccountSettingsTab> createState()=>_AccountSettingsTabState();}
class _AccountSettingsTabState extends State<_AccountSettingsTab>{
  bool loading=true,busy=false,usernameAvailable=false;int resendCooldown=0;Timer? resendTimer;String? error,notice;String email='',verificationId='';
  final picker=ImagePicker();final confirmPassword=TextEditingController();
  final first=TextEditingController(),last=TextEditingController(),username=TextEditingController(),newEmail=TextEditingController(),current=TextEditingController(),newPassword=TextEditingController(),otp=TextEditingController();
  @override void initState(){super.initState();load();}
  @override void dispose(){resendTimer?.cancel();for(final c in [first,last,username,newEmail,current,newPassword,otp,confirmPassword]){c.dispose();}
    super.dispose();}
  Future<void> load()async{setState(() { loading=true; error=null; });try{final r=await widget.api.get('/account',authenticated:true);final d=r['data'];if(d is Map){first.text=d['firstName']?.toString()??'';last.text=d['lastName']?.toString()??'';username.text=d['userName']?.toString()??'';email=d['email']?.toString()??'';newEmail.text=email;}}catch(e){error=e.toString();}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> run(Future<void> Function() fn)async{setState(() { busy=true; error=null; notice=null; });try{await fn();}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('ApiException: ',''));}finally{if(mounted)setState(()=>busy=false);}}
  Future<void> uploadAccountPhoto() async { final file=await picker.pickImage(source:ImageSource.gallery,imageQuality:88);if(file==null)return;final bytes=await file.readAsBytes();if(bytes.length>5*1024*1024){setState(()=>error='Photo size cannot exceed 5 MB.');return;}final ext=file.name.split('.').last.toLowerCase();if(!['jpg','jpeg','png','webp'].contains(ext)){setState(()=>error='Choose JPG, PNG or WEBP.');return;}await run(()async{await widget.api.putMultipartFile('/account/profile-picture',bytes:bytes,filename:file.name,authenticated:true);setState(()=>notice='Profile picture updated.');});}
  void startResendCooldown(){
    resendTimer?.cancel();
    setState(()=>resendCooldown=60);
    resendTimer=Timer.periodic(const Duration(seconds:1),(timer){
      if(!mounted){timer.cancel();return;}
      if(resendCooldown<=1){timer.cancel();setState(()=>resendCooldown=0);}
      else{setState(()=>resendCooldown--);}
    });
  }
  Future<void> resendEmailOtp() async {
    if(verificationId.isEmpty||resendCooldown>0)return;
    await run(()async{
      await widget.api.post('/account/email-change/resend',body:{'verificationId':verificationId,'newEmail':newEmail.text.trim()},authenticated:true);
      setState(()=>notice='A new verification code has been sent.');
      startResendCooldown();
    });
  }
  Future<void> deleteAccount() async {
    int step=1;
    bool? married;
    final confirmed=await showDialog<bool>(
      context:context,
      builder:(ctx)=>StatefulBuilder(
        builder:(ctx,setDialog)=>AlertDialog(
          title:Text(step==1?'Delete your account?':step==2?'One quick question…':'Final confirmation'),
          content:step==1
            ?const Text('This will permanently delete your profile, photos, messages and all activity. This action cannot be undone.')
            :step==2
              ?Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Did you find your match on VedicVivah?'),
                RadioListTile<bool>(contentPadding:EdgeInsets.zero,value:true,groupValue:married,onChanged:(v){setDialog((){married=v;});},title:const Text('Yes, I found my partner here')),
                RadioListTile<bool>(contentPadding:EdgeInsets.zero,value:false,groupValue:married,onChanged:(v){setDialog((){married=v;});},title:const Text('No')),
              ])
              :Text(married==true?'Congratulations on finding your partner. Your account will be marked as married and removed.':'Your account and all associated data will be permanently removed.'),
          actions:[
            if(step==1)TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),
            if(step>1)TextButton(onPressed:(){setDialog((){step=step-1;});},child:const Text('Back')),
            if(step<3)FilledButton(onPressed:(){
              if(step==1){setDialog((){step=2;});}
              else if(married!=null){setDialog((){step=3;});}
            },child:Text(step==1?'Continue':'Next')),
            if(step==3)FilledButton(style:FilledButton.styleFrom(backgroundColor:AppPalette.error),onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete my account forever')),
          ],
        ),
      ),
    );
    if(confirmed==true&&married!=null){
      await run(()async{await widget.api.delete('/account?isMarried=$married',authenticated:true);await widget.onSignOut();});
    }
  }
  Widget field(String label,TextEditingController c,{bool secret=false,ValueChanged<String>? onChanged})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,obscureText:secret,onChanged:onChanged,decoration:InputDecoration(labelText:label,filled:true)));
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
      field('Username',username,onChanged:(_)=>setState(()=>usernameAvailable=false)),
      action('Check availability',()=>run(()async{final r=await widget.api.get('/account/username-availability?username='+Uri.encodeQueryComponent(username.text.trim()),authenticated:true);final d=r['data'];usernameAvailable=d is Map&&d['available']==true;setState(()=>notice=usernameAvailable?'Username is available.':'Username is not available.');})),
      action('Update username',()=>run(()async{final value=username.text.trim();if(!RegExp(r'^[a-zA-Z0-9._]{3,30},body:{'username':value},authenticated:true);
        final updated=(r['data'] is Map?(r['data'] as Map)['username']?.toString():null)??value;
        final session=SessionStore.instance.current;
        if(session!=null){await SessionStore.instance.update(AuthSession(userId:session.userId,userName:updated,role:session.role,accessToken:session.accessToken,expiresAtUtc:session.expiresAtUtc,refreshToken:session.refreshToken,refreshTokenExpiresAtUtc:session.refreshTokenExpiresAtUtc));}
        setState(() { username.text=updated; usernameAvailable=false; notice='Username updated.'; });})),
    ])),
    panel(Column(children:[
      const Text('Change email',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      Text('Current email: '+email),field('New email address',newEmail),field('Current password',current,secret:true),
      action('Send verification code',()=>run(()async{final r=await widget.api.post('/account/email-change',body:{'newEmail':newEmail.text.trim(),'currentPassword':current.text},authenticated:true);final d=r['data'];if(d is Map)verificationId=d['verificationId']?.toString()??'';if(verificationId.isEmpty)throw Exception('The server did not return a verification ID.');setState(()=>notice='Verification code sent. Enter the code below.');startResendCooldown();})),
      field('6-digit verification code',otp),
      if(verificationId.isNotEmpty)Align(alignment:Alignment.centerRight,child:TextButton(onPressed:busy||resendCooldown>0?null:resendEmailOtp,child:Text(resendCooldown>0?'Resend code in '+resendCooldown.toString()+'s':'Resend code'))),
      action('Verify email change',()=>run(()async{if(otp.text.trim().length!=6)throw Exception('Enter the 6-digit code.');await widget.api.post('/account/email-change/verify',body:{'verificationId':verificationId,'newEmail':newEmail.text.trim(),'otp':otp.text.trim()},authenticated:true);setState(() { notice='Email updated successfully.'; email=newEmail.text.trim(); verificationId=''; otp.clear(); current.clear(); });})),
    ])),
    panel(Column(children:[
      const Text('Change password',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      field('Current password',current,secret:true),field('New password',newPassword,secret:true),field('Confirm new password',confirmPassword,secret:true),
      action('Update password',()=>run(()async{if(current.text.isEmpty)throw Exception('Enter your current password.');if(newPassword.text.length<8||newPassword.text.length>128)throw Exception('New password must be 8–128 characters.');if(newPassword.text==current.text)throw Exception('New password must be different from your current password.');if(newPassword.text!=confirmPassword.text)throw Exception('New password and confirmation do not match.');await widget.api.put('/account/password',body:{'currentPassword':current.text,'newPassword':newPassword.text},authenticated:true);setState(() { notice='Password changed.'; current.clear(); newPassword.clear(); confirmPassword.clear(); });})),
    ])),
    panel(Column(children:[
      const Text('Profile picture',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      action('Change profile picture',uploadAccountPhoto),
    ])),
    panel(Column(children:[
      const Text('Account security',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      const SizedBox(height:8),
      SizedBox(width:double.infinity,child:OutlinedButton(onPressed:busy?null:deleteAccount,style:OutlinedButton.styleFrom(foregroundColor:AppPalette.error),child:const Text('Delete account permanently'))),
    ])),
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
).hasMatch(value))throw Exception('Use 3–30 letters, numbers, dots or underscores.');if(!usernameAvailable)throw Exception('Check that the username is available before saving.');final r=await widget.api.put('/account/username',body:{'username':value},authenticated:true);
        final updated=(r['data'] is Map?(r['data'] as Map)['username']?.toString():null)??value;
        final session=SessionStore.instance.current;
        if(session!=null){await SessionStore.instance.update(AuthSession(userId:session.userId,userName:updated,role:session.role,accessToken:session.accessToken,expiresAtUtc:session.expiresAtUtc,refreshToken:session.refreshToken,refreshTokenExpiresAtUtc:session.refreshTokenExpiresAtUtc));}
        setState(() { username.text=updated; notice='Username updated.'; });})),
    ])),
    panel(Column(children:[
      const Text('Change email',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      Text('Current email: '+email),field('New email address',newEmail),field('Current password',current,secret:true),
      action('Send verification code',()=>run(()async{final r=await widget.api.post('/account/email-change',body:{'newEmail':newEmail.text.trim(),'currentPassword':current.text},authenticated:true);final d=r['data'];if(d is Map)verificationId=d['verificationId']?.toString()??'';if(verificationId.isEmpty)throw Exception('The server did not return a verification ID.');setState(()=>notice='Verification code sent. Enter the code below.');})),
      field('6-digit verification code',otp),
      if(verificationId.isNotEmpty)Align(alignment:Alignment.centerRight,child:TextButton(onPressed:busy?null:resendEmailOtp,child:const Text('Resend code'))),
      action('Verify email change',()=>run(()async{if(otp.text.trim().length!=6)throw Exception('Enter the 6-digit code.');await widget.api.post('/account/email-change/verify',body:{'verificationId':verificationId,'newEmail':newEmail.text.trim(),'otp':otp.text.trim()},authenticated:true);setState(() { notice='Email updated successfully.'; email=newEmail.text.trim(); verificationId=''; otp.clear(); current.clear(); });})),
    ])),
    panel(Column(children:[
      const Text('Change password',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      field('Current password',current,secret:true),field('New password',newPassword,secret:true),field('Confirm new password',confirmPassword,secret:true),
      action('Update password',()=>run(()async{if(current.text.isEmpty)throw Exception('Enter your current password.');if(newPassword.text.length<8||newPassword.text.length>128)throw Exception('New password must be 8–128 characters.');if(newPassword.text==current.text)throw Exception('New password must be different from your current password.');if(newPassword.text!=confirmPassword.text)throw Exception('New password and confirmation do not match.');await widget.api.put('/account/password',body:{'currentPassword':current.text,'newPassword':newPassword.text},authenticated:true);setState(() { notice='Password changed.'; current.clear(); newPassword.clear(); confirmPassword.clear(); });})),
    ])),
    panel(Column(children:[
      const Text('Profile picture',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      action('Change profile picture',uploadAccountPhoto),
    ])),
    panel(Column(children:[
      const Text('Account security',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.maroon)),
      const SizedBox(height:8),
      SizedBox(width:double.infinity,child:OutlinedButton(onPressed:busy?null:deleteAccount,style:OutlinedButton.styleFrom(foregroundColor:AppPalette.error),child:const Text('Delete account permanently'))),
    ])),
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
