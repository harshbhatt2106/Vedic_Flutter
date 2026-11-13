import 'package:flutter_test/flutter_test.dart';
import 'package:vedicvivah_mobile/features/admin/data/models/admin_mentor_models.dart';

void main() {
  test('parses country, state and city options', () {
    final option = AdminLocationOption.fromJson({'id': 12, 'name': 'Gujarat'});
    expect(option.id, 12);
    expect(option.name, 'Gujarat');
  });

  test('parses mentor location with optional parent values', () {
    final location = AdminMentorLocation.fromJson({
      'countryId': 1,
      'countryName': 'India',
      'stateId': 2,
      'stateName': 'Gujarat',
      'cityId': 3,
      'cityName': 'Vadodara',
    });
    expect(location.countryId, 1);
    expect(location.stateName, 'Gujarat');
    expect(location.cityName, 'Vadodara');
  });

  test('parses assigned member list records', () {
    final member = AdminAssignedMember.fromJson({
      'userId': 'member-1',
      'firstName': 'Mira',
      'lastName': 'Shah',
      'mobileNumber': '9876543210',
      'email': 'mira@example.com',
      'userName': 'mira.shah',
      'assignedAtUtc': '2026-11-13T08:30:00Z',
      'isActive': true,
    });
    expect(member.displayName, 'Mira Shah');
    expect(member.userName, 'mira.shah');
    expect(member.isActive, isTrue);
    expect(member.assignedAtUtc, isNotNull);
  });
}
