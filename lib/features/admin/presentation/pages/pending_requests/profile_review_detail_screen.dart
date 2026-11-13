import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_profile_review_models.dart';

class ProfileReviewDetailScreen extends StatefulWidget {
  const ProfileReviewDetailScreen({
    super.key,
    required this.apiClient,
    required this.profile,
    this.allowReviewActions = true,
    this.title = 'Profile review',
  });

  final ApiClient apiClient;
  final AdminQueueProfile profile;
  final bool allowReviewActions;
  final String title;

  @override
  State<ProfileReviewDetailScreen> createState() => _ProfileReviewDetailScreenState();
}

class _ProfileReviewDetailScreenState extends State<ProfileReviewDetailScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  AdminProfileReviewDetail? _detail;
  Map<String, Uint8List> _photoBytes = {};

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
      final response = await widget.apiClient.get('/admin/profiles/${widget.profile.id}', authenticated: true);
      final raw = response['data'];
      if (raw is! Map) throw const FormatException('The profile response was not in the expected format.');
      final detail = AdminProfileReviewDetail.fromJson(Map<String, dynamic>.from(raw));
      final imageResults = await Future.wait(detail.photos.map((photo) async {
        try {
          final bytes = await widget.apiClient.getBytes(
            '/admin/profiles/${widget.profile.id}/photos/${photo.id}/content',
            authenticated: true,
          );
          return MapEntry<String, Uint8List>(photo.id, bytes);
        } catch (_) {
          return null;
        }
      }));
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _photoBytes = {
          for (final entry in imageResults)
            if (entry != null) entry.key: entry.value,
        };
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

  String _value(String key, [String fallback = 'Not provided']) {
    final value = _detail?.profile[key];
    if (value == null) return fallback;
    if (value is String && value.trim().isEmpty) return fallback;
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  bool get _canDecide => _value('approvalStatus', '').toLowerCase() == 'submittedforreview';

  String get _statusLabel {
    switch (_value('approvalStatus', '').toLowerCase()) {
      case 'submittedforreview': return 'Awaiting review';
      case 'approved': return 'Approved';
      case 'rejected': return 'Changes requested';
      case 'pending': return 'Not submitted';
      default: return _value('approvalStatus');
    }
  }

  int? get _age {
    final birth = DateTime.tryParse(_value('dateOfBirth', ''));
    if (birth == null) return null;
    final today = DateTime.now();
    var years = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) years--;
    return years;
  }

  String _formatDate(String key) {
    final value = DateTime.tryParse(_value(key, ''));
    if (value == null) return 'Not provided';
    return '${value.day.toString().padLeft(2, '0')} ${_month(value.month)} ${value.year}';
  }

  String _month(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve this profile?'),
        content: Text('Approve ${widget.profile.fullName.isEmpty ? widget.profile.userName : widget.profile.fullName}’s biodata? The profile becomes visible according to the platform visibility rules.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Approve')),
        ],
      ),
    );
    if (confirmed == true) await _submitDecision(approve: true);
  }

  Future<String?> _requestReason() async {
    final controller = TextEditingController();
    String? validation;
    const quickReasons = [
      'Please add a clear, recent photo of yourself.',
      'Some sections are incomplete. Please fill in all required details.',
      'The information looks inconsistent. Please review and correct it.',
      'The introduction contains content that is not allowed.',
    ];
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final trimmed = controller.text.trim();
          return AlertDialog(
            title: const Text('Request profile changes'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Text('The member will see this note and can update the biodata before submitting again.'),
                  const SizedBox(height: 14),
                  const Text('Suggested notes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 7),
                  for (final reason in quickReasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: ActionChip(
                        label: Text(reason, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          final current = controller.text.trim();
                          final next = current.isEmpty ? reason : '$current $reason';
                          controller.text = next.length > 1000 ? next.substring(0, 1000) : next;
                          setDialogState(() => validation = null);
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    maxLength: 1000,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(hintText: 'Explain clearly what needs to change…'),
                    onChanged: (_) => setDialogState(() => validation = null),
                  ),
                  if (validation != null)
                    Text(validation!, style: const TextStyle(color: AppPalette.error, fontSize: 12)),
                  Text(
                    trimmed.length < 5 ? 'At least 5 characters are required.' : '${trimmed.length}/1000 characters',
                    style: TextStyle(fontSize: 11, color: trimmed.length < 5 ? AppPalette.error : AppPalette.secondary),
                  ),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: trimmed.length < 5 ? null : () => Navigator.pop(dialogContext, trimmed),
                child: const Text('Send & request changes'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _reject() async {
    final reason = await _requestReason();
    if (reason == null) return;
    await _submitDecision(approve: false, reason: reason);
  }

  Future<void> _submitDecision({required bool approve, String? reason}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final path = '/admin/profiles/${widget.profile.id}/${approve ? 'approve' : 'reject'}';
      await widget.apiClient.put(
        path,
        body: approve ? const {} : {'reason': reason ?? ''},
        authenticated: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Profile approved.' : 'Changes requested. The member has been notified.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileName = _detail == null
        ? widget.profile.fullName
        : [_value('firstName', ''), _value('lastName', '')].where((v) => v.isNotEmpty).join(' ');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppPalette.surface,
        foregroundColor: AppPalette.darkMaroon,
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppPalette.maroon))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 38, color: AppPalette.error),
                    const SizedBox(height: 12),
                    const Text('Could not load this profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.secondary)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again')),
                  ]),
                ))
              : _buildBody(profileName),
      bottomNavigationBar: widget.allowReviewActions && !_loading && _error == null && _canDecide
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(color: AppPalette.surface, border: Border(top: BorderSide(color: AppPalette.border))),
                child: Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: _saving ? null : _reject,
                    child: const Text('Request changes'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: _saving ? null : _approve,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne))
                        : const Text('Approve profile'),
                  )),
                ]),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(String profileName) {
    final detail = _detail!;
    final photos = detail.photos;
    final contacts = detail.contacts;
    final about = _value('aboutMe', '');
    final statusColor = _value('approvalStatus', '').toLowerCase() == 'approved'
        ? const Color(0xFF287A55)
        : _value('approvalStatus', '').toLowerCase() == 'rejected'
            ? AppPalette.error
            : AppPalette.gold;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        if (photos.isNotEmpty)
          SizedBox(
            height: 230,
            child: PageView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                final bytes = _photoBytes[photo.id];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(fit: StackFit.expand, children: [
                    Container(color: AppPalette.champagne, child: bytes == null
                        ? const Center(child: Icon(Icons.broken_image_outlined, size: 38, color: AppPalette.secondary))
                        : Image.memory(bytes, fit: BoxFit.cover)),
                    if (photo.isPrimary)
                      Positioned(left: 12, top: 12, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppPalette.darkMaroon.withValues(alpha: .88), borderRadius: BorderRadius.circular(30)),
                        child: const Text('Main photo', style: TextStyle(color: AppPalette.surface, fontSize: 11, fontWeight: FontWeight.w700)),
                      )),
                    Positioned(right: 12, bottom: 12, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: AppPalette.darkMaroon.withValues(alpha: .8), borderRadius: BorderRadius.circular(30)),
                      child: Text('${index + 1} / ${photos.length}', style: const TextStyle(color: AppPalette.surface, fontSize: 11)),
                    )),
                  ]),
                );
              },
            ),
          )
        else
          Container(
            height: 150,
            decoration: BoxDecoration(color: AppPalette.champagne.withValues(alpha: .45), borderRadius: BorderRadius.circular(18)),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.image_not_supported_outlined, size: 32, color: AppPalette.secondary),
              SizedBox(height: 8),
              Text('No profile photos uploaded', style: TextStyle(color: AppPalette.secondary)),
            ]),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppPalette.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(30)),
              child: Text(_statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 9),
            Text(profileName.isEmpty ? widget.profile.userName : profileName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 3),
            Text('@${_value('userName', widget.profile.userName)}', style: const TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 12)),
            const SizedBox(height: 7),
            Text([
              if (_age != null) '$_age years',
              _value('gender', ''),
              _value('profession', _value('education', '')),
              _value('cityName', ''),
            ].where((v) => v.isNotEmpty).join(' · '), style: const TextStyle(fontFamily: 'sans-serif', color: AppPalette.secondary, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _CheckPill(label: 'Photos', value: photos.isNotEmpty ? '${photos.length} uploaded' : 'None', ok: photos.isNotEmpty),
              _CheckPill(label: 'Contacts', value: '${contacts.length} of 3', ok: contacts.length >= 3),
              _CheckPill(label: 'About me', value: about.trim().isNotEmpty ? 'Added' : 'Missing', ok: about.trim().isNotEmpty),
              _CheckPill(label: 'Biodata', value: _value('isProfileComplete') == 'true' ? 'Complete' : 'Incomplete', ok: _value('isProfileComplete') == 'true'),
            ]),
          ]),
        ),
        if (_value('approvalStatus', '').toLowerCase() == 'rejected' && _value('rejectionReason', '').isNotEmpty)
          _InfoNote(title: 'Previous note sent to member', message: _value('rejectionReason')),
        const SizedBox(height: 14),
        _DetailSection(title: 'Personal', items: {
          'Email': widget.profile.email,
          'Date of birth': _formatDate('dateOfBirth'),
          'Gender': _value('gender'),
          'Time of birth': _value('timeOfBirth'),
          'Birth place': _value('birthPlace'),
          'Marital status': _value('maritalStatus'),
          'Disability': _value('disabilityStatus'),
          'Disability details': _value('disabilityDetails'),
        }),
        _DetailSection(title: 'Religion & community', items: {
          'Religion': _value('religionName'),
          'Caste': _value('casteName'),
          'Sub-caste': _value('subCasteName'),
          'Community': _value('community'),
          'Mother tongue': _value('motherTongueName', _value('motherTongue')),
        }),
        _DetailSection(title: 'Education & career', items: {
          'Education': _value('education'),
          'Qualification': _value('qualificationName', _value('qualification')),
          'Course': _value('courseName', _value('course')),
          'Occupation': _value('occupationName', _value('occupation')),
          'Profession': _value('professionName', _value('profession')),
          'Work type': _value('workType'),
          'Yearly income': _value('yearlyIncome'),
        }),
        _DetailSection(title: 'Physical', items: {
          'Height': _height(),
          'Weight': _value('weight'),
        }),
        _DetailSection(title: 'Family', items: {
          'Father': _value('fatherName'),
          'Mother': _value('motherName'),
          'Brother(s)': _value('brother'),
          'Sister(s)': _value('sister'),
          'Married brothers': _value('marriedBrotherCount'),
          'Married sisters': _value('marriedSisterCount'),
          'Nanaji': _value('nanajiName'),
          'Mosal surname': _value('mosalSurname'),
        }),
        _DetailSection(title: 'Location & residence', items: {
          'Country': _value('countryName'),
          'State': _value('stateName'),
          'City': _value('cityName'),
          'PIN code': _value('pinCode'),
          'Native place': _value('nativePlace'),
          'Area': _value('area'),
          'Residence type': _value('residenceType'),
          'Area (sq ft)': _value('areaInSqFt'),
          'Rooms': _value('roomCount'),
        }),
        _DetailSection(title: 'About me', body: about.trim().isEmpty ? 'The member has not written an introduction.' : about),
        _DetailSection(
          title: 'Relative contacts',
          body: contacts.isEmpty ? 'No relative contacts added.' : null,
          child: Column(children: contacts.map((contact) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: AppPalette.champagne, foregroundColor: AppPalette.maroon, child: Text(contact.name.isEmpty ? '?' : contact.name.substring(0, 1).toUpperCase())),
            title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text([contact.relationshipWithUser, contact.cityName, contact.phoneNumber].where((v) => v.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 11)),
          )).toList()),
        ),
        const SizedBox(height: 12),
        Text('Submitted ${_formatDate('createdAtUtc')} · Updated ${_formatDate('updatedAtUtc')}', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 10, color: AppPalette.secondary)),
      ],
    );
  }

  String _height() {
    final feet = _detail?.profile['heightFeet'];
    final inches = _detail?.profile['heightInches'];
    if (feet == null) return 'Not provided';
    return '$feet′ ${inches ?? 0}″';
  }
}

