import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/constants/app_bar_titles.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/shared/widgets/app_app_bar.dart';

void main() {
  group('AppAppBar Tests', () {
    testWidgets('Renders standardized title correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            appBar: AppAppBar(
              title: AppBarTitles.dataCapture,
              showBackButton: false,
            ),
          ),
        ),
      );

      expect(find.text('Data Capture'), findsOneWidget);
      expect(find.byIcon(Remix.arrow_left_line), findsNothing);
    });

    testWidgets(
      'Renders back button with Back tooltip when showBackButton is true',
      (WidgetTester tester) async {
        bool backPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              appBar: AppAppBar(
                title: AppBarTitles.notifications,
                showBackButton: true,
                onBack: () => backPressed = true,
              ),
            ),
          ),
        );

        expect(find.text('Notifications'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        expect(backPressed, isTrue);
      },
    );

    testWidgets('Renders actions correctly', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppAppBar(
              title: AppBarTitles.leadsPipeline,
              actions: [
                IconButton(
                  icon: const Icon(Remix.add_circle_line),
                  onPressed: () => actionPressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Remix.add_circle_line), findsOneWidget);
      await tester.tap(find.byIcon(Remix.add_circle_line));
      expect(actionPressed, isTrue);
    });

    testWidgets('PreferredSize includes bottom widget height when present', (
      WidgetTester tester,
    ) async {
      const tabBar = TabBar(
        tabs: [
          Tab(text: 'Tab 1'),
          Tab(text: 'Tab 2'),
        ],
      );

      const appBar = AppAppBar(
        title: AppBarTitles.requests,
        showBackButton: false,
        bottom: tabBar,
      );

      expect(
        appBar.preferredSize.height,
        equals(kToolbarHeight + kTextTabBarHeight),
      );
    });

    testWidgets(
      'Uses platform-independent BackButton on iOS target platform as well',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
            home: const Scaffold(
              appBar: AppAppBar(
                title: AppBarTitles.attendance,
                showBackButton: true,
              ),
            ),
          ),
        );

        expect(find.byType(BackButton), findsOneWidget);
      },
    );
  });
}
