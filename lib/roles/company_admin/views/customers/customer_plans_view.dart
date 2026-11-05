import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/services/subscription_service.dart';

class CustomerPlansView extends ConsumerStatefulWidget {
  final int customerId;
  const CustomerPlansView({super.key, required this.customerId});
  @override
  ConsumerState<CustomerPlansView> createState() => _CustomerPlansViewState();
}

class _CustomerPlansViewState extends ConsumerState<CustomerPlansView> {
  late final Razorpay _razorpay;
  List<Map<String, dynamic>>? _plans;
  String _cycle = 'MONTHLY';
  String? _message;
  bool _busy = false;
  Map<String, dynamic>? _order;
  String? _storageKey;
  SubscriptionService get _service =>
      SubscriptionService(dio: ref.read(apiClientProvider).dio);
  String _money(dynamic paise) =>
      '₹${((paise as num) / 100).toStringAsFixed(2)}';
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _success);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message =
              'Payment was unsuccessful or closed. Retry safely with the same order.';
        });
      }
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final plans = await _service.getPlans();
      if (mounted) setState(() => _plans = plans);
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _success(PaymentSuccessResponse response) async {
    try {
      await _service.verifyPayment({
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'planId': _order!['planId'],
        'billingCycle': _order!['billingCycle'],
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey!);
      if (mounted) {
        setState(() {
          _busy = false;
          _message =
              'Payment verified! Subscription is pending activation (scheduled in 2 days).';
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message =
              'Payment confirmation pending: $e. Customer status will refresh from the backend.';
        });
      }
    }
  }

  Future<void> _purchase(Map<String, dynamic> plan) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'qb-checkout:${widget.customerId}:${plan['id']}:$_cycle';
      final requestKey =
          prefs.getString(key) ??
          List.generate(
            32,
            (_) =>
                Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
          ).join();
      await prefs.setString(key, requestKey);
      final order = await _service.purchaseSubscription(
        plan['id'] as int,
        customerId: widget.customerId,
        billingCycle: _cycle,
        idempotencyKey: requestKey,
      );
      if (!mounted) return;
      if (order['status'] == 'PAID') {
        await prefs.remove(key);
        setState(() {
          _busy = false;
          _message = 'This purchase is already paid.';
        });
        return;
      }
      _order = order;
      _storageKey = key;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${plan['name']} · $_cycle'),
          content: _breakdown(order),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Pay ${_money(order['totalPaise'])}'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      _razorpay.open({
        'key': order['keyId'],
        'amount': order['totalPaise'],
        'currency': 'INR',
        'order_id': order['orderId'],
        'name': 'Quickboom',
        'description': plan['name'],
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = e.toString();
        });
      }
    }
  }

  Widget _breakdown(Map<String, dynamic> price) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Base: ${_money(price['basePaise'])}'),
      if ((price['discountPaise'] as num) > 0)
        Text(
          'Save ${(price['yearlyDiscountBps'] as num) / 100}%: −${_money(price['discountPaise'])}',
          style: const TextStyle(color: Colors.green),
        ),
      Text('Taxable: ${_money(price['taxablePaise'])}'),
      Text(
        'GST ${(price['taxRateBps'] as num) / 100}%: ${_money(price['gstPaise'])}',
      ),
      Text(
        'Total payable: ${_money(price['totalPaise'])}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Subscription plans')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'MONTHLY', label: Text('Monthly')),
            ButtonSegment(value: 'YEARLY', label: Text('Yearly')),
          ],
          selected: {_cycle},
          onSelectionChanged: _busy
              ? null
              : (value) => setState(() => _cycle = value.first),
        ),
        if (_message != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(_message!)),
        if (_plans == null && _message == null)
          const Center(child: CircularProgressIndicator()),
        ...?_plans?.where((p) => (p['pricing'] as Map).containsKey(_cycle)).map((
          plan,
        ) {
          final price = Map<String, dynamic>.from(
            plan['pricing'][_cycle] as Map,
          );
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan['isRecommended'] == true)
                    const Chip(
                      label: Text('Most Popular'),
                      backgroundColor: Color(0xFFD1FAE5),
                    ),
                  Text(
                    plan['name'].toString(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(plan['subtitle']?.toString() ?? ''),
                  const SizedBox(height: 12),
                  Text(
                    '${_money(price['taxablePaise'])}/${_cycle == 'YEARLY' ? 'year' : 'month'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _breakdown(price),
                  const SizedBox(height: 12),
                  ...(plan['features'] as List).map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('✓ $f'),
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : () => _purchase(plan),
                    child: const Text('Purchase Now'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}
