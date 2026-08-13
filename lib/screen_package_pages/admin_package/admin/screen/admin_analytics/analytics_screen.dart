// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool loading = true;
  bool refreshing = false;
  String? error;

  Map<String, dynamic> analytics = {};

  List packages = [];
  List riders = [];
  List customers = [];
  List withdrawals = [];
  List wallets = [];

  String range = '30D';

  // ============================================================
  // SENMI DARK THEME
  // ============================================================

  static const Color background = Color(0xff080B10);
  static const Color surface = Color(0xff11161D);
  static const Color surface3 = Color(0xff1A2029);
  static const Color border = Color(0xff252D38);

  static const Color primary = Color(0xff7C5CFF);
  static const Color blue = Color(0xff4C8DFF);
  static const Color green = Color(0xff2DD881);
  static const Color orange = Color(0xffffa726);
  static const Color red = Color(0xffff5c68);
  static const Color cyan = Color(0xff27C7D9);
  static const Color yellow = Color(0xffffd54f);

  static const Color textPrimary = Color(0xffF5F7FA);
  static const Color textSecondary = Color(0xff8D98A8);
  static const Color textMuted = Color(0xff626C7A);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    load();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> load() async {
    if (mounted) {
      setState(() {
        if (loading) {
          error = null;
        } else {
          refreshing = true;
        }
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getAdminAnalytics(),
        ApiService.getAdminPackages(),
        ApiService.getRiders(),
        ApiService.getCustomers(),
        ApiService.getAdminWithdrawals(),
        ApiService.getAdminRiderWallets(),
      ]);

      if (!mounted) return;

      setState(() {
        analytics = Map<String, dynamic>.from(results[0] as Map);

        packages = List.from(results[1] as List);
        riders = List.from(results[2] as List);
        customers = List.from(results[3] as List);
        withdrawals = List.from(results[4] as List);
        wallets = List.from(results[5] as List);

        loading = false;
        refreshing = false;
        error = null;
      });
    } catch (e) {
      debugPrint('Analytics load error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
        error = e.toString();
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double d(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int i(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String money(double value) {
    return '₦${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},')}';
  }

  // ============================================================
  // TREND
  // ============================================================

  List<Map<String, dynamic>> _trendPackages() {
    final now = DateTime.now();

    final int days = range == '7D'
        ? 7
        : range == '90D'
        ? 90
        : 30;

    final List<Map<String, dynamic>> output = List.generate(
      days,
      (_) => <String, dynamic>{'count': 0, 'revenue': 0.0},
    );

    for (final package in packages) {
      final rawDate = package['created_at'] ?? package['date'];

      final date = DateTime.tryParse(rawDate?.toString() ?? '');

      if (date == null) continue;

      final today = DateTime(now.year, now.month, now.day);

      final packageDate = DateTime(date.year, date.month, date.day);

      final diff = today.difference(packageDate).inDays;

      if (diff >= 0 && diff < days) {
        final index = days - 1 - diff;

        output[index]['count'] = (output[index]['count'] as int) + 1;

        output[index]['revenue'] =
            (output[index]['revenue'] as double) + d(package['price']);
      }
    }

    return output;
  }

  // ============================================================
  // STATUS
  // ============================================================

  Map<String, int> statusCounts() {
    final Map<String, int> map = {};

    for (final package in packages) {
      final status = (package['status'] ?? 'unknown').toString().toLowerCase();

      map[status] = (map[status] ?? 0) + 1;
    }

    return map;
  }

  // ============================================================
  // FINANCIAL
  // ============================================================

  double get totalRevenue {
    final apiValue = analytics['total_revenue'] ?? analytics['revenue'];

    if (apiValue != null) {
      return d(apiValue);
    }

    double total = 0;

    for (final package in packages) {
      total += d(package['price']);
    }

    return total;
  }

  double get totalCommission {
    final apiValue = analytics['total_commission'] ?? analytics['commission'];

    if (apiValue != null) {
      return d(apiValue);
    }

    double total = 0;

    for (final package in packages) {
      total += d(package['commission'] ?? package['service_fee']);
    }

    return total;
  }

  double get riderEarnings {
    final apiValue =
        analytics['rider_earnings'] ?? analytics['total_rider_earnings'];

    if (apiValue != null) {
      return d(apiValue);
    }

    double total = 0;

    for (final package in packages) {
      total += d(package['rider_earning']);
    }

    return total;
  }

  // ============================================================
  // DELIVERY
  // ============================================================

  int get completed {
    final apiValue =
        analytics['completed_deliveries'] ?? analytics['completed_packages'];

    if (apiValue != null) {
      return i(apiValue);
    }

    return statusCounts()['delivered'] ?? 0;
  }

  int get cancelled {
    return statusCounts()['cancelled'] ?? 0;
  }

  int get pending {
    return statusCounts()['pending'] ?? 0;
  }

  int get active {
    return (statusCounts()['accepted'] ?? 0) +
        (statusCounts()['picked_up'] ?? 0);
  }

  // ============================================================
  // EXTRA METRICS
  // ============================================================

  double get avgOrderValue {
    if (packages.isEmpty) return 0;

    double total = 0;

    for (final package in packages) {
      total += d(package['price']);
    }

    return total / packages.length;
  }

  double get walletBalance {
    double total = 0;

    for (final wallet in wallets) {
      total += d(wallet['balance']);
    }

    return total;
  }

  double get payoutTotal {
    double total = 0;

    for (final withdrawal in withdrawals) {
      final status = (withdrawal['status'] ?? '').toString().toLowerCase();

      if (status == 'success' ||
          status == 'processing' ||
          status == 'approved') {
        total += d(withdrawal['amount']);
      }
    }

    return total;
  }

  double get completionRate {
    if (packages.isEmpty) return 0;

    return completed / packages.length * 100;
  }

  double get cancellationRate {
    if (packages.isEmpty) return 0;

    return cancelled / packages.length * 100;
  }

  double get revenuePerDelivery {
    if (completed == 0) return 0;

    return totalRevenue / completed;
  }

  int get pendingWithdrawals {
    return withdrawals.where((withdrawal) {
      return (withdrawal['status'] ?? '').toString().toLowerCase() == 'pending';
    }).length;
  }

  double get riderPerCustomer {
    if (customers.isEmpty) return 0;

    return riders.length / customers.length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,

        title: const Text(
          'Analytics',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),

        iconTheme: const IconThemeData(color: textPrimary),

        actions: [
          if (refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
              ),
            ),

          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: refreshing ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              backgroundColor: surface,
              onRefresh: load,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),

                children: [
                  _header(),

                  const SizedBox(height: 20),

                  if (error != null) _error(),

                  _sectionTitle(
                    'Financial performance',
                    'Your platform revenue at a glance',
                  ),

                  const SizedBox(height: 11),

                  _financialCards(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Delivery activity',
                    'Track package movement over time',
                  ),

                  const SizedBox(height: 11),

                  _rangeSelector(),

                  const SizedBox(height: 11),

                  _chartCard(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Delivery status',
                    'Live distribution of your packages',
                  ),

                  const SizedBox(height: 11),

                  _statusCard(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Platform health',
                    'Users, wallets and payout activity',
                  ),

                  const SizedBox(height: 11),

                  _healthCard(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Performance metrics',
                    'Important operating ratios',
                  ),

                  const SizedBox(height: 11),

                  _metricGrid(),

                  const SizedBox(height: 24),

                  _sectionTitle(
                    'Business insights',
                    'Automatic observations from your data',
                  ),

                  const SizedBox(height: 11),

                  _insightsCard(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [Color(0xff18152D), Color(0xff111827), Color(0xff11161D)],
        ),

        border: Border.all(color: primary.withOpacity(.20)),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.06),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),

                      decoration: BoxDecoration(
                        color: primary.withOpacity(.13),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: const Icon(
                        Icons.insights_rounded,
                        color: primary,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Text(
                      'Senmi Analytics',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                const Text(
                  'Your operations command center.',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Monitor revenue, deliveries, riders and payouts from one place.',
                  style: TextStyle(
                    color: textSecondary,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    _miniHeaderStat(
                      'Packages',
                      packages.length.toString(),
                      primary,
                    ),

                    const SizedBox(width: 18),

                    _miniHeaderStat('Delivered', completed.toString(), green),

                    const SizedBox(width: 18),

                    _miniHeaderStat('Active', active.toString(), orange),
                  ],
                ),
              ],
            ),
          ),

          if (refreshing)
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: CircularProgressIndicator(color: primary, strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _miniHeaderStat(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(title, style: const TextStyle(color: textMuted, fontSize: 9)),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _error() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: red.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: red.withOpacity(.15)),
      ),

      child: const Row(
        children: [
          Icon(Icons.error_outline_rounded, color: red),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Some analytics data could not be loaded. Pull down to retry.',
              style: TextStyle(color: textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,

      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FINANCIAL CARDS
  // ============================================================

  Widget _financialCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 11,
      mainAxisSpacing: 11,

      // FIX:
      // Slightly taller cards to prevent the
      // 0.511px RenderFlex overflow.
      childAspectRatio: 1.42,

      children: [
        _financialCard(
          'Revenue',
          money(totalRevenue),
          Icons.payments_rounded,
          green,
          '+ platform volume',
        ),

        _financialCard(
          'Commission',
          money(totalCommission),
          Icons.account_balance_rounded,
          primary,
          'Senmi earnings',
        ),

        _financialCard(
          'Rider earnings',
          money(riderEarnings),
          Icons.delivery_dining_rounded,
          blue,
          'Rider share',
        ),

        _financialCard(
          'Payouts',
          money(payoutTotal),
          Icons.outbound_rounded,
          orange,
          'Processed payouts',
        ),
      ],
    );
  }

  Widget _financialCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String caption,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(19),

        border: Border.all(color: border),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [surface, Color.lerp(surface, color, .035)!],
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),

                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(icon, color: color, size: 18),
              ),

              const Spacer(),

              Container(
                width: 6,
                height: 6,

                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),

          const Spacer(),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(color: textSecondary, fontSize: 11),
          ),

          const SizedBox(height: 3),

          // FIX:
          // Flexible prevents the FittedBox/Text from
          // demanding more vertical space than the card has.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,

              child: Text(
                value,
                maxLines: 1,

                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: color.withOpacity(.75),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RANGE
  // ============================================================

  Widget _rangeSelector() {
    return Row(
      children: [
        for (final value in ['7D', '30D', '90D'])
          Padding(
            padding: const EdgeInsets.only(right: 8),

            child: GestureDetector(
              onTap: () {
                setState(() {
                  range = value;
                });
              },

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),

                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),

                decoration: BoxDecoration(
                  color: range == value ? primary : surface,

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: range == value ? primary : border),

                  boxShadow: range == value
                      ? [
                          BoxShadow(
                            color: primary.withOpacity(.18),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),

                child: Text(
                  value,

                  style: TextStyle(
                    color: range == value ? Colors.white : textSecondary,

                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CHART
  // ============================================================

  Widget _chartCard() {
    final trend = _trendPackages();

    final values = trend.map<double>((item) => d(item['count'])).toList();

    final maxValue = values.isEmpty
        ? 1.0
        : math.max(1.0, values.reduce((a, b) => math.max(a, b))).toDouble();

    final totalInRange = values.fold<double>(0, (sum, value) => sum + value);

    return Container(
      height: 285,

      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),

        border: Border.all(color: border),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: const Icon(
                  Icons.show_chart_rounded,
                  color: primary,
                  size: 18,
                ),
              ),

              const SizedBox(width: 9),

              const Text(
                'Packages per day',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

                decoration: BoxDecoration(
                  color: surface3,
                  borderRadius: BorderRadius.circular(8),
                ),

                child: Text(
                  '${totalInRange.round()} packages',

                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(values: values, max: maxValue),

              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _statusCard() {
    final statuses = statusCounts();

    const order = [
      'pending',
      'paid',
      'accepted',
      'picked_up',
      'delivered',
      'cancelled',
    ];

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),

        border: Border.all(color: border),
      ),

      child: Column(
        children: [
          Row(
            children: [
              _statusSummary('Completed', completed, green),

              const SizedBox(width: 10),

              _statusSummary('Active', active, primary),

              const SizedBox(width: 10),

              _statusSummary('Pending', pending, orange),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(color: border, height: 1),

          const SizedBox(height: 18),

          ...order.map((status) {
            final value = statuses[status] ?? 0;

            final ratio = packages.isEmpty ? 0.0 : value / packages.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),

              child: _statusRow(status, value, ratio),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusSummary(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),

        decoration: BoxDecoration(
          color: color.withOpacity(.06),

          borderRadius: BorderRadius.circular(13),

          border: Border.all(color: color.withOpacity(.10)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              '$value',

              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,

              style: const TextStyle(color: textSecondary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String status, int value, double ratio) {
    final color = _statusColor(status);

    final safeRatio = ratio.clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,

              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                status.replaceAll('_', ' ').toUpperCase(),

                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Text(
              '$value',

              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),

            const SizedBox(width: 8),

            Text(
              '${(ratio * 100).toStringAsFixed(1)}%',

              style: const TextStyle(color: textSecondary, fontSize: 10),
            ),
          ],
        ),

        const SizedBox(height: 7),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),

          child: LinearProgressIndicator(
            minHeight: 6,

            value: safeRatio,

            backgroundColor: color.withOpacity(.07),

            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLATFORM HEALTH
  // ============================================================

  Widget _healthCard() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),

        border: Border.all(color: border),
      ),

      child: Column(
        children: [
          _healthRow(
            'Customers',
            customers.length,
            Icons.people_alt_rounded,
            blue,
          ),

          _healthRow(
            'Riders',
            riders.length,
            Icons.delivery_dining_rounded,
            primary,
          ),

          _healthRow(
            'Wallets',
            wallets.length,
            Icons.account_balance_wallet_rounded,
            cyan,
          ),

          _healthRow(
            'Pending withdrawals',
            pendingWithdrawals,
            Icons.pending_actions_rounded,
            orange,
          ),

          _healthRow(
            'Wallet balance',
            money(walletBalance),
            Icons.account_balance_rounded,
            green,
          ),

          _healthRow(
            'Total payouts',
            money(payoutTotal),
            Icons.outbound_rounded,
            yellow,
          ),
        ],
      ),
    );
  }

  Widget _healthRow(String title, dynamic value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color: color.withOpacity(.10),

              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(icon, color: color, size: 17),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              title,

              style: const TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),

          Text(
            value.toString(),

            style: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // METRICS
  // ============================================================

  Widget _metricGrid() {
    return GridView.count(
      crossAxisCount: 2,

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 11,
      mainAxisSpacing: 11,

      childAspectRatio: 1.45,

      children: [
        _metric(
          'Completion rate',
          '${completionRate.toStringAsFixed(1)}%',
          green,
          Icons.task_alt_rounded,
        ),

        _metric(
          'Cancellation rate',
          '${cancellationRate.toStringAsFixed(1)}%',
          red,
          Icons.cancel_outlined,
        ),

        _metric(
          'Average order',
          money(avgOrderValue),
          blue,
          Icons.receipt_long_rounded,
        ),

        _metric(
          'Revenue / delivery',
          money(revenuePerDelivery),
          primary,
          Icons.trending_up_rounded,
        ),

        _metric(
          'Active deliveries',
          '$active',
          orange,
          Icons.local_shipping_outlined,
        ),

        _metric(
          'Riders / customer',
          riderPerCustomer.toStringAsFixed(2),
          cyan,
          Icons.groups_rounded,
        ),
      ],
    );
  }

  Widget _metric(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),

                decoration: BoxDecoration(
                  color: color.withOpacity(.08),

                  borderRadius: BorderRadius.circular(9),
                ),

                child: Icon(icon, color: color, size: 17),
              ),

              const Spacer(),

              Container(
                width: 6,
                height: 6,

                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),

          const Spacer(),

          Text(
            title,

            style: const TextStyle(color: textSecondary, fontSize: 11),
          ),

          const SizedBox(height: 5),

          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,

              child: Text(
                value,

                style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUSINESS INSIGHTS
  // ============================================================

  Widget _insightsCard() {
    final insights = <Map<String, dynamic>>[];

    if (packages.isEmpty) {
      insights.add({
        'icon': Icons.info_outline_rounded,
        'color': blue,
        'title': 'Waiting for activity',
        'message':
            'Once packages start coming in, Senmi will show operational insights here.',
      });
    } else {
      // Completion
      if (completionRate >= 80) {
        insights.add({
          'icon': Icons.verified_rounded,
          'color': green,
          'title': 'Excellent completion rate',
          'message':
              'Your delivery completion rate is ${completionRate.toStringAsFixed(1)}%. Operations are performing strongly.',
        });
      } else if (completionRate >= 50) {
        insights.add({
          'icon': Icons.trending_up_rounded,
          'color': orange,
          'title': 'Completion could improve',
          'message':
              'Your completion rate is ${completionRate.toStringAsFixed(1)}%. There may be opportunities to reduce delivery failures.',
        });
      } else {
        insights.add({
          'icon': Icons.warning_amber_rounded,
          'color': red,
          'title': 'Low completion rate',
          'message':
              'Only ${completionRate.toStringAsFixed(1)}% of packages are completed. Review rider availability and delivery issues.',
        });
      }

      // Cancellation
      if (cancellationRate > 15) {
        insights.add({
          'icon': Icons.warning_rounded,
          'color': red,
          'title': 'Cancellation attention needed',
          'message':
              'Cancellation rate is ${cancellationRate.toStringAsFixed(1)}%. Consider investigating the reasons behind cancelled deliveries.',
        });
      } else {
        insights.add({
          'icon': Icons.check_circle_outline_rounded,
          'color': green,
          'title': 'Cancellation rate looks healthy',
          'message':
              'Only ${cancellationRate.toStringAsFixed(1)}% of packages are cancelled.',
        });
      }

      // Pending packages
      if (pending > active) {
        insights.add({
          'icon': Icons.schedule_rounded,
          'color': orange,
          'title': 'Packages waiting for riders',
          'message':
              '$pending packages are pending while $active deliveries are currently active.',
        });
      }

      // Withdrawals
      if (pendingWithdrawals > 0) {
        insights.add({
          'icon': Icons.account_balance_wallet_outlined,
          'color': orange,
          'title': 'Withdrawals need attention',
          'message':
              '$pendingWithdrawals rider withdrawal request(s) are currently pending.',
        });
      }

      // Wallet
      if (walletBalance > 0) {
        insights.add({
          'icon': Icons.account_balance_rounded,
          'color': cyan,
          'title': 'Rider wallet exposure',
          'message':
              '${money(walletBalance)} is currently sitting across rider wallets.',
        });
      }

      // Rider ratio
      if (customers.isNotEmpty && riderPerCustomer < .10) {
        insights.add({
          'icon': Icons.people_outline_rounded,
          'color': orange,
          'title': 'Rider coverage is low',
          'message':
              'There are approximately ${riderPerCustomer.toStringAsFixed(2)} riders per customer. Consider growing your rider network as demand increases.',
        });
      }

      // Revenue
      if (totalRevenue > 0 && totalCommission > 0) {
        final commissionRate = totalCommission / totalRevenue * 100;

        insights.add({
          'icon': Icons.auto_graph_rounded,
          'color': primary,
          'title': 'Platform commission',
          'message':
              'Senmi is currently generating approximately ${commissionRate.toStringAsFixed(1)}% of total package value as commission.',
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: surface,

        borderRadius: BorderRadius.circular(21),

        border: Border.all(color: border),
      ),

      child: Column(
        children: [
          ...insights.asMap().entries.map((entry) {
            final index = entry.key;
            final insight = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == insights.length - 1 ? 0 : 15,
              ),

              child: _insightRow(insight),
            );
          }),
        ],
      ),
    );
  }

  Widget _insightRow(Map<String, dynamic> insight) {
    final color = insight['color'] as Color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          padding: const EdgeInsets.all(9),

          decoration: BoxDecoration(
            color: color.withOpacity(.10),

            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(insight['icon'] as IconData, color: color, size: 19),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                insight['title'].toString(),

                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                insight['message'].toString(),

                style: const TextStyle(
                  color: textSecondary,
                  height: 1.4,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return green;

      case 'cancelled':
        return red;

      case 'pending':
        return orange;

      case 'paid':
        return blue;

      case 'accepted':
      case 'picked_up':
        return primary;

      default:
        return textSecondary;
    }
  }
}

// ================================================================
// LINE CHART PAINTER
// ================================================================

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double max;

  _LineChartPainter({required this.values, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    // ============================================================
    // GRID
    // ============================================================

    final grid = Paint()
      ..color = _AnalyticsScreenState.border
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3.0;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.isEmpty) {
      return;
    }

    // ============================================================
    // LINE
    // ============================================================

    final line = Paint()
      ..color = _AnalyticsScreenState.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ============================================================
    // AREA
    // ============================================================

    final fill = Paint()
      ..color = _AnalyticsScreenState.primary.withOpacity(.09)
      ..style = PaintingStyle.fill;

    final path = Path();
    final area = Path();

    // ============================================================
    // POINTS
    // ============================================================

    for (int index = 0; index < values.length; index++) {
      final double x;

      if (values.length == 1) {
        x = size.width / 2;
      } else {
        x = index * size.width / (values.length - 1);
      }

      final normalized = (values[index] / max).clamp(0.0, 1.0).toDouble();

      final y = size.height - (normalized * size.height * .85) - 5;

      if (index == 0) {
        path.moveTo(x, y);

        area.moveTo(x, size.height);

        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }

    // ============================================================
    // CLOSE AREA
    // ============================================================

    final lastX = values.length == 1 ? size.width / 2 : size.width;

    area.lineTo(lastX, size.height);

    area.close();

    // ============================================================
    // DRAW AREA
    // ============================================================

    canvas.drawPath(area, fill);

    // ============================================================
    // DRAW LINE
    // ============================================================

    canvas.drawPath(path, line);

    // ============================================================
    // DOTS
    // ============================================================

    final dot = Paint()..color = _AnalyticsScreenState.primary;

    final glow = Paint()
      ..color = _AnalyticsScreenState.primary.withOpacity(.12);

    for (int index = 0; index < values.length; index++) {
      final double x;

      if (values.length == 1) {
        x = size.width / 2;
      } else {
        x = index * size.width / (values.length - 1);
      }

      final normalized = (values[index] / max).clamp(0.0, 1.0).toDouble();

      final y = size.height - (normalized * size.height * .85) - 5;

      if (index == values.length - 1 || values.length <= 14) {
        canvas.drawCircle(Offset(x, y), 7, glow);

        canvas.drawCircle(Offset(x, y), 3.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.max != max;
  }
}
