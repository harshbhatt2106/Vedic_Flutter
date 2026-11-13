import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/api/api_client.dart';

class ChatRealtimeService {
  HubConnection? _connection;
  String? _joinedConversationId;
  final ApiClient api;
  final void Function(Map<String,dynamic>) onMessage;
  final void Function(String messageId,String conversationId) onMessageDeleted;

  ChatRealtimeService({required this.api,required this.onMessage,required this.onMessageDeleted});

  Future<void> connect() async {
    if(_connection?.state==HubConnectionState.Connected)return;
    final base=AppConfig.apiBaseUrl.trim().replaceFirst(RegExp(r'/api/?$'),'').replaceFirst(RegExp(r'/+$'),'');
    final url='$base/api/hubs/chat';
    final options=HttpConnectionOptions(accessTokenFactory:() async=>await api.getValidAccessToken()??'');
    final connection=HubConnectionBuilder()
      .withUrl(url,options:options)
      .withAutomaticReconnect(retryDelays:<int>[2000,5000,10000,20000])
      .build();
    connection.on('ReceiveMessage',(arguments){
      if(arguments==null||arguments.isEmpty||arguments.first is! Map)return;
      onMessage(Map<String,dynamic>.from(arguments.first as Map));
    });
    connection.on('MessageDeleted',(arguments){
      if(arguments==null||arguments.length<2)return;
      onMessageDeleted(arguments[0].toString(),arguments[1].toString());
    });
    connection.onreconnected(({connectionId}) async {
      final conversationId=_joinedConversationId;
      if(conversationId!=null){await connection.invoke('JoinConversation',args:<Object>[conversationId]);}
    });
    _connection=connection;
    await connection.start();
    final id=_joinedConversationId;
    if(id!=null)await connection.invoke('JoinConversation',args:<Object>[id]);
  }

  Future<void> joinConversation(String id) async {
    _joinedConversationId=id;
    final connection=_connection;
    if(connection?.state==HubConnectionState.Connected){
      await connection!.invoke('JoinConversation',args:<Object>[id]);
    }
  }

  Future<void> leaveConversation() async {
    final id=_joinedConversationId;
    _joinedConversationId=null;
    final connection=_connection;
    if(id!=null&&connection?.state==HubConnectionState.Connected){
      await connection!.invoke('LeaveConversation',args:<Object>[id]);
    }
  }

  Future<void> dispose() async {
    await leaveConversation();
    final connection=_connection;
    _connection=null;
    if(connection!=null){await connection.stop();}
  }
}
