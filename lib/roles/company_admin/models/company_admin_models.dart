import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

enum TaskCategory {
  reelShoot(
    'Reel Shoot',
    'REEL_SHOOT',
    Color(0xFFF97316), // Orange
    Color(0xFFFFEDD5),
    Remix.video_line,
  ),
  reelEdit(
    'Reel Edit',
    'REEL_EDIT',
    Color(0xFF2563EB), // Blue
    Color(0xFFDBEAFE),
    Remix.film_line,
  ),
  reelPost(
    'Reel Post',
    'REEL_POST',
    Color(0xFF16A34A), // Green
    Color(0xFFDCFCE7),
    Remix.upload_cloud_2_line,
  ),
  storyDesign(
    'Story Design',
    'STORY_DESIGN',
    Color(0xFF9333EA), // Purple
    Color(0xFFF3E8FF),
    Remix.smartphone_line,
  ),
  storyPost(
    'Story Post',
    'STORY_POST',
    Color(0xFFEC4899), // Pink
    Color(0xFFFCE7F3),
    Remix.send_plane_line,
  ),
  postDesign(
    'Post Design',
    'POST_DESIGN',
    Color(0xFF0D9488), // Teal
    Color(0xFFCCFBF1),
    Remix.image_line,
  ),
  postPublish(
    'Post Publish',
    'POST_PUBLISH',
    Color(0xFF059669), // Emerald
    Color(0xFFD1FAE5),
    Remix.share_forward_line,
  ),
  influencerPromotion(
    'Influencer Promo',
    'INFLUENCER_PROMOTION',
    Color(0xFFEA580C), // Dark Orange
    Color(0xFFFFEDD5),
    Remix.user_star_line,
  ),
  adsManagement(
    'Ads Campaign',
    'ADS_MANAGEMENT',
    Color(0xFF4F46E5), // Indigo
    Color(0xFFE0E7FF),
    Remix.advertisement_line,
  ),
  videoShoot(
    'Video Shoot',
    'VIDEO_SHOOT',
    Color(0xFF0891B2), // Cyan
    Color(0xFFCFFAFE),
    Remix.camera_3_line,
  ),
  videoEditing(
    'Video Editing',
    'VIDEO_EDITING',
    Color(0xFF2563EB), // Blue
    Color(0xFFDBEAFE),
    Remix.film_line,
  ),
  unknown(
    'Scheduled Task',
    'UNKNOWN',
    Color(0xFF64748B), // Slate
    Color(0xFFF1F5F9),
    Remix.calendar_event_line,
  );

  final String label;
  final String key;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const TaskCategory(this.label, this.key, this.color, this.bgColor, this.icon);
}

TaskCategory resolveTaskCategory(
  dynamic activityOrType, {
  String? title,
  String? serviceName,
  String? productName,
  String? type,
  String? status,
}) {
  String rawType = '';
  String rawTitle = '';
  String rawService = '';
  String rawProduct = '';
  String rawStatus = '';

  if (activityOrType is CustomerCalendarActivity) {
    rawType = activityOrType.type;
    rawTitle = activityOrType.title ?? activityOrType.notes ?? '';
    rawService = activityOrType.serviceName ?? '';
    rawProduct = activityOrType.productName ?? activityOrType.planName ?? '';
    rawStatus = activityOrType.status;
  } else if (activityOrType is TaskCategory) {
    return activityOrType;
  } else if (activityOrType is CustomerActivityType) {
    switch (activityOrType) {
      case CustomerActivityType.reelShoot:
        return TaskCategory.reelShoot;
      case CustomerActivityType.videoShoot:
      case CustomerActivityType.photoShoot:
        return TaskCategory.videoShoot;
      case CustomerActivityType.videoEditing:
        return TaskCategory.reelEdit;
      case CustomerActivityType.postDesign:
      case CustomerActivityType.postCampaign:
        return TaskCategory.postDesign;
      case CustomerActivityType.posting:
        return TaskCategory.postPublish;
      case CustomerActivityType.storyDesign:
        return TaskCategory.storyDesign;
      default:
        rawType = activityOrType.label;
    }
  } else if (activityOrType != null) {
    rawType = activityOrType.toString();
  }

  if (type != null && type.isNotEmpty) rawType = type;
  if (title != null && title.isNotEmpty) rawTitle = title;
  if (serviceName != null && serviceName.isNotEmpty) rawService = serviceName;
  if (productName != null && productName.isNotEmpty) rawProduct = productName;
  if (status != null && status.isNotEmpty) rawStatus = status;

  final normType = rawType
      .trim()
      .toUpperCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
  final titleLower = rawTitle.toLowerCase();
  final serviceLower = rawService.toLowerCase();
  final productLower = rawProduct.toLowerCase();
  final statusLower = rawStatus.toLowerCase();
  final combinedText =
      '$titleLower $serviceLower $productLower $statusLower $normType'
          .toLowerCase();

  // 1. Reel Multi-stage Workflow
  if (normType == 'REEL_POST' ||
      (combinedText.contains('reel') &&
          (combinedText.contains('post') ||
              combinedText.contains('publish')))) {
    return TaskCategory.reelPost;
  }
  if (normType == 'REEL_EDIT' ||
      normType == 'VIDEO_EDITING' ||
      normType == 'EDIT' ||
      normType == 'EDITING' ||
      combinedText.contains('edit') ||
      combinedText.contains('editing')) {
    return TaskCategory.reelEdit;
  }
  if (normType == 'REEL_SHOOT' ||
      normType == 'REEL' ||
      combinedText.contains('reel')) {
    return TaskCategory.reelShoot;
  }

  // 2. Story Multi-stage Workflow
  if (normType == 'STORY_POST' ||
      (combinedText.contains('story') &&
          (combinedText.contains('post') ||
              combinedText.contains('publish') ||
              combinedText.contains('upload')))) {
    return TaskCategory.storyPost;
  }
  if (normType == 'STORY_DESIGN' || combinedText.contains('story')) {
    return TaskCategory.storyDesign;
  }

  // 3. Creative Post Multi-stage Workflow
  if (normType == 'POST_PUBLISH' ||
      normType == 'UPLOADING' ||
      ((combinedText.contains('post') || combinedText.contains('creative')) &&
          (combinedText.contains('publish') ||
              combinedText.contains('upload')))) {
    return TaskCategory.postPublish;
  }
  if (normType == 'POST_DESIGN' ||
      combinedText.contains('post') ||
      combinedText.contains('creative') ||
      combinedText.contains('design') ||
      combinedText.contains('graphic')) {
    return TaskCategory.postDesign;
  }

  // 4. Influencer & Campaigns
  if (normType == 'INFLUENCER_PROMOTION' ||
      normType == 'INFLUENCER_PROMO' ||
      combinedText.contains('influencer')) {
    return TaskCategory.influencerPromotion;
  }
  if (normType == 'ADS_MANAGEMENT' ||
      normType == 'META_ADS' ||
      normType == 'GOOGLE_ADS' ||
      combinedText.contains('ads') ||
      combinedText.contains('campaign')) {
    return TaskCategory.adsManagement;
  }
  if (normType == 'VIDEO_SHOOT' ||
      normType == 'PHOTOGRAPHY' ||
      normType == 'PHOTO_SHOOT' ||
      normType == 'PHOTO' ||
      combinedText.contains('video') ||
      combinedText.contains('shoot') ||
      combinedText.contains('photo') ||
      combinedText.contains('photography')) {
    return TaskCategory.videoShoot;
  }

  return TaskCategory.unknown;
}

