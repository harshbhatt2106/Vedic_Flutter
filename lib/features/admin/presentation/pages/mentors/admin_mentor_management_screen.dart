import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_member.dart';
import '../../../data/models/admin_mentor_models.dart';
import 'admin_mentor_form_sheet.dart';

class AdminMentorManagementScreen extends StatefulWidget {
  const AdminMentorManagementScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<AdminMentorManagementScreen> createState() => _AdminMentorManagementScreenState();
}

class _AdminMentorManagementScreenState extends State<AdminMentorManagementScreen> {
  bool _loading = true;
  String? _error;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  List<AdminMember> _mentors = [];

  @override
  void initState() {
    super.initState();
    _loadMentors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMentors() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.apiClient.get('/admin/users?page=1&pageSize=100', authenticated: true);
      final data = response['data'];
      final raw = data is Map ? data['items'] : null;
      final users = raw is List
          ? raw.whereType<Map>().map((item) => AdminMember.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminMember>[];
      if (!mounted) return;
      setState(() {
        _mentors = users.where((user) => user.roleName == 'Mentor' && !user.isDeleted).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  List<AdminMember> get _filtered {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _mentors;
    return _mentors.where((mentor) => [
      mentor.firstName,
      mentor.lastName,
      mentor.userName,
      mentor.email,
      mentor.mobileNumber,
    ].whereType<String>().join(' ').toLowerCase().contains(query)).toList();
  }

  Future<void> _openForm([AdminMember? mentor]) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => AdminMentorFormSheet(apiClient: widget.apiClient, mentor: mentor),
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _loadMentors();
  }

  Future<void> _openProfile(AdminMember mentor) async {
    AdminMentorLocation? location;
    try {
      final response = await widget.apiClient.get('/admin/mentors/${mentor.userId}/location', authenticated: true);
      if (response['data'] is Map) {
        location = AdminMentorLocation.fromJson(Map<String, dynamic>.from(response['data'] as Map));
      }
    } catch (_) {
      // Location is optional in the profile view; keep the rest of the mentor details available.
    }
    if (!mounted) return;
    final shouldEdit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => AdminMentorProfileSheet(mentor: mentor, location: location),
    );
    if (shouldEdit == true && mounted) _openForm(mentor);
  }

  Future<void> _openMembers(AdminMember mentor) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => AdminMentorMembersSheet(apiClient: widget.apiClient, mentor: mentor),
    );
    if (mounted) _loadMentors();
  }

  Future<void> _toggleActive(AdminMember mentor) async {
    final action = mentor.isActive ? 'deactivate' : 'activate';
    try {
      await widget.apiClient.put(
        '/admin/mentors/${mentor.userId}',
        body: {
          'firstName': mentor.firstName ?? '',
          'lastName': mentor.lastName ?? '',
          'mobileNumber': mentor.mobileNumber,
          'email': mentor.email ?? '',
          'isActive': !mentor.isActive,
        },
        authenticated: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${mentor.displayName} is now ${action == 'activate' ? 'active' : 'inactive'}.')),
      );
      _loadMentors();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _deleteMentor(AdminMember mentor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete mentor?'),
        content: Text('Delete ${mentor.displayName}? This deactivates the account and keeps its record as a soft delete.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete mentor')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.apiClient.delete('/admin/mentors/${mentor.userId}', authenticated: true);
      if (!mounted) return;
      setState(() => _mentors.removeWhere((item) => item.userId == mentor.userId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${mentor.displayName} was deleted.')));
      _loadMentors();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))));
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
    final mentors = _filtered;
    final active = _mentors.where((mentor) => mentor.isActive).length;
    return RefreshIndicator(
      color: AppPalette.maroon,
      onRefresh: _loadMentors,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const Text('PEOPLE & ACCESS', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 1.8, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Mentor management', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text('Create mentor accounts and manage their assigned members.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _MentorMetric(label: 'Total mentors', value: _mentors.length)),
            const SizedBox(width: 8),
            Expanded(child: _MentorMetric(label: 'Active', value: active)),
            const SizedBox(width: 8),
            Expanded(child: _MentorMetric(label: 'Inactive', value: _mentors.length - active)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create mentor'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Search name, username, email or mobile',
              prefixIcon: const Icon(Icons.search, color: AppPalette.secondary),
              suffixIcon: _search.isEmpty ? null : IconButton(onPressed: () {
                _searchController.clear();
                setState(() => _search = '');
              }, icon: const Icon(Icons.close)),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading && _mentors.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon))),
          if (!_loading && _error != null)
            _MentorStateCard(title: 'Could not load mentors', message: _error!, action: TextButton.icon(onPressed: _loadMentors, icon: const Icon(Icons.refresh), label: const Text('Retry'))),
          if (!_loading && _error == null && mentors.isEmpty)
            _MentorStateCard(title: 'No mentors found', message: _search.isEmpty ? 'No active mentor records were returned by the Admin API.' : 'No mentors match this search.'),
          if (mentors.isNotEmpty) ...[
            Text('${mentors.length} mentors', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...mentors.map((mentor) => _MentorCard(
              mentor: mentor,
              date: _date(mentor.createdAtUtc),
              onView: () => _openProfile(mentor),
              onMembers: () => _openMembers(mentor),
              onToggle: () => _toggleActive(mentor),
              onDelete: () => _deleteMentor(mentor),
            )),
          ],
          const SizedBox(height: 8),
          const Text('The web Admin page loads the first 100 users, then keeps Mentor-role and non-deleted accounts. Search is local; this page does not paginate.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ],
      ),
    );
  }
}

