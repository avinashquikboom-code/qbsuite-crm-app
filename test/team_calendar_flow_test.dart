import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/employee/viewmodels/team_calendar_viewmodel.dart';

void main() {
  group('Team Calendar Flow & Parsing Tests', () {
    test('Correctly parses unified Team Calendar JSON response', () {
      final jsonResponse = [
        {
          "id": 84,
          "activityType": "REEL_EDIT",
          "type": "REEL_EDIT",
          "title": "Reel Edit",
          "scheduledDate": "2026-09-08",
          "scheduledTime": "11:00 AM",
          "time": "11:00 AM",
          "status": "SCHEDULED",
          "customer": {
            "id": 3,
            "name": "Calendar Test Customer A",
            "companyName": "Alpha Brand Studios",
          },
          "team": {"id": 2, "name": "SSM Team A"},
          "employee": {
            "id": 50,
            "name": "Avinash Magar",
            "designation": "Video Editor",
          },
        },
        {
          "id": 40,
          "activityType": "STORY_DESIGN",
          "type": "STORY_DESIGN",
          "title": "Story Design",
          "scheduledDate": "2026-09-08",
          "scheduledTime": "02:00 PM",
          "time": "02:00 PM",
          "status": "SCHEDULED",
          "customer": {
            "id": 3,
            "name": "Calendar Test Customer A",
            "companyName": "Alpha Brand Studios",
          },
          "team": {"id": 2, "name": "SSM Team A"},
          "employee": {
            "id": 53,
            "name": "Rahul Sharma",
            "designation": "Graphic Designer",
          },
        },
        {
          "id": 85,
          "activityType": "REEL_POST",
          "type": "REEL_POST",
          "title": "Reel Post",
          "scheduledDate": "2026-09-08",
          "scheduledTime": "05:00 PM",
          "time": "05:00 PM",
          "status": "SCHEDULED",
          "customer": {
            "id": 3,
            "name": "Calendar Test Customer A",
            "companyName": "Alpha Brand Studios",
          },
          "team": {"id": 2, "name": "SSM Team A"},
          "employee": {
            "id": 55,
            "name": "Sneha Patil",
            "designation": "Social Media Executive",
          },
        },
      ];

      final activities = jsonResponse
          .map((item) => CustomerCalendarActivity.fromJson(item))
          .toList();

      expect(activities.length, 3);

      // Verify Reel Edit
      final reelEdit = activities[0];
      expect(reelEdit.id, '84');
      expect(reelEdit.scheduledDateStr, '2026-09-08');
      expect(reelEdit.time, '11:00 AM');
      expect(reelEdit.status, 'SCHEDULED');
      expect(resolveTaskColor(reelEdit), const Color(0xFF2563EB)); // Blue

      // Verify Story Design
      final storyDesign = activities[1];
      expect(storyDesign.id, '40');
      expect(storyDesign.scheduledDateStr, '2026-09-08');
      expect(storyDesign.time, '02:00 PM');
      expect(storyDesign.status, 'SCHEDULED');
      expect(resolveTaskColor(storyDesign), const Color(0xFF9333EA)); // Purple

      // Verify Reel Post
      final reelPost = activities[2];
      expect(reelPost.id, '85');
      expect(reelPost.scheduledDateStr, '2026-09-08');
      expect(reelPost.time, '05:00 PM');
      expect(reelPost.status, 'SCHEDULED');
      expect(resolveTaskColor(reelPost), const Color(0xFF16A34A)); // Green
    });

    test(
      'Generates distinct multi-dots for dates with multiple activity types',
      () {
        final sep8 = DateTime(2026, 9, 8);
        final key = TeamCalendarState.formatDateKey(sep8);

        final activities = <CustomerCalendarActivity>[
          CustomerCalendarActivity.fromJson({
            'id': '84',
            'customerId': '3',
            'customerName': 'Customer A',
            'type': 'REEL_EDIT',
            'title': 'Reel Edit',
            'scheduledDate': '2026-09-08',
            'status': 'SCHEDULED',
          }),
          CustomerCalendarActivity.fromJson({
            'id': '40',
            'customerId': '3',
            'customerName': 'Customer A',
            'type': 'STORY_DESIGN',
            'title': 'Story Design',
            'scheduledDate': '2026-09-08',
            'status': 'SCHEDULED',
          }),
          CustomerCalendarActivity.fromJson({
            'id': '85',
            'customerId': '3',
            'customerName': 'Customer A',
            'type': 'REEL_POST',
            'title': 'Reel Post',
            'scheduledDate': '2026-09-08',
            'status': 'SCHEDULED',
          }),
        ];

        final state = TeamCalendarState(
          currentMonth: DateTime(2026, 9, 1),
          selectedDate: sep8,
          activitiesByDate: {key: activities},
        );

        final dots = state.getDotsForDate(sep8);
        expect(dots.length, 3);
        expect(dots[0], const Color(0xFF2563EB)); // Blue (Reel Edit)
        expect(dots[1], const Color(0xFF9333EA)); // Purple (Story Design)
        expect(dots[2], const Color(0xFF16A34A)); // Green (Reel Post)

        // Selected date activities should return all 3
        expect(state.selectedDateActivities.length, 3);

        // Other dates have 0 dots and 0 activities
        final sep9 = DateTime(2026, 9, 9);
        expect(state.getDotsForDate(sep9).isEmpty, true);
      },
    );
  });
}