Color resolveTaskColor(
  dynamic activityOrType, {
  String? title,
  String? serviceName,
  String? productName,
  String? type,
  String? status,
}) {
  return resolveTaskCategory(
    activityOrType,
    title: title,
    serviceName: serviceName,
    productName: productName,
    type: type,
    status: status,
  ).color;
}

Color resolveTaskBgColor(
  dynamic activityOrType, {
  String? title,
  String? serviceName,
  String? productName,
  String? type,
  String? status,
}) {
  return resolveTaskCategory(
    activityOrType,
    title: title,
    serviceName: serviceName,
    productName: productName,
    type: type,
    status: status,
  ).bgColor;
}

/// Visually distinct, accessible color palette for deterministic customer color assignment.
const List<Color> kCustomerColorPalette = [
  Color(0xFF2563EB), // Blue
  Color(0xFF7C3AED), // Purple
  Color(0xFF059669), // Emerald Green
  Color(0xFFD97706), // Amber / Warm Orange
  Color(0xFFDC2626), // Crimson Red
  Color(0xFF0891B2), // Cyan / Teal
  Color(0xFFDB2777), // Pink / Rose
  Color(0xFF4F46E5), // Indigo
  Color(0xFF0D9488), // Teal Green
  Color(0xFFEA580C), // Deep Orange
  Color(0xFF9333EA), // Violet
  Color(0xFF0284C7), // Sky Blue
  Color(0xFF16A34A), // Forest Green
  Color(0xFFC026D3), // Fuchsia
  Color(0xFFCA8A04), // Dark Gold
  Color(0xFF475569), // Slate
];