class _MentorMetric extends StatelessWidget {
  const _MentorMetric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.ink)),
          Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ]),
      );
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({required this.mentor, required this.date, required this.onView, required this.onMembers, required this.onToggle, required this.onDelete});
  final AdminMember mentor;
  final String date;
  final VoidCallback onView;
  final VoidCallback onMembers;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = mentor.isActive ? const Color(0xFF287A55) : AppPalette.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: AppPalette.champagne, foregroundColor: AppPalette.maroon, child: Text(mentor.displayName.isEmpty ? 'M' : mentor.displayName[0].toUpperCase())),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mentor.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(mentor.email ?? mentor.userName, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)), child: Text(mentor.isActive ? 'Active' : 'Inactive', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: color, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.phone_outlined, size: 14, color: AppPalette.gold),
          const SizedBox(width: 5),
          Expanded(child: Text(mentor.mobileNumber, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary))),
          const Icon(Icons.calendar_today_outlined, size: 13, color: AppPalette.gold),
          const SizedBox(width: 5),
          Text(date, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ]),
        const Divider(height: 18, color: AppPalette.border),
        Wrap(spacing: 4, runSpacing: 0, children: [
          TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility_outlined, size: 15), label: const Text('Profile')),
          TextButton.icon(onPressed: onMembers, icon: const Icon(Icons.groups_outlined, size: 15), label: const Text('Members')),
          TextButton.icon(onPressed: onToggle, icon: Icon(mentor.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 15), label: Text(mentor.isActive ? 'Deactivate' : 'Activate')),
          TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 15, color: AppPalette.error), label: const Text('Delete', style: TextStyle(color: AppPalette.error))),
        ]),
      ]),
    );
  }
}

class AdminMentorProfileSheet extends StatelessWidget {
  const AdminMentorProfileSheet({super.key, required this.mentor, required this.location});
  final AdminMember mentor;
  final AdminMentorLocation? location;

