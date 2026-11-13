import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.apiClient,
    required this.userName,
    required this.onOpenModule,
  });

  final ApiClient apiClient;
  final String userName;
  final ValueChanged<String> onOpenModule;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  bool _statsError = false;
  bool _queueError = false;
  bool _activityError = false;
  bool _emailError = false;
  bool _emailActionBusy = false;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _queue = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _emailChanges = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, dynamic>?> _loadMap(String path) async {
    try {
      return await widget.apiClient.get(path, authenticated: true);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _readItems(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final responses = await Future.wait([
      _loadMap('/admin/dashboard'),
      _loadMap('/admin/profiles/pending'),
      _loadMap('/admin/activities?take=6'),
      _loadMap('/admin/email-changes/pending'),
    ]);
    if (!mounted) return;
    setState(() {
      final statsResponse = responses[0];
      final queueResponse = responses[1];
      final activityResponse = responses[2];
      final emailResponse = responses[3];
      _statsError = statsResponse == null || statsResponse['success'] == false;
      _queueError = queueResponse == null || queueResponse['success'] == false;
      _activityError = activityResponse == null || activityResponse['success'] == false;
      _emailError = emailResponse == null || emailResponse['success'] == false;
      _stats = statsResponse?['data'] is Map
          ? Map<String, dynamic>.from(statsResponse!['data'] as Map)
          : null;
      _queue = _readItems(queueResponse?['data']);
      _activities = _readItems(activityResponse?['data']);
      _emailChanges = _readItems(emailResponse?['data']);
      _loading = false;
    });
  }

  Future<void> _handleEmailChange(String userId, String action) async {
    if (_emailActionBusy) return;
    setState(() => _emailActionBusy = true);
    try {
      await widget.apiClient.post(
        '/admin/email-changes/$userId/$action',
        body: const {},
        authenticated: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'approve' ? 'Email change approved.' : 'Email change rejected.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _emailActionBusy = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _timeAgo(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Recently';
    final minutes = DateTime.now().toUtc().difference(date.toUtc()).inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '${minutes}m ago';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ago';
    final days = hours ~/ 24;
    if (days < 7) return '${days}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _text(dynamic value, [String fallback = '—']) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  int _number(String key) {
    final value = _stats?[key];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppPalette.maroon,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Text(
            DateTime.now().toLocal().toString().split(' ').first,
            style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, letterSpacing: 1.1, color: AppPalette.secondary),
          ),
          const SizedBox(height: 7),
          Text('${_greeting()}, ${widget.userName.isNotEmpty ? widget.userName : 'Admin'}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 5),
          const Text('Your VedicVivah administration overview.', style: TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 13)),
          const SizedBox(height: 20),
          if (_statsError)
            _ErrorPanel(message: 'Dashboard statistics could not be loaded.', onRetry: _load)
          else
            _buildMetrics(),
          const SizedBox(height: 18),
          _buildSignupCard(),
          const SizedBox(height: 18),
          _buildReviewQueue(),
          const SizedBox(height: 18),
          _buildActivity(),
          if (_emailError || _emailChanges.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildEmailChanges(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    if (_loading && _stats == null) {
      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: AppPalette.maroon)));
    }
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _MetricCard(label: 'Total members', value: _number('totalMembers'), icon: Icons.groups_2_outlined),
        _MetricCard(label: 'Awaiting review', value: _number('pendingReviews'), icon: Icons.fact_check_outlined, attention: _number('pendingReviews') > 0),
        _MetricCard(label: 'Approved profiles', value: _number('approvedProfiles'), icon: Icons.verified_outlined),
        _MetricCard(label: 'Active mentors', value: _number('activeMentors'), icon: Icons.support_agent_outlined),
      ],
    );
  }

  Widget _buildSignupCard() {
    final raw = _stats?['signupsLast14Days'];
    final days = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    final total = days.fold<int>(0, (sum, item) => sum + ((item['count'] as num?)?.toInt() ?? 0));
    final maxValue = days.fold<int>(1, (max, item) {
      final value = (item['count'] as num?)?.toInt() ?? 0;
      return value > max ? value : max;
    });
    return _SectionCard(
      title: 'New members',
      subtitle: 'Daily sign-ups · last 14 days',
      trailing: Text('$total total', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.gold, fontWeight: FontWeight.w700)),
      child: _statsError
          ? const Text('Signup data is unavailable.', style: TextStyle(color: AppPalette.secondary))
          : days.isEmpty
              ? const Text('No signup history returned by the server.', style: TextStyle(color: AppPalette.secondary))
              : SizedBox(
                  height: 112,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: days.map((day) {
                      final count = (day['count'] as num?)?.toInt() ?? 0;
                      final double height = count == 0 ? 3.0 : (count / maxValue * 78).clamp(3.0, 78.0).toDouble();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$count', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppPalette.secondary)),
                              const SizedBox(height: 4),
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: AppPalette.gold.withValues(alpha: count == 0 ? .25 : .9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _text(day['date']).length >= 10 ? _text(day['date']).substring(8, 10) : '',
                                style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppPalette.secondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  Widget _buildReviewQueue() {
    return _SectionCard(
      title: 'Profile review queue',
      subtitle: 'Submitted member biodatas awaiting moderation',
      trailing: TextButton(onPressed: () => widget.onOpenModule('Profile Reviews'), child: const Text('View all')),
      child: _queueError
          ? _InlineError(onRetry: _load)
          : _queue.isEmpty
              ? const _EmptyState(icon: Icons.task_alt, title: 'No pending profiles', subtitle: 'The review queue is clear.')
              : Column(
                  children: _queue.take(5).map((profile) {
                    final fullName = '${_text(profile['firstName'], '')} ${_text(profile['lastName'], '')}'.trim();
                    final details = [
                      _text(profile['gender'], ''),
                      _text(profile['profession'] ?? profile['education'], ''),
                      _text(profile['cityName'], ''),
                    ].where((part) => part.isNotEmpty).join(' · ');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppPalette.champagne,
                        foregroundColor: AppPalette.maroon,
                        child: Text(fullName.isEmpty ? '?' : fullName.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(fullName.isEmpty ? 'Member profile' : fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(details.isEmpty ? _timeAgo(profile['createdAtUtc']) : details, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right, color: AppPalette.gold),
                      onTap: () => widget.onOpenModule('Profile Reviews'),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildActivity() {
    return _SectionCard(
      title: 'Recent activity',
      subtitle: 'Latest administrative actions',
      trailing: TextButton(onPressed: () => widget.onOpenModule('Activity Log'), child: const Text('View log')),
      child: _activityError
          ? _InlineError(onRetry: _load)
          : _activities.isEmpty
              ? const _EmptyState(icon: Icons.history, title: 'No recent activity', subtitle: 'New administrative actions will appear here.')
              : Column(
                  children: _activities.take(6).map((item) {
                    final actor = _text(item['actorUserName'], '');
                    final entity = _text(item['entityName'] ?? item['entityType'], '');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.circle, size: 9, color: AppPalette.gold),
                      title: Text(_text(item['action'], 'Activity'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text([actor, entity].where((s) => s.isNotEmpty).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(_timeAgo(item['createdAtUtc']), style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildEmailChanges() {
    return _SectionCard(
      title: 'Pending email changes',
      subtitle: 'Review requested account email updates',
      child: _emailError
          ? _InlineError(onRetry: _load)
          : Column(
              children: _emailChanges.map((item) {
                final id = _text(item['userId'], '');
                final name = '${_text(item['firstName'], '')} ${_text(item['lastName'], '')}'.trim();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? _text(item['userName'], 'Member') : name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${_text(item['currentEmail'], '(no email)')} → ${_text(item['pendingEmail'])}', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: OutlinedButton(
                          onPressed: _emailActionBusy || id.isEmpty ? null : () => _handleEmailChange(id, 'reject'),
                          child: const Text('Reject'),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton(
                          onPressed: _emailActionBusy || id.isEmpty ? null : () => _handleEmailChange(id, 'approve'),
                          child: const Text('Approve'),
                        )),
                      ]),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, this.attention = false});
  final String label;
  final int value;
  final IconData icon;
  final bool attention;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: attention ? AppPalette.gold.withValues(alpha: .65) : AppPalette.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(icon, size: 18, color: attention ? AppPalette.maroon : AppPalette.gold),
            const Spacer(),
            if (attention) const Icon(Icons.priority_high_rounded, size: 15, color: AppPalette.maroon),
          ]),
          Text(value.toString(), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: AppPalette.ink)),
          Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
        ]),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child, this.trailing});
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppPalette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.ink)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary)),
            ])),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Icon(icon, size: 28, color: AppPalette.gold),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary)),
        ]),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Could not load. Retry')),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined, color: AppPalette.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