/// Deterministically resolves a stable, distinct Color for any customer
/// using a stable customer identifier (customerId or customer name).
Color resolveCustomerColor(dynamic activityOrCustomerId, [String? customerName]) {
  String rawKey = '';
  if (activityOrCustomerId is CustomerCalendarActivity) {
    if (activityOrCustomerId.customerId.trim().isNotEmpty && activityOrCustomerId.customerId.trim() != '0') {
      rawKey = activityOrCustomerId.customerId.trim();
    } else {
      rawKey = activityOrCustomerId.businessName.trim().isNotEmpty
          ? activityOrCustomerId.businessName.trim().toLowerCase()
          : activityOrCustomerId.customerName.trim().toLowerCase();
    }
  } else if (activityOrCustomerId != null) {
    final str = activityOrCustomerId.toString().trim();
    if (str.isNotEmpty && str != '0') {
      rawKey = str;
    } else if (customerName != null && customerName.trim().isNotEmpty) {
      rawKey = customerName.trim().toLowerCase();
    }
  }
  if (rawKey.isEmpty) {
    rawKey = (customerName != null && customerName.trim().isNotEmpty)
        ? customerName.trim().toLowerCase()
        : 'default_customer';
  }

  int hash = 0;
  for (int i = 0; i < rawKey.length; i++) {
    hash = (hash * 31 + rawKey.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return kCustomerColorPalette[hash % kCustomerColorPalette.length];
}

class TaskTypeColorResolver {
  static const Color reelShootColor = Color(0xFFF97316); // Orange
  static const Color reelShootBgColor = Color(0xFFFFEDD5);

  static const Color videoShootColor = Color(0xFFF97316); // Orange
  static const Color videoShootBgColor = Color(0xFFFFEDD5);

  static const Color videoEditingColor = Color(0xFF2563EB); // Blue
  static const Color videoEditingBgColor = Color(0xFFDBEAFE);

  static const Color reelPostColor = Color(0xFF16A34A); // Green
  static const Color reelPostBgColor = Color(0xFFDCFCE7);

  static const Color postDesignColor = Color(0xFF0D9488); // Teal
  static const Color postDesignBgColor = Color(0xFFCCFBF1);

  static const Color storyDesignColor = Color(0xFF9333EA); // Purple
  static const Color storyDesignBgColor = Color(0xFFF3E8FF);

  static const Color storyPostColor = Color(0xFFEC4899); // Pink
  static const Color storyPostBgColor = Color(0xFFFCE7F3);

  static const Color influencerPromoColor = Color(0xFFEA580C); // Dark Orange
  static const Color influencerPromoBgColor = Color(0xFFFFEDD5);

  static const Color fallbackColor = Color(0xFF64748B);
  static const Color fallbackBgColor = Color(0xFFF1F5F9);

  static TaskCategory resolveCategory(
    dynamic activityOrType, {
    String? id,
    String? title,
    String? serviceName,
    String? productName,
    String? type,
    String? status,
  }) {
    return resolveTaskCategory(
      activityOrType,
      title: title,
      serviceName: serviceName,
      productName: productName,
      type: type,
      status: status,
    );
  }

  static Color getColor(
    dynamic activityOrType, {
    String? id,
    String? title,
    String? serviceName,
    String? productName,
    String? type,
    String? status,
  }) {
    return resolveTaskColor(
      activityOrType,
      title: title,
      serviceName: serviceName,
      productName: productName,
      type: type,
      status: status,
    );
  }

  static Color getBgColor(
    dynamic activityOrType, {
    String? id,
    String? title,
    String? serviceName,
    String? productName,
    String? type,
    String? status,
  }) {
    return resolveTaskBgColor(
      activityOrType,
      title: title,
      serviceName: serviceName,
      productName: productName,
      type: type,
      status: status,
    );
  }

  static Color resolveColor(
    dynamic rawType, {
    String? id,
    String? title,
    String? serviceName,
    String? productName,
  }) {
    return resolveTaskColor(
      rawType,
      title: title,
      serviceName: serviceName,
      productName: productName,
    );
  }

  static Color resolveBgColor(
    dynamic rawType, {
    String? id,
    String? title,
    String? serviceName,
    String? productName,
  }) {
    return resolveTaskBgColor(
      rawType,
      title: title,
      serviceName: serviceName,
      productName: productName,
    );
  }

  static String? normalizeType(dynamic rawType) {
    if (rawType == null) return null;
    if (rawType is CustomerCalendarActivity) {
      return normalizeType(
        rawType.type.isNotEmpty ? rawType.type : rawType.activityType,
      );
    }
    final category = resolveTaskCategory(rawType);
    return category.key;
  }
}

Color getScheduleColor(dynamic activityType, {String? id, String? title}) {
  return resolveTaskColor(activityType, title: title);
}

Color getScheduleBgColor(dynamic activityType, {String? id, String? title}) {
  return resolveTaskBgColor(activityType, title: title);
}

enum CustomerActivityType {
  reelShoot(
    'Reel Shoot',
    Remix.video_line,
    TaskTypeColorResolver.reelShootColor,
    TaskTypeColorResolver.reelShootBgColor,
  ),
  videoShoot(
    'Video Shoot',
    Remix.camera_3_line,
    TaskTypeColorResolver.videoShootColor,
    TaskTypeColorResolver.videoShootBgColor,
  ),
  videoEditing(
    'Video Editing',
    Remix.film_line,
    TaskTypeColorResolver.videoEditingColor,
    TaskTypeColorResolver.videoEditingBgColor,
  ),
  postDesign(
    'Post Design',
    Remix.image_line,
    TaskTypeColorResolver.postDesignColor,
    TaskTypeColorResolver.postDesignBgColor,
  ),
  postCampaign(
    'Post Design',
    Remix.image_line,
    TaskTypeColorResolver.postDesignColor,
    TaskTypeColorResolver.postDesignBgColor,
  ),
  storyDesign(
    'Story Design',
    Remix.smartphone_line,
    TaskTypeColorResolver.storyDesignColor,
    TaskTypeColorResolver.storyDesignBgColor,
  ),
  posting(
    'Post Design',
    Remix.send_plane_line,
    TaskTypeColorResolver.postDesignColor,
    TaskTypeColorResolver.postDesignBgColor,
  ),
  photoShoot(
    'Video Shoot',
    Remix.camera_3_line,
    TaskTypeColorResolver.videoShootColor,
    TaskTypeColorResolver.videoShootBgColor,
  ),
  followUp('Follow-up', Remix.phone_line, Color(0xFFD97706), Color(0xFFFEF3C7)),
  customerVisit(
    'Customer Visit',
    Remix.map_pin_2_line,
    Color(0xFFD97706),
    Color(0xFFFEF3C7),
  ),
  proposalMeeting(
    'Meeting',
    Remix.calendar_check_line,
    Color(0xFFDB2777),
    Color(0xFFFCE7F3),
  ),
  dataCapture(
    'Data Capture',
    Remix.scan_2_line,
    Color(0xFF64748B),
    Color(0xFFF1F5F9),
  ),
  task('Task', Remix.task_line, Color(0xFF64748B), Color(0xFFF1F5F9)),
  other(
    'Scheduled Activity',
    Remix.calendar_event_line,
    Color(0xFF64748B),
    Color(0xFFF1F5F9),
  );

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const CustomerActivityType(this.label, this.icon, this.color, this.bgColor);
}

class CustomerCalendarActivity {
  final String id;
  final String customerId;
  final String customerName;
  final String businessName;
  final CustomerActivityType activityType;
  final String type;
  final DateTime date;
  final String? scheduledDate;
  final DateTime? scheduleDate;
  final String time;
  final String? startTime;
  final String? endTime;
  final String assignedEmployee;
  final String? assignedToId;
  final String? editorId;
  final String? editorName;
  final String? team;
  final String? teamId;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final String? notes;
  final String? relatedWorkId;
  final String? planName;
  final String? purchaseId;
  final String? productName;
  final String? serviceName;
  final String? title;
  final bool isLocked;
  final String? outputUrl;
  final String? feedback;
  final int revisionCount;
  final bool canReschedule;
  final bool canRequestRework;
  final String? reworkActionLabel;
  final String? location;
  final bool isCarriedForward;
  final String? originalScheduledDate;
  final String? carryForwardNote;
  final String? wonByName;

  const CustomerCalendarActivity({
    required this.id,
    this.customerId = '',
    required this.customerName,
    required this.businessName,
    required this.activityType,
    this.type = '',
    required this.date,
    this.scheduledDate,
    this.scheduleDate,
    required this.time,
    this.startTime,
    this.endTime,
    required this.assignedEmployee,
    this.assignedToId,
    this.editorId,
    this.editorName,
    this.team,
    this.teamId,
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
    this.notes,
    this.relatedWorkId,
    this.planName,
    this.purchaseId,
    this.productName,
    this.serviceName,
    this.title,
    this.isLocked = false,
    this.outputUrl,
    this.feedback,
    this.revisionCount = 0,
    this.canReschedule = true,
    this.canRequestRework = false,
    this.reworkActionLabel,
    this.location,
    this.isCarriedForward = false,
    this.originalScheduledDate,
    this.carryForwardNote,
    this.wonByName,
  });

  String get scheduledTime => time;
  String get assignedToName => assignedEmployee;
  String? get assignedTeam => team;

  String? get originalScheduledDateDisplay {
    if (carryForwardNote != null && carryForwardNote!.trim().isNotEmpty) {
      final raw = carryForwardNote!.trim();
      if (raw.toLowerCase().startsWith('originally scheduled:')) {
        return raw.substring(21).trim();
      }
      return raw;
    }
    if (originalScheduledDate != null && originalScheduledDate!.trim().isNotEmpty) {
      return originalScheduledDate!.trim();
    }
    final n = notes ?? '';
    final match = RegExp(r'Originally scheduled:\s*([^\n\r]+)', caseSensitive: false).firstMatch(n);
    if (match != null) {
      return match.group(1)?.trim();
    }
    final tagMatch = RegExp(r'\[ORIGINAL_SCHEDULE:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\]').firstMatch(n);
    if (tagMatch != null) {
      return tagMatch.group(1)?.trim();
    }
    return null;
  }

  String get scheduledDateStr {
    if (scheduledDate != null && scheduledDate!.trim().isNotEmpty) {
      final s = scheduledDate!.trim();
      return s.contains('T') ? s.split('T')[0] : s.split(' ')[0];
    }
    return normalizeDate(date);
  }

  bool get isValidCustomerFacingSchedule {
    final t = (title ?? '').toLowerCase();
    final n = (notes ?? '').toLowerCase();
    final ty = type.toLowerCase();
    if (t.contains('installment payment') ||
        t.contains('advance payment reminder')) {
      return false;
    }
    if (n.contains('payment installment') ||
        n.contains('advance payment reminder')) {
      return false;
    }
    if (ty == 'payment_reminder' || ty == 'installment_reminder') {
      return false;
    }
    return true;
  }

  CustomerCalendarActivity copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? businessName,
    CustomerActivityType? activityType,
    String? type,
    DateTime? date,
    String? scheduledDate,
    DateTime? scheduleDate,
    String? time,
    String? startTime,
    String? endTime,
    String? assignedEmployee,
    String? assignedToId,
    String? editorId,
    String? editorName,
    String? team,
    String? teamId,
    String? status,
    Color? statusColor,
    Color? statusBgColor,
    String? notes,
    String? relatedWorkId,
    String? planName,
    String? purchaseId,
    String? productName,
    String? serviceName,
    String? title,
    bool? isLocked,
    String? outputUrl,
    String? feedback,
    int? revisionCount,
    bool? canReschedule,
    bool? canRequestRework,
    String? reworkActionLabel,
    String? location,
    bool? isCarriedForward,
    String? originalScheduledDate,
    String? carryForwardNote,
    String? wonByName,
  }) {
    return CustomerCalendarActivity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      businessName: businessName ?? this.businessName,
      activityType: activityType ?? this.activityType,
      type: type ?? this.type,
      date: date ?? this.date,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      time: time ?? this.time,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      assignedToId: assignedToId ?? this.assignedToId,
      editorId: editorId ?? this.editorId,
      editorName: editorName ?? this.editorName,
      team: team ?? this.team,
      teamId: teamId ?? this.teamId,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      statusBgColor: statusBgColor ?? this.statusBgColor,
      notes: notes ?? this.notes,
      relatedWorkId: relatedWorkId ?? this.relatedWorkId,
      planName: planName ?? this.planName,
      purchaseId: purchaseId ?? this.purchaseId,
      productName: productName ?? this.productName,
      serviceName: serviceName ?? this.serviceName,
      title: title ?? this.title,
      isLocked: isLocked ?? this.isLocked,
      outputUrl: outputUrl ?? this.outputUrl,
      feedback: feedback ?? this.feedback,
      revisionCount: revisionCount ?? this.revisionCount,
      canReschedule: canReschedule ?? this.canReschedule,
      canRequestRework: canRequestRework ?? this.canRequestRework,
      reworkActionLabel: reworkActionLabel ?? this.reworkActionLabel,
      location: location ?? this.location,
      isCarriedForward: isCarriedForward ?? this.isCarriedForward,
      originalScheduledDate: originalScheduledDate ?? this.originalScheduledDate,
      carryForwardNote: carryForwardNote ?? this.carryForwardNote,
      wonByName: wonByName ?? this.wonByName,
    );
  }

  factory CustomerCalendarActivity.fromJson(Map<String, dynamic> json) {
    final titleStr =
        (json['title'] ?? json['productName'] ?? json['serviceName'] ?? '')
            .toString();
    final rawType =
        json['type'] ??
        json['workType'] ??
        json['activityType'] ??
        json['category'];
    final rawTypeStr = rawType?.toString();
    final serviceStr = json['serviceName']?.toString();
    final productStr = json['productName']?.toString();
    final planStr = json['planName']?.toString() ??
        (json['plan'] is Map
            ? json['plan']['name']?.toString()
            : json['plan']?.toString());
    final rawStatus = (json['status'] ?? 'Scheduled').toString();

    final category = resolveTaskCategory(
      null,
      type: rawTypeStr,
      title: titleStr,
      serviceName: serviceStr,
      productName: productStr ?? planStr,
      status: rawStatus,
    );

    CustomerActivityType actType;
    switch (category) {
      case TaskCategory.reelShoot:
        actType = CustomerActivityType.reelShoot;
        break;
      case TaskCategory.reelEdit:
      case TaskCategory.videoEditing:
        actType = CustomerActivityType.videoEditing;
        break;
      case TaskCategory.reelPost:
      case TaskCategory.postPublish:
        actType = CustomerActivityType.posting;
        break;
      case TaskCategory.videoShoot:
        actType = CustomerActivityType.videoShoot;
        break;
      case TaskCategory.postDesign:
        actType = CustomerActivityType.postDesign;
        break;
      case TaskCategory.storyDesign:
      case TaskCategory.storyPost:
        actType = CustomerActivityType.storyDesign;
        break;
      case TaskCategory.influencerPromotion:
      case TaskCategory.adsManagement:
        actType = CustomerActivityType.postCampaign;
        break;
      case TaskCategory.unknown:
        final norm = (rawTypeStr ?? '').trim().toUpperCase();
        if (norm == 'FOLLOW_UP') {
          actType = CustomerActivityType.followUp;
        } else if (norm == 'CUSTOMER_VISIT') {
          actType = CustomerActivityType.customerVisit;
        } else if (norm == 'MEETING' || norm == 'PROPOSAL_MEETING') {
          actType = CustomerActivityType.proposalMeeting;
        } else if (norm == 'TASK' ||
            norm == 'PURCHASE_TASK' ||
            norm == 'INTERNAL_TASK') {
          actType = CustomerActivityType.task;
        } else {
          actType = CustomerActivityType.other;
        }
        break;
    }

    final statusLower = rawStatus.toLowerCase();
    Color sColor = const Color(0xFFD97706);
    Color sBgColor = const Color(0xFFFEF3C7);
    if (statusLower.contains('complete') || statusLower.contains('approve')) {
      sColor = const Color(0xFF16A34A);
      sBgColor = const Color(0xFFDCFCE7);
    } else if (statusLower.contains('progress') ||
        statusLower.contains('assigned') ||
        statusLower.contains('shoot')) {
      sColor = const Color(0xFF0284C7);
      sBgColor = const Color(0xFFE0F2FE);
    } else if (statusLower.contains('review') ||
        statusLower.contains('revision')) {
      sColor = const Color(0xFF9333EA);
      sBgColor = const Color(0xFFF3E8FF);
    }

    DateTime actDate = DateTime.now();
    final rawDate =
        json['scheduledDate'] ??
        json['scheduledAt'] ??
        json['scheduleDate'] ??
        json['date'];
    if (rawDate != null) {
      final str = rawDate.toString().trim();
      final datePart = str.contains('T')
          ? str.split('T')[0]
          : str.split(' ')[0];
      final parts = datePart.split('-').map(int.tryParse).toList();
      if (parts.length == 3 &&
          parts[0] != null &&
          parts[1] != null &&
          parts[2] != null) {
        actDate = DateTime(parts[0]!, parts[1]!, parts[2]!);
      } else {
        final parsed = DateTime.tryParse(str);
        if (parsed != null) {
          final local = parsed.toLocal();
          actDate = DateTime(local.year, local.month, local.day);
        }
      }
    }

    final normalizedDateStr = normalizeDate(actDate);
    final String rawScheduledDateStr;
    if (json['scheduledDate'] != null &&
        json['scheduledDate'].toString().trim().isNotEmpty) {
      final s = json['scheduledDate'].toString().trim();
      rawScheduledDateStr =
          s.contains('T') ? s.split('T')[0] : s.split(' ')[0];
    } else if (json['scheduledAt'] != null &&
        json['scheduledAt'].toString().trim().isNotEmpty) {
      final s = json['scheduledAt'].toString().trim();
      rawScheduledDateStr =
          s.contains('T') ? s.split('T')[0] : s.split(' ')[0];
    } else if (json['scheduleDate'] != null &&
        json['scheduleDate'].toString().trim().isNotEmpty) {
      final s = json['scheduleDate'].toString().trim();
      rawScheduledDateStr =
          s.contains('T') ? s.split('T')[0] : s.split(' ')[0];
    } else if (json['date'] != null &&
        json['date'].toString().trim().isNotEmpty) {
      final s = json['date'].toString().trim();
      rawScheduledDateStr =
          s.contains('T') ? s.split('T')[0] : s.split(' ')[0];
    } else {
      rawScheduledDateStr = normalizedDateStr;
    }

    final purchaseIdVal = json['purchaseId']?.toString();
    final idVal =
        json['id']?.toString() ?? json['activityId']?.toString() ?? '';

    String? rawAssigned;
    if (json.containsKey('assignedEmployee')) {
      // The API's explicit assignment is authoritative, including null.
      rawAssigned = json['assignedEmployee']?.toString().trim();
    } else if (json['assignedToName'] != null &&
        json['assignedToName'].toString().trim().isNotEmpty) {
      rawAssigned = json['assignedToName'].toString().trim();
    } else if (json['assignedEmployees'] is List &&
        (json['assignedEmployees'] as List).isNotEmpty) {
      final firstEmp =
          (json['assignedEmployees'] as List).first?.toString().trim();
      if (firstEmp != null && firstEmp.isNotEmpty) {
        rawAssigned = firstEmp;
      }
    } else if (json['employee'] is Map) {
      final empMap = Map<String, dynamic>.from(json['employee'] as Map);
      final eName = (empMap['name'] ??
              '${empMap['firstName'] ?? ''} ${empMap['lastName'] ?? ''}')
          .toString()
          .trim();
      if (eName.isNotEmpty) {
        rawAssigned = eName;
      }
    }

    final isSuperAdmin = rawAssigned != null &&
        RegExp(r'^(super\s*admin|company\s*admin|tenant\s*admin|\badmin\b)$',
                caseSensitive: false)
            .hasMatch(rawAssigned);

    final assignedRole = rawAssigned != null &&
            rawAssigned.isNotEmpty &&
            rawAssigned != '—' &&
            rawAssigned.toLowerCase() != 'null' &&
            !isSuperAdmin
        ? rawAssigned
        : 'Not assigned';

    String? cleanTitle = titleStr.isNotEmpty ? titleStr : null;
    if (cleanTitle != null) {
      if (cleanTitle.startsWith('Task / ')) {
        cleanTitle = cleanTitle.substring(7).trim();
      } else if (cleanTitle.startsWith('Task - ')) {
        cleanTitle = cleanTitle.substring(7).trim();
      } else if (cleanTitle.toLowerCase() == 'task' ||
          cleanTitle.toLowerCase() == 'schedule') {
        cleanTitle = category.label;
      }
    } else {
      cleanTitle = category.label;
    }

    final rawCustomerName =
        (json['customerName'] ??
                json['contactFullName'] ??
                json['contactPerson'] ??
                json['clientName'] ??
                '')
            .toString();
    final rawBusinessName =
        (json['businessName'] ?? json['companyName'] ?? json['company'] ?? '')
            .toString();

    String resolvedCustomerName = rawCustomerName;
    String resolvedBusinessName = rawBusinessName;

    // Check nested customer object
    if (json['customer'] is Map) {
      final custMap = Map<String, dynamic>.from(json['customer'] as Map);
      if (resolvedBusinessName.isEmpty) {
        resolvedBusinessName =
            (custMap['companyName'] ?? custMap['businessName'] ?? '')
                .toString();
      }
      if (resolvedCustomerName.isEmpty) {
        final cFirst =
            (custMap['firstName'] ?? custMap['contactFirstName'] ?? '')
                .toString();
        final cMiddle = (custMap['middleName'] ?? '').toString();
        final cLast = (custMap['lastName'] ?? custMap['contactLastName'] ?? '')
            .toString();
        final cFull = [
          cFirst,
          cMiddle,
          cLast,
        ].where((s) => s.isNotEmpty && s != 'null').join(' ').trim();
        if (cFull.isNotEmpty) {
          resolvedCustomerName = cFull;
        } else if (custMap['name'] != null &&
            custMap['name'].toString() != resolvedBusinessName) {
          resolvedCustomerName = custMap['name'].toString();
        }
      }
    }

    // Check explicit contact name fields
    if (resolvedCustomerName.isEmpty ||
        (resolvedBusinessName.isNotEmpty &&
            resolvedCustomerName.toLowerCase() ==
                resolvedBusinessName.toLowerCase())) {
      final jFirst = (json['firstName'] ?? json['contactFirstName'] ?? '')
          .toString();
      final jMiddle = (json['middleName'] ?? '').toString();
      final jLast = (json['lastName'] ?? json['contactLastName'] ?? '')
          .toString();
      final jFull = [
        jFirst,
        jMiddle,
        jLast,
      ].where((s) => s.isNotEmpty && s != 'null').join(' ').trim();
      if (jFull.isNotEmpty &&
          jFull.toLowerCase() != resolvedBusinessName.toLowerCase()) {
        resolvedCustomerName = jFull;
      }
    }

    if (resolvedCustomerName.isEmpty) {
      resolvedCustomerName = rawCustomerName;
    }
    if (resolvedBusinessName.isEmpty) {
      resolvedBusinessName = rawBusinessName;
    }

    String? wonByName;
    final rawWonByName = json['wonByName']?.toString().trim();
    if (rawWonByName != null &&
        rawWonByName.isNotEmpty &&
        rawWonByName.toLowerCase() != 'null') {
      wonByName = rawWonByName;
    } else if (json['wonBy'] is Map) {
      final wonBy = Map<String, dynamic>.from(json['wonBy'] as Map);
      final nestedName = wonBy['name']?.toString().trim();
      if (nestedName != null &&
          nestedName.isNotEmpty &&
          nestedName.toLowerCase() != 'null') {
        wonByName = nestedName;
      }
    }

    final activity = CustomerCalendarActivity(
      id: idVal,
      customerId: json['customerId']?.toString() ?? '',
      customerName: resolvedCustomerName,
      businessName: resolvedBusinessName,
      activityType: actType,
      type: rawTypeStr ?? category.key,
      date: actDate,
      scheduledDate: rawScheduledDateStr,
      scheduleDate: actDate,
      time:
          json['scheduledTime']?.toString() ??
          json['time']?.toString() ??
          json['startTime']?.toString() ??
          'Time not set',
      startTime:
          json['startTime']?.toString() ?? json['scheduledTime']?.toString(),
      endTime: json['endTime']?.toString(),
      assignedEmployee: assignedRole,
      assignedToId: json['assignedToId']?.toString(),
      editorId: json['editorId']?.toString(),
      editorName: json['editorName']?.toString(),
      team: json.containsKey('team')
          ? json['team']?.toString()
          : json['assignedTeam']?.toString(),
      teamId: json['teamId']?.toString(),
      status: rawStatus,
      statusColor: sColor,
      statusBgColor: sBgColor,
      notes:
          json['notes']?.toString() ??
          json['description']?.toString() ??
          cleanTitle,
      relatedWorkId: json['relatedWorkId']?.toString() ?? idVal,
      planName:
          json['planName']?.toString() ??
          json['productName']?.toString() ??
          (json['plan'] is Map
              ? json['plan']['name']?.toString()
              :           json['plan']?.toString()) ??
          '',
      purchaseId: purchaseIdVal,
      productName: productStr,
      serviceName: serviceStr,
      title: cleanTitle,
      isLocked:
          json['isLocked'] == true ||
          json['isLocked'] == 1 ||
          json['isLocked'] == 'true',
      outputUrl: json['outputUrl']?.toString(),
      feedback: json['feedback']?.toString(),
      revisionCount: int.tryParse(json['revisionCount']?.toString() ?? '') ?? 0,
      canReschedule:
          json['canReschedule'] == true ||
          (json['canReschedule'] == null &&
              (rawStatus.toUpperCase() == 'SCHEDULED' ||
                  rawStatus.toUpperCase() == 'PENDING')),
      canRequestRework:
          json['canRequestRework'] == true ||
          (json['canRequestRework'] == null &&
              (rawStatus.toUpperCase() == 'COMPLETED' ||
                  rawStatus.toUpperCase() == 'APPROVED' ||
                  rawStatus.toUpperCase() == 'DONE')),
      reworkActionLabel: json['reworkActionLabel']?.toString(),
      location: (json['location'] ?? json['address'])?.toString(),
      isCarriedForward: json['isCarriedForward'] == true ||
          json['isCarriedForward'] == 1 ||
          json['isCarriedForward'] == 'true' ||
          (json['notes']?.toString() ?? json['description']?.toString() ?? '')
              .contains('[ORIGINAL_SCHEDULE:') ||
          (json['notes']?.toString() ?? json['description']?.toString() ?? '')
              .toLowerCase()
              .contains('originally scheduled'),
      originalScheduledDate: json['originalScheduledDate']?.toString(),
      carryForwardNote: json['carryForwardNote']?.toString(),
      wonByName: wonByName,
    );

    final resolvedColor = category.color;
    final dateStrFormatted =
        '${actDate.year.toString().padLeft(4, '0')}-${actDate.month.toString().padLeft(2, '0')}-${actDate.day.toString().padLeft(2, '0')}';

    debugPrint(
      '[CALENDAR_TASK_DEBUG]\nid: ${activity.id}\ntitle: ${activity.title ?? activity.notes ?? "null"}\ntype: ${rawTypeStr ?? "null"}\nserviceName: ${serviceStr ?? "null"}\nproductName: ${productStr ?? "null"}\ndate: $dateStrFormatted\nstatus: $rawStatus\nresolvedTaskCategory: ${category.key}\nresolvedColor: $resolvedColor',
    );

    return activity;
  }
}

