import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/app_url.dart';
import '../models/customer_model.dart';
import '../models/lead_model.dart';
import '../viewmodels/leads_viewmodel.dart';

class CustomersResponse {
  final List<CustomerModel> customers;
  final Map<String, int> counts;

  const CustomersResponse({required this.customers, required this.counts});
}

final customerServiceProvider = Provider<CustomerService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CustomerService(client);
});

final customersProvider = FutureProvider.autoDispose<CustomersResponse>((
  ref,
) async {
  final service = ref.watch(customerServiceProvider);
  final leadsAsync = ref.watch(leadsProvider);
  final leadService = ref.watch(leadServiceProvider);

  final response = await service.getCustomers();

  // Merge eligible follow-up and final-call leads into Upcoming
  List<LeadModel> leads = [];
  if (leadsAsync.hasValue &&
      leadsAsync.value != null &&
      leadsAsync.value!.isNotEmpty) {
    leads = leadsAsync.value!;
  } else {
    try {
      leads = await leadService.getLeads();
    } catch (e) {
      debugPrint(
        '[CUSTOMERS_PROVIDER] Error retrieving leads for upcoming merge: $e',
      );
    }
  }

  return service.mergeWithUpcomingLeads(response, leads);
});

final customerDetailFutureProvider =
    FutureProvider.family<Map<String, dynamic>?, dynamic>((
      ref,
      customerId,
    ) async {
      final service = ref.watch(customerServiceProvider);
      return service.getCustomerDetails(customerId);
    });

final customerAssignedTeamProvider =
    FutureProvider.family<Map<String, dynamic>?, dynamic>((
      ref,
      customerId,
    ) async {
      final service = ref.watch(customerServiceProvider);
      return service.getAssignedTeam(customerId);
    });

final availableTeamsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(customerServiceProvider);
  return service.getAvailableTeams();
});

/// Service responsible for fetching Customer profile and account details from /api/v1/customers/{id}
/// and managing team assignments.
class CustomerService {
  final ApiClient _client;

