import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_report.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _loading = true;
  String? _error;
  List<AdminReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await widget.apiClient.get('/reports', authenticated: true);
      final raw = response['data'];
      final items = raw is List
          ? raw.whereType<Map>().map((item) => AdminReport.fromJson(Map<String, dynamic>.from(item))).toList()
          : <AdminReport>[];
      if (!mounted) return;
      setState(() {
        _reports = items;
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

  String _date(DateTime? value) {
    if (value == null) return 'Date unavailable';
    final date = value.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
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
          const Text('MODERATION', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: 1.8, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('Member reports', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text('Reports submitted by members about other accounts.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppPalette.border)),
            child: Row(children: [
              const Icon(Icons.flag_outlined, color: AppPalette.gold, size: 22),
              const SizedBox(width: 12),
              const Expanded(child: Text('Reports submitted', style: TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary))),
              Text(_reports.length.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.ink)),
              const SizedBox(width: 8),
              IconButton(onPressed: _loading ? null : _load, tooltip: 'Refresh reports', icon: const Icon(Icons.refresh, color: AppPalette.maroon)),
            ]),
          ),
          const SizedBox(height: 14),
          if (_loading && _reports.isEmpty)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon))),
          if (!_loading && _error != null)
            _ReportStateCard(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load reports',
              message: _error!,
              action: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            ),
          if (!_loading && _error == null && _reports.isEmpty)
            const _ReportStateCard(
              icon: Icons.task_alt,
              title: 'No reports to review',
              message: 'Your moderation queue is clear. New member reports will appear here when submitted.',
              eyebrow: 'ALL CLEAR',
            ),
          if (_reports.isNotEmpty) ...[
            Text('${_reports.length} reports returned by the server', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w700, color: AppPalette.ink)),
            const SizedBox(height: 8),
            ..._reports.map((report) => _ReportCard(report: report, date: _date(report.createdAtUtc))),
          ],
          const SizedBox(height: 10),
          const Text('The web Admin page is read-only and requests the default first 50 reports. No dismiss, block or delete action is available.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.date});
  final AdminReport report;
  final String date;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _PersonLine(label: 'Reported by', name: report.reportedByName, icon: Icons.person_outline)),
            const SizedBox(width: 8),
            Expanded(child: _PersonLine(label: 'Reported member', name: report.reportedUserName, icon: Icons.person_off_outlined)),
          ]),
          const SizedBox(height: 14),
          const Text('Reason', style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, letterSpacing: .4, color: AppPalette.secondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(report.reason, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 13, height: 1.45, color: AppPalette.ink)),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 13, color: AppPalette.gold),
            const SizedBox(width: 6),
            Text(date, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
          ]),
        ]),
      );
}

class _PersonLine extends StatelessWidget {
  const _PersonLine({required this.label, required this.name, required this.icon});
  final String label;
  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppPalette.secondary)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(icon, size: 14, color: AppPalette.gold),
          const SizedBox(width: 5),
          Expanded(child: Text(name.isEmpty ? 'Unknown member' : name, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w700, color: AppPalette.ink), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
      ]);
}

class _ReportStateCard extends StatelessWidget {
  const _ReportStateCard({required this.icon, required this.title, required this.message, this.action, this.eyebrow});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
        child: Column(children: [
          Icon(icon, size: 32, color: AppPalette.gold),
          if (eyebrow != null) ...[
            const SizedBox(height: 8),
            Text(eyebrow!, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, letterSpacing: 1.4, color: AppPalette.gold, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary, height: 1.4)),
          if (action != null) action!,
        ]),
      );
}