String resolveActivityDisplayName(CustomerCalendarActivity activity) {
  final raw = (activity.title ?? '').trim();
  if (raw.isNotEmpty) {
    if (raw.startsWith('Task / ')) {
      return raw.substring(7).trim();
    }
    if (raw.startsWith('Task - ')) {
      return raw.substring(7).trim();
    }
    if (raw.toLowerCase() != 'task' && raw.toLowerCase() != 'schedule') {
      return raw;
    }
  }
  final category = resolveTaskCategory(activity);
  return category.label;
}

String calendarAssigneeLabel(CustomerCalendarActivity activity) {
  final name = activity.assignedEmployee.trim();
  final isSuperAdmin = RegExp(
    r'^(super\s*admin|company\s*admin|tenant\s*admin|\badmin\b)$',
    caseSensitive: false,
  ).hasMatch(name);

  final isInvalid = name.isEmpty ||
      name == '—' ||
      name.toLowerCase() == 'unassigned' ||
      name.toLowerCase() == 'not assigned' ||
      name.toLowerCase() == 'employee not assigned' ||
      isSuperAdmin;

  final validEmployee = isInvalid ? null : name;
  final team = activity.team?.trim();
  final hasTeam = team != null && team.isNotEmpty;

  if (validEmployee != null && hasTeam) {
    return '$validEmployee • $team';
  } else if (validEmployee != null) {
    return validEmployee;
  } else if (hasTeam) {
    return team;
  }
  return 'Employee not assigned';
}

