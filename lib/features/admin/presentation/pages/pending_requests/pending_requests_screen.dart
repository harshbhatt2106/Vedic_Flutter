import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_profile_review_models.dart';
import 'profile_review_detail_screen.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  static const _statuses = ['Pending', 'Approved', 'Rejected', 'All'];
  String _status = 'Pending';
  String _search = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  Timer? _searchTimer;
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  List<AdminQueueProfile> _profiles = [];
  int? _pendingCount;
  int? _approvedCount;
  int? _rejectedCount;

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

  String _dateParam(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final query = <String, String>{'status': _status};
    if (_search.trim().isNotEmpty) query['search'] = _search.trim();
    if (_fromDate != null) query['fromDate'] = _dateParam(_fromDate!);
    if (_toDate != null) query['toDate'] = _dateParam(_toDate!);
    final uriQuery = Uri(queryParameters: query).query;

    try {
      final results = await Future.wait([
        widget.apiClient.get('/admin/profiles/pending?$uriQuery', authenticated: true),
        widget.apiClient.get('/admin/dashboard', authenticated: true),
      ]);
      final rawProfiles = results[0]['data'];
      final items = rawProfiles is List
          ? rawProfiles.whereType<Map>().map((item) => AdminQueueProfile.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminQueueProfile>[];
      items.sort((a, b) {
        final left = a.createdAtUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAtUtc ?? DateTime.fromMillisecondsSinceEpoch(0);
        return _status == 'Pending' ? left.compareTo(right) : right.compareTo(left);
      });
      final stats = results[1]['data'];
      if (!mounted) return;
      setState(() {
        _profiles = items;
        if (stats is Map) {
          _pendingCount = (stats['pendingReviews'] as num?)?.toInt();
          _approvedCount = (stats['approvedProfiles'] as num?)?.toInt();
          _rejectedCount = (stats['rejectedProfiles'] as num?)?.toInt();
        }
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

  void _onSearchChanged(String value) {
    _search = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? _fromDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isFrom ? DateTime(2000) : (_fromDate ?? DateTime(2000)),
      lastDate: DateTime.now(),
      helpText: isFrom ? 'Submitted from' : 'Submitted until',
    );
    if (picked == null || !mounted) return;
    if (isFrom) {
      if (_toDate != null && picked.isAfter(_toDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start date cannot be after end date.')));
        return;
      }
      setState(() => _fromDate = picked);
    } else {
      if (_fromDate != null && picked.isBefore(_fromDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date cannot be before start date.')));
        return;
      }
      setState(() => _toDate = picked);
    }
    _load();
  }

  Future<void> _openProfile(AdminQueueProfile profile) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileReviewDetailScreen(apiClient: widget.apiClient, profile: profile),
      ),
    );
    if (changed == true) _load();
  }

  String _labelForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'submittedforreview':
        return 'Awaiting review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Changes requested';
      case 'pending':
        return 'Not submitted';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF287A55);
      case 'rejected':
        return AppPalette.error;
      case 'submittedforreview':
        return AppPalette.gold;
      default:
        return AppPalette.secondary;
    }
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Date unavailable';
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
  }

  String _month(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppPalette.maroon,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Text('PROFILE MODERATION', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.gold, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Review applications', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text('Inspect each biodata before approving it or requesting changes.', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 12)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _CountTile(label: 'Awaiting', value: _pendingCount, color: AppPalette.gold)),
            const SizedBox(width: 8),
            Expanded(child: _CountTile(label: 'Approved', value: _approvedCount, color: const Color(0xFF287A55))),
            const SizedBox(width: 8),
            Expanded(child: _CountTile(label: 'Changes', value: _rejectedCount, color: AppPalette.error)),
          ]),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _statuses.map((status) => Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                label: Text(_statusName(status)),
                selected: _status == status,
                onSelected: (_) {
                  setState(() => _status = status);
                  _load();
                },
                selectedColor: AppPalette.maroon,
                backgroundColor: AppPalette.surface,
                labelStyle: TextStyle(fontFamily: 'sans-serif', fontSize: 12, fontWeight: FontWeight.w600, color: _status == status ? AppPalette.surface : AppPalette.secondary),
                side: BorderSide(color: _status == status ? AppPalette.maroon : AppPalette.border),
              ),
            )).toList()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search name or username',
              prefixIcon: const Icon(Icons.search, color: AppPalette.secondary),
              suffixIcon: _search.isEmpty ? null : IconButton(onPressed: () {
                _searchController.clear();
                setState(() => _search = '');
                _load();
              }, icon: const Icon(Icons.close)),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: true),
              icon: const Icon(Icons.calendar_today_outlined, size: 15),
              label: Text(_fromDate == null ? 'From date' : _dateLabel(_fromDate), overflow: TextOverflow.ellipsis),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: false),
              icon: const Icon(Icons.event_outlined, size: 15),
              label: Text(_toDate == null ? 'To date' : _dateLabel(_toDate), overflow: TextOverflow.ellipsis),
            )),
          ]),
          if (_fromDate != null || _toDate != null || _search.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() { _fromDate = null; _toDate = null; _search = ''; });
                  _load();
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('Clear filters'),
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon))),
          if (!_loading && _error != null)
            _StateCard(icon: Icons.cloud_off_outlined, title: 'Could not load applications', message: _error!, action: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again'))),
          if (!_loading && _error == null && _profiles.isEmpty)
            _StateCard(icon: Icons.inbox_outlined, title: 'No applications found', message: _status == 'Pending' ? 'There are no submitted profiles waiting for review.' : 'No profiles match the selected status and filters.'),
          if (!_loading && _error == null && _profiles.isNotEmpty) ...[
            Row(children: [
              Text('${_profiles.length} profiles', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, fontWeight: FontWeight.w700, color: AppPalette.ink)),
              const Spacer(),
              Text(_status == 'Pending' ? 'Oldest first' : 'Newest first', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
            ]),
            const SizedBox(height: 8),
            ..._profiles.map((profile) => _ProfileQueueCard(
              profile: profile,
              statusLabel: _labelForStatus(profile.approvalStatus),
              statusColor: _statusColor(profile.approvalStatus),
              dateLabel: _dateLabel(profile.createdAtUtc),
              onTap: () => _openProfile(profile),
            )),
          ],
          const SizedBox(height: 12),
          const Text('The backend returns up to 100 matching profiles per request.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ],
      ),
    );
  }

  String _statusName(String status) {
    switch (status) {
      case 'Pending': return 'Awaiting review';
      case 'Rejected': return 'Changes requested';
      default: return status;
    }
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value, required this.color});
  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value?.toString() ?? '—', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ]),
      );
}

class _ProfileQueueCard extends StatelessWidget {
  const _ProfileQueueCard({required this.profile, required this.statusLabel, required this.statusColor, required this.dateLabel, required this.onTap});
  final AdminQueueProfile profile;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = profile.fullName.isEmpty ? profile.userName : profile.fullName;
    final details = [
      if (profile.age != null) '${profile.age} years',
      profile.gender,
      profile.profession ?? profile.education,
      profile.cityName,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      color: AppPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppPalette.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: AppPalette.champagne, foregroundColor: AppPalette.maroon, child: Text(title.isEmpty ? '?' : title.substring(0, 1).toUpperCase())),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppPalette.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('@${profile.userName}', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
              ])),
              const Icon(Icons.chevron_right, color: AppPalette.gold),
            ]),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(details, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(30)),
                child: Text(statusLabel, style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const Spacer(),
              Text(dateLabel, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
        child: Column(children: [
          Icon(icon, color: AppPalette.gold, size: 30),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 12)),
          if (action != null) action!,
        ]),
      );
}
