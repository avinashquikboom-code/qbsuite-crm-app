import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/roles/employee/models/commission_model.dart';
import 'package:quickboom_app/roles/employee/services/employee_api_service.dart';
import 'package:quickboom_app/roles/employee/viewmodels/commission_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/commission_view.dart';

void main() {
  test(
    'commission pagination loads additional own records and retains customer totals',
    () async {
      final container = ProviderContainer(
        overrides: [
          employeeApiServiceProvider.overrideWithValue(
            _PagedCommissionService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(employeeCommissionProvider.notifier);
      await notifier.loadCommissions();
      expect(container.read(employeeCommissionProvider).items.length, 1);
      expect(container.read(employeeCommissionProvider).total, 2);
      await notifier.loadMore();
      expect(
        container.read(employeeCommissionProvider).items.map((item) => item.id),
        [1, 2],
      );
      expect(container.read(employeeCommissionProvider).page, 2);
    },
  );
  test(
    'Split ledger preserves original rate, own effective rate, leader attribution and payroll',
    () {
      final item = CommissionItem.fromJson({
        'id': 1,
        'customerId': 50,
        'employeeId': 10,
        'commissionType': 'PERCENTAGE',
        'commissionRate': 1.5,
        'originalCommissionRate': 3,
        'commissionAmount': 150,
        'employeeShareAmount': 150,
        'leaderShareAmount': 150,
        'recipientRole': 'LEADER',
        'employee': {'firstName': 'Seller', 'lastName': 'One'},
        'status': 'PAID',
        'payrollPeriod': '2026-10',
        'customerCommissionTotal': 150,
        'qualifyingAt': '2026-10-11T12:00:00Z',
        'employeeShareStatus': 'APPROVED',
      });
      expect(item.commissionRate, 1.5);
      expect(item.originalCommissionRate, 3);
      expect(item.commissionAmount, 150);
      expect(item.recipientRole, 'LEADER');
      expect(item.sourceEmployeeName, 'Seller One');
      expect(item.payrollPeriod, '2026-10');
      expect(item.customerCommissionTotal, 150);
      expect(item.employeeShareStatus, 'APPROVED');
    },
  );

  group('1. Commission Model Deserialization & Calculations', () {
    test('Correctly deserializes CommissionItem from Backend JSON', () {
      final json = {
        'id': 101,
        'customerId': 55,
        'employeeId': 12,
        'leadId': 701,
        'planId': 3,
        'purchaseId': 9001,
        'orderId': 'ORD_QB_9001',
        'commissionType': 'PERCENTAGE',
        'commissionRate': 5.0,
        'purchaseAmount': 20000.0,
        'commissionAmount': 1000.0,
        'status': 'APPROVED',
        'paidAt': null,
        'createdAt': '2026-09-24T12:00:00.000Z',
        'lead': {
          'id': 701,
          'firstName': 'Suresh',
          'lastName': 'Patil',
          'companyName': 'Patil Fitness Hub',
          'title': 'Owner',
        },
        'customer': {
          'id': 55,
          'name': 'Patil Fitness',
          'companyName': 'Patil Fitness Pvt Ltd',
        },
        'plan': {
          'id': 3,
          'name': 'Premium Growth Plan',
          'monthlyPrice': 20000.0,
          'yearlyPrice': 190000.0,
        },
        'purchase': {
          'id': 9001,
          'orderNumber': '#QB-2026-001',
          'paymentId': 'pay_999999',
          'amount': 20000.0,
          'totalAmount': 23600.0,
        },
      };

      final item = CommissionItem.fromJson(json);

      expect(item.id, 101);
      expect(item.employeeId, 12);
      expect(item.commissionRate, 5.0);
      expect(item.purchaseAmount, 20000.0);
      expect(item.commissionAmount, 1000.0);
      expect(item.status, 'APPROVED');
      expect(item.isEarned, isTrue);
      expect(item.isApproved, isTrue);
      expect(item.isPaid, isFalse);
      expect(item.isPending, isFalse);

      expect(item.customer?.displayName, 'Patil Fitness Pvt Ltd');
      expect(item.lead?.displayName, 'Patil Fitness Hub');
      expect(item.plan?.name, 'Premium Growth Plan');
      expect(item.purchase?.orderNumber, '#QB-2026-001');
    });

    test('Correctly deserializes CommissionSummary with real totals', () {
      final json = {
        'totalCommission': 45000.0,
        'pendingCommission': 5000.0,
        'approvedCommission': 15000.0,
        'paidCommission': 25000.0,
        'totalCount': 18,
        'pendingCount': 2,
        'approvedCount': 6,
        'paidCount': 10,
      };

      final summary = CommissionSummary.fromJson(json);

      expect(summary.totalCommission, 45000.0);
      expect(summary.pendingCommission, 5000.0);
      expect(summary.approvedCommission, 15000.0);
      expect(summary.paidCommission, 25000.0);
      expect(summary.totalCount, 18);
      expect(summary.approvedCount, 6);
      expect(summary.paidCount, 10);
    });

    test('Status flags evaluate accurately across full lifecycle', () {
      final earned = CommissionItem(
        id: 1,
        customerId: 1,
        employeeId: 1,
        commissionType: 'PERCENTAGE',
        commissionRate: 5.0,
        purchaseAmount: 10000,
        commissionAmount: 500,
        status: 'APPROVED',
        createdAt: '2026-09-24',
      );
      expect(earned.isEarned, isTrue);
      expect(earned.isPaid, isFalse);

      final paid = CommissionItem(
        id: 2,
        customerId: 1,
        employeeId: 1,
        commissionType: 'PERCENTAGE',
        commissionRate: 7.0,
        purchaseAmount: 20000,
        commissionAmount: 1400,
        status: 'PAID',
        paidAt: '2026-09-25',
        createdAt: '2026-09-24',
      );
      expect(paid.isPaid, isTrue);
      expect(paid.isEarned, isFalse);

      final pending = CommissionItem(
        id: 3,
        customerId: 1,
        employeeId: 1,
        commissionType: 'FIXED',
        commissionRate: 1500,
        purchaseAmount: 15000,
        commissionAmount: 1500,
        status: 'PENDING',
        createdAt: '2026-09-24',
      );
      expect(pending.isPending, isTrue);

      final cancelled = CommissionItem(
        id: 4,
        customerId: 1,
        employeeId: 1,
        commissionType: 'PERCENTAGE',
        commissionRate: 5.0,
        purchaseAmount: 10000,
        commissionAmount: 500,
        status: 'CANCELLED',
        createdAt: '2026-09-24',
      );
      expect(cancelled.isCancelled, isTrue);
    });
  });

  group('2. RBAC & AppModule Integration', () {
    test('AppModule recognizes COMMISSION module constant', () {
      expect(AppModule.commission, 'COMMISSION');
      expect(AppModule.all.contains(AppModule.commission), isTrue);
      expect(AppModule.normalize('employee.commission'), 'COMMISSION');
      expect(AppModule.normalize('commissions'), 'COMMISSION');
    });

    test('PermissionManager grants commission access when permitted', () {
      final pm = PermissionManager.instance;
      pm.setPermissions([
        UserPermission(module: 'COMMISSION', action: 'VIEW'),
      ], isCrmEligible: true);

      expect(pm.canViewCommission, isTrue);
      expect(pm.canAccessScreen('COMMISSION'), isTrue);
    });

    test('PermissionManager denies commission access when not permitted', () {
      final pm = PermissionManager.instance;
      pm.setPermissions([
        UserPermission(module: 'LEADS', action: 'VIEW'),
      ], isCrmEligible: false);

      expect(pm.canViewCommission, isFalse);
    });
  });

  group('3. Employee Commission Screen Widget Rendering & Responsiveness', () {
    final mockCommissionItems = [
      CommissionItem(
        id: 1,
        customerId: 10,
        employeeId: 5,
        leadId: 101,
        planId: 2,
        purchaseId: 501,
        orderId: 'ORD_QB_101',
        commissionType: 'PERCENTAGE',
        commissionRate: 5.0,
        purchaseAmount: 20000,
        commissionAmount: 1000,
        status: 'APPROVED', // Earned
        createdAt: '2026-09-24T10:00:00.000Z',
        customer: CustomerSummary(
          id: 10,
          name: 'ABC Fitness Gym',
          companyName: 'ABC Fitness',
        ),
        lead: LeadSummary(
          id: 101,
          title: 'ABC Gym Lead',
          firstName: 'Karan',
          lastName: 'Singh',
        ),
        plan: PlanSummary(id: 2, name: 'Premium Plan'),
      ),
      CommissionItem(
        id: 2,
        customerId: 11,
        employeeId: 5,
        leadId: 102,
        planId: 1,
        purchaseId: 502,
        orderId: 'ORD_QB_102',
        commissionType: 'PERCENTAGE',
        commissionRate: 5.0,
        purchaseAmount: 10000,
        commissionAmount: 500,
        status: 'PAID', // Paid
        paidAt: '2026-09-25T11:00:00.000Z',
        createdAt: '2026-09-23T14:00:00.000Z',
        customer: CustomerSummary(
          id: 11,
          name: 'XYZ Dental Care',
          companyName: 'XYZ Dental Clinic',
        ),
        lead: LeadSummary(id: 102, title: 'Dental Clinic Conversion'),
        plan: PlanSummary(id: 1, name: 'Basic Plan'),
      ),
    ];

    final mockSummary = CommissionSummary(
      totalCommission: 1500,
      pendingCommission: 0,
      approvedCommission: 1000,
      paidCommission: 500,
      totalCount: 2,
      pendingCount: 0,
      approvedCount: 1,
      paidCount: 1,
    );

    final mockEmployeeInfo = CommissionEmployeeInfo(
      id: 5,
      name: 'Rahul Sharma',
      employeeCode: 'QB-EMP-005',
      designation: 'Telesales Executive',
    );

    Widget buildTestWidget({
      required EmployeeCommissionState state,
      Size screenSize = const Size(390, 844),
    }) {
      return ProviderScope(
        overrides: [
          employeeCommissionProvider.overrideWith(() {
            return _MockCommissionNotifier(state);
          }),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: const EmployeeCommissionView(),
          ),
        ),
      );
    }

    testWidgets(
      'Leader split ledger shows seller, both shares and paise without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final item = CommissionItem.fromJson({
          'id': 3,
          'customerId': 50,
          'employeeId': 20,
          'commissionType': 'PERCENTAGE',
          'commissionRate': 1.5,
          'originalCommissionRate': 3,
          'commissionAmount': 150.01,
          'employeeShareAmount': 150,
          'leaderShareAmount': 150.01,
          'recipientRole': 'LEADER',
          'employee': {'firstName': 'Seller', 'lastName': 'One'},
          'customer': {'id': 50, 'name': 'Split Customer'},
          'plan': {'id': 2, 'name': 'Growth'},
          'purchaseAmount': 10000,
          'status': 'APPROVED',
          'createdAt': '2026-10-11',
          'payrollPeriod': '2026-10',
          'employeeShareStatus': 'APPROVED',
        });
        await tester.pumpWidget(
          buildTestWidget(
            state: EmployeeCommissionState(
              items: [item],
              summary: mockSummary,
              employee: mockEmployeeInfo,
            ),
            screenSize: const Size(320, 800),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Seller One'), findsOneWidget);
        expect(find.text('₹150.01'), findsOneWidget);
        expect(find.textContaining('1.5% of 3.0% total'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Renders Commission dashboard with KPIs and list items', (
      tester,
    ) async {
      final state = EmployeeCommissionState(
        items: mockCommissionItems,
        summary: mockSummary,
        employee: mockEmployeeInfo,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestWidget(state: state));
      await tester.pumpAndSettle();

      // Title & Hero Banner
      expect(find.text('My Commissions'), findsOneWidget);
      expect(find.text('TOTAL COMMISSION'), findsOneWidget);
      expect(find.text('₹1,500.00'), findsOneWidget);
      expect(find.text('Telesales Executive'), findsOneWidget);

      // KPI Metric Cards
      expect(find.text('Earned'), findsWidgets);
      expect(find.text('Paid'), findsWidgets);
      expect(find.text('Pending'), findsWidgets);

      // Filter Chips
      expect(find.text('All'), findsOneWidget);

      // List Items
      expect(find.text('ABC Fitness · #10'), findsOneWidget);
      expect(find.text('XYZ Dental Clinic · #11'), findsOneWidget);
      expect(find.text('₹1,000.00'), findsWidgets);
      expect(find.text('₹500.00'), findsWidgets);
    });

    testWidgets(
      'Responsiveness test across all phone sizes (320, 360, 375, 390, 414, 430) with ZERO overflow',
      (tester) async {
        final oldOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details);
        };
        final widths = [320.0, 360.0, 375.0, 390.0, 414.0, 430.0];
        final state = EmployeeCommissionState(
          items: mockCommissionItems,
          summary: mockSummary,
          employee: mockEmployeeInfo,
          isLoading: false,
        );

        for (final w in widths) {
          tester.view.physicalSize = Size(w, 800);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildTestWidget(state: state, screenSize: Size(w, 800)),
          );
          await tester.pumpAndSettle();

          final exc = tester.takeException();
          expect(exc, isNull, reason: 'Failed with overflow on width $w');

          // Reset
          addTearDown(() {
            FlutterError.onError = oldOnError;
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
        }
      },
    );
  });
}

class _MockCommissionNotifier extends EmployeeCommissionNotifier {
  final EmployeeCommissionState _mockState;
  _MockCommissionNotifier(this._mockState);

  @override
  EmployeeCommissionState build() => _mockState;

  @override
  Future<void> loadCommissions({String? status}) async {}

  @override
  Future<void> refresh() async {}
}

class _PagedCommissionService implements EmployeeApiService {
  @override
  Future<EmployeeCommissionResponse> getMyCommissions({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return EmployeeCommissionResponse.fromJson({
      'data': [
        {
          'id': page,
          'customerId': 50,
          'employeeId': 10,
          'commissionRate': 1.5,
          'originalCommissionRate': 3,
          'commissionAmount': 150,
          'status': 'APPROVED',
        },
      ],
      'summary': {'totalCommission': 300},
      'meta': {'total': 2, 'page': page, 'limit': 1},
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
