import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_member.dart';
import '../../../data/models/admin_profile_review_models.dart';
import '../pending_requests/profile_review_detail_screen.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  static const _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  String _search = '';
  String _role = 'All';
  String _status = 'All';
  String _gender = 'All';
  String _completion = 'All';
  int _page = 1;
  int _totalCount = 0;
  bool _loading = true;
  String? _error;
  List<AdminMember> _members = [];
  Map<String, Uint8List> _avatars = {};
  List<Map<String, String>> _mentors = [];
  bool _mentorsLoaded = false;

  int get _totalPages => _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final query = <String, String>{
      'page': '$_page',
      'pageSize': '$_pageSize',
    };
    if (_search.trim().isNotEmpty) query['search'] = _search.trim();
    if (_role != 'All') query['role'] = _role;
    if (_gender != 'All') query['gender'] = _gender;
    if (_status != 'All') query['isActive'] = (_status == 'Active').toString();
    if (_completion != 'All') query['isProfileComplete'] = (_completion == 'Complete').toString();

    try {
      final response = await widget.apiClient.get(
        '/admin/users?${Uri(queryParameters: query).query}',
        authenticated: true,
      );
      final data = response['data'];
      if (data is! Map) throw const FormatException('The member list response was not in the expected format.');
      final rawItems = data['items'];
      final items = rawItems is List
          ? rawItems.whereType<Map>().map((item) => AdminMember.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminMember>[];
      if (!mounted) return;
      setState(() {
        _members = items;
        _totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
        _avatars = {};
        _loading = false;
      });
      _loadAvatars(items);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadAvatars(List<AdminMember> members) async {
    final results = await Future.wait(members.map((member) async {
      try {
        final bytes = await widget.apiClient.getBytes(
          '/admin/users/${member.userId}/primary-photo',
          authenticated: true,
        );
        return MapEntry<String, Uint8List>(member.userId, bytes);
      } catch (_) {
        return null;
      }
    }));
    if (!mounted) return;
    setState(() {
      _avatars = {
        for (final item in results)
          if (item != null) item.key: item.value,
      };
    });
  }

  void _onSearch(String value) {
    _search = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _page = 1);
      _load();
    });
  }

  void _changeFilter(String kind, String value) {
    setState(() {
      _page = 1;
      switch (kind) {
        case 'role': _role = value;
        case 'status': _status = value;
        case 'gender': _gender = value;
        case 'completion': _completion = value;
      }
    });
    _load();
  }

  bool get _hasFilters =>
      _search.trim().isNotEmpty || _role != 'All' || _status != 'All' || _gender != 'All' || _completion != 'All';

  void _clearFilters() {
    _searchTimer?.cancel();
    _searchController.clear();
    setState(() {
      _search = '';
      _role = 'All';
      _status = 'All';
      _gender = 'All';
      _completion = 'All';
      _page = 1;
    });
    _load();
  }

  Future<void> _openProfile(AdminMember member) async {
    final profileId = member.profileId;
    if (profileId == null || profileId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This user does not have a profile yet.')));
      return;
    }
    final profile = AdminQueueProfile(
      id: profileId,
      userId: member.userId,
      userName: member.userName,
      firstName: member.firstName ?? '',
      lastName: member.lastName,
      email: member.email,
      gender: member.gender ?? '',
      dateOfBirth: member.dateOfBirth,
      profession: member.profession,
      education: member.education,
      cityName: member.cityName,
      approvalStatus: member.approvalStatus ?? 'Pending',
      createdAtUtc: member.createdAtUtc,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProfileReviewDetailScreen(
          apiClient: widget.apiClient,
          profile: profile,
          allowReviewActions: false,
          title: 'Member profile',
        ),
      ),
    );
  }

  Future<void> _changeActiveState(AdminMember member) async {
    final action = member.isActive ? 'deactivate' : 'activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(member.isActive ? 'Deactivate account?' : 'Activate account?'),
        content: Text(member.isActive
            ? 'The member will no longer be able to use their account until it is activated again.'
            : 'This member will be able to sign in again after activation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(member.isActive ? 'Deactivate' : 'Activate')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.apiClient.put('/admin/users/${member.userId}/$action', body: const {}, authenticated: true);
      if (!mounted) return;
      setState(() {
        _members = _members.map((item) => item.userId == member.userId
            ? AdminMember.fromJson({
                'userId': item.userId,
                'userName': item.userName,
                'mobileNumber': item.mobileNumber,
                'email': item.email,
                'roleName': item.roleName,
                'isMobileVerified': item.isMobileVerified,
                'isEmailVerified': item.isEmailVerified,
                'isActive': action == 'activate',
                'isDeleted': item.isDeleted,
                'createdAtUtc': item.createdAtUtc?.toIso8601String(),
                'profileId': item.profileId,
                'firstName': item.firstName,
                'lastName': item.lastName,
                'gender': item.gender,
                'profession': item.profession,
                'education': item.education,
                'approvalStatus': item.approvalStatus,
                'visibilityStatus': item.visibilityStatus,
                'isProfileComplete': item.isProfileComplete,
                'dateOfBirth': item.dateOfBirth?.toIso8601String(),
                'cityName': item.cityName,
                'religionName': item.religionName,
                'mentorName': item.mentorName,
                'mentorUserId': item.mentorUserId,
              })
            : item).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(action == 'activate' ? 'Member activated.' : 'Member deactivated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _loadMentors() async {
    if (_mentorsLoaded) return;
    final response = await widget.apiClient.get('/admin/users?role=Mentor&pageSize=500', authenticated: true);
    final data = response['data'];
    final items = data is Map ? data['items'] : null;
    if (items is! List) throw const FormatException('The mentor list response was not in the expected format.');
    _mentors = items.whereType<Map>().map((item) {
      final json = Map<String, dynamic>.from(item);
      final name = [
        json['firstName']?.toString().trim() ?? '',
        json['lastName']?.toString().trim() ?? '',
      ].where((part) => part.isNotEmpty).join(' ');
      return {
        'id': json['userId']?.toString() ?? '',
        'name': name.isEmpty ? (json['userName']?.toString() ?? 'Mentor') : name,
        'deleted': (json['isDeleted'] == true).toString(),
      };
    }).where((mentor) => mentor['deleted'] != 'true' && mentor['id']!.isNotEmpty).toList();
    _mentorsLoaded = true;
  }

  Future<void> _openMentorManager(AdminMember member) async {
    try {
      await _loadMentors();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))));
      return;
    }
    if (!mounted) return;
    String selectedMentorId = member.mentorUserId ?? '';
    bool busy = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppPalette.border, borderRadius: BorderRadius.circular(5)))),
              const SizedBox(height: 18),
              Text('Mentor assignment', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(member.displayName, style: const TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 12)),
              const SizedBox(height: 16),
              if (_mentors.isEmpty)
                const Text('No active mentors were returned by the server.')
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('mentor-${member.userId}'),
                  initialValue: _mentors.any((mentor) => mentor['id'] == selectedMentorId) ? selectedMentorId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select mentor'),
                  items: _mentors.map((mentor) => DropdownMenuItem(
                    value: mentor['id'],
                    child: Text(mentor['name'] ?? 'Mentor', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: busy ? null : (value) => setSheetState(() => selectedMentorId = value ?? ''),
                ),
              const SizedBox(height: 14),
              if (member.mentorUserId != null && member.mentorUserId!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () async {
                      setSheetState(() => busy = true);
                      try {
                        await widget.apiClient.delete(
                          '/admin/user-mentor-assignments/${member.userId}/${member.mentorUserId}',
                          authenticated: true,
                        );
                        if (!mounted) return;
                        setState(() {
                          _members = _members.map((item) => item.userId == member.userId
                              ? _copyWithMentor(item, name: null, mentorId: null)
                              : item).toList();
                        });
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mentor assignment removed.')));
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))));
                      } finally {
                        if (sheetContext.mounted) setSheetState(() => busy = false);
                      }
                    },
                    icon: const Icon(Icons.person_remove_outlined),
                    label: const Text('Remove current assignment'),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy || selectedMentorId.isEmpty ? null : () async {
                    setSheetState(() => busy = true);
                    try {
                      await widget.apiClient.post(
                        '/admin/user-mentor-assignments',
                        body: {'userId': member.userId, 'mentorUserId': selectedMentorId},
                        authenticated: true,
                      );
                      final mentor = _mentors.firstWhere((item) => item['id'] == selectedMentorId);
                      if (!mounted) return;
                      setState(() {
                        _members = _members.map((item) => item.userId == member.userId
                            ? _copyWithMentor(item, name: mentor['name'], mentorId: selectedMentorId)
                            : item).toList();
                      });
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mentor assigned.')));
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))));
                    } finally {
                      if (sheetContext.mounted) setSheetState(() => busy = false);
                    }
                  },
                  child: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne))
                      : const Text('Assign mentor'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  AdminMember _copyWithMentor(AdminMember member, {required String? name, required String? mentorId}) => AdminMember(
        userId: member.userId,
        userName: member.userName,
        mobileNumber: member.mobileNumber,
        email: member.email,
        roleName: member.roleName,
        isMobileVerified: member.isMobileVerified,
        isEmailVerified: member.isEmailVerified,
        isActive: member.isActive,
        isDeleted: member.isDeleted,
        createdAtUtc: member.createdAtUtc,
        profileId: member.profileId,
        firstName: member.firstName,
        lastName: member.lastName,
        gender: member.gender,
        profession: member.profession,
        education: member.education,
        approvalStatus: member.approvalStatus,
        visibilityStatus: member.visibilityStatus,
        isProfileComplete: member.isProfileComplete,
        dateOfBirth: member.dateOfBirth,
        cityName: member.cityName,
        religionName: member.religionName,
        mentorName: name,
        mentorUserId: mentorId,
      );

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Date unavailable';
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
  }

  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  Widget _filter(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      items: options.map((option) => DropdownMenuItem(value: option, child: Text(option, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (next) { if (next != null) onChanged(next); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppPalette.maroon,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const Text('MEMBER ADMINISTRATION', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 1.8, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Members', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text('Search accounts, review biodatas and manage mentor assignments.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
            child: Row(children: [
              const Icon(Icons.groups_outlined, color: AppPalette.gold, size: 22),
              const SizedBox(width: 12),
              const Expanded(child: Text('Total accounts', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 12))),
              Text(_totalCount.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.ink)),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search name, username, email or mobile',
              prefixIcon: const Icon(Icons.search, color: AppPalette.secondary),
              suffixIcon: _search.isEmpty ? null : IconButton(onPressed: _clearFilters, icon: const Icon(Icons.close)),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              SizedBox(width: width, child: _filter('Role', _role, const ['All', 'User', 'Mentor', 'Admin'], (value) => _changeFilter('role', value))),
              SizedBox(width: width, child: _filter('Account status', _status, const ['All', 'Active', 'Inactive'], (value) => _changeFilter('status', value))),
              SizedBox(width: width, child: _filter('Gender', _gender, const ['All', 'Male', 'Female', 'Other'], (value) => _changeFilter('gender', value))),
              SizedBox(width: width, child: _filter('Profile completion', _completion, const ['All', 'Complete', 'Incomplete'], (value) => _changeFilter('completion', value))),
            ]);
          }),
          if (_hasFilters) Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(onPressed: _clearFilters, icon: const Icon(Icons.filter_alt_off_outlined, size: 16), label: const Text('Clear filters')),
          ),
          const SizedBox(height: 8),
          if (_loading && _members.isEmpty)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon))),
          if (!_loading && _error != null)
            _MemberStateCard(title: 'Could not load members', message: _error!, action: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry'))),
          if (!_loading && _error == null && _members.isEmpty)
            _MemberStateCard(title: 'No members found', message: _hasFilters ? 'Try changing or clearing the search and filters.' : 'The API returned an empty member list.', action: _hasFilters ? TextButton(onPressed: _clearFilters, child: const Text('Clear filters')) : null),
          if (_members.isNotEmpty) ...[
            Row(children: [
              Text('Showing ${_members.length} of $_totalCount', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Page $_page of $_totalPages', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
            ]),
            const SizedBox(height: 8),
            ..._members.map((member) => _MemberCard(
              member: member,
              avatar: _avatars[member.userId],
              dateLabel: _dateLabel(member.createdAtUtc),
              onView: () => _openProfile(member),
              onMentor: () => _openMentorManager(member),
              onToggleActive: member.roleName == 'Admin' ? null : () => _changeActiveState(member),
            )),
            if (_totalPages > 1)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: _page <= 1 || _loading ? null : () { setState(() => _page--); _load(); }, icon: const Icon(Icons.chevron_left)),
                Text('$_page / $_totalPages', style: const TextStyle(fontFamily: 'sans-serif', fontWeight: FontWeight.w700)),
                IconButton(onPressed: _page >= _totalPages || _loading ? null : () { setState(() => _page++); _load(); }, icon: const Icon(Icons.chevron_right)),
              ]),
          ],
          const SizedBox(height: 10),
          const Text('The API returns newest accounts first and limits each request to 200 records. This screen requests 10 per page.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.avatar,
    required this.dateLabel,
    required this.onView,
    required this.onMentor,
    required this.onToggleActive,
  });

  final AdminMember member;
  final Uint8List? avatar;
  final String dateLabel;
  final VoidCallback onView;
  final VoidCallback onMentor;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final statusColor = member.isActive ? const Color(0xFF287A55) : AppPalette.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      color: AppPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppPalette.border)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppPalette.champagne,
              foregroundColor: AppPalette.maroon,
              backgroundImage: avatar == null ? null : MemoryImage(avatar!),
              child: avatar == null ? Text((member.firstName?.isNotEmpty == true ? member.firstName![0] : member.userName.isNotEmpty ? member.userName[0] : 'U').toUpperCase()) : null,
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppPalette.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(member.email ?? '@${member.userName}', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(30)),
              child: Text(member.isActive ? 'Active' : 'Inactive', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 7, runSpacing: 7, children: [
            _MetaChip(icon: Icons.phone_outlined, label: member.mobileNumber),
            _MetaChip(icon: Icons.badge_outlined, label: member.roleName),
            _MetaChip(icon: Icons.calendar_today_outlined, label: dateLabel),
            if (member.approvalStatus != null) _MetaChip(icon: Icons.fact_check_outlined, label: member.approvalStatus!),
            if (member.visibilityStatus != null) _MetaChip(icon: Icons.visibility_outlined, label: member.visibilityStatus!),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.support_agent_outlined, size: 15, color: AppPalette.gold),
            const SizedBox(width: 6),
            Expanded(child: Text(
              member.mentorName?.trim().isNotEmpty == true ? member.mentorName!.split(',').first.trim() : 'No assigned mentor',
              style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
            Text(member.isProfileComplete ? 'Complete' : 'Incomplete', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w700, color: member.isProfileComplete ? const Color(0xFF287A55) : AppPalette.error)),
          ]),
          const Divider(height: 20, color: AppPalette.border),
          Wrap(spacing: 6, runSpacing: 4, children: [
            TextButton.icon(onPressed: onView, icon: const Icon(Icons.visibility_outlined, size: 16), label: const Text('View')),
            TextButton.icon(onPressed: onMentor, icon: const Icon(Icons.support_agent_outlined, size: 16), label: const Text('Mentor')),
            TextButton.icon(
              onPressed: onToggleActive,
              icon: Icon(member.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
              label: Text(member.isActive ? 'Deactivate' : 'Activate'),
            ),
          ]),
          if (member.roleName == 'Admin')
            const Text('Admin accounts cannot be activated or deactivated through this API.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ]),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(color: AppPalette.background, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppPalette.secondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ]),
      );
}

class _MemberStateCard extends StatelessWidget {
  const _MemberStateCard({required this.title, required this.message, this.action});
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
        child: Column(children: [
          const Icon(Icons.groups_outlined, size: 30, color: AppPalette.gold),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 12)),
          if (action != null) action!,
        ]),
      );
}
