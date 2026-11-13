import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_role_landing_screen.dart';
import 'login_screen.dart';
class AuthGate extends StatefulWidget {
 const AuthGate({super.key,required this.repository,required this.apiClient});
 final AuthRepository repository; final ApiClient apiClient;
 @override State<AuthGate> createState()=>_AuthGateState();
}
class _AuthGateState extends State<AuthGate>{
 late final Future<AuthSession?> _session=widget.repository.restoreSession();
 @override Widget build(BuildContext context)=>FutureBuilder<AuthSession?>(future:_session,builder:(context,snapshot){
 if(snapshot.connectionState!=ConnectionState.done)return const Scaffold(backgroundColor:Color(0xFFF7F1E8),body:Center(child:CircularProgressIndicator(color:Color(0xFF741B35))));
 final session=snapshot.data;
 return session==null?LoginScreen(repository:widget.repository,apiClient:widget.apiClient):AuthRoleLandingScreen(repository:widget.repository,apiClient:widget.apiClient,session:session);
 });
}