import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/admin_member.dart';
import '../../../data/models/admin_mentor_models.dart';

class AdminMentorFormSheet extends StatefulWidget {
  const AdminMentorFormSheet({super.key, required this.apiClient, this.mentor});
  final ApiClient apiClient;
  final AdminMember? mentor;

  @override
  State<AdminMentorFormSheet> createState() => _AdminMentorFormSheetState();
}

class _AdminMentorFormSheetState extends State<AdminMentorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  List<AdminLocationOption> _countries = [];
  List<AdminLocationOption> _states = [];
  List<AdminLocationOption> _cities = [];
  int? _countryId;
  int? _stateId;
  int? _cityId;
  bool _loadingLocations = true;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _saving = false;
  String? _formError;

  bool get _editing => widget.mentor != null;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.mentor?.firstName ?? '');
    _lastName = TextEditingController(text: widget.mentor?.lastName ?? '');
    _mobile = TextEditingController(text: widget.mentor?.mobileNumber ?? '');
    _email = TextEditingController(text: widget.mentor?.email ?? '');
    _loadLocations();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  List<AdminLocationOption> _parseOptions(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) => AdminLocationOption.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<List<AdminLocationOption>> _getStates(int countryId) async {
    final response = await widget.apiClient.get('/locations/states?${Uri(queryParameters: {'countryId': '$countryId'}).query}', authenticated: true);
    return _parseOptions(response['data']);
  }

  Future<List<AdminLocationOption>> _getCities(int stateId) async {
    final response = await widget.apiClient.get('/locations/cities?${Uri(queryParameters: {'stateId': '$stateId'}).query}', authenticated: true);
    return _parseOptions(response['data']);
  }

  Future<void> _loadLocations() async {
    try {
      final countriesResponse = await widget.apiClient.get('/locations/countries', authenticated: true);
      final countries = _parseOptions(countriesResponse['data']);
      var states = <AdminLocationOption>[];
      var cities = <AdminLocationOption>[];
      int? countryId;
      int? stateId;
      int? cityId;

      if (_editing) {
        try {
          final locationResponse = await widget.apiClient.get('/admin/mentors/${widget.mentor!.userId}/location', authenticated: true);
          final raw = locationResponse['data'];
          if (raw is Map) {
            final location = AdminMentorLocation.fromJson(Map<String, dynamic>.from(raw));
            countryId = location.countryId;
            stateId = location.stateId;
            cityId = location.cityId;
            if (countryId != null) states = await _getStates(countryId);
            if (stateId != null) cities = await _getCities(stateId);
          }
        } catch (_) {
          // Existing location is optional when editing a mentor.
        }
      }

      if (!mounted) return;
      setState(() {
        _countries = countries;
        _states = states;
        _cities = cities;
        _countryId = countries.any((item) => item.id == countryId) ? countryId : null;
        _stateId = states.any((item) => item.id == stateId) ? stateId : null;
        _cityId = cities.any((item) => item.id == cityId) ? cityId : null;
        _loadingLocations = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingLocations = false;
        _formError = error.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _onCountryChanged(int? value) async {
    setState(() {
      _countryId = value;
      _stateId = null;
      _cityId = null;
      _states = [];
      _cities = [];
      _loadingStates = value != null;
      _formError = null;
    });
    if (value == null) return;
    try {
      final states = await _getStates(value);
      if (!mounted) return;
      setState(() { _states = states; _loadingStates = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loadingStates = false; _formError = error.toString().replaceFirst('ApiException: ', ''); });
    }
  }

  Future<void> _onStateChanged(int? value) async {
    setState(() {
      _stateId = value;
      _cityId = null;
      _cities = [];
      _loadingCities = value != null;
      _formError = null;
    });
    if (value == null) return;
    try {
      final cities = await _getCities(value);
      if (!mounted) return;
      setState(() { _cities = cities; _loadingCities = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loadingCities = false; _formError = error.toString().replaceFirst('ApiException: ', ''); });
    }
  }

  String? _validateFirstName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Enter at least 2 characters.';
    if (text.length > 100) return 'Maximum 100 characters.';
    return null;
  }

  String? _validateLastName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Last name is required.';
    if (text.length > 100) return 'Maximum 100 characters.';
    return null;
  }

  String? _validateMobile(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(text)) return 'Enter 7 to 15 digits.';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 254 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_editing && (_countryId == null || _stateId == null || _cityId == null)) {
      setState(() => _formError = 'Please select a country, state and city.');
      return;
    }

    setState(() { _saving = true; _formError = null; });
    try {
      final firstName = _firstName.text.trim();
      final lastName = _lastName.text.trim();
      final mobile = _mobile.text.trim();
      final email = _email.text.trim();
      Map<String, dynamic> response;
      if (_editing) {
        response = await widget.apiClient.put(
          '/admin/mentors/${widget.mentor!.userId}',
          body: {
            'firstName': firstName,
            'lastName': lastName,
            'mobileNumber': mobile,
            'email': email,
            'isActive': widget.mentor!.isActive,
            'cityId': _cityId,
          },
          authenticated: true,
        );
      } else {
        response = await widget.apiClient.postMultipart(
          '/admin/mentors',
          authenticated: true,
          fields: {
            'FirstName': firstName,
            'LastName': lastName,
            'MobileNumber': mobile,
            'Email': email,
            'CountryId': _countryId.toString(),
            'StateId': _stateId.toString(),
            'CityId': _cityId.toString(),
          },
        );
      }
      if (response['success'] == false) {
        throw Exception(response['message']?.toString() ?? 'The server could not save this mentor.');
      }
      if (!mounted) return;
      Navigator.of(context).pop(response['message']?.toString() ?? (_editing ? 'Mentor updated.' : 'Mentor created.'));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _formError = error.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  Widget _locationDropdown({
    required String label,
    required int? value,
    required List<AdminLocationOption> options,
    required ValueChanged<int?>? onChanged,
    required bool requiredField,
    bool loading = false,
    String? disabledHint,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$value-${options.length}'),
      initialValue: options.any((item) => item.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, suffixIcon: loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null),
      items: options.map((item) => DropdownMenuItem<int>(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: _saving || loading ? null : onChanged,
      validator: requiredField ? (selected) => selected == null ? 'Select $label.' : null : null,
      hint: Text(disabledHint ?? 'Select $label'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .94,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(children: [
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: AppPalette.border, borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(_editing ? 'Edit mentor' : 'Create mentor', style: Theme.of(context).textTheme.titleLarge)),
              IconButton(onPressed: _saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(_editing ? 'Update account details and optional location.' : 'A mentor account will be created and the sign-in details will be sent to the email address.', style: const TextStyle(fontFamily: 'sans-serif', fontSize: 11, color: AppPalette.secondary))),
            const SizedBox(height: 12),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(children: [
                  TextFormField(
                    controller: _firstName,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ\s'.-]")), LengthLimitingTextInputFormatter(100)],
                    decoration: const InputDecoration(labelText: 'First name', prefixIcon: Icon(Icons.person_outline)),
                    validator: _validateFirstName,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _lastName,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ\s'.-]")), LengthLimitingTextInputFormatter(100)],
                    decoration: const InputDecoration(labelText: 'Last name', prefixIcon: Icon(Icons.person_outline)),
                    validator: _validateLastName,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _mobile,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                    decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: _validateMobile,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 18),
                  Text(_editing ? 'Location (optional)' : 'Location (required)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (_loadingLocations)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(color: AppPalette.maroon)))
                  else ...[
                    _locationDropdown(
                      label: 'Country',
                      value: _countryId,
                      options: _countries,
                      onChanged: _onCountryChanged,
                      requiredField: !_editing,
                    ),
                    const SizedBox(height: 10),
                    _locationDropdown(
                      label: 'State',
                      value: _stateId,
                      options: _states,
                      onChanged: _countryId == null ? null : _onStateChanged,
                      requiredField: !_editing,
                      loading: _loadingStates,
                      disabledHint: _countryId == null ? 'Select a country first' : 'Select state',
                    ),
                    const SizedBox(height: 10),
                    _locationDropdown(
                      label: 'City',
                      value: _cityId,
                      options: _cities,
                      onChanged: _stateId == null ? null : (value) => setState(() { _cityId = value; _formError = null; }),
                      requiredField: !_editing,
                      loading: _loadingCities,
                      disabledHint: _stateId == null ? 'Select a state first' : 'Select city',
                    ),
                  ],
                  if (_formError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppPalette.error.withValues(alpha: .07), borderRadius: BorderRadius.circular(12)),
                      child: Text(_formError!, style: const TextStyle(fontFamily: 'sans-serif', fontSize: 12, color: AppPalette.error)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.champagne))
                          : Text(_editing ? 'Save changes' : 'Create mentor'),
                    ),
                  ),
                  const SizedBox(height: 18),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
