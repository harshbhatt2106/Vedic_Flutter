import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/session_store.dart';
import '../../../auth/data/models/auth_models.dart';
import 'dashboard/user_dashboard_screen.dart';
import 'user_tools_screen.dart';
import 'user_interests_screen.dart';
import 'user_workspace_screen.dart';
import 'user_account_privacy_screen.dart';

class UserPanelShell extends StatefulWidget {
  const UserPanelShell({super.key, required this.apiClient, required this.session, required this.onSignOut});
  final ApiClient apiClient;
  final AuthSession session;
  final Future<void> Function() onSignOut;

  @override
  State<UserPanelShell> createState() => _UserPanelShellState();
}

class _UserPanelShellState extends State<UserPanelShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  int _workspaceInitialTab = 0;
  void _navigateFromDashboard(int target){setState((){if(target>=10){_workspaceInitialTab=target-10;_index=6;}else{_index=target;}});}
  void _openSidebar() {
    _scaffoldKey.currentState?.openDrawer();
  }
  void _selectPanel(int index, {int? workspaceTab}) {
    final allowed = _subscriptionExpired
        ? const {0, 6, 7}
        : _approvalRestricted
            ? const {0, 1, 6}
            : const {0, 1, 2, 3, 4, 5, 6, 7};
    Navigator.of(context).pop();
    if (!allowed.contains(index)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This section is unavailable until your profile or subscription status is resolved.')),
      );
      return;
    }
    setState(() {
      _index = index;
      if (index == 6) _workspaceInitialTab = workspaceTab ?? 0;
    });
    if (index == 6 || index == 7) _loadAccountAccess();
  }
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon, color: selected ? AppPalette.maroon : AppPalette.secondary),
    title: Text(title, style: TextStyle(
      color: selected ? AppPalette.darkMaroon : AppPalette.ink,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      fontSize: 14,
    )),
    selected: selected,
    selectedColor: AppPalette.maroon,
    selectedTileColor: AppPalette.champagne.withValues(alpha: .55),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
    onTap: onTap,
  );
  Widget _buildSidebar() => Drawer(
    backgroundColor: AppPalette.background,
    child: SafeArea(child: Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppPalette.darkMaroon, AppPalette.maroon],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.favorite_rounded, color: AppPalette.gold, size: 25),
          SizedBox(height: 10),
          Text('VedicVivah', style: TextStyle(
            color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700,
          )),
          SizedBox(height: 3),
          Text('YOUR PERSONAL SPACE', style: TextStyle(
            color: AppPalette.champagne, fontSize: 10,
            letterSpacing: 1.5, fontWeight: FontWeight.w600,
          )),
        ]),
      ),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(10, 12, 10, 16), children: [
        _drawerItem(icon: Icons.home_outlined, title: 'Dashboard', selected: _index == 0, onTap: () => _selectPanel(0)),
        _drawerItem(icon: Icons.notifications_none_rounded, title: 'Notifications', selected: _index == 1, onTap: () => _selectPanel(1)),
        _drawerItem(icon: Icons.favorite_border_rounded, title: 'Shortlisted Profiles', selected: _index == 2, onTap: () => _selectPanel(2)),
        _drawerItem(icon: Icons.block_outlined, title: 'Blocked Users', selected: _index == 3, onTap: () => _selectPanel(3)),
        _drawerItem(icon: Icons.flag_outlined, title: 'My Reports', selected: _index == 4, onTap: () => _selectPanel(4)),
        _drawerItem(icon: Icons.favorite_outline_rounded, title: 'Interests', selected: _index == 5, onTap: () => _selectPanel(5)),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 12, 7),
          child: Text('MY WORKSPACE', style: TextStyle(
            color: AppPalette.secondary, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.3,
          )),
        ),
        _drawerItem(icon: Icons.search_rounded, title: 'Find Matches', selected: _index == 6 && _workspaceInitialTab == 0, onTap: () => _selectPanel(6, workspaceTab: 0)),
        _drawerItem(icon: Icons.person_outline_rounded, title: 'My Profile / Biodata', selected: _index == 6 && _workspaceInitialTab == 1, onTap: () => _selectPanel(6, workspaceTab: 1)),
        _drawerItem(icon: Icons.photo_library_outlined, title: 'Photos', selected: _index == 6 && _workspaceInitialTab == 2, onTap: () => _selectPanel(6, workspaceTab: 2)),
        _drawerItem(icon: Icons.tune_rounded, title: 'Partner Preferences', selected: _index == 6 && _workspaceInitialTab == 3, onTap: () => _selectPanel(6, workspaceTab: 3)),
        _drawerItem(icon: Icons.chat_bubble_outline_rounded, title: 'Chat / Messages', selected: _index == 6 && _workspaceInitialTab == 4, onTap: () => _selectPanel(6, workspaceTab: 4)),
        _drawerItem(icon: Icons.support_agent_outlined, title: 'Support', selected: _index == 6 && _workspaceInitialTab == 5, onTap: () => _selectPanel(6, workspaceTab: 5)),
        _drawerItem(icon: Icons.workspace_premium_outlined, title: 'Subscription', selected: _index == 6 && _workspaceInitialTab == 6, onTap: () => _selectPanel(6, workspaceTab: 6)),
        _drawerItem(icon: Icons.contacts_outlined, title: 'Reference Contacts', selected: _index == 6 && _workspaceInitialTab == 7, onTap: () => _selectPanel(6, workspaceTab: 7)),
        _drawerItem(icon: Icons.support_agent_rounded, title: 'Mentor', selected: _index == 6 && _workspaceInitialTab == 8, onTap: () => _selectPanel(6, workspaceTab: 8)),
        const Divider(height: 24, color: AppPalette.border),
        _drawerItem(icon: Icons.privacy_tip_outlined, title: 'Account & Privacy', selected: _index == 7, onTap: () => _selectPanel(7)),
      ])),
    ])),
  );
  bool _policyLoading = true;
  String? _policyError;
  bool _subscriptionExpired = false;
  bool _approvalRestricted = false;
  List<Map<String,dynamic>> _pendingPolicies = [];
  @override void initState(){super.initState();_checkPendingPolicies();}
  Future<void> _checkPendingPolicies() async {
    if(mounted)setState(() { _policyLoading=true; _policyError=null; });
    try {
      final r=await widget.apiClient.get('/privacy-policy/pending-acceptance',authenticated:true);
      if(r['success']==false)throw Exception(r['message']??'Unable to verify policy acceptance.');
      final d=r['data'];
      final pending=d is List?d.whereType<Map>().map((x)=>Map<String,dynamic>.from(x)).toList():<Map<String,dynamic>>[];
      if(mounted)setState(()=>_pendingPolicies=pending);
      if(pending.isEmpty)await _loadAccountAccess();
    } catch(e) {
      if(SessionStore.instance.current==null){await widget.onSignOut();return;}
      if(mounted)setState(()=>_policyError=e.toString().replaceFirst('ApiException: ',''));
    } finally { if(mounted)setState(()=>_policyLoading=false); }
  }
  Future<Map<String,dynamic>?> _safeGet(String path) async {
    try{return await widget.apiClient.get(path,authenticated:true);}catch(_){return null;}
  }
  Future<void> _loadAccountAccess() async {
    final results=await Future.wait([
      _safeGet('/subscription-plans/my-subscription'),
      _safeGet('/user-profile'),
    ]);
    final subscription=results[0],profile=results[1];
    if(SessionStore.instance.current==null){await widget.onSignOut();return;}
    if(!mounted)return;
    setState((){
      if(subscription!=null){final data=subscription['data'];_subscriptionExpired=data==null||(data is Map&&data['isExpired']==true);}
      if(profile!=null){final data=profile['data'];final status=data is Map?data['approvalStatus']?.toString()??'Approved':'Approved';_approvalRestricted=status.toLowerCase()!='approved';}
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      UserDashboardScreen(apiClient: widget.apiClient, session: widget.session, onSignOut: widget.onSignOut, onNavigate: _navigateFromDashboard, onOpenMenu: _openSidebar),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.notifications, onOpenMenu: _openSidebar),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.shortlist, onOpenMenu: _openSidebar),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.blocked, onOpenMenu: _openSidebar),
      UserToolsScreen(apiClient: widget.apiClient, kind: UserToolKind.reports, onOpenMenu: _openSidebar),
      UserInterestsScreen(apiClient: widget.apiClient, onOpenChat: ()=>_navigateFromDashboard(14), onOpenMenu: _openSidebar),
      UserWorkspaceScreen(apiClient: widget.apiClient, initialTab: _workspaceInitialTab, subscriptionExpired: _subscriptionExpired, approvalRestricted: _approvalRestricted, onSubscriptionCheck: (){_loadAccountAccess();}, onOpenMenu: _openSidebar),
      UserAccountPrivacyScreen(apiClient: widget.apiClient, onSignOut: widget.onSignOut, onOpenMenu: _openSidebar),
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSidebar(),
      backgroundColor: AppPalette.background,
      body: Stack(children:[
        if(_policyError!=null)Positioned.fill(child:Scaffold(backgroundColor:AppPalette.background,body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.shield_outlined,size:42,color:AppPalette.maroon),const SizedBox(height:12),const Text('Unable to verify required privacy policies.',textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(_policyError!,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton(onPressed:_checkPendingPolicies,child:const Text('Retry'))]))))),
        if(_policyError==null)IndexedStack(index: _index, children: pages),
        if(_policyError==null&&_policyLoading)const Positioned.fill(child:ColoredBox(color:AppPalette.background,child:Center(child:CircularProgressIndicator(color:AppPalette.maroon)))),
        if(_policyError==null&&!_policyLoading&&_pendingPolicies.isNotEmpty)Positioned.fill(child:_MandatoryPrivacyGate(api:widget.apiClient,policies:_pendingPolicies,onAccepted:(){setState(()=>_pendingPolicies=[]);_loadAccountAccess();})),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          final allowed = _subscriptionExpired ? const {0,6,7} : _approvalRestricted ? const {0,1,6} : const {0,1,2,3,4,5,6,7};
          if(!allowed.contains(value)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('This section is unavailable until your profile or subscription status is resolved.')));return;}
          setState(() => _index = value);
          if(value==6||value==7)_loadAccountAccess();
        },
        backgroundColor: AppPalette.surface,
        indicatorColor: AppPalette.champagne,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Updates'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Shortlist'),
          NavigationDestination(icon: Icon(Icons.block_outlined), selectedIcon: Icon(Icons.block), label: 'Blocked'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Interests'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'More'),
          NavigationDestination(icon: Icon(Icons.manage_accounts_outlined), selectedIcon: Icon(Icons.manage_accounts), label: 'Account'),
        ],
      ),
    );
  }
}

