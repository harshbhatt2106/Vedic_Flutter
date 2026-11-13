import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../user/presentation/pages/dashboard/user_dashboard_screen.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';
class AuthRoleLandingScreen extends StatelessWidget {
 const AuthRoleLandingScreen({super.key,required this.repository,required this.apiClient,required this.session});
 final AuthRepository repository; final ApiClient apiClient; final AuthSession session;
 @override Widget build(BuildContext context){
 if(session.role=='User') { return UserDashboardScreen(apiClient:apiClient,session:session,onSignOut:() async{
 await repository.logout(); if(!context.mounted)return;
 Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>LoginScreen(repository:repository)),(_)=>false);
 }); }
 final destination=session.role=='Admin'?'Admin Dashboard':'Mentor Dashboard';
 return Scaffold(backgroundColor:const Color(0xFFF7F1E8),body:SafeArea(child:Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
 const Icon(Icons.verified_user_outlined,size:52,color:Color(0xFFB68A55)),const SizedBox(height:22),
 Text('Welcome, ${session.userName}',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineMedium),
 const SizedBox(height:10),Text('You are securely signed in as ${session.role}.',textAlign:TextAlign.center),
 const SizedBox(height:28),Text(destination,style:Theme.of(context).textTheme.titleLarge),
 const SizedBox(height:10),const Text('This role dashboard is the next implementation stage.',textAlign:TextAlign.center),
 const SizedBox(height:28),OutlinedButton(onPressed:() async{await repository.logout();if(!context.mounted)return;Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>LoginScreen(repository:repository)),(_)=>false);},child:const Text('Sign out')),
 ])))));
 }
}