  CustomerService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Fetches single customer details by ID via authenticated GET /api/v1/customers/{id}.
  /// Uses existing session token via ApiClient's global interceptor.
  Future<Map<String, dynamic>?> getCustomerDetails(dynamic customerId) async {
    final rawStr = customerId?.toString().trim();
    if (rawStr == null || rawStr.isEmpty) {
      debugPrint(
        '[CUSTOMER_SERVICE] Cannot fetch customer details: customerId is null or empty',
      );
      return null;
    }

    if (rawStr.startsWith('-')) {
      debugPrint(
        '[CUSTOMER_SERVICE] Cannot fetch customer details: negative customerId "$rawStr" is invalid',
      );
      return null;
    }

    final cleanId = rawStr.replaceAll(RegExp(r'^[^\d]+'), '').trim();
    final parsed = int.tryParse(cleanId);
    if (parsed == null || parsed <= 0) {
      debugPrint(
        '[CUSTOMER_SERVICE] Cannot fetch customer details: non-positive customerId "$rawStr" is invalid',
      );
      return null;
    }

    try {
      final endpoint = AppUrl.customerDetails(parsed);
      final response = await _client.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        if (raw is Map<String, dynamic>) {
          if (raw['data'] is Map<String, dynamic>) {
            return raw['data'] as Map<String, dynamic>;
          }
          return raw;
        }
      }
      return null;
    } on DioException catch (dioErr) {
      final status = dioErr.response?.statusCode;
      debugPrint(
        '[CUSTOMER_SERVICE] Dio error fetching customer $cleanId (HTTP $status): ${dioErr.message}',
      );
      if (status == 401) {
        debugPrint('[CUSTOMER_SERVICE] 401 Unauthorized for customer $cleanId');
      } else if (status == 403) {
        debugPrint(
          '[CUSTOMER_SERVICE] 403 Forbidden: insufficient permission for customer $cleanId',
        );
      } else if (status == 404) {
        debugPrint('[CUSTOMER_SERVICE] 404 Not Found for customer $cleanId');
      }
      rethrow;
    } catch (e) {
      debugPrint(
        '[CUSTOMER_SERVICE] Unexpected error fetching customer $cleanId: $e',
      );
      rethrow;
    }
  }

  /// Fetches assigned team for a customer via GET /api/v1/customers/{id}/assign-team.
  Future<Map<String, dynamic>?> getAssignedTeam(dynamic customerId) async {
    final rawId = customerId?.toString().trim() ?? '';
    final directId = int.tryParse(rawId);
    final prefixedMatch = RegExp(
      r'^CUST-(\d+)$',
      caseSensitive: false,
    ).firstMatch(rawId);
    final parsedId = directId ?? int.tryParse(prefixedMatch?.group(1) ?? '');
    if (parsedId == null || parsedId <= 0) {
      throw ArgumentError.value(
        customerId,
        'customerId',
        'A valid customer database ID is required.',
      );
    }
    final cleanId = parsedId.toString();

    try {
      final endpoint = AppUrl.customerAssignTeam(cleanId);
      final response = await _client.get(endpoint);

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        if (raw is Map<String, dynamic>) {
          if (raw['data'] is Map<String, dynamic>) {
            return raw['data'] as Map<String, dynamic>;
          }
          return raw;
        }
      }
      return null;
    } on DioException catch (dioErr) {
      debugPrint(
        '[CUSTOMER_SERVICE] Error fetching assigned team for customer $cleanId: ${dioErr.message}',
      );
      if (dioErr.response?.statusCode == 404) {
        try {
          final details = await getCustomerDetails(parsedId);
          if (details != null) {
            final dynamic team = details['assignedTeam'] ?? details['team'];
            return {
              'id': parsedId,
              'customerId': parsedId,
              'assignedTeamId': details['assignedTeamId'],
              'team': team is Map<String, dynamic> ? team : null,
              'assignedTeam': team is Map<String, dynamic> ? team : null,
            };
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Assigns customer to a team via PATCH /api/v1/customers/{id}/assign-team.
  /// Pass [teamId] = null to unassign.
  Future<Map<String, dynamic>?> assignTeam(
    dynamic customerId,
    int? teamId,
  ) async {
    final rawId = customerId?.toString().trim() ?? '';
    final directId = int.tryParse(rawId);
    final prefixedMatch = RegExp(
      r'^CUST-(\d+)$',
      caseSensitive: false,
    ).firstMatch(rawId);
    final parsedId = directId ?? int.tryParse(prefixedMatch?.group(1) ?? '');
    if (parsedId == null || parsedId <= 0) {
      throw ArgumentError.value(
        customerId,
        'customerId',
        'A valid customer database ID is required.',
      );
    }
    final cleanId = parsedId.toString();

    try {
      final endpoint = AppUrl.customerAssignTeam(cleanId);
      final response = await _client.patch(endpoint, data: {'teamId': teamId});

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        if (raw is Map<String, dynamic>) {
          if (raw['data'] is Map<String, dynamic>) {
            return raw['data'] as Map<String, dynamic>;
          }
          return raw;
        }
      }
      return null;
    } on DioException catch (dioErr) {
      debugPrint(
        '[CUSTOMER_SERVICE] Error assigning team $teamId to customer $cleanId: ${dioErr.message}',
      );
      rethrow;
    }
  }

  /// Fetches available teams from GET /api/v1/teams.
  Future<List<Map<String, dynamic>>> getAvailableTeams() async {
    try {
      final response = await _client.get(AppUrl.teams);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        List<dynamic>? list;
        if (raw is Map<String, dynamic>) {
          if (raw['data'] is List) {
            list = raw['data'] as List<dynamic>;
          } else if (raw['items'] is List) {
            list = raw['items'] as List<dynamic>;
          } else if (raw['data'] is Map &&
              (raw['data'] as Map)['items'] is List) {
            list = (raw['data'] as Map)['items'] as List<dynamic>;
          }
        } else if (raw is List) {
          list = raw;
        }

        if (list != null) {
          return list.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } on DioException catch (dioErr) {
      debugPrint(
        '[CUSTOMER_SERVICE] Error fetching available teams: ${dioErr.message}',
      );
      return [];
    }
  }

  /// Fetches customers with pagination, dynamic counts and lead info via GET /api/v1/customers.
  Future<CustomersResponse> getCustomers({
    String? search,
    String? status,
    int page = 1,
    int limit = 100,
    bool forCalendar = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status != 'ALL' && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }
      if (forCalendar) {
        queryParams['forCalendar'] = 'true';
        queryParams['isActive'] = 'true';
      }

      final response = await _client.get(
        AppUrl.customers,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        List<dynamic> itemsRaw = [];
        Map<String, int> counts = {
          'active': 0,
          'upcoming': 0,
          'completed': 0,
          'all': 0,
        };

        if (raw is Map<String, dynamic>) {
          if (raw['items'] is List) {
            itemsRaw = raw['items'] as List<dynamic>;
          } else if (raw['data'] is List) {
            itemsRaw = raw['data'] as List<dynamic>;
          }

          if (raw['meta'] is Map && raw['meta']['counts'] is Map) {
            final c = raw['meta']['counts'] as Map;
            counts = {
              'active': (c['active'] as num?)?.toInt() ?? 0,
              'upcoming': (c['upcoming'] as num?)?.toInt() ?? 0,
              'inactive': (c['inactive'] as num?)?.toInt() ?? 0,
              'completed': (c['completed'] as num?)?.toInt() ?? 0,
              'all': (c['all'] as num?)?.toInt() ?? 0,
            };
          }
        } else if (raw is List) {
          itemsRaw = raw;
        }

        final customers = itemsRaw
            .whereType<Map<String, dynamic>>()
            .map((j) => CustomerModel.fromJson(j))
            .where(_isEligibleCustomerRecord)
            .toList();

        debugPrint(
          '[CUSTOMERS] filter=${status ?? "ALL"} search=${search ?? ""} count=${customers.length}',
        );

        // Derive active/inactive/upcoming counts and log Section 13 diagnostic details
        {
          int act = 0, inact = 0, upc = 0;
          final upcomingLeadIds = <String>[];
          final upcomingCustomerIds = <String>[];

          for (final c in customers) {
            if (c.isSubscriptionActive) {
              act++;
            } else if (c.hasUpcomingCall) {
              upc++;
              if (c.leadId.isNotEmpty) upcomingLeadIds.add(c.leadId);
              if (c.customerId.isNotEmpty) {
                upcomingCustomerIds.add(c.customerId);
              }
              debugPrint(
                '[UPCOMING_DIAGNOSTIC] customerId=${c.customerId} leadId=${c.leadId} stageName=${c.leadStageName ?? "N/A"} callDate=${c.upcomingCallDate ?? "N/A"} callTime=${c.upcomingCallTime ?? "N/A"} callType=${c.upcomingCallType ?? "N/A"} callStatus=${c.status}',
              );
            } else {
              inact++;
            }
          }

          debugPrint(
            '[UPCOMING_SUMMARY] Upcoming API result count=$upc | leadIds=$upcomingLeadIds | customerIds=$upcomingCustomerIds',
          );

          final backendAll = counts['all'] ?? 0;
          counts = {
            'active': counts['all'] != 0 ? (counts['active'] ?? act) : act,
            'upcoming': counts['all'] != 0 ? (counts['upcoming'] ?? upc) : upc,
            'inactive': counts['all'] != 0 && (counts['inactive'] ?? 0) != 0
                ? (counts['inactive'] ?? inact)
                : inact,
            'all': backendAll != 0 ? backendAll : customers.length,
          };
        }

        return CustomersResponse(customers: customers, counts: counts);
      }
      throw Exception('Failed to load customers (HTTP ${response.statusCode})');
    } on DioException catch (dioErr) {
      debugPrint(
        '[CUSTOMER_SERVICE] Dio error fetching customers: ${dioErr.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[CUSTOMER_SERVICE] Error fetching customers: $e');
      rethrow;
    }
  }

  /// Merges Won leads (as Customers) and Follow-up / Final Call leads (Upcoming only)
  /// that are not yet present as Customer records.
  CustomersResponse mergeWithUpcomingLeads(
    CustomersResponse response,
    List<LeadModel> leads,
  ) {
    if (leads.isEmpty) return response;

    final existingCustomerIds = <String>{};
    final existingLeadIds = <String>{};

    for (final c in response.customers) {
      if (c.customerId.isNotEmpty) existingCustomerIds.add(c.customerId);
      if (c.leadId.isNotEmpty) existingLeadIds.add(c.leadId);
    }

    final mergedCustomers = List<CustomerModel>.from(response.customers);

    for (final lead in leads) {
      if (!lead.isWon && !_isFinalCallLead(lead)) continue;

      final custId = 'LEAD-${lead.id.padLeft(4, '0')}';
      final altCustId = 'CUST-${lead.id}';
      if (!existingLeadIds.contains(lead.id) &&
          !existingCustomerIds.contains(custId) &&
          !existingCustomerIds.contains(altCustId)) {
        final cust = CustomerModel.fromLead(lead);
        mergedCustomers.add(cust);
        existingLeadIds.add(lead.id);
        existingCustomerIds.add(cust.customerId);
      }
    }

    int activeCount = 0;
    int upcomingCount = 0;
    int inactiveCount = 0;

    for (final c in mergedCustomers) {
      if (c.isSubscriptionActive) {
        activeCount++;
      } else if (c.hasUpcomingCall) {
        upcomingCount++;
      } else {
        inactiveCount++;
      }
    }

    final updatedCounts = {
      'all': mergedCustomers.length,
      'active': activeCount,
      'upcoming': upcomingCount,
      'inactive': inactiveCount,
    };

    return CustomersResponse(customers: mergedCustomers, counts: updatedCounts);
  }

  static bool _isFinalCallLead(LeadModel lead) {
    final status = lead.status.trim().toUpperCase().replaceAll(' ', '_');
    final stage = lead.stageName.trim().toUpperCase();
    if (status == 'FINAL_CALL') {
      return true;
    }
    if (stage.contains('FINAL')) {
      return true;
    }
    return false;
  }

  /// Synthetic LEAD-* cards: WON customers, or Follow-up / Final Call upcoming calls.
  /// Persisted CUST-* records are already gated by the backend.
  static bool _isEligibleCustomerRecord(CustomerModel c) {
    if (c.isSubscriptionActive) return true;
    final sub = (c.subscriptionStatus ?? '').trim().toUpperCase();
    if (sub == 'EXPIRED' || sub == 'CANCELLED') return true;

    final isSyntheticLeadCard = c.customerId.toUpperCase().startsWith('LEAD-');
    if (!isSyntheticLeadCard) return true;

    if (c.hasUpcomingCall) return true;
    final custStatus = (c.customerStatus).trim().toUpperCase();
    if (custStatus == 'UPCOMING') return true;

    final status = (c.leadStatus ?? '').trim().toUpperCase().replaceAll(
      ' ',
      '_',
    );
    final stage = (c.leadStageName ?? '').trim().toUpperCase().replaceAll(
      ' ',
      '_',
    );
    bool isWonStage(String value) =>
        value == 'WON' ||
        value == 'CONVERTED' ||
        value == 'WORK_STARTED' ||
        value == 'CLOSED';
    bool isUpcomingStage(String value) =>
        value == 'FINAL_CALL' || value.contains('FINAL');
    return isWonStage(status) ||
        isWonStage(stage) ||
        isUpcomingStage(status) ||
        isUpcomingStage(stage);
  }
}
