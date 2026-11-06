import 'package:quickboom_app/core/utils/app_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';

class CompanyAdminState {
  final AdminCompanyProfile profile;
  final List<AdminCustomer> customers;
  final List<AdminSSMWork> workList;
  final List<AdminEmployee> employees;
  final List<AdminTeam> teams;
  final List<AdminLead> leads;
  final List<AdminVisit> visits;
  final List<AdminDataCapture> dataCaptures;
  final List<AdminProposal> proposals;
  final List<AdminPackage> packages;
  final List<AdminAuditLog> auditLogs;
  final List<CustomerCalendarActivity> customCalendarActivities;
  final List<AdminLiveAttendance> liveAttendanceList;

  CompanyAdminState({
    required this.profile,
    required this.customers,
    required this.workList,
    required this.employees,
    required this.teams,
    required this.leads,
    required this.visits,
    required this.dataCaptures,
    required this.proposals,
    required this.packages,
    required this.auditLogs,
    this.customCalendarActivities = const [],
    this.liveAttendanceList = const [],
  });

  // KPI Computations
  int get totalEmployees => employees.length;
  int get activeClients =>
      customers.where((c) => c.status == ClientStatus.active).length;
  int get openLeads => leads
      .where(
        (l) =>
            l.status == LeadStatus.newLead || l.status == LeadStatus.followUp,
      )
      .length;
  int get todayVisitsCount =>
      visits.where((v) => v.status == VisitStatus.today).length;
  int get activeSSMWorkCount =>
      workList.where((w) => w.status == WorkStatus.inProgress).length;
  int get pendingProposalsCount => proposals
      .where(
        (p) =>
            p.status == ProposalStatus.draft || p.status == ProposalStatus.sent,
      )
      .length;

  // Live Attendance Computations
  int get presentStaffCount => liveAttendanceList
      .where((a) => a.status == LiveAttendanceStatus.working)
      .length;
  int get onBreakStaffCount => liveAttendanceList
      .where((a) => a.status == LiveAttendanceStatus.onBreak)
      .length;
  int get onLeaveStaffCount => liveAttendanceList
      .where((a) => a.status == LiveAttendanceStatus.onLeave)
      .length;
  int get absentStaffCount => liveAttendanceList
      .where((a) => a.status == LiveAttendanceStatus.absent)
      .length;
  int get checkedOutStaffCount => liveAttendanceList
      .where((a) => a.status == LiveAttendanceStatus.checkedOut)
      .length;
  int get liveAttendancePercentage => liveAttendanceList.isNotEmpty
      ? (((presentStaffCount + onBreakStaffCount) / liveAttendanceList.length) *
                100)
            .round()
      : 0;

  /// Unified list of customer activities aggregated from local Work, Visits, Leads, Proposals, Data Captures
  List<CustomerCalendarActivity> get allCustomerActivities {
    final List<CustomerCalendarActivity> list = [];

    // 1. From workList (SSM Work)
    for (final work in workList) {
      CustomerActivityType type;
      switch (work.workType) {
        case WorkType.reel:
          type = CustomerActivityType.reelShoot;
          break;
        case WorkType.shoot:
          type = CustomerActivityType.videoShoot;
          break;
        case WorkType.post:
          type = CustomerActivityType.postCampaign;
          break;
      }

      for (int i = 0; i < work.durationDays; i++) {
        final activityDate = work.startDate.add(Duration(days: i));
        String stageDesc = 'Content Capture';
        if (i == 1) stageDesc = 'Editing & Production';
        if (i == 2) stageDesc = 'Review & Final Deliverable';

        list.add(
          CustomerCalendarActivity(
            id: '${work.id}_day_${i + 1}',
            customerId: work.customerId,
            customerName: work.customerName,
            businessName: '${work.customerName} Pvt Ltd',
            activityType: type,
            date: DateTime(
              activityDate.year,
              activityDate.month,
              activityDate.day,
            ),
            time: i == 0
                ? '10:00 AM — 11:30 AM'
                : (i == 1 ? '02:00 PM — 04:00 PM' : '04:30 PM — 06:00 PM'),
            assignedEmployee: work.assignedEmployee,
            team: work.team,
            status: work.status.label,
            statusColor: work.status.color,
            statusBgColor: work.status.bgColor,
            notes:
                'Day ${i + 1} of ${work.durationDays}: $stageDesc. Platform: ${work.platform}.',
            relatedWorkId: work.id,
          ),
        );
      }
    }

    // 2. From visits
    for (final visit in visits) {
      DateTime visitDate = DateTime(2026, 8, 20);
      if (visit.status == VisitStatus.completed) {
        visitDate = DateTime(2026, 8, 18);
      } else if (visit.status == VisitStatus.upcoming) {
        visitDate = DateTime(2026, 8, 21);
      }

      list.add(
        CustomerCalendarActivity(
          id: visit.id,
          customerId: visit.customerId,
          customerName: visit.customerName,
          businessName: '${visit.customerName} Pvt Ltd',
          activityType: CustomerActivityType.customerVisit,
          date: visitDate,
          time: visit.time,
          assignedEmployee: visit.employeeName,
          team: 'SSM Team A',
          status: visit.status.label,
          statusColor: visit.status.color,
          statusBgColor: visit.status.bgColor,
          notes: visit.notes ?? 'Scheduled client visit at ${visit.location}.',
        ),
      );
    }

    // 3. Leads are CRM pipeline entities and are strictly excluded from calendar activities (which only track work/deliverables).

    // 4. From proposals
    for (final prop in proposals) {
      DateTime propDate = DateTime(2026, 8, 18);
      if (prop.status == ProposalStatus.sent) propDate = DateTime(2026, 8, 22);
      if (prop.status == ProposalStatus.draft) propDate = DateTime(2026, 8, 20);

      list.add(
        CustomerCalendarActivity(
          id: prop.id,
          customerId: prop.customerId,
          customerName: prop.customerName,
          businessName: prop.businessName,
          activityType: CustomerActivityType.proposalMeeting,
          date: propDate,
          time: '03:00 PM — 03:45 PM',
          assignedEmployee: 'Demo User',
          team: 'SSM Team A',
          status: prop.status.label,
          statusColor: prop.status.color,
          statusBgColor: prop.status.bgColor,
          notes:
              'Package: ${prop.packageName}. Amount: ${AppCurrency.format(prop.amount)}.',
        ),
      );
    }

    // 5. From dataCaptures
    for (final dc in dataCaptures) {
      list.add(
        CustomerCalendarActivity(
          id: dc.id,
          customerId: dc.customerId,
          customerName: dc.customerName,
          businessName: '${dc.customerName} Pvt Ltd',
          activityType: CustomerActivityType.dataCapture,
          date: DateTime(2026, 8, 20),
          time: '05:15 PM — 06:00 PM',
          assignedEmployee: dc.employeeName,
          team: 'SSM Team A',
          status: dc.status,
          statusColor: const Color(0xFF16A34A),
          statusBgColor: const Color(0xFFDCFCE7),
          notes:
              'Capture type: ${dc.captureType}. Customer: ${dc.customerName}.',
        ),
      );
    }

    list.addAll(customCalendarActivities);

    // Sort by time
    return list;
  }

