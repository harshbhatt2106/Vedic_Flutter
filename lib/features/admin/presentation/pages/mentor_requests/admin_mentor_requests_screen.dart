import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_mentor_request_models.dart';

class AdminMentorRequestsScreen extends StatefulWidget {
  const AdminMentorRequestsScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<AdminMentorRequestsScreen> createState() => _AdminMentorRequestsScreenState();
}

class _AdminMentorRequestsScreenState extends State<AdminMentorRequestsScreen> {
  static const _statuses = ['Pending', 'Fulfilled', 'Rejected', 'All'];
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _status = 'Pending';
  bool _requestsLoading = true;
  bool _statsLoading = true;
  String? _requestsError;
  String? _statsError;
  String? _assigningTo;
  List<AdminMentorUserRequest> _requests = [];
  List<AdminMentorStat> _mentors = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_loadRequests(), _loadStats()]);
  }

  Future<void> _loadRequests() async {
    setState(() { _requestsLoading = true; _requestsError = null; });
    try {
      final response = await widget.apiClient.get('/admin/mentor-user-requests', authenticated: true);
      final raw = response['data'];
      final items = raw is List
          ? raw.whereType<Map>().map((item) => AdminMentorUserRequest.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminMentorUserRequest>[];
      if (!mounted) return;
      setState(() { _requests = items; _requestsLoading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _requestsError = error.toString().replaceFirst('ApiException: ', ''); _requestsLoading = false; });
    }
  }

  Future<void> _loadStats() async {
    setState(() { _statsLoading = true; _statsError = null; });
    try {
      final response = await widget.apiClient.get('/admin/mentor-stats', authenticated: true);
      final raw = response['data'];
      final items = raw is List
          ? raw.whereType<Map>().map((item) => AdminMentorStat.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminMentorStat>[];
      if (!mounted) return;
      setState(() { _mentors = items; _statsLoading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _statsError = error.toString().replaceFirst('ApiException: ', ''); _statsLoading = false; });
    }
  }

  List<AdminMentorUserRequest> get _filteredRequests {
    final term = _search.trim().toLowerCase();
    return _requests.where((request) {
      final matchesStatus = _status == 'All' || request.status.toLowerCase() == _status.toLowerCase();
      final matchesSearch = term.isEmpty || [
        request.requestedName,
        request.requestedMobileNumber,
        request.mentorName,
      ].join(' ').toLowerCase().contains(term);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  int _statusCount(String status) => _requests.where((item) => item.status.toLowerCase() == status.toLowerCase()).length;

  Future<void> _assign(AdminMentorUserRequest request) async {
    if (_assigningTo != null) return;
    setState(() => _assigningTo = request.id);
    try {
      final response = await widget.apiClient.post(
        '/admin/mentor-user-requests/${request.id}/assign',
        body: const {},
        authenticated: true,
      );
      if (response['success'] == false) {
        throw Exception(response['message']?.toString() ?? 'Could not assign this request.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message']?.toString() ?? '${request.requestedName} assigned to ${request.mentorName}.')));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _assigningTo = null);
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Date unavailable';
    final date = value.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final requests = _filteredRequests;
    return RefreshIndicator(
      color: AppPalette.maroon,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const Text('MENTOR OPERATIONS', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 1.8, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Mentor requests', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text('Process requests submitted by mentors and review their direct member counts.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Mentor requests',
            subtitle: 'Requests are listed newest first.',
            child: Column(children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Search name, mobile or mentor',
                  prefixIcon: const Icon(Icons.search, color: AppPalette.secondary),
                  suffixIcon: _search.isEmpty ? null : IconButton(onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  }, icon: const Icon(Icons.close)),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _statuses.map((status) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    selected: _status == status,
                    label: Text(status == 'All' ? 'All (${_requests.length})' : '$status (${_statusCount(status)})'),
                    onSelected: (_) => setState(() => _status = status),
                    selectedColor: AppPalette.maroon,
                    backgroundColor: AppPalette.background,
                    labelStyle: TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: _status == status ? AppPalette.surface : AppPalette.secondary, fontWeight: FontWeight.w600),
                    side: BorderSide(color: _status == status ? AppPalette.maroon : AppPalette.border),
                  ),
                )).toList()),
              ),
              const SizedBox(height: 8),
              if (_requestsLoading && _requests.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon))),
              if (!_requestsLoading && _requestsError != null)
                _StateCard(title: 'Could not load mentor requests', message: _requestsError!, action: TextButton.icon(onPressed: _loadRequests, icon: const Icon(Icons.refresh), label: const Text('Retry'))),
              if (!_requestsLoading && _requestsError == null && _requests.isEmpty)
                const _StateCard(title: 'No requests yet', message: 'Mentor requests will appear here when submitted.'),
              if (!_requestsLoading && _requestsError == null && _requests.isNotEmpty && requests.isEmpty)
                const _StateCard(title: 'No matching requests', message: 'Try another status or search term.'),
              if (!_requestsLoading && _requestsError == null && requests.isNotEmpty) ...[
                Align(alignment: Alignment.centerLeft, child: Text('${requests.length} requests shown', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w700))),
                const SizedBox(height: 7),
                ...requests.map((request) => _RequestCard(
                  request: request,
                  date: _date(request.createdAtUtc),
                  assigning: _assigningTo == request.id,
                  onAssign: request.status.toLowerCase() == 'pending' ? () => _assign(request) : null,
                )),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Mentor member counts',
            subtitle: 'Direct assignments only; deleted member accounts are excluded.',
            child: _statsLoading && _mentors.isEmpty
                ? const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon)))
                : _statsError != null
                    ? _StateCard(title: 'Could not load mentor counts', message: _statsError!, action: TextButton.icon(onPressed: _loadStats, icon: const Icon(Icons.refresh), label: const Text('Retry')))
                    : _mentors.isEmpty
                        ? const _StateCard(title: 'No mentors found', message: 'No mentor statistics were returned by the server.')
                        : Column(children: [
                            Row(children: [
                              const Expanded(child: Text('Mentor', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w700, color: AppPalette.secondary))),
                              const Text('Members', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w700, color: AppPalette.secondary)),
                            ]),
                            const Divider(color: AppPalette.border),
                            ..._mentors.map((mentor) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(mentor.displayName.isEmpty ? 'Mentor' : mentor.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(mentor.mobileNumber, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
                                ])),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 42),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AppPalette.champagne, borderRadius: BorderRadius.circular(20)),
                                  child: Text(mentor.memberCount.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: AppPalette.maroon)),
                                ),
                              ]),
                            )),
                          ]),
          ),
          const SizedBox(height: 8),
          const Text('Assign works only for Pending requests. The server looks up a registered account by the requested mobile number, assigns it to the mentor and marks the request Fulfilled. There is no Admin reject action in the current API.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
          const SizedBox(height: 13),
          child,
        ]),
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.date, required this.assigning, required this.onAssign});
  final AdminMentorUserRequest request;
  final String date;
  final bool assigning;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final status = request.status.toLowerCase();
    final color = status == 'fulfilled' ? const Color(0xFF287A55) : status == 'rejected' ? AppPalette.error : AppPalette.gold;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppPalette.background, borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(request.requestedName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)), child: Text(request.status, style: TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: color, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 6),
        Text(request.requestedMobileNumber, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
        const SizedBox(height: 7),
        Row(children: [
          const Icon(Icons.support_agent_outlined, size: 14, color: AppPalette.gold),
          const SizedBox(width: 5),
          Expanded(child: Text(request.mentorName.isEmpty ? 'Unknown mentor' : request.mentorName, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11))),
          Text(date, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppPalette.secondary)),
        ]),
        if (onAssign != null) ...[
          const SizedBox(height: 9),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: assigning ? null : onAssign,
            child: assigning ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne)) : const Text('Assign to mentor'),
          )),
        ] else
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('Processed', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary))),
      ]),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.message, this.action});
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          const Icon(Icons.inbox_outlined, size: 28, color: AppPalette.gold),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
          if (action != null) action!,
        ]),
      );
}
