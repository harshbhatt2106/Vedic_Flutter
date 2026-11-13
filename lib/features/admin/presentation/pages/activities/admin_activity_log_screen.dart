import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_audit_log.dart';

class AdminActivityLogScreen extends StatefulWidget {
  const AdminActivityLogScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _search = '';
  String _activityType = 'All';
  String _action = 'All';
  String _entityType = 'All';
  String _dateFilter = 'All';
  List<AdminAuditLog> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.apiClient.get('/admin/activities?take=100', authenticated: true);
      final raw = response['data'];
      final items = raw is List
          ? raw.whereType<Map>().map((item) => AdminAuditLog.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminAuditLog>[];
      if (!mounted) return;
      setState(() {
        _activities = items;
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

  List<String> _distinctValues(String Function(AdminAuditLog) selector) {
    final values = _activities.map(selector).where((value) => value.trim().isNotEmpty).toSet().toList()..sort();
    return values;
  }

  String _humanize(String value) {
    final spaced = value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (spaced.isEmpty) return 'Unknown';
    return spaced.split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  List<AdminAuditLog> get _filtered {
    final query = _search.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startTime = switch (_dateFilter) {
      'Today' => today,
      'Last 7 Days' => now.subtract(const Duration(days: 7)),
      'Last 30 Days' => now.subtract(const Duration(days: 30)),
      _ => null,
    };

    return _activities.where((item) {
      if (_activityType != 'All' && item.activityType != _activityType) return false;
      if (_action != 'All' && item.action != _action) return false;
      if (_entityType != 'All' && item.entityType != _entityType) return false;
      if (startTime != null) {
        final created = item.createdAtUtc?.toLocal();
        if (created == null || created.isBefore(startTime)) return false;
      }
      if (query.isEmpty) return true;
      return [
        item.action,
        item.activityType,
        item.entityType,
        item.entityId,
        item.entityName,
        item.actorUserId,
        item.actorUserName,
        item.ipAddress,
      ].any((value) => (value ?? '').toLowerCase().contains(query));
    }).toList();
  }

  bool get _hasFilters =>
      _search.trim().isNotEmpty || _activityType != 'All' || _action != 'All' || _entityType != 'All' || _dateFilter != 'All';

  int _countType(String type) => _activities.where((item) => item.activityType.toLowerCase() == type.toLowerCase()).length;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _activityType = 'All';
      _action = 'All';
      _entityType = 'All';
      _dateFilter = 'All';
    });
  }

  String _dateTime(DateTime? value) {
    if (value == null) return 'Date unavailable';
    final date = value.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year} · $hour:$minute $period';
  }

  String _month(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  Widget _filter(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10)),
      items: options.map((option) => DropdownMenuItem(value: option, child: Text(option == 'All' ? 'All $label' : _humanize(option), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (next) { if (next != null) setState(() => onChanged(next)); },
    );
  }

  void _showDetails(AdminAuditLog item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _ActivityDetailSheet(item: item, humanize: _humanize, dateTime: _dateTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return RefreshIndicator(
      color: AppPalette.maroon,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          const Text('SECURITY & AUDIT', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 1.8, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Activity log', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text('Review account activity and administrative changes across VedicVivah.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _SummaryCard(label: 'Total', value: _activities.length, icon: Icons.history, color: AppPalette.maroon)),
            const SizedBox(width: 7),
            Expanded(child: _SummaryCard(label: 'Auth', value: _countType('Authentication'), icon: Icons.lock_outline, color: AppPalette.gold)),
            const SizedBox(width: 7),
            Expanded(child: _SummaryCard(label: 'Profile', value: _countType('Profile'), icon: Icons.person_outline, color: const Color(0xFF287A55))),
            const SizedBox(width: 7),
            Expanded(child: _SummaryCard(label: 'Admin', value: _countType('Administration'), icon: Icons.settings_outlined, color: AppPalette.secondary)),
          ]),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Search action, actor, entity or IP',
              prefixIcon: const Icon(Icons.search, color: AppPalette.secondary),
              suffixIcon: _search.isEmpty ? null : IconButton(onPressed: _clearFilters, icon: const Icon(Icons.close)),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(spacing: 8, runSpacing: 8, children: [
              SizedBox(width: width, child: _filter('Activity type', _activityType, ['All', ..._distinctValues((item) => item.activityType)], (value) => _activityType = value)),
              SizedBox(width: width, child: _filter('Action', _action, ['All', ..._distinctValues((item) => item.action)], (value) => _action = value)),
              SizedBox(width: width, child: _filter('Entity type', _entityType, ['All', ..._distinctValues((item) => item.entityType)], (value) => _entityType = value)),
              SizedBox(width: width, child: _filter('Date range', _dateFilter, const ['All', 'Today', 'Last 7 Days', 'Last 30 Days'], (value) => _dateFilter = value)),
            ]);
          }),
          if (_hasFilters)
            Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _clearFilters, icon: const Icon(Icons.filter_alt_off_outlined, size: 16), label: const Text('Clear filters'))),
          const SizedBox(height: 8),
          Row(children: [
            Text('${items.length} records shown', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh, size: 16), label: const Text('Refresh')),
          ]),
          if (_loading && _activities.isEmpty)
            const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon))),
          if (!_loading && _error != null)
            _ActivityStateCard(title: 'Could not load activities', message: _error!, action: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry'))),
          if (!_loading && _error == null && items.isEmpty)
            _ActivityStateCard(title: 'No activities found', message: _hasFilters ? 'Try changing or clearing your filters.' : 'The API returned no activity records.', icon: Icons.history),
          if (items.isNotEmpty) ...items.map((item) => _ActivityCard(item: item, dateTime: _dateTime, humanize: _humanize, onTap: () => _showDetails(item))),
          const SizedBox(height: 8),
          const Text('The backend returns the latest 100 records for this page. Filters and search are applied on the device.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 7),
          Text(value.toString(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppPalette.ink)),
          Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppPalette.secondary)),
        ]),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.dateTime, required this.humanize, required this.onTap});
  final AdminAuditLog item;
  final String Function(DateTime?) dateTime;
  final String Function(String) humanize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actor = item.actorUserName ?? (item.actorUserId == null ? 'System' : 'Unknown user');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppPalette.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 16, backgroundColor: AppPalette.champagne, foregroundColor: AppPalette.maroon, child: Text(actor.isEmpty ? 'S' : actor[0].toUpperCase(), style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 9),
              Expanded(child: Text(actor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(dateTime(item.createdAtUtc), style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppPalette.secondary)),
            ]),
            const SizedBox(height: 10),
            Text(humanize(item.action), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppPalette.ink)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _ActivityTag(label: humanize(item.activityType), color: AppPalette.gold),
              _ActivityTag(label: humanize(item.entityType), color: AppPalette.secondary),
            ]),
            if (item.entityName?.isNotEmpty == true || item.entityId?.isNotEmpty == true) ...[
              const SizedBox(height: 7),
              Text(item.entityName?.isNotEmpty == true ? item.entityName! : 'Entity ID: ${item.entityId}', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.info_outline, size: 13, color: AppPalette.gold),
              const SizedBox(width: 5),
              const Expanded(child: Text('Tap to inspect safe details', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary))),
              const Icon(Icons.chevron_right, size: 18, color: AppPalette.gold),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ActivityTag extends StatelessWidget {
  const _ActivityTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontFamily: 'sans-serif', fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );
}

