import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/api/api_client.dart';

class UserInterestsScreen extends StatefulWidget {
  const UserInterestsScreen({super.key, required this.apiClient, required this.onOpenChat});
  final ApiClient apiClient;
  final VoidCallback onOpenChat;

  @override
  State<UserInterestsScreen> createState() => _UserInterestsScreenState();
}

class _UserInterestsScreenState extends State<UserInterestsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  bool _working = false;
  String? _error;
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sent = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(() {
      if (mounted && !_tabs.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.apiClient.get('/interests/received', authenticated: true),
        widget.apiClient.get('/interests/sent', authenticated: true),
      ]);
      if (!mounted) return;
      List<Map<String, dynamic>> parse(dynamic raw) => raw is List
          ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _received = parse(results[0]['data']);
        _sent = parse(results[1]['data']);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _read(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return '';
  }

  Future<void> _openChat(Map<String,dynamic> item) async { final userId=_read(item,['userId']);if(userId.isEmpty)return;setState(()=>_working=true);try{await widget.apiClient.post('/conversations/$userId',body:{},authenticated:true);widget.onOpenChat();}catch(e){if(mounted)setState(()=>_error=e.toString().replaceFirst('ApiException: ',''));}finally{if(mounted)setState(()=>_working=false);} }

  Future<void> _act(Map<String, dynamic> item, String action) async {
    final id = _read(item, ['id']);
    if (id.isEmpty) return;
    final labels = {
      'accept': 'Accept this interest?',
      'reject': 'Reject this interest?',
      'resubmit': 'Send this rejected interest again?',
      'withdraw': 'Withdraw this interest?',
    };
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Confirm action'),
      content: Text(labels[action] ?? 'Continue?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
      ],
    ));
    if (confirm != true) return;
    setState(() => _working = true);
    try {
      if (action == 'accept' || action == 'reject' || action == 'resubmit') {
        await widget.apiClient.put('/interests/' + id + '/' + action, body: {}, authenticated: true);
      } else if (action == 'withdraw') {
        await widget.apiClient.delete('/interests/' + id, authenticated: true);
      }
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receivedTab = _tabs.index == 0;
    final items = receivedTab ? _received : _sent;
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        title: const Text('Interests', style: TextStyle(color: AppPalette.darkMaroon)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppPalette.maroon,
          unselectedLabelColor: AppPalette.secondary,
          indicatorColor: AppPalette.gold,
          tabs: const [Tab(text: 'Received'), Tab(text: 'Sent')],
        ),
        actions: [IconButton(onPressed: _loading || _working ? null : _load, icon: const Icon(Icons.refresh, color: AppPalette.maroon))],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppPalette.maroon))
        : _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ])))
          : items.isEmpty
            ? Center(child: Text(receivedTab ? 'No interests received yet.' : 'You have not sent any interests yet.', style: const TextStyle(color: AppPalette.secondary)))
            : RefreshIndicator(
                color: AppPalette.maroon,
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) => _card(items[index], receivedTab),
                ),
              ),
    );
  }

  Widget _card(Map<String, dynamic> item, bool received) {
    final first = _read(item, ['firstName']);
    final last = _read(item, ['lastName']);
    final name = (first + ' ' + last).trim();
    final status = _read(item, ['status']);
    final details = [_read(item, ['profession']), _read(item, ['cityName']), _read(item, ['religionName']), _read(item, ['casteName'])]
        .where((value) => value.isNotEmpty).join(' · ');
    final actions = <Widget>[];
    if (received && status == 'Pending') {
      actions.add(TextButton(onPressed: _working ? null : () => _act(item, 'reject'), child: const Text('Reject')));
      actions.add(FilledButton(onPressed: _working ? null : () => _act(item, 'accept'), child: const Text('Accept')));
    } else if (!received && status == 'Rejected') {
      actions.add(FilledButton(onPressed: _working ? null : () => _act(item, 'resubmit'), child: const Text('Resend')));
    } else if (!received && status == 'Pending') {
      actions.add(TextButton(onPressed: _working ? null : () => _act(item, 'withdraw'), child: const Text('Withdraw')));
    } else if (status == 'Accepted') {
      actions.add(const Text('Accepted', style: TextStyle(color: AppPalette.gold, fontWeight: FontWeight.w600)));
      actions.add(TextButton(onPressed:_working?null:()=>_openChat(item),child:const Text('Message')));
    }
    return Card(
      color: AppPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppPalette.border)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: AppPalette.champagne, child: Text(name.isEmpty ? 'V' : name[0].toUpperCase(), style: const TextStyle(color: AppPalette.maroon))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? 'VedicVivah member' : name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppPalette.darkMaroon)),
              if (details.isNotEmpty) Text(details, style: const TextStyle(fontSize: 12, color: AppPalette.secondary)),
            ])),
            Text(status, style: const TextStyle(fontSize: 11, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          ]),
          if (actions.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ),
        ]),
      ),
    );
  }
}