String resolveAssignedRole(CustomerCalendarActivity activity) {
  final category = resolveTaskCategory(activity);
  switch (category) {
    case TaskCategory.reelShoot:
    case TaskCategory.videoShoot:
      return 'Photographer';
    case TaskCategory.reelEdit:
    case TaskCategory.videoEditing:
      return 'Video Editor';
    case TaskCategory.postDesign:
    case TaskCategory.storyDesign:
      return 'Graphic Designer';
    case TaskCategory.reelPost:
    case TaskCategory.postPublish:
    case TaskCategory.storyPost:
      return 'Social Media Manager';
    case TaskCategory.influencerPromotion:
      return 'Influencer Lead';
    default:
      if (activity.assignedEmployee.trim().isNotEmpty &&
          activity.assignedEmployee != 'Creative Crew' &&
          activity.assignedEmployee != 'Creative Lead' &&
          activity.assignedEmployee != 'Staff') {
        return activity.assignedEmployee;
      }
      return 'Creative Crew';
  }
}

String normalizeDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String getScheduledDateString(CustomerCalendarActivity activity) {
  return activity.scheduledDateStr;
}

/// Reusable deduplication function that preserves legitimate activities while
/// guaranteeing that duplicate records sharing the same primary key (activity.id)
/// are rendered only once.
List<CustomerCalendarActivity> deduplicateCustomerActivities(
  Iterable<CustomerCalendarActivity> activities,
) {
  final uniqueMap = <String, CustomerCalendarActivity>{};
  for (final a in activities) {
    // Work and Task ids come from separate tables and can share a number.
    final source = a.type.trim().toUpperCase() == 'TASK' ? 'TASK' : 'WORK';
    final key = a.id.trim().isNotEmpty
        ? '$source:${a.id.trim()}'
        : '${getScheduledDateString(a)}_${a.title}_${a.time}';
    if (!uniqueMap.containsKey(key)) {
      uniqueMap[key] = a;
    }
  }
  return uniqueMap.values.toList();
}

