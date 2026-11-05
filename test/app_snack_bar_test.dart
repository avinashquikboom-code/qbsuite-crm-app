import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/utils/app_snack_bar.dart';
import 'package:quickboom_app/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppSnackBar Widget & Visibility Tests', () {
    testWidgets(
      'showSuccess renders green background, check icon, and readable white text',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: NotificationService.instance.messengerKey,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showSuccess(
                      context,
                      '2 records imported successfully!',
                    );
                  },
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Verify the snackbar content is present
        expect(find.text('2 records imported successfully!'), findsOneWidget);
        expect(find.byIcon(Remix.checkbox_circle_fill), findsOneWidget);

        // Verify text styling
        final textWidget = tester.widget<Text>(
          find.text('2 records imported successfully!'),
        );
        expect(textWidget.style?.color, equals(Colors.white));
        expect(textWidget.style?.fontSize, equals(14));

        // Verify snackbar properties
        final snackBarFinder = find.byType(SnackBar);
        expect(snackBarFinder, findsOneWidget);
        final snackBar = tester.widget<SnackBar>(snackBarFinder);
        expect(snackBar.backgroundColor, equals(AppColors.primary));
        expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      },
    );

    testWidgets(
      'showError renders error background, error icon, and readable white text',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: NotificationService.instance.messengerKey,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showError(
                      context,
                      'Import failed: Connection refused',
                    );
                  },
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Import failed: Connection refused'), findsOneWidget);
        expect(find.byIcon(Remix.error_warning_fill), findsOneWidget);

        final textWidget = tester.widget<Text>(
          find.text('Import failed: Connection refused'),
        );
        expect(textWidget.style?.color, equals(Colors.white));

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, equals(AppColors.error));
        expect(snackBar.behavior, equals(SnackBarBehavior.floating));
      },
    );

    testWidgets(
      'Rapid duplicate calls deduplicate and do not queue multiple snackbars',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: NotificationService.instance.messengerKey,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showSuccess(context, 'First message');
                    AppSnackBar.showSuccess(context, 'Second message');
                  },
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Only the second message should be displayed, first is replaced
        expect(find.text('First message'), findsNothing);
        expect(find.text('Second message'), findsOneWidget);
      },
    );

    testWidgets(
      'SnackBar remains visible when navigating to a new screen',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: NotificationService.instance.navigatorKey,
            scaffoldMessengerKey: NotificationService.instance.messengerKey,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showSuccess(
                      context,
                      '2 records imported successfully!',
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: Center(child: Text('New Screen')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Trigger Navigation'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger Navigation'));
        await tester.pump(); // Starts transition
        await tester.pumpAndSettle(); // Finishes navigation

        // New screen is mounted
        expect(find.text('New Screen'), findsOneWidget);

        // SnackBar is still visible on top of the new screen!
        expect(find.text('2 records imported successfully!'), findsOneWidget);
        expect(find.byIcon(Remix.checkbox_circle_fill), findsOneWidget);
      },
    );
  });
}
