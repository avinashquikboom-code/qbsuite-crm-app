import 'package:quickboom_app/core/icons/remix_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/shared/widgets/app_app_bar.dart';
import 'package:quickboom_app/shared/widgets/common_app_bar.dart';

void main() {
  group('Platform-Independent AppBar Back Icon Tests', () {
    testWidgets('BackButton uses Remix on Android', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.android),
          home: Scaffold(appBar: AppBar(leading: const BackButton())),
        ),
      );

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(BackButtonIcon), findsOneWidget);
      expect(find.byIcon(RemixIcons.mapping[AppIcon.back]!), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('BackButton uses Remix on iOS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
          home: Scaffold(appBar: AppBar(leading: const BackButton())),
        ),
      );

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(BackButtonIcon), findsOneWidget);
      final iconWidgets = tester.widgetList<Icon>(find.byType(Icon));
      expect(
        iconWidgets.any((i) => i.icon == RemixIcons.mapping[AppIcon.back]),
        isTrue,
      );
      expect(find.byIcon(RemixIcons.mapping[AppIcon.back]!), findsOneWidget);
    });

    testWidgets(
      'AppAppBar automatically renders platform BackButton on subpages',
      (tester) async {
        final key = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: key,
            theme: AppTheme.lightTheme.copyWith(
              platform: TargetPlatform.android,
            ),
            home: Scaffold(
              appBar: const AppAppBar(title: 'Root Screen'),
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          appBar: AppAppBar(title: 'Detail Screen'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Detail'),
                ),
              ),
            ),
          ),
        );

        // Root screen should NOT have BackButton
        expect(find.byType(BackButton), findsNothing);

        // Navigate to detail
        await tester.tap(find.text('Open Detail'));
        await tester.pumpAndSettle();

        // Detail screen should have BackButton
        expect(find.text('Detail Screen'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.byIcon(RemixIcons.mapping[AppIcon.back]!), findsOneWidget);

        // Tap back button
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Returned to Root Screen
        expect(find.text('Root Screen'), findsOneWidget);
        expect(find.text('Detail Screen'), findsNothing);
      },
    );

    testWidgets(
      'CommonAppBar automatically renders platform BackButton when route can pop',
      (tester) async {
        final key = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: key,
            theme: AppTheme.lightTheme.copyWith(platform: TargetPlatform.iOS),
            home: Scaffold(
              appBar: const CommonAppBar(title: 'Root Screen'),
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          appBar: CommonAppBar(title: 'Subpage Screen'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Go Subpage'),
                ),
              ),
            ),
          ),
        );

        // Root screen: no back button
        expect(find.byType(BackButton), findsNothing);

        await tester.tap(find.text('Go Subpage'));
        await tester.pumpAndSettle();

        // Subpage has BackButton with iOS back icon
        expect(find.text('Subpage Screen'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
        final subpageIcons = tester.widgetList<Icon>(find.byType(Icon));
        expect(subpageIcons.any((i) => i.icon?.codePoint == 0xf570), isTrue);

        // Tap back button pops route
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.text('Root Screen'), findsOneWidget);
        expect(find.text('Subpage Screen'), findsNothing);
      },
    );
  });
}