enum WorkStatus {
  inProgress('IN PROGRESS', Color(0xFF0284C7), Color(0xFFE0F2FE)),
  scheduled('SCHEDULED', Color(0xFFD97706), Color(0xFFFEF3C7)),
  completed('COMPLETED', Color(0xFF16A34A), Color(0xFFDCFCE7)),
  review('REVIEW', Color(0xFF9333EA), Color(0xFFF3E8FF));

  final String label;
  final Color color;
  final Color bgColor;
  const WorkStatus(this.label, this.color, this.bgColor);
}

enum WorkType {
  reel('Reel', 3),
  shoot('Shoot', 3),
  post('Post', 1);

  final String label;
  final int defaultDurationDays;
  const WorkType(this.label, this.defaultDurationDays);
}

enum ClientStatus {
  active('ACTIVE', Color(0xFF16A34A), Color(0xFFDCFCE7)),
  inactive('INACTIVE', Color(0xFF64748B), Color(0xFFF1F5F9)),
  pending('PENDING', Color(0xFFD97706), Color(0xFFFEF3C7));

  final String label;
  final Color color;
  final Color bgColor;
  const ClientStatus(this.label, this.color, this.bgColor);
}

enum LeadStatus {
  newLead('New', Color(0xFF0284C7), Color(0xFFE0F2FE)),
  followUp('Follow-up', Color(0xFFD97706), Color(0xFFFEF3C7)),
  converted('Converted', Color(0xFF16A34A), Color(0xFFDCFCE7)),
  closed('Closed', Color(0xFF64748B), Color(0xFFF1F5F9)),
  lost('Lost', Color(0xFFDC2626), Color(0xFFFEE2E2));

