import 'package:flutter_test/flutter_test.dart';
import 'package:vedic_vivah/features/admin/data/models/admin_profile_review_models.dart';

void main() {
  group('AdminQueueProfile', () {
    test('parses a submitted profile and exposes review state', () {
      final profile = AdminQueueProfile.fromJson({
        'id': 'profile-1',
        'userId': 'user-1',
        'userName': 'member.one',
        'email': 'member@example.com',
        'firstName': 'Aarav',
        'lastName': 'Patel',
        'gender': 'Male',
        'dateOfBirth': '2000-05-10',
        'profession': 'Engineer',
        'education': 'Graduate',
        'cityName': 'Vadodara',
        'approvalStatus': 'SubmittedForReview',
        'createdAtUtc': '2026-11-10T10:00:00Z',
      });

      expect(profile.fullName, 'Aarav Patel');
      expect(profile.userName, 'member.one');
      expect(profile.canReview, isTrue);
      expect(profile.cityName, 'Vadodara');
    });

    test('does not allow review actions for already decided profiles', () {
      final profile = AdminQueueProfile.fromJson({
        'id': 'profile-2',
        'userId': 'user-2',
        'userName': 'member.two',
        'firstName': 'Mira',
        'gender': 'Female',
        'dateOfBirth': '1999-02-01',
        'approvalStatus': 'Approved',
      });

      expect(profile.canReview, isFalse);
      expect(profile.lastName, isNull);
      expect(profile.email, isNull);
    });
  });

  test('parses profile detail, photos and relative contacts', () {
    final detail = AdminProfileReviewDetail.fromJson({
      'profile': {
        'id': 'profile-1',
        'userId': 'user-1',
        'firstName': 'Aarav',
        'approvalStatus': 'SubmittedForReview',
        'isProfileComplete': true,
      },
      'photos': [
        {'id': 'photo-1', 'isPrimary': true},
        {'id': 'photo-2', 'isPrimary': false},
      ],
      'relativeContacts': [
        {
          'referenceId': 'ref-1',
          'name': 'Ravi Patel',
          'phoneNumber': '9876543210',
          'cityName': 'Vadodara',
          'relationshipWithUser': 'Brother',
        },
      ],
    });

    expect(detail.profile['firstName'], 'Aarav');
    expect(detail.photos, hasLength(2));
    expect(detail.photos.first.isPrimary, isTrue);
    expect(detail.contacts.single.relationshipWithUser, 'Brother');
  });
}