  /// Strictly filters all state data to a specific customer ID.
  /// If targetCustomerId is null or empty, returns an empty state (never global data fallback).
  CompanyAdminState forCustomer(String? targetCustomerId) {
    if (targetCustomerId == null || targetCustomerId.trim().isEmpty) {
      return CompanyAdminState(
        profile: profile,
        customers: const [],
        workList: const [],
        employees: const [],
        teams: const [],
        leads: const [],
        visits: const [],
        dataCaptures: const [],
        proposals: const [],
        packages: const [],
        auditLogs: const [],
        customCalendarActivities: const [],
        liveAttendanceList: const [],
      );
    }

    final tid = targetCustomerId.trim().toUpperCase();
    final targetId =
        (tid == 'CUSTOMER_B' ||
            tid == 'CUST_2' ||
            tid == 'CUST-2' ||
            tid == '2' ||
            tid == 'CUST-002')
        ? 'T002'
        : (tid == 'CUSTOMER_A' ||
              tid == 'CUST_1' ||
              tid == 'CUST-1' ||
              tid == '1' ||
              tid == 'CUST-001')
        ? 'T001'
        : tid;

    return CompanyAdminState(
      profile: profile,
      customers: customers
          .where((c) => c.customerId.toUpperCase() == targetId)
          .toList(),
      workList: workList
          .where((w) => w.customerId.toUpperCase() == targetId)
          .toList(),
      employees: employees
          .where((e) => e.customerId.toUpperCase() == targetId)
          .toList(),
      teams: teams
          .where((t) => t.customerId.toUpperCase() == targetId)
          .toList(),
      leads: leads
          .where((l) => l.customerId.toUpperCase() == targetId)
          .toList(),
      visits: visits
          .where((v) => v.customerId.toUpperCase() == targetId)
          .toList(),
      dataCaptures: dataCaptures
          .where((d) => d.customerId.toUpperCase() == targetId)
          .toList(),
      proposals: proposals
          .where((p) => p.customerId.toUpperCase() == targetId)
          .toList(),
      packages: packages,
      auditLogs: auditLogs,
      customCalendarActivities: customCalendarActivities
          .where((a) => a.customerId.toUpperCase() == targetId)
          .toList(),
      liveAttendanceList: liveAttendanceList
          .where((a) => a.customerId.toUpperCase() == targetId)
          .toList(),
    );
  }

  List<CustomerCalendarActivity> getActivitiesForDate(DateTime date) {
    return allCustomerActivities
        .where(
          (a) =>
              a.date.year == date.year &&
              a.date.month == date.month &&
              a.date.day == date.day,
        )
        .toList();
  }

  bool hasActivitiesOnDate(DateTime date) {
    return allCustomerActivities.any(
      (a) =>
          a.date.year == date.year &&
          a.date.month == date.month &&
          a.date.day == date.day,
    );
  }

  int countActivitiesOnDate(DateTime date) {
    return getActivitiesForDate(date).length;
  }

  CompanyAdminState copyWith({
    AdminCompanyProfile? profile,
    List<AdminCustomer>? customers,
    List<AdminSSMWork>? workList,
    List<AdminEmployee>? employees,
    List<AdminTeam>? teams,
    List<AdminLead>? leads,
    List<AdminVisit>? visits,
    List<AdminDataCapture>? dataCaptures,
    List<AdminProposal>? proposals,
    List<AdminPackage>? packages,
    List<AdminAuditLog>? auditLogs,
    List<CustomerCalendarActivity>? customCalendarActivities,
    List<AdminLiveAttendance>? liveAttendanceList,
  }) {
    return CompanyAdminState(
      profile: profile ?? this.profile,
      customers: customers ?? this.customers,
      workList: workList ?? this.workList,
      employees: employees ?? this.employees,
      teams: teams ?? this.teams,
      leads: leads ?? this.leads,
      visits: visits ?? this.visits,
      dataCaptures: dataCaptures ?? this.dataCaptures,
      proposals: proposals ?? this.proposals,
      packages: packages ?? this.packages,
      auditLogs: auditLogs ?? this.auditLogs,
      customCalendarActivities:
          customCalendarActivities ?? this.customCalendarActivities,
      liveAttendanceList: liveAttendanceList ?? this.liveAttendanceList,
    );
  }
}

class CompanyAdminNotifier extends Notifier<CompanyAdminState> {
  @override
  CompanyAdminState build() => _initialSeedState();