  final String label;
  final Color color;
  final Color bgColor;
  const LeadStatus(this.label, this.color, this.bgColor);
}

enum VisitStatus {
  today('Today', Color(0xFF0284C7), Color(0xFFE0F2FE)),
  upcoming('Upcoming', Color(0xFFD97706), Color(0xFFFEF3C7)),
  completed('Completed', Color(0xFF16A34A), Color(0xFFDCFCE7)),
  cancelled('Cancelled', Color(0xFFDC2626), Color(0xFFFEE2E2));

  final String label;
  final Color color;
  final Color bgColor;
  const VisitStatus(this.label, this.color, this.bgColor);
}

enum ProposalStatus {
  draft('Draft', Color(0xFF64748B), Color(0xFFF1F5F9)),
  sent('Sent', Color(0xFF0284C7), Color(0xFFE0F2FE)),
  accepted('Accepted', Color(0xFF16A34A), Color(0xFFDCFCE7)),
  rejected('Rejected', Color(0xFFDC2626), Color(0xFFFEE2E2)),
  expired('Expired', Color(0xFFD97706), Color(0xFFFEF3C7));

  final String label;
  final Color color;
  final Color bgColor;
  const ProposalStatus(this.label, this.color, this.bgColor);
}

// ── Core Models ──────────────────────────────────────────────────────────────

class AdminCustomer {
  final String id;
  final String customerId;
  final String name;
  final String businessName;
  final String mobile;
  final String? alternateNumber;
  final String email;
  final String? website;
  final String? industry;
  final String? businessCategory;
  final String city;
  final String? state;
  final String? pincode;
  final String assignedEmployee;
  final String assignedTeam;
  final String activeWork;
  final ClientStatus status;
  final String customerSince;
  final String nextFollowUp;
  final String? notes;

  AdminCustomer({
    required this.id,
    this.customerId = '',
    required this.name,
    required this.businessName,
    required this.mobile,
    this.alternateNumber,
    required this.email,
    this.website,
    this.industry,
    this.businessCategory,
    required this.city,
    this.state,
    this.pincode,
    required this.assignedEmployee,
    required this.assignedTeam,
    required this.activeWork,
    this.status = ClientStatus.active,
    required this.customerSince,
    required this.nextFollowUp,
    this.notes,
  });

  AdminCustomer copyWith({
    String? id,
    String? customerId,
    String? name,
    String? businessName,
    String? mobile,
    String? alternateNumber,
    String? email,
    String? website,
    String? industry,
    String? businessCategory,
    String? city,
    String? state,
    String? pincode,
    String? assignedEmployee,
    String? assignedTeam,
    String? activeWork,
    ClientStatus? status,
    String? customerSince,
    String? nextFollowUp,
    String? notes,
  }) {
    return AdminCustomer(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      mobile: mobile ?? this.mobile,
      alternateNumber: alternateNumber ?? this.alternateNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      industry: industry ?? this.industry,
      businessCategory: businessCategory ?? this.businessCategory,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      activeWork: activeWork ?? this.activeWork,
      status: status ?? this.status,
      customerSince: customerSince ?? this.customerSince,
      nextFollowUp: nextFollowUp ?? this.nextFollowUp,
      notes: notes ?? this.notes,
    );
  }
}

class AdminSSMWork {
  final String id;
  final String customerId;
  final String customerName;
  final String socialAccount;
  final String platform;
  final WorkType workType;
  final String team;
  final List<String> teamMembers;
  final String assignedEmployee;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int currentDay;
  final String todayTask;
  final List<DayTask> allTasks;
  final WorkStatus status;
  final String priority;
  final String? notes;

  AdminSSMWork({
    required this.id,
    this.customerId = '',
    required this.customerName,
    required this.socialAccount,
    required this.platform,
    required this.workType,
    required this.team,
    required this.teamMembers,
    required this.assignedEmployee,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.currentDay,
    required this.todayTask,
    required this.allTasks,
    this.status = WorkStatus.inProgress,
    this.priority = 'High',
    this.notes,
  });
}

class DayTask {
  final int day;
  final String title;
  final String description;
  final bool isCompleted;
  final bool isCurrent;

