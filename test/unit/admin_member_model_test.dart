import 'package:flutter_test/flutter_test.dart';
import 'package:vedicvivah_mobile/features/admin/data/models/admin_member.dart';

void main() {
  test('parses AdminUserDto fields used by the member list', () {
    final member = AdminMember.fromJson({
      'userId': 'user-123',
      'userName': 'aarav.patel',
      'mobileNumber': '9876543210',
      'email': 'aarav@example.com',
      'roleName': 'User',
      'isMobileVerified': true,
      'isEmailVerified': true,
      'isActive': true,
      'isDeleted': false,
      'createdAtUtc': '2026-11-12T10:30:00Z',
      'profileId': 'profile-123',
      'firstName': 'Aarav',
      'lastName': 'Patel',
      'gender': 'Male',
      'profession': 'Engineer',
      'education': 'Graduate',
      'approvalStatus': 'Approved',
      'visibilityStatus': 'Visible',
      'isProfileComplete': true,
      'dateOfBirth': '2000-05-10',
      'cityName': 'Vadodara',
      'religionName': 'Hindu',
      'mentorName': 'Mentor One',
      'mentorUserId': 'mentor-1',
    });

    expect(member.userId, 'user-123');
    expect(member.displayName, 'Aarav Patel');
    expect(member.isActive, isTrue);
    expect(member.isProfileComplete, isTrue);
    expect(member.mentorUserId, 'mentor-1');
  });

  test('falls back to username when profile name is unavailable', () {
    final member = AdminMember.fromJson({
      'userId': 'user-456',
      'userName': 'new.member',
      'mobileNumber': '9000000000',
      'roleName': 'User',
    });

    expect(member.displayName, 'new.member');
    expect(member.email, isNull);
    expect(member.profileId, isNull);
    expect(member.isActive, isFalse);
  });
}
