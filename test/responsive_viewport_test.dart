import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/shared/views/demo/demo_workspace_views.dart';

void main() {
  const viewports = <String, Size>{
    '320x568 compact': Size(320, 568),
    '360x800 compact': Size(360, 800),
    '375x812 standard': Size(375, 812),
    '390x844 standard': Size(390, 844),
    '412x915 large': Size(412, 915),
    '430x932 large': Size(430, 932),
    '600x960 tablet': Size(600, 960),
    '768x1024 tablet': Size(768, 1024),
  };

  for (final entry in viewports.entries) {
    testWidgets('demo home renders without overflow at ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: DemoHomeView()));
      await tester.pumpAndSettle();
      expect(find.text('BPO Employee'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('demo workspace grid adapts at ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: DemoEmployeeWorkspaceView(workspace: DemoEmployeeWorkspace.bpo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Today at a glance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('demo home supports landscape without overflow', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: DemoHomeView()));
    await tester.pumpAndSettle();
    expect(find.text('BPO Employee'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo home supports large text scaling', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: DemoHomeView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('BPO Employee'), findsWidgets);
    expect(find.text('Visitor Employee'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation switches to the visitor workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: DemoHomeView()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Visitor Employee'));
    await tester.pumpAndSettle();
    expect(find.text('Today’s visits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