class _CheckPill extends StatelessWidget {
  const _CheckPill({required this.label, required this.value, required this.ok});
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(color: (ok ? const Color(0xFF287A55) : AppPalette.error).withValues(alpha: .08), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 9, color: AppPalette.secondary)),
          Text(value, style: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w700, color: ok ? const Color(0xFF287A55) : AppPalette.error)),
        ]),
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppPalette.error.withValues(alpha: .06), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppPalette.error.withValues(alpha: .18))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppPalette.error)),
          const SizedBox(height: 5),
          Text(message, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, height: 1.4)),
        ]),
      );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, this.items, this.body, this.child});
  final String title;
  final Map<String, String?>? items;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final values = items?.entries.where((entry) => entry.value != null && entry.value!.isNotEmpty).toList() ?? [];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppPalette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppPalette.ink)),
        const SizedBox(height: 10),
        if (items != null)
          if (values.isEmpty)
            const Text('No information provided.', style: TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.secondary))
          else
            ...values.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: Text(entry.key, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary))),
                Expanded(flex: 6, child: Text(entry.value!, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.ink, fontWeight: FontWeight.w600))),
              ]),
            )),
        if (body != null) Text(body!, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, height: 1.5, color: AppPalette.ink)),
        if (child != null) child!,
      ]),
    );
  }
}