  static CompanyAdminState _initialSeedState() {
    final profile = AdminCompanyProfile(
      companyName: 'ABC Digital Solutions',
      businessName: 'ABC Digital Solutions Pvt. Ltd.',
      mobile: '+91 98765 43210',
      email: 'contact@abcdigital.com',
      website: 'https://abcdigital.com',
      address: 'Suite 402, Pinnacle Tech Park, Andheri East',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400069',
      businessDetails:
          'Premium digital marketing, content creation & social media agency.',
    );

    final customers = [
      AdminCustomer(
        id: 'CUST-001',
        customerId: 'T001',
        name: 'Care Fitness Gym',
        businessName: 'Care Fitness & Wellness Hub',
        mobile: '+91 98201 12345',
        alternateNumber: '+91 98201 54321',
        email: 'info@carefitness.com',
        website: 'https://carefitness.in',
        industry: 'Fitness & Health',
        businessCategory: 'Gymnasium',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400053',
        assignedEmployee: 'Demo User',
        assignedTeam: 'SSM Team A',
        activeWork: 'Reel Shoot',
        status: ClientStatus.active,
        customerSince: '15 Jan 2025',
        nextFollowUp: '20 Aug',
        notes:
            'VIP fitness client. Requires weekly high-engagement video shoots.',
      ),
      AdminCustomer(
        id: 'CUST-002',
        customerId: 'CUST-002',
        name: 'IB Gym',
        businessName: 'Iron Body Fitness Center',
        mobile: '+91 99302 98765',
        alternateNumber: '+91 99302 11223',
        email: 'contact@ibgym.com',
        website: 'https://ibgym.com',
        industry: 'Health & Fitness',
        businessCategory: 'Crossfit Gym',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        assignedEmployee: 'Amit',
        assignedTeam: 'SSM Team B',
        activeWork: 'Post Creation',
        status: ClientStatus.active,
        customerSince: '01 Feb 2025',
        nextFollowUp: '22 Aug',
        notes: 'Regular monthly branding and social graphic posts.',
      ),
      AdminCustomer(
        id: 'CUST-003',
        customerId: 'CUST-003',
        name: 'Urban Cafe & Bistro',
        businessName: 'Urban Hospitality LLP',
        mobile: '+91 98111 22334',
        email: 'manager@urbancafe.com',
        city: 'Mumbai',
        assignedEmployee: 'Sneha',
        assignedTeam: 'SSM Team A',
        activeWork: 'Food Shoot',
        status: ClientStatus.active,
        customerSince: '10 Mar 2025',
        nextFollowUp: '25 Aug',
      ),
      AdminCustomer(
        id: 'CUST-004',
        customerId: 'CUST-004',
        name: 'Zenith Dental Care',
        businessName: 'Zenith Healthcare Clinics',
        mobile: '+91 97654 32109',
        email: 'dr@zenithdental.com',
        city: 'Thane',
        assignedEmployee: 'Rahul',
        assignedTeam: 'SSM Team A',
        activeWork: 'Reel Production',
        status: ClientStatus.active,
        customerSince: '20 Apr 2025',
        nextFollowUp: '28 Aug',
      ),
      AdminCustomer(
        id: 'CUST-005',
        customerId: 'CUST-005',
        name: 'Luxe Salon & Spa',
        businessName: 'Luxe Aesthetics Care',
        mobile: '+91 98450 67890',
        email: 'hello@luxesalon.in',
        city: 'Navi Mumbai',
        assignedEmployee: 'Priya',
        assignedTeam: 'SSM Team B',
        activeWork: 'Product Shoot',
        status: ClientStatus.active,
        customerSince: '05 May 2025',
        nextFollowUp: '30 Aug',
      ),
      // ── CUSTOMER B (T002) Isolated Mock Customers ─────────────────────────────
      AdminCustomer(
        id: 'CUST-T2-001',
        customerId: 'T002',
        name: 'ABC Fitness',
        businessName: 'ABC Fitness & Health Club',
        mobile: '+91 98900 11223',
        alternateNumber: '+91 98900 99887',
        email: 'contact@abcfitness.in',
        website: 'https://abcfitness.in',
        industry: 'Fitness & Gym',
        businessCategory: 'Crossfit & Gym',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411004',
        assignedEmployee: 'Rahul',
        assignedTeam: 'Growth Team 1',
        activeWork: 'Reel Shoot',
        status: ClientStatus.active,
        customerSince: '10 Jan 2026',
        nextFollowUp: '20 Aug',
        notes: 'Customer B premier gym client.',
      ),
      AdminCustomer(
        id: 'CUST-T2-002',
        customerId: 'T002',
        name: 'XYZ Restaurant',
        businessName: 'XYZ Fine Dining & Lounge',
        mobile: '+91 98900 44556',
        alternateNumber: '+91 98900 33221',
        email: 'manager@xyzrestaurant.com',
        website: 'https://xyzrestaurant.com',
        industry: 'Food & Beverage',
        businessCategory: 'Fine Dining Restaurant',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400050',
        assignedEmployee: 'Priya',
        assignedTeam: 'Creative Team Alpha',
        activeWork: 'Video Editing',
        status: ClientStatus.active,
        customerSince: '15 Feb 2026',
        nextFollowUp: '21 Aug',
        notes: 'Customer B food & beverage client.',
      ),
      AdminCustomer(
        id: 'CUST-T2-003',
        customerId: 'T002',
        name: 'Demo Business',
        businessName: 'Demo Business Solutions Pvt Ltd',
        mobile: '+91 98900 88990',
        email: 'info@demobusiness.com',
        website: 'https://demobusiness.com',
        industry: 'Retail & E-commerce',
        businessCategory: 'Retail Store',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411038',
        assignedEmployee: 'Rahul',
        assignedTeam: 'Growth Team 1',
        activeWork: 'Post Creation',
        status: ClientStatus.active,
        customerSince: '01 Mar 2026',
        nextFollowUp: '23 Aug',
        notes: 'Customer B demo retail enterprise.',
      ),
    ];

    // Seed up to 48 dummy records representation (stored cleanly) for Customer A
    for (int i = 6; i <= 48; i++) {
      customers.add(
        AdminCustomer(
          id: 'CUST-${i.toString().padLeft(3, '0')}',
          customerId: 'CUST-${i.toString().padLeft(3, '0')}',
          name: 'Client Business #$i',
          businessName: 'Enterprise $i Solutions',
          mobile: '+91 98000 ${10000 + i}',
          email: 'client$i@business.com',
          city: i % 2 == 0 ? 'Mumbai' : 'Pune',
          assignedEmployee: i % 2 == 0 ? 'Demo User' : 'Amit',
          assignedTeam: i % 2 == 0 ? 'SSM Team A' : 'SSM Team B',
          activeWork: i % 3 == 0 ? 'Reel Shoot' : 'Post Creation',
          status: ClientStatus.active,
          customerSince: '01 Jun 2025',
          nextFollowUp: '${15 + (i % 15)} Aug',
        ),
      );
    }

    final workList = [
      AdminSSMWork(
        id: 'WRK-001',
        customerId: 'T001',
        customerName: 'Care Fitness Gym',
        socialAccount: '@carefitness_official',
        platform: 'Instagram',
        workType: WorkType.reel,
        team: 'SSM Team A',
        teamMembers: ['Demo User', 'Rahul', 'Sneha'],
        assignedEmployee: 'Demo User',
        startDate: DateTime.now().subtract(const Duration(days: 0)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        durationDays: 3,
        currentDay: 1,
        todayTask: 'Day 1: Shoot / Content Capture at main gym floor',
        allTasks: [
          DayTask(
            day: 1,
            title: 'Shoot / Content Capture',
            description:
                'Capture gym equipment, member workout reels, and trainer interviews.',
            isCompleted: false,
            isCurrent: true,
          ),
          DayTask(
            day: 2,
            title: 'Editing / Production',
            description:
                'Color grading, viral audio sync, and motion graphics overlay.',
            isCompleted: false,
          ),
          DayTask(
            day: 3,
            title: 'Final Review / Submission',
            description: 'Client review, revisions, and automated scheduling.',
            isCompleted: false,
          ),
        ],
        status: WorkStatus.inProgress,
        priority: 'High',
        notes: 'Priority reel for monthly campaign promo.',
      ),
      AdminSSMWork(
        id: 'WRK-002',
        customerId: 'CUST-002',
        customerName: 'IB Gym',
        socialAccount: '@ib_fitness_pune',
        platform: 'Facebook & Instagram',
        workType: WorkType.post,
        team: 'SSM Team B',
        teamMembers: ['Amit', 'Priya', 'Neha'],
        assignedEmployee: 'Amit',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        durationDays: 1,
        currentDay: 1,
        todayTask: 'Day 1: Post Creation / Publishing',
        allTasks: [
          DayTask(
            day: 1,
            title: 'Post Creation / Publishing',
            description:
                'Design typography carousel, write captions, post at 7 PM peak time.',
            isCompleted: false,
            isCurrent: true,
          ),
        ],
        status: WorkStatus.inProgress,
        priority: 'Medium',
        notes: 'Weekend membership offer post.',
      ),
      AdminSSMWork(
        id: 'WRK-003',
        customerId: 'CUST-003',
        customerName: 'Urban Cafe & Bistro',
        socialAccount: '@urbancafe_mumbai',
        platform: 'Instagram',
        workType: WorkType.shoot,
        team: 'SSM Team A',
        teamMembers: ['Demo User', 'Rahul', 'Sneha'],
        assignedEmployee: 'Rahul',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        durationDays: 3,
        currentDay: 2,
        todayTask: 'Day 2: Shooting main menu signature dishes',
        allTasks: [
          DayTask(
            day: 1,
            title: 'Location / Preparation',
            description: 'Lighting setup, chef alignment, shot list review.',
            isCompleted: true,
          ),
          DayTask(
            day: 2,
            title: 'Shooting',
            description:
                'Signature drinks, plating, ambiance and customer reactions.',
            isCompleted: false,
            isCurrent: true,
          ),
          DayTask(
            day: 3,
            title: 'Remaining Shots / Backup',
            description: 'Drone exterior shots, high-res backup, raw delivery.',
            isCompleted: false,
          ),
        ],
        status: WorkStatus.inProgress,
        priority: 'High',
      ),
      // ── CUSTOMER B (T002) Isolated SSM Work ─────────────────────────────────
      AdminSSMWork(
        id: 'WRK-T2-001',
        customerId: 'T002',
        customerName: 'ABC Fitness',
        socialAccount: '@abcfitness_pune',
        platform: 'Instagram Reels',
        workType: WorkType.reel,
        team: 'Growth Team 1',
        teamMembers: ['Rahul', 'Priya'],
        assignedEmployee: 'Rahul',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        durationDays: 3,
        currentDay: 1,
        todayTask: 'Day 1: Shoot Crossfit training & coach interviews',
        allTasks: [
          DayTask(
            day: 1,
            title: 'Crossfit Shoot',
            description: 'Capture fast-paced workout circuits',
            isCompleted: false,
            isCurrent: true,
          ),
          DayTask(
            day: 2,
            title: 'Editing & Beats Sync',
            description: 'Sync action shots with trending audio',
            isCompleted: false,
          ),
          DayTask(
            day: 3,
            title: 'Final Review & Post',
            description: 'Publish reel to Instagram',
            isCompleted: false,
          ),
        ],
        status: WorkStatus.inProgress,
        priority: 'High',
        notes: 'Customer B crossfit promo reel.',
      ),
      AdminSSMWork(
        id: 'WRK-T2-002',
        customerId: 'T002',
        customerName: 'XYZ Restaurant',
        socialAccount: '@xyz_lounge_mumbai',
        platform: 'Meta Ads',
        workType: WorkType.post,
        team: 'Creative Team Alpha',
        teamMembers: ['Priya'],
        assignedEmployee: 'Priya',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        durationDays: 1,
        currentDay: 1,
        todayTask: 'Day 1: Video Editing & Fine Dine Carousel Ad',
        allTasks: [
          DayTask(
            day: 1,
            title: 'Video Editing',
            description: 'Edit cocktail bar showcase and promo card',
            isCompleted: false,
            isCurrent: true,
          ),
        ],
        status: WorkStatus.inProgress,
        priority: 'Medium',
        notes: 'Customer B fine-dine campaign asset.',
      ),
      AdminSSMWork(
        id: 'WRK-T2-003',
        customerId: 'T002',
        customerName: 'Demo Business',
        socialAccount: '@demobusiness_official',
        platform: 'Instagram',
        workType: WorkType.shoot,
        team: 'Growth Team 1',
        teamMembers: ['Rahul', 'Priya'],
        assignedEmployee: 'Rahul',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        durationDays: 3,
        currentDay: 2,
        todayTask: 'Day 2: Product Showcase Photography & Store Walkthrough',
        allTasks: [
          DayTask(
            day: 1,
            title: 'Store Prep',
            description: 'Setup lighting and catalog',
            isCompleted: true,
          ),
          DayTask(
            day: 2,
            title: 'Product Shoot',
            description: 'Capture retail displays and customer engagement',
            isCompleted: false,
            isCurrent: true,
          ),
          DayTask(
            day: 3,
            title: 'Export & Deliver',
            description: 'Deliver edited reels and posts',
            isCompleted: false,
          ),
        ],
        status: WorkStatus.inProgress,
        priority: 'High',
        notes: 'Customer B demo retail enterprise.',
      ),
    ];

    // Seed work items for separate client businesses
    for (int i = 4; i <= 12; i++) {
      workList.add(
        AdminSSMWork(
          id: 'WRK-00$i',
          customerId: 'CUST-00$i',
          customerName: 'Client Business #$i',
          socialAccount: '@client_$i',
          platform: i % 2 == 0 ? 'Instagram' : 'YouTube Shorts',
          workType: i % 3 == 0
              ? WorkType.shoot
              : (i % 2 == 0 ? WorkType.reel : WorkType.post),
          team: i % 2 == 0 ? 'SSM Team A' : 'SSM Team B',
          teamMembers: i % 2 == 0
              ? ['Demo User', 'Rahul', 'Sneha']
              : ['Amit', 'Priya', 'Neha'],
          assignedEmployee: i % 2 == 0 ? 'Demo User' : 'Amit',
          startDate: DateTime.now().subtract(Duration(days: i % 2)),
          endDate: DateTime.now().add(Duration(days: (i % 3) + 1)),
          durationDays: (i % 3) == 0 ? 3 : ((i % 2) == 0 ? 3 : 1),
          currentDay: 1,
          todayTask: 'Content drafting and asset alignment',
          allTasks: [
            DayTask(
              day: 1,
              title: 'Content Phase 1',
              description: 'Primary deliverables execution',
              isCompleted: false,
              isCurrent: true,
            ),
          ],
          status: WorkStatus.inProgress,
          priority: i % 2 == 0 ? 'High' : 'Medium',
        ),
      );
    }

    final employees = [
      AdminEmployee(
        id: 'EMP-001',
        customerId: 'T001',
        name: 'Demo User',
        role: 'Employee',
        mobile: '+91 98765 00001',
        email: 'demouser@abcdigital.com',
        team: 'SSM Team A',
        status: 'ACTIVE',
        todayWork: 'Care Fitness Gym Reel Shoot (Day 1)',
        activeWorkCount: 5,
        completedWorkCount: 28,
        leadsCount: 6,
        visitsCount: 12,
        dataCaptureCount: 18,
      ),
      AdminEmployee(
        id: 'EMP-002',
        customerId: 'T001',
        name: 'Rahul Sharma',
        role: 'Employee',
        mobile: '+91 98765 00002',
        email: 'rahul@abcdigital.com',
        team: 'SSM Team A',
        status: 'ACTIVE',
        todayWork: 'Urban Cafe Dish Shoot (Day 2)',
        activeWorkCount: 4,
        completedWorkCount: 22,
        leadsCount: 4,
        visitsCount: 8,
        dataCaptureCount: 14,
      ),
      AdminEmployee(
        id: 'EMP-003',
        customerId: 'T001',
        name: 'Sneha Patel',
        role: 'Employee',
        mobile: '+91 98765 00003',
        email: 'sneha@abcdigital.com',
        team: 'SSM Team A',
        status: 'ACTIVE',
        todayWork: 'Reel Post-Production & Color Grade',
        activeWorkCount: 3,
        completedWorkCount: 19,
        leadsCount: 5,
        visitsCount: 6,
        dataCaptureCount: 10,
      ),
      AdminEmployee(
        id: 'EMP-004',
        customerId: 'T001',
        name: 'Amit Verma',
        role: 'Employee',
        mobile: '+91 98765 00004',
        email: 'amit@abcdigital.com',
        team: 'SSM Team B',
        status: 'ACTIVE',
        todayWork: 'IB Gym Creative Post Design',
        activeWorkCount: 4,
        completedWorkCount: 25,
        leadsCount: 3,
        visitsCount: 10,
        dataCaptureCount: 16,
      ),
      AdminEmployee(
        id: 'EMP-005',
        customerId: 'T001',
        name: 'Priya Deshmukh',
        role: 'Employee',
        mobile: '+91 98765 00005',
        email: 'priya@abcdigital.com',
        team: 'SSM Team B',
        status: 'ACTIVE',
        todayWork: 'Luxe Salon Product Story Campaign',
        activeWorkCount: 3,
        completedWorkCount: 17,
        leadsCount: 4,
        visitsCount: 5,
        dataCaptureCount: 12,
      ),
      AdminEmployee(
        id: 'EMP-006',
        customerId: 'T001',
        name: 'Neha Kulkarni',
        role: 'Employee',
        mobile: '+91 98765 00006',
        email: 'neha@abcdigital.com',
        team: 'SSM Team B',
        status: 'ACTIVE',
        todayWork: 'Customer Onboarding & Brief Collection',
        activeWorkCount: 2,
        completedWorkCount: 15,
        leadsCount: 7,
        visitsCount: 9,
        dataCaptureCount: 20,
      ),
      // ── CUSTOMER B (T002) Isolated Employees ─────────────────────────────────
      AdminEmployee(
        id: 'EMP-T2-001',
        customerId: 'T002',
        name: 'Rahul',
        role: 'Lead Content Creator',
        mobile: '+91 98765 22001',
        email: 'rahul@customerb.com',
        team: 'Growth Team 1',
        status: 'ACTIVE',
        todayWork: 'ABC Fitness Reel Shoot & Member Interviews',
        activeWorkCount: 1,
        completedWorkCount: 12,
        leadsCount: 2,
        visitsCount: 4,
        dataCaptureCount: 6,
      ),
      AdminEmployee(
        id: 'EMP-T2-002',
        customerId: 'T002',
        name: 'Priya',
        role: 'Senior Video Editor',
        mobile: '+91 98765 22002',
        email: 'priya@customerb.com',
        team: 'Creative Team Alpha',
        status: 'ACTIVE',
        todayWork: 'XYZ Restaurant Video Editing & Menu Promo',
        activeWorkCount: 1,
        completedWorkCount: 10,
        leadsCount: 1,
        visitsCount: 3,
        dataCaptureCount: 4,
      ),
    ];

    // Seed up to 24 employees total
    for (int i = 7; i <= 22; i++) {
      employees.add(
        AdminEmployee(
          id: 'EMP-${i.toString().padLeft(3, '0')}',
          customerId: 'T001',
          name: 'Staff Member $i',
          role: 'Employee',
          mobile: '+91 98765 ${10000 + i}',
          email: 'employee$i@abcdigital.com',
          team: i % 2 == 0 ? 'SSM Team A' : 'SSM Team B',
          status: 'ACTIVE',
          todayWork: 'Client Field Operations & Work',
          activeWorkCount: 2,
          completedWorkCount: 10 + i,
          leadsCount: 2,
          visitsCount: 3,
          dataCaptureCount: 5,
        ),
      );
    }

    final teams = [
      AdminTeam(
        id: 'TEAM-A',
        customerId: 'T001',
        name: 'SSM Team A',
        teamLeader: 'Demo User',
        members: ['Demo User', 'Rahul', 'Sneha'],
        activeWork: 7,
        completedWork: 48,
        status: 'ACTIVE',
      ),
      AdminTeam(
        id: 'TEAM-B',
        customerId: 'T001',
        name: 'SSM Team B',
        teamLeader: 'Amit Verma',
        members: ['Amit', 'Priya', 'Neha'],
        activeWork: 5,
        completedWork: 36,
        status: 'ACTIVE',
      ),
      // ── CUSTOMER B (T002) Isolated Teams ────────────────────────────────────
      AdminTeam(
        id: 'TEAM-T2-1',
        customerId: 'T002',
        name: 'Growth Team 1',
        teamLeader: 'Rahul',
        members: ['Rahul', 'Priya'],
        activeWork: 1,
        completedWork: 12,
        status: 'ACTIVE',
      ),
      AdminTeam(
        id: 'TEAM-T2-2',
        customerId: 'T002',
        name: 'Creative Team Alpha',
        teamLeader: 'Priya',
        members: ['Priya'],
        activeWork: 1,
        completedWork: 10,
        status: 'ACTIVE',
      ),
    ];

    final leads = [
      AdminLead(
        id: 'LEAD-001',
        customerId: 'CUST-008',
        customerName: 'Gourmet Grills',
        contact: '+91 98200 44556',
        email: 'info@gourmetgrills.in',
        source: 'Instagram Ad',
        assignedEmployee: 'Demo User',
        status: LeadStatus.newLead,
        nextFollowUp: '19 Aug, 3:00 PM',
        priority: 'High',
        notes: 'Looking for full monthly restaurant SSM package.',
      ),
      AdminLead(
        id: 'LEAD-002',
        customerId: 'CUST-006',
        customerName: 'Apex Real Estate',
        contact: '+91 99333 77889',
        email: 'sales@apexrealty.com',
        source: 'Google Search',
        assignedEmployee: 'Amit',
        status: LeadStatus.followUp,
        nextFollowUp: '20 Aug, 11:30 AM',
        priority: 'High',
        notes: 'Follow-up regarding video property walkthrough shoot pricing.',
      ),
      AdminLead(
        id: 'LEAD-003',
        customerId: 'CUST-011',
        customerName: 'Veda Ayurveda Clinic',
        contact: '+91 98111 66554',
        email: 'contact@vedacare.com',
        source: 'Referral',
        assignedEmployee: 'Sneha',
        status: LeadStatus.followUp,
        nextFollowUp: '21 Aug',
        priority: 'Medium',
        notes: 'Reviewing proposal terms.',
      ),
      AdminLead(
        id: 'LEAD-004',
        customerId: 'CUST-010',
        customerName: 'Matrix Tech Solutions',
        contact: '+91 97654 11223',
        email: 'connect@matrixtech.io',
        source: 'Cold Call',
        assignedEmployee: 'Rahul',
        status: LeadStatus.newLead,
        nextFollowUp: '22 Aug',
        priority: 'Medium',
      ),
      AdminLead(
        id: 'LEAD-005',
        customerId: 'CUST-012',
        customerName: 'Sunrise Fashion Hub',
        contact: '+91 98450 99887',
        email: 'contact@sunrisefashion.com',
        source: 'Website Form',
        assignedEmployee: 'Priya',
        status: LeadStatus.followUp,
        nextFollowUp: '23 Aug',
        priority: 'High',
        notes: 'Follow up on shoot package.',
      ),
      // ── CUSTOMER B (T002) Isolated Leads ────────────────────────────────────
      AdminLead(
        id: 'LEAD-T2-001',
        customerId: 'T002',
        customerName: 'ABC Fitness',
        contact: '+91 98900 11223',
        email: 'contact@abcfitness.in',
        source: 'Social Ad',
        assignedEmployee: 'Rahul',
        status: LeadStatus.followUp,
        nextFollowUp: '20 Aug, 11:00 AM',
        priority: 'High',
        notes: 'Follow-up on yearly social marketing package.',
      ),
      AdminLead(
        id: 'LEAD-T2-002',
        customerId: 'T002',
        customerName: 'XYZ Restaurant',
        contact: '+91 98900 44556',
        email: 'manager@xyzrestaurant.com',
        source: 'Referral',
        assignedEmployee: 'Priya',
        status: LeadStatus.newLead,
        nextFollowUp: '21 Aug, 03:00 PM',
        priority: 'High',
        notes: 'Discussion on menu video shoot.',
      ),
    ];

    // Seed up to 18 total open leads
    for (int i = 6; i <= 16; i++) {
      leads.add(
        AdminLead(
          id: 'LEAD-${i.toString().padLeft(3, '0')}',
          customerId: 'LEAD-CUST-$i',
          customerName: 'Prospective Client #$i',
          contact: '+91 98000 ${20000 + i}',
          email: 'lead$i@clientbiz.com',
          source: i % 2 == 0 ? 'Social Media' : 'Referral',
          assignedEmployee: i % 2 == 0 ? 'Demo User' : 'Amit',
          status: i % 2 == 0 ? LeadStatus.newLead : LeadStatus.followUp,
          nextFollowUp: '${18 + (i % 10)} Aug',
          priority: i % 2 == 0 ? 'High' : 'Medium',
        ),
      );
    }

    final visits = [
      AdminVisit(
        id: 'VIS-001',
        customerId: 'T001',
        customerName: 'Care Fitness Gym',
        employeeName: 'Demo User',
        date: 'Today, 20 Aug',
        time: '10:30 AM',
        location: 'Andheri West, Mumbai',
        status: VisitStatus.today,
        notes: 'Equipment shoot & testimonial video capture.',
      ),
      AdminVisit(
        id: 'VIS-002',
        customerId: 'CUST-003',
        customerName: 'Urban Cafe & Bistro',
        employeeName: 'Rahul Sharma',
        date: 'Today, 20 Aug',
        time: '01:00 PM',
        location: 'Bandra West, Mumbai',
        status: VisitStatus.today,
        notes: 'Chef special menu shoot session.',
      ),
      AdminVisit(
        id: 'VIS-003',
        customerId: 'CUST-004',
        customerName: 'Zenith Dental Care',
        employeeName: 'Sneha Patel',
        date: 'Today, 20 Aug',
        time: '03:30 PM',
        location: 'Thane West',
        status: VisitStatus.today,
        notes: 'Clinic tour reel recording.',
      ),
      AdminVisit(
        id: 'VIS-004',
        customerId: 'CUST-002',
        customerName: 'IB Gym',
        employeeName: 'Amit Verma',
        date: 'Today, 20 Aug',
        time: '04:30 PM',
        location: 'FC Road, Pune',
        status: VisitStatus.today,
        notes: 'Review month-end social performance.',
      ),
      AdminVisit(
        id: 'VIS-005',
        customerId: 'CUST-005',
        customerName: 'Luxe Salon & Spa',
        employeeName: 'Priya Deshmukh',
        date: 'Today, 20 Aug',
        time: '05:45 PM',
        location: 'Vashi, Navi Mumbai',
        status: VisitStatus.today,
        notes: 'Product lineup shoot & reel clips.',
      ),
      AdminVisit(
        id: 'VIS-006',
        customerId: 'CUST-006',
        customerName: 'Apex Real Estate',
        employeeName: 'Neha Kulkarni',
        date: 'Today, 20 Aug',
        time: '06:30 PM',
        location: 'Powai, Mumbai',
        status: VisitStatus.today,
        notes: 'Sample flat walkthrough recording.',
      ),
      AdminVisit(
        id: 'VIS-007',
        customerId: 'CUST-008',
        customerName: 'Gourmet Grills',
        employeeName: 'Demo User',
        date: 'Tomorrow, 21 Aug',
        time: '11:00 AM',
        location: 'Juhu, Mumbai',
        status: VisitStatus.upcoming,
      ),
      AdminVisit(
        id: 'VIS-008',
        customerId: 'CUST-009',
        customerName: 'Prime Motors',
        employeeName: 'Amit Verma',
        date: '18 Aug',
        time: '02:00 PM',
        location: 'Koregaon Park, Pune',
        status: VisitStatus.completed,
      ),
      // ── CUSTOMER B (T002) Isolated Visits ───────────────────────────────────
      AdminVisit(
        id: 'VIS-T2-001',
        customerId: 'T002',
        customerName: 'ABC Fitness',
        employeeName: 'Rahul',
        date: 'Tomorrow, 21 Aug',
        time: '11:00 AM',
        location: 'FC Road, Pune',
        status: VisitStatus.upcoming,
        notes: 'Fitness equipment workout video recording.',
      ),
      AdminVisit(
        id: 'VIS-T2-002',
        customerId: 'T002',
        customerName: 'XYZ Restaurant',
        employeeName: 'Priya',
        date: 'Tomorrow, 21 Aug',
        time: '03:00 PM',
        location: 'Bandra, Mumbai',
        status: VisitStatus.upcoming,
        notes: 'Chef special dish video recording.',
      ),
      AdminVisit(
        id: 'VIS-T2-003',
        customerId: 'T002',
        customerName: 'Demo Business',
        employeeName: 'Rahul',
        date: '22 Aug',
        time: '04:00 PM',
        location: 'Kothrud, Pune',
        status: VisitStatus.upcoming,
        notes: 'Store inventory visual audit and footage capture.',
      ),
    ];

    final dataCaptures = [
      AdminDataCapture(
        id: 'CAP-001',
        customerId: 'T001',
        employeeName: 'Demo User',
        customerName: 'Care Fitness Gym',
        captureType: 'Social Media Audit & Credentials',
        date: '18 Aug 2026',
        status: 'VERIFIED',
        capturedData: {
          'Instagram Handle': '@carefitness_official',
          'Follower Count': '14.2k',
          'Target Audience': 'Gym enthusiasts & local fitness seekers',
          'Brand Colors': '#FF5722, #111827',
          'Key Contact': 'Mr. Rohit (Owner)',
        },
        recentActivity: [
          'Audited existing grid and reel engagement',
          'Exported high-res brand logos and font kit',
          'Scheduled weekly shoot cadence',
        ],
      ),
      AdminDataCapture(
        id: 'CAP-002',
        customerId: 'CUST-002',
        employeeName: 'Amit Verma',
        customerName: 'IB Gym',
        captureType: 'Brand Guidelines & Onboarding Form',
        date: '17 Aug 2026',
        status: 'VERIFIED',
        capturedData: {
          'Facebook Page': 'Iron Body Pune',
          'Offers Active': '20% Student Discount',
          'Preferred Platforms': 'Instagram, YouTube Shorts',
        },
        recentActivity: [
          'Collected member workout footage',
          'Verified contact number on Google My Business',
        ],
      ),
      // ── CUSTOMER B (T002) Isolated Data Capture ─────────────────────────────
      AdminDataCapture(
        id: 'CAP-T2-001',
        customerId: 'T002',
        employeeName: 'Rahul',
        customerName: 'ABC Fitness',
        captureType: 'Fitness Profile & Media Kit',
        date: '19 Aug 2026',
        status: 'VERIFIED',
        capturedData: {
          'Instagram Handle': '@abcfitness_pune',
          'Follower Count': '8.5k',
        },
        recentActivity: ['Collected workout equipment shots'],
      ),
    ];

    final proposals = [
      AdminProposal(
        id: 'PROP-001',
        customerId: 'T001',
        customerName: 'Care Fitness Gym',
        businessName: 'Care Fitness & Wellness Hub',
        contact: '+91 98201 12345',
        email: 'info@carefitness.com',
        address: 'Andheri West, Mumbai',
        packageName: 'Growth Plan',
        services: '12 Reels, 8 Posts, 2 Shoot Sessions, Weekly Ad Boosting',
        amount: 35000.0,
        validity: '30 Days',
        status: ProposalStatus.sent,
        notes: 'Includes drone camera shoot in second week.',
        date: '15 Aug 2026',
      ),
      AdminProposal(
        id: 'PROP-002',
        customerId: 'CUST-008',
        customerName: 'Gourmet Grills',
        businessName: 'Gourmet Hospitality LLP',
        contact: '+91 98200 44556',
        email: 'info@gourmetgrills.in',
        address: 'Juhu, Mumbai',
        packageName: 'Premium Plan',
        services:
            '20 Reels, 15 Posts, 4 Dedicated Shoot Days, Influencer Collabs',
        amount: 60000.0,
        validity: '15 Days',
        status: ProposalStatus.draft,
        notes: 'Waiting for menu finalization.',
        date: '17 Aug 2026',
      ),
      AdminProposal(
        id: 'PROP-003',
        customerId: 'CUST-002',
        customerName: 'IB Gym',
        businessName: 'Iron Body Fitness Center',
        contact: '+91 99302 98765',
        email: 'contact@ibgym.com',
        address: 'FC Road, Pune',
        packageName: 'Starter Plan',
        services: '6 Reels, 6 Posts, 1 Shoot Day',
        amount: 20000.0,
        validity: '30 Days',
        status: ProposalStatus.sent,
        date: '10 Aug 2026',
      ),
      AdminProposal(
        id: 'PROP-004',
        customerId: 'CUST-010',
        customerName: 'Matrix Tech Solutions',
        businessName: 'Matrix Tech Solutions Inc',
        contact: '+91 97654 11223',
        email: 'connect@matrixtech.io',
        address: 'BKC, Mumbai',
        packageName: 'Growth Plan',
        services: 'Corporate Video Shoot & LinkedIn Branding',
        amount: 45000.0,
        validity: '15 Days',
        status: ProposalStatus.draft,
        date: '01 Jul 2026',
      ),
      // ── CUSTOMER B (T002) Isolated Proposals ────────────────────────────────
      AdminProposal(
        id: 'PROP-T2-001',
        customerId: 'T002',
        customerName: 'ABC Fitness',
        businessName: 'ABC Fitness & Health Club',
        contact: '+91 98900 11223',
        email: 'contact@abcfitness.in',
        address: 'FC Road, Pune',
        packageName: 'Growth Plan',
        services: '12 Reels, 8 Posts, 2 Shoot Days',
        amount: 32000.0,
        validity: '30 Days',
        status: ProposalStatus.accepted,
        notes: 'Crossfit promo package.',
        date: '18 Aug 2026',
      ),
    ];

    final packages = [
      AdminPackage(
        id: 'PKG-001',
        name: 'Starter',
        description:
            'Ideal for small businesses starting their digital marketing journey.',
        price: 15000.0,
        duration: '1 Month',
        services: [
          '6 High-Quality Reels',
          '8 Graphic Posts & Stories',
          '1 Half-Day Shoot Session',
          'Monthly Performance Report',
        ],
        status: 'ACTIVE',
      ),
      AdminPackage(
        id: 'PKG-002',
        name: 'Growth',
        description:
            'Accelerate brand visibility with viral reels and high engagement campaigns.',
        price: 35000.0,
        duration: '1 Month',
        services: [
          '12 High-Quality Reels',
          '12 Graphic Posts & Stories',
          '2 Full-Day Shoot Sessions',
          'Meta Ads Management & Optimization',
          'Weekly Analytics & Bi-Weekly Revisions',
        ],
        status: 'ACTIVE',
      ),
      AdminPackage(
        id: 'PKG-003',
        name: 'Premium',
        description:
            'Full-service end-to-end creative production, shoots, and omnichannel growth.',
        price: 65000.0,
        duration: '1 Month',
        services: [
          '24 High-Definition Cinematic Reels',
          '20 Graphic Posts & Carousels',
          '4 Dedicated Shoot Days with Drone',
          'Dedicated SSM Team Leader & Priority Revisions',
          'Influencer Collaboration Coordination',
          '24/7 Account Management',
        ],
        status: 'ACTIVE',
      ),
    ];

    final auditLogs = [
      AdminAuditLog(
        id: 'AUD-001',
        action: 'Customer Created',
        user: 'Admin',
        role: 'Company Admin',
        module: 'Clients',
        date: '18 Aug 2026',
        time: '09:15 AM',
        description:
            'Created new customer Care Fitness Gym with SSM Team A assigned.',
      ),
      AdminAuditLog(
        id: 'AUD-002',
        action: 'SSM Work Created',
        user: 'Admin',
        role: 'Company Admin',
        module: 'Work',
        date: '18 Aug 2026',
        time: '09:30 AM',
        description:
            'Scheduled Reel Shoot (3 Days) for Care Fitness Gym assigned to Demo User.',
      ),
      AdminAuditLog(
        id: 'AUD-003',
        action: 'SSM Work Started',
        user: 'Demo User',
        role: 'Employee',
        module: 'Work',
        date: '18 Aug 2026',
        time: '10:00 AM',
        description: 'Started Day 1 Content Shoot task at Care Fitness Gym.',
      ),
      AdminAuditLog(
        id: 'AUD-004',
        action: 'Proposal Created',
        user: 'Admin',
        role: 'Company Admin',
        module: 'Proposals',
        date: '18 Aug 2026',
        time: '11:00 AM',
        description:
            'Generated Proposal PROP-001 (Growth Plan ${AppCurrency.format(35000)}) for Care Fitness Gym.',
      ),
      AdminAuditLog(
        id: 'AUD-005',
        action: 'Visit Created',
        user: 'Admin',
        role: 'Company Admin',
        module: 'Visits',
        date: '18 Aug 2026',
        time: '11:45 AM',
        description:
            'Scheduled today visit with Urban Cafe & Bistro for Rahul Sharma.',
      ),
      AdminAuditLog(
        id: 'AUD-006',
        action: 'Lead Converted',
        user: 'Sneha Patel',
        role: 'Employee',
        module: 'Leads',
        date: '17 Aug 2026',
        time: '04:20 PM',
        description: 'Converted Lead Veda Ayurveda Clinic to active client.',
      ),
      AdminAuditLog(
        id: 'AUD-007',
        action: 'Data Captured',
        user: 'Demo User',
        role: 'Employee',
        module: 'Data Capture',
        date: '17 Aug 2026',
        time: '05:10 PM',
        description:
            'Submitted verified social credentials and audience demographics.',
      ),
      AdminAuditLog(
        id: 'AUD-008',
        action: 'Task Completed',
        user: 'Rahul Sharma',
        role: 'Employee',
        module: 'Work',
        date: '17 Aug 2026',
        time: '06:00 PM',
        description: 'Completed Day 1 Preparation for Urban Cafe Shoot.',
      ),
    ];

    final liveAttendanceList = [
      // ── Customer A (T001) Live Workforce ──────────────────────────────
      const AdminLiveAttendance(
        id: 'ATT-001',
        customerId: 'T001',
        employeeId: 'EMP-001',
        employeeName: 'Demo User',
        role: 'Creative Lead',
        team: 'SSM Team A',
        status: LiveAttendanceStatus.working,
        punchInTime: '09:00 AM',
        totalWorkingHours: '5h 45m',
        location: 'BKC Media Office (Geo-verified)',
      ),
      const AdminLiveAttendance(
        id: 'ATT-002',
        customerId: 'T001',
        employeeId: 'EMP-002',
        employeeName: 'Rahul Sharma',
        role: 'Cinematographer',
        team: 'SSM Team A',
        status: LiveAttendanceStatus.onBreak,
        punchInTime: '09:15 AM',
        breakStartTime: '01:30 PM',
        breakDuration: '25m',
        totalWorkingHours: '4h 15m',
        location: 'Urban Cafe Location (On Site)',
      ),
      const AdminLiveAttendance(
        id: 'ATT-003',
        customerId: 'T001',
        employeeId: 'EMP-003',
        employeeName: 'Sneha Patel',
        role: 'Video Editor',
        team: 'SSM Team A',
        status: LiveAttendanceStatus.working,
        punchInTime: '08:55 AM',
        totalWorkingHours: '5h 50m',
        location: 'Head Office Studio',
      ),
      const AdminLiveAttendance(
        id: 'ATT-004',
        customerId: 'T001',
        employeeId: 'EMP-004',
        employeeName: 'Amit Verma',
        role: 'Senior Graphic Designer',
        team: 'SSM Team B',
        status: LiveAttendanceStatus.working,
        punchInTime: '09:30 AM',
        totalWorkingHours: '5h 15m',
        location: 'Head Office Studio',
      ),
      const AdminLiveAttendance(
        id: 'ATT-005',
        customerId: 'T001',
        employeeId: 'EMP-005',
        employeeName: 'Priya Deshmukh',
        role: 'Social Media Manager',
        team: 'SSM Team B',
        status: LiveAttendanceStatus.onLeave,
        leaveType: 'Casual Leave',
        leaveReason: 'Family Function (Approved)',
        location: 'Home',
      ),
      const AdminLiveAttendance(
        id: 'ATT-006',
        customerId: 'T001',
        employeeId: 'EMP-006',
        employeeName: 'Neha Kulkarni',
        role: 'Client Relationship Exec',
        team: 'SSM Team B',
        status: LiveAttendanceStatus.working,
        punchInTime: '09:05 AM',
        totalWorkingHours: '5h 40m',
        location: 'Client On-Site (Andheri)',
      ),
      const AdminLiveAttendance(
        id: 'ATT-007',
        customerId: 'T001',
        employeeId: 'EMP-007',
        employeeName: 'Staff Member 7',
        role: 'Content Executive',
        team: 'SSM Team A',
        status: LiveAttendanceStatus.absent,
        location: 'Not Logged In',
      ),

      // ── Customer B (T002) Live Workforce ──────────────────────────────
      const AdminLiveAttendance(
        id: 'ATT-T2-001',
        customerId: 'T002',
        employeeId: 'EMP-T2-001',
        employeeName: 'Rahul',
        role: 'Lead Content Creator',
        team: 'Growth Team 1',
        status: LiveAttendanceStatus.working,
        punchInTime: '09:10 AM',
        totalWorkingHours: '5h 35m',
        location: 'FC Road Studio, Pune',
      ),
      const AdminLiveAttendance(
        id: 'ATT-T2-002',
        customerId: 'T002',
        employeeId: 'EMP-T2-002',
        employeeName: 'Priya',
        role: 'Senior Video Editor',
        team: 'Creative Team Alpha',
        status: LiveAttendanceStatus.onBreak,
        punchInTime: '09:40 AM',
        breakStartTime: '01:45 PM',
        breakDuration: '20m',
        totalWorkingHours: '4h 05m',
        location: 'FC Road Studio, Pune',
      ),
    ];

    return CompanyAdminState(
      profile: profile,
      customers: customers,
      workList: workList,
      employees: employees,
      teams: teams,
      leads: leads,
      visits: visits,
      dataCaptures: dataCaptures,
      proposals: proposals,
      packages: packages,
      auditLogs: auditLogs,
      liveAttendanceList: liveAttendanceList,
    );
  }

  // ── State Mutation Methods ─────────────────────────────────────────────────

  void addCustomer(AdminCustomer customer) {
    state = state.copyWith(
      customers: [customer, ...state.customers],
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Customer Created',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Clients',
          date: 'Today',
          time: _formattedCurrentTime(),
          description:
              'Added client "${customer.name}" in ${customer.city}, assigned to ${customer.assignedEmployee} (${customer.assignedTeam}).',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void addWork(AdminSSMWork work) {
    state = state.copyWith(
      workList: [work, ...state.workList],
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'SSM Work Created',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Work',
          date: 'Today',
          time: _formattedCurrentTime(),
          description:
              'Scheduled ${work.workType.label} (${work.durationDays} Days) for ${work.customerName} on ${work.platform}.',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void addLead(AdminLead lead) {
    state = state.copyWith(
      leads: [lead, ...state.leads],
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Lead Created',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Leads',
          date: 'Today',
          time: _formattedCurrentTime(),
          description:
              'Created lead "${lead.customerName}" via ${lead.source} assigned to ${lead.assignedEmployee}.',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void updateLeadStatus(String leadId, LeadStatus newStatus) {
    final updated = state.leads.map((l) {
      if (l.id == leadId) {
        return AdminLead(
          id: l.id,
          customerName: l.customerName,
          contact: l.contact,
          email: l.email,
          source: l.source,
          assignedEmployee: l.assignedEmployee,
          status: newStatus,
          nextFollowUp: newStatus == LeadStatus.converted
              ? 'Converted'
              : l.nextFollowUp,
          priority: l.priority,
          notes: l.notes,
        );
      }
      return l;
    }).toList();

    state = state.copyWith(
      leads: updated,
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: newStatus == LeadStatus.converted
              ? 'Lead Converted'
              : 'Lead Updated',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Leads',
          date: 'Today',
          time: _formattedCurrentTime(),
          description: 'Updated lead $leadId status to ${newStatus.label}.',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void addVisit(AdminVisit visit) {
    state = state.copyWith(
      visits: [visit, ...state.visits],
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Visit Created',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Visits',
          date: 'Today',
          time: _formattedCurrentTime(),
          description:
              'Scheduled visit to ${visit.customerName} for ${visit.employeeName} at ${visit.time}.',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void addProposal(AdminProposal proposal) {
    state = state.copyWith(
      proposals: [proposal, ...state.proposals],
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Proposal Created',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Proposals',
          date: 'Today',
          time: _formattedCurrentTime(),
          description:
              'Generated Proposal ${proposal.id} for ${proposal.customerName} (${AppCurrency.format(proposal.amount)}).',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void addPackage(AdminPackage pkg) {
    state = state.copyWith(
      packages: [pkg, ...state.packages],
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Package Created',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Packages',
          date: 'Today',
          time: _formattedCurrentTime(),
          description:
              'Created new package "${pkg.name}" priced at ${AppCurrency.format(pkg.price)}.',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void updateProfile(AdminCompanyProfile updatedProfile) {
    state = state.copyWith(
      profile: updatedProfile,
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Company Profile Updated',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Company Profile',
          date: 'Today',
          time: _formattedCurrentTime(),
          description: 'Company information and contact credentials updated.',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void addCustomerActivity(CustomerCalendarActivity activity) {
    state = state.copyWith(
      customCalendarActivities: [activity, ...state.customCalendarActivities],
      auditLogs: [
        AdminAuditLog(
          id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Activity Scheduled',
          user: 'Admin',
          role: 'Company Admin',
          module: 'Customer Calendar',
          date: 'Today',
          time: _formattedCurrentTime(),
          description:
              'Scheduled ${activity.activityType.label} for "${activity.customerName}" on ${activity.time}.',
        ),
        ...state.auditLogs,
      ],
    );
  }

  void addCustomCalendarActivity(CustomerCalendarActivity activity) {
    addCustomerActivity(activity);
  }

  void updateCustomCalendarActivity(CustomerCalendarActivity activity) {
    final updated = state.customCalendarActivities.map((a) {
      if (a.id == activity.id) return activity;
      return a;
    }).toList();
    state = state.copyWith(customCalendarActivities: updated);
  }

  static String _formattedCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

final companyAdminProvider =
    NotifierProvider<CompanyAdminNotifier, CompanyAdminState>(
      CompanyAdminNotifier.new,
    );