  @override
  Widget build(BuildContext context) {
    final address = [location?.cityName, location?.stateName, location?.countryName].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppPalette.border, borderRadius: BorderRadius.circular(5)))),
          const SizedBox(height: 18),
          Row(children: [
            CircleAvatar(radius: 25, backgroundColor: AppPalette.champagne, foregroundColor: AppPalette.maroon, child: Text(mentor.displayName.isEmpty ? 'M' : mentor.displayName[0].toUpperCase())),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mentor.displayName, style: Theme.of(context).textTheme.titleLarge),
              const Text('Mentor account', style: TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
            ])),
          ]),
          const SizedBox(height: 18),
          _MentorProfileLine(label: 'Username', value: mentor.userName),
          _MentorProfileLine(label: 'Email', value: mentor.email ?? 'Not provided'),
          _MentorProfileLine(label: 'Mobile', value: mentor.mobileNumber),
          _MentorProfileLine(label: 'Location', value: address.isEmpty ? 'Not available' : address),
          _MentorProfileLine(label: 'Account status', value: mentor.isActive ? 'Active' : 'Inactive'),
          _MentorProfileLine(label: 'Email verified', value: mentor.isEmailVerified ? 'Yes' : 'No'),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.edit_outlined), label: const Text('Edit mentor'))),
        ]),
      ),
    );
  }
}

class _MentorProfileLine extends StatelessWidget {
  const _MentorProfileLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.ink, fontWeight: FontWeight.w600))),
        ]),
      );
}

class AdminMentorMembersSheet extends StatefulWidget {
  const AdminMentorMembersSheet({super.key, required this.apiClient, required this.mentor});
  final ApiClient apiClient;
  final AdminMember mentor;

  @override
  State<AdminMentorMembersSheet> createState() => _AdminMentorMembersSheetState();
}

class _AdminMentorMembersSheetState extends State<AdminMentorMembersSheet> {
  bool _loading = true;
  String? _error;
  bool _busy = false;
  List<AdminAssignedMember> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await widget.apiClient.get('/admin/mentors/${widget.mentor.userId}/members', authenticated: true);
      final raw = response['data'];
      final members = raw is List
          ? raw.whereType<Map>().map((item) => AdminAssignedMember.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminAssignedMember>[];
      if (!mounted) return;
      setState(() { _members = members; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString().replaceFirst('ApiException: ', ''); _loading = false; });
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Date unavailable';
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _remove(AdminAssignedMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member assignment?'),
        content: Text('Remove ${member.displayName} from ${widget.mentor.displayName}? The member account and any other mentor assignments will remain unchanged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || _busy || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await widget.apiClient.delete('/admin/user-mentor-assignments/${member.userId}/${widget.mentor.userId}', authenticated: true);
      if (!mounted) return;
      setState(() => _members.removeWhere((item) => item.userId == member.userId));
      messenger.showSnackBar(const SnackBar(content: Text('Member removed from this mentor.')));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .88,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppPalette.border, borderRadius: BorderRadius.circular(5)))),
              const SizedBox(height: 16),
              Text('Assigned members', style: Theme.of(context).textTheme.titleLarge),
              Text(widget.mentor.displayName, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
              const SizedBox(height: 12),
              if (_loading) const Expanded(child: Center(child: CircularProgressIndicator(color: AppPalette.maroon))),
              if (!_loading && _error != null) Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, textAlign: TextAlign.center),
                TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ]))),
              if (!_loading && _error == null && _members.isEmpty) const Expanded(child: Center(child: Text('No directly assigned members.'))),
              if (!_loading && _error == null && _members.isNotEmpty) Expanded(child: ListView.separated(
                itemCount: _members.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppPalette.border),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: AppPalette.champagne, foregroundColor: AppPalette.maroon, child: Text(member.displayName.isEmpty ? '?' : member.displayName[0].toUpperCase())),
                    title: Text(member.displayName.isEmpty ? member.userName : member.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text('${member.mobileNumber} · ${member.isActive ? 'Active' : 'Inactive'} · ${_date(member.assignedAtUtc)}', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
                    trailing: IconButton(
                      onPressed: _busy ? null : () => _remove(member),
                      icon: const Icon(Icons.person_remove_outlined, color: AppPalette.error),
                      tooltip: 'Remove assignment',
                    ),
                  );
                },
              )),
            ]),
          ),
        ),
      );
}

class _MentorStateCard extends StatelessWidget {
  const _MentorStateCard({required this.title, required this.message, this.action});
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
        child: Column(children: [
          const Icon(Icons.support_agent_outlined, size: 30, color: AppPalette.gold),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
          if (action != null) action!,
        ]),
      );
}