class _ActivityDetailSheet extends StatelessWidget {
  const _ActivityDetailSheet({required this.item, required this.humanize, required this.dateTime});
  final AdminAuditLog item;
  final String Function(String) humanize;
  final String Function(DateTime?) dateTime;

  static const _sensitiveKeys = {'password', 'otp', 'accesstoken', 'refreshtoken', 'secretkey'};

  List<MapEntry<String, String>> _safeDetails() {
    final raw = item.detailsJson;
    if (raw == null || raw.trim().isEmpty) return const [MapEntry('Details', 'No additional details')];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [MapEntry('Details', 'No structured details available')];
      return decoded.entries
          .where((entry) => !_sensitiveKeys.contains(entry.key.toString().replaceAll(RegExp(r'[_-]'), '').toLowerCase()))
          .map((entry) => MapEntry(
                humanize(entry.key.toString()),
                entry.value is Map || entry.value is List ? jsonEncode(entry.value) : entry.value?.toString() ?? 'null',
              ))
          .toList();
    } catch (_) {
      return const [MapEntry('Details', 'Details could not be safely parsed')];
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = item.actorUserName ?? (item.actorUserId == null ? 'System' : 'Unknown user');
    final details = _safeDetails();
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppPalette.border, borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 17),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AUDIT RECORD', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 1.6, color: AppPalette.gold, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(humanize(item.action), style: Theme.of(context).textTheme.titleLarge),
              ])),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 12),
            Expanded(child: ListView(children: [
              _DetailLine(label: 'Date & time', value: dateTime(item.createdAtUtc)),
              _DetailLine(label: 'Actor', value: actor),
              _DetailLine(label: 'Actor ID', value: item.actorUserId ?? 'System'),
              _DetailLine(label: 'Activity type', value: humanize(item.activityType)),
              _DetailLine(label: 'Action', value: humanize(item.action)),
              _DetailLine(label: 'Entity type', value: humanize(item.entityType)),
              _DetailLine(label: 'Entity name', value: item.entityName ?? 'Not provided'),
              _DetailLine(label: 'Entity ID', value: item.entityId ?? 'Not provided'),
              _DetailLine(label: 'IP address', value: item.ipAddress ?? 'Not provided'),
              const SizedBox(height: 12),
              const Text('Additional details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              ...details.map((entry) => _DetailLine(label: entry.key, value: entry.value)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: AppPalette.background, borderRadius: BorderRadius.circular(11)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.ink)),
        ]),
      );
}

class _ActivityStateCard extends StatelessWidget {
  const _ActivityStateCard({required this.title, required this.message, this.action, this.icon = Icons.cloud_off_outlined});
  final String title;
  final String message;
  final Widget? action;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
        child: Column(children: [
          Icon(icon, size: 30, color: AppPalette.gold),
          const SizedBox(height: 9),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
          if (action != null) action!,
        ]),
      );
}
