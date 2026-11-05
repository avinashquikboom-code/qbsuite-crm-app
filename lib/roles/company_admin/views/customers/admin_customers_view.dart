import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/models/user_role.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/services/subscription_service.dart';
import 'customer_plans_view.dart';

class AdminCustomersView extends ConsumerStatefulWidget {
  const AdminCustomersView({super.key});
  @override
  ConsumerState<AdminCustomersView> createState() => _AdminCustomersViewState();
}

class _AdminCustomersViewState extends ConsumerState<AdminCustomersView>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>>? _customers;
  String? _error;
  Timer? _timer;
  bool _loading = false;
  bool _deleting = false;
  final Set<int> _selected = {};
  bool get _canDelete =>
      ref.watch(loginStateProvider).role == UserRole.companyAdmin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final customers = await SubscriptionService(
        dio: ref.read(apiClientProvider).dio,
      ).getCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _selected.removeWhere((id) => !customers.any((c) => c['id'] == id));
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _loading = false;
    }
  }

  Future<void> _delete(List<int> ids) async {
    if (_deleting || ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          ids.length == 1
              ? 'Delete customer?'
              : 'Delete ${ids.length} customers?',
        ),
        content: const Text(
          'Lead and billing history will be retained. Active subscriptions and unresolved checkouts must be resolved first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final service = SubscriptionService(dio: ref.read(apiClientProvider).dio);
      if (ids.length == 1) {
        await service.deleteCustomer(ids.first);
      } else {
        await service.deleteCustomers(ids);
      }
      if (mounted) {
        setState(() => _selected.clear());
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Customers'),
      actions: [
        if (_canDelete && _selected.isNotEmpty)
          IconButton(
            tooltip: 'Delete selected (${_selected.length})',
            onPressed: _deleting ? null : () => _delete(_selected.toList()),
            icon: const Icon(Icons.delete_outline),
          ),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_canDelete && _customers?.isNotEmpty == true)
            CheckboxListTile(
              title: Text('${_selected.length} selected'),
              subtitle: const Text('Select up to 100 customers'),
              value: _customers!.every((c) => _selected.contains(c['id'])),
              onChanged: _deleting || _customers!.length > 100
                  ? null
                  : (value) => setState(() {
                      _selected.clear();
                      if (value == true) {
                        _selected.addAll(
                          _customers!.map((c) => c['id'] as int),
                        );
                      }
                    }),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_customers == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_customers?.isEmpty == true)
            const Text('No converted customers yet.'),
          ...?_customers?.map((customer) {
            final active = customer['status'] == 'ACTIVE';
            final isPending =
                customer['subscriptionStatus'] == 'PENDING_ACTIVATION';
            final statusLabel = active
                ? 'Active'
                : (isPending ? 'Pending Activation' : 'Inactive');
            final statusColor = active
                ? Colors.green.shade700
                : (isPending ? Colors.amber.shade800 : Colors.grey.shade700);
            final actDate = customer['activationDate']?.toString();
            final actInfo = (isPending && actDate != null && actDate.isNotEmpty)
                ? ' • Activates: ${actDate.split('T').first}'
                : '';
            return Card(
              child: ListTile(
                leading: _canDelete
                    ? Checkbox(
                        value: _selected.contains(customer['id']),
                        onChanged:
                            _deleting ||
                                (!_selected.contains(customer['id']) &&
                                    _selected.length >= 100)
                            ? null
                            : (value) => setState(() {
                                if (value == true) {
                                  _selected.add(customer['id'] as int);
                                } else {
                                  _selected.remove(customer['id']);
                                }
                              }),
                      )
                    : null,
                title: Text(customer['companyName']?.toString() ?? 'Customer'),
                subtitle: Text(
                  '$statusLabel • ${customer['planName'] ?? 'No active plan'}$actInfo',
                  style: TextStyle(color: statusColor),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_canDelete)
                      IconButton(
                        tooltip: 'Delete customer',
                        onPressed: _deleting
                            ? null
                            : () => _delete([customer['id'] as int]),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    if (ref
                        .watch(permissionManagerProvider)
                        .canCreate(AppModule.payments))
                      const Icon(Icons.chevron_right),
                  ],
                ),
                onTap:
                    !ref
                        .watch(permissionManagerProvider)
                        .canCreate(AppModule.payments)
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerPlansView(
                              customerId: customer['id'] as int,
                            ),
                          ),
                        );
                        await _load();
                      },
              ),
            );
          }),
        ],
      ),
    ),
  );
}