class _MandatoryPrivacyGate extends StatefulWidget {
  const _MandatoryPrivacyGate({required this.api,required this.policies,required this.onAccepted});
  final ApiClient api;final List<Map<String,dynamic>> policies;final VoidCallback onAccepted;
  @override State<_MandatoryPrivacyGate> createState()=>_MandatoryPrivacyGateState();
}
class _MandatoryPrivacyGateState extends State<_MandatoryPrivacyGate>{
  final ScrollController controller=ScrollController();
  bool bottom=false,confirmed=false,busy=false;String? error;
  @override void initState(){super.initState();controller.addListener(checkBottom);WidgetsBinding.instance.addPostFrameCallback((_)=>checkBottom());}
  @override void dispose(){controller.removeListener(checkBottom);controller.dispose();super.dispose();}
  void checkBottom(){if(!controller.hasClients)return;final atEnd=controller.position.maxScrollExtent<=1||controller.position.pixels>=controller.position.maxScrollExtent-2;if(atEnd&&!bottom&&mounted)setState(()=>bottom=true);}
  Future<void> accept()async{
    if(!bottom||!confirmed||busy)return;setState(() { busy=true; error=null; });
    try{final accepted=await widget.api.post('/privacy-policy/accept-all',body:{},authenticated:true);if(accepted['success']!=true)throw Exception(accepted['message']??'Policy acceptance was not confirmed.');final r=await widget.api.get('/privacy-policy/pending-acceptance',authenticated:true);if(r['success']!=true)throw Exception(r['message']??'Unable to verify policy acceptance.');final d=r['data'];if(d is List&&d.isNotEmpty)throw Exception('Some required policies are still pending. Please review and accept again.');widget.onAccepted();}
    catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>PopScope(canPop:false,child:Scaffold(
    backgroundColor:AppPalette.background,
    appBar:AppBar(title:const Text('Review required policies'),automaticallyImplyLeading:false,backgroundColor:AppPalette.background),
    body:SafeArea(child:Column(children:[
      const Padding(padding:EdgeInsets.all(14),child:Text('Please read all required policies to the end before accepting.')),
      Expanded(child:NotificationListener<ScrollNotification>(onNotification:(n){checkBottom();return false;},child:ListView(controller:controller,padding:const EdgeInsets.all(14),children:widget.policies.map((p)=>Card(color:AppPalette.surface,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p['title']?.toString()??'Policy',style:const TextStyle(fontWeight:FontWeight.w700,color:AppPalette.darkMaroon,fontSize:18)),const SizedBox(height:8),Text(p['details']?.toString()??'')])))).toList()))),
      CheckboxListTile(value:confirmed,onChanged:bottom?(v)=>setState(()=>confirmed=v??false):null,title:const Text('I have read and agree to all required policies.')),
      if(error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(error!,style:const TextStyle(color:AppPalette.error))),
      Padding(padding:const EdgeInsets.all(14),child:SizedBox(width:double.infinity,child:FilledButton(onPressed:busy||!bottom||!confirmed?null:accept,child:Text(busy?'Submitting...':'Accept all policies')))),
    ])),
  ));
}
