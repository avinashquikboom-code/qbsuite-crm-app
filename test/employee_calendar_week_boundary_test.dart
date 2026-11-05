import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_calendar_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/employee_schedule_view.dart';

class _BoundaryDate extends EmployeeCalendarSelectedDateNotifier {
  @override
  DateTime build() => DateTime(2026, 10, 31);
}

void main() {
  testWidgets(
    'Week loads adjacent-month dots, selected cards, search and refresh',
    (tester) async {
      final allowFetching = GoogleFonts.config.allowRuntimeFetching;
      GoogleFonts.config.allowRuntimeFetching = false;
      addTearDown(
        () => GoogleFonts.config.allowRuntimeFetching = allowFetching,
      );
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final activity = CustomerCalendarActivity.fromJson({
        'id': '801',
        'customerId': '30',
        'customerName': 'Allotted Client',
        'title': 'Boundary shoot',
        'scheduledDate': '2026-11-01',
        'startTime': '11:00 AM',
        'activityType': 'REEL_SHOOT',
        'assignedTeam': 'PRODUCTION TEAM_A',
        'status': 'SCHEDULED',
      });
      final weekRequests = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            employeeCalendarSelectedDateProvider.overrideWith(
              _BoundaryDate.new,
            ),
            employeeCalendarActivitiesForMonthProvider.overrideWith(
              (ref, month) async => month == '2026-11' ? [activity] : [],
            ),
            employeeCalendarActivitiesForDateProvider.overrideWith(
              (ref, day) async => day == '2026-11-01' ? [activity] : [],
            ),
            employeeCalendarActivitiesFor7DayWindowProvider.overrideWith((
              ref,
              start,
            ) async {
              weekRequests.add(start);
              return start == '2026-10-26' ? [activity] : [];
            }),
          ],
          child: const MaterialApp(home: EmployeeScheduleView()),
        ),
      );
      await tester.pumpAndSettle();
      expect(weekRequests, isEmpty);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(weekRequests, ['2026-10-26']);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 4 &&
              widget.constraints?.maxHeight == 4 &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ASSIGNED TASKS (1)'), findsOneWidget);
      expect(find.text('Boundary shoot'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Allotted');
      await tester.pumpAndSettle();
      expect(find.text('Boundary shoot'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'unrelated');
      await tester.pumpAndSettle();
      expect(find.text('Boundary shoot'), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.byTooltip('Refresh Calendar'));
      await tester.pumpAndSettle();
      expect(weekRequests, ['2026-10-26', '2026-10-26']);
      expect(find.text('Boundary shoot'), findsOneWidget);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Remix.arrow_right_s_line).first);
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text('Boundary shoot'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Month and date responses retain Work and Task with the same ID',
    (tester) async {
      final previous = GoogleFonts.config.allowRuntimeFetching;
      GoogleFonts.config.allowRuntimeFetching = false;
      addTearDown(() => GoogleFonts.config.allowRuntimeFetching = previous);
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final work = CustomerCalendarActivity.fromJson({
        'id': '801',
        'title': 'Assigned production work',
        'scheduledDate': '2026-10-31',
        'activityType': 'REEL_SHOOT',
        'status': 'ASSIGNED',
      });
      final task = CustomerCalendarActivity.fromJson({
        'id': '801',
        'title': 'Assigned internal task',
        'scheduledDate': '2026-10-31',
        'activityType': 'TASK',
        'status': 'PENDING',
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            employeeCalendarSelectedDateProvider.overrideWith(
              _BoundaryDate.new,
            ),
            employeeCalendarActivitiesForMonthProvider.overrideWith(
              (ref, month) async => [work],
            ),
            employeeCalendarActivitiesForDateProvider.overrideWith(
              (ref, day) async => [task],
            ),
          ],
          child: const MaterialApp(home: EmployeeScheduleView()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('ASSIGNED TASKS (2)'), findsOneWidget);
      expect(find.text('Assigned production work'), findsOneWidget);
      expect(find.text('Assigned internal task'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