  DayTask({
    required this.day,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class AdminEmployee {
  final String id;
  final String customerId;
  final String name;
  final String role;
  final String mobile;
  final String email;
  final String team;
  final String status;
  final String todayWork;
  final int activeWorkCount;
  final int completedWorkCount;
  final int leadsCount;
  final int visitsCount;
  final int dataCaptureCount;

  AdminEmployee({
    required this.id,
    this.customerId = '',
    required this.name,
    required this.role,
    required this.mobile,
    required this.email,
    required this.team,
    this.status = 'ACTIVE',
    required this.todayWork,
    this.activeWorkCount = 0,
    this.completedWorkCount = 0,
    this.leadsCount = 0,
    this.visitsCount = 0,
    this.dataCaptureCount = 0,
  });
}

class AdminTeam {
  final String id;
  final String customerId;
  final String name;
  final String teamLeader;
  final List<String> members;
  final int activeWork;
  final int completedWork;
  final String status;

  AdminTeam({
    required this.id,
    this.customerId = '',
    required this.name,
    required this.teamLeader,
    required this.members,
    required this.activeWork,
    required this.completedWork,
    this.status = 'ACTIVE',
  });
}

class AdminLead {
  final String id;
  final String customerId;
  final String customerName;
  final String contact;
  final String email;
  final String source;
  final String assignedEmployee;
  final LeadStatus status;
  final String nextFollowUp;
  final String priority;
  final String? notes;
  final String? category;

  AdminLead({
    required this.id,
    this.customerId = '',
    required this.customerName,
    required this.contact,
    required this.email,
    required this.source,
    required this.assignedEmployee,
    required this.status,
    required this.nextFollowUp,
    required this.priority,
    this.notes,
    this.category,
  });
}

class AdminVisit {
  final String id;
  final String customerId;
  final String customerName;
  final String employeeName;
  final String date;
  final String time;
  final String location;
  final VisitStatus status;
  final String? notes;

  AdminVisit({
    required this.id,
    this.customerId = '',
    required this.customerName,
    required this.employeeName,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    this.notes,
  });
}

class AdminDataCapture {
  final String id;
  final String customerId;
  final String employeeName;
  final String customerName;
  final String captureType;
  final String date;
  final String status;
  final Map<String, String> capturedData;
  final List<String> recentActivity;

  AdminDataCapture({
    required this.id,
    this.customerId = '',
    required this.employeeName,
    required this.customerName,
    required this.captureType,
    required this.date,
    required this.status,
    required this.capturedData,
    required this.recentActivity,
  });
}

class AdminProposal {
  final String id;
  final String customerId;
  final String customerName;
  final String businessName;
  final String contact;
  final String email;
  final String address;
  final String packageName;
  final String services;
  final double amount;
  final String validity;
  final ProposalStatus status;
  final String? notes;
  final String date;

  AdminProposal({
    required this.id,
    this.customerId = '',
    required this.customerName,
    required this.businessName,
    required this.contact,
    required this.email,
    required this.address,
    required this.packageName,
    required this.services,
    required this.amount,
    required this.validity,
    required this.status,
    this.notes,
    required this.date,
  });
}

class AdminPackage {
  final String id;
  final String name;
  final String description;
  final double price;
  final String duration;
  final List<String> services;
  final String status;

  AdminPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.services,
    this.status = 'ACTIVE',
  });
}

class AdminAuditLog {
  final String id;
  final String action;
  final String user;
  final String role;
  final String module;
  final String date;
  final String time;
  final String description;

  AdminAuditLog({
    required this.id,
    required this.action,
    required this.user,
    this.role = 'Admin',
    required this.module,
    required this.date,
    required this.time,
    required this.description,
  });
}

class AdminCompanyProfile {
  final String companyName;
  final String businessName;
  final String mobile;
  final String email;
  final String website;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String businessDetails;

  AdminCompanyProfile({
    required this.companyName,
    required this.businessName,
    required this.mobile,
    required this.email,
    required this.website,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.businessDetails,
  });

  AdminCompanyProfile copyWith({
    String? companyName,
    String? businessName,
    String? mobile,
    String? email,
    String? website,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? businessDetails,
  }) {
    return AdminCompanyProfile(
      companyName: companyName ?? this.companyName,
      businessName: businessName ?? this.businessName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      businessDetails: businessDetails ?? this.businessDetails,
    );
  }
}

enum LiveAttendanceStatus {
  working(
    'Working',
    Color(0xFF16A34A),
    Color(0xFFDCFCE7),
    Remix.checkbox_circle_fill,
  ),
  onBreak('On Break', Color(0xFFD97706), Color(0xFFFEF3C7), Remix.cup_fill),
  onLeave(
    'On Leave',
    Color(0xFF9333EA),
    Color(0xFFF3E8FF),
    Remix.calendar_close_fill,
  ),
  checkedOut(
    'Checked Out',
    Color(0xFF64748B),
    Color(0xFFF1F5F9),
    Remix.logout_circle_fill,
  ),
  absent(
    'Absent',
    Color(0xFFDC2626),
    Color(0xFFFEE2E2),
    Remix.close_circle_fill,
  );

  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const LiveAttendanceStatus(this.label, this.color, this.bgColor, this.icon);
}

class AdminLiveAttendance {
  final String id;
  final String customerId;
  final String employeeId;
  final String employeeName;
  final String role;
  final String team;
  final LiveAttendanceStatus status;
  final String? punchInTime;
  final String? punchOutTime;
  final String? breakStartTime;
  final String breakDuration;
  final String totalWorkingHours;
  final String? leaveReason;
  final String? leaveType;
  final String location;

  const AdminLiveAttendance({
    required this.id,
    this.customerId = '',
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.team,
    required this.status,
    this.punchInTime,
    this.punchOutTime,
    this.breakStartTime,
    this.breakDuration = '0m',
    this.totalWorkingHours = '0h 0m',
    this.leaveReason,
    this.leaveType,
    this.location = 'Office Geofence',
  });

  AdminLiveAttendance copyWith({
    String? id,
    String? customerId,
    String? employeeId,
    String? employeeName,
    String? role,
    String? team,
    LiveAttendanceStatus? status,
    String? punchInTime,
    String? punchOutTime,
    String? breakStartTime,
    String? breakDuration,
    String? totalWorkingHours,
    String? leaveReason,
    String? leaveType,
    String? location,
  }) {
    return AdminLiveAttendance(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      role: role ?? this.role,
      team: team ?? this.team,
      status: status ?? this.status,
      punchInTime: punchInTime ?? this.punchInTime,
      punchOutTime: punchOutTime ?? this.punchOutTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakDuration: breakDuration ?? this.breakDuration,
      totalWorkingHours: totalWorkingHours ?? this.totalWorkingHours,
      leaveReason: leaveReason ?? this.leaveReason,
      leaveType: leaveType ?? this.leaveType,
      location: location ?? this.location,
    );
  }
}
