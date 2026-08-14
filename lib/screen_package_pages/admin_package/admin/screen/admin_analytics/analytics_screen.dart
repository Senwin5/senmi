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
  // COLORS
  // ============================================================

  static const Color background = Color(0xff070A0F);
  static const Color surface = Color(0xff10151C);
  static const Color surface2 = Color(0xff151B23);
  static const Color surface3 = Color(0xff1B222C);
  static const Color border = Color(0xff252D38);

  static const Color primary = Color(0xff8065FF);
  static const Color blue = Color(0xff4C8DFF);
  static const Color green = Color(0xff2DD881);
  static const Color orange = Color(0xffffa726);
  static const Color red = Color(0xffff5c68);
  static const Color cyan = Color(0xff27C7D9);
  static const Color yellow = Color(0xffffd54f);

  static const Color textPrimary = Color(0xffF5F7FA);
  static const Color textSecondary = Color(0xff929DAC);
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
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int i(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String money(double value) {
    return '₦${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},')}';
  }

  // ============================================================
  // TREND
  // ============================================================

  List<Map<String, dynamic>> trendPackages() {
    final now = DateTime.now();

    final int days = range == '7D'
        ? 7
        : range == '90D'
        ? 90
        : 30;

    final output = List.generate(
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

    if (apiValue != null) return d(apiValue);

    double total = 0;

    for (final package in packages) {
      total += d(package['price']);
    }

    return total;
  }

  double get totalCommission {
    final apiValue = analytics['total_commission'] ?? analytics['commission'];

    if (apiValue != null) return d(apiValue);

    double total = 0;

    for (final package in packages) {
      total += d(package['commission'] ?? package['service_fee']);
    }

    return total;
  }

  double get riderEarnings {
    final apiValue =
        analytics['rider_earnings'] ?? analytics['total_rider_earnings'];

    if (apiValue != null) return d(apiValue);

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

    if (apiValue != null) return i(apiValue);

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
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 21,
              ),
            ),
            Text(
              'Senmi command center',
              style: TextStyle(color: textMuted, fontSize: 10),
            ),
          ],
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
            tooltip: 'Refresh',
            onPressed: refreshing ? null : load,
            icon: const Icon(Icons.refresh_rounded),
          ),

          const SizedBox(width: 5),
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

                padding: const EdgeInsets.fromLTRB(16, 8, 16, 50),

                children: [
                  _hero(),

                  const SizedBox(height: 22),

                  if (error != null) _error(),

                  _sectionHeader(
                    'Financial overview',
                    'Money moving through your platform',
                    onTap: () {
                      _openDetails(AnalyticsDetailsType.financial);
                    },
                  ),

                  const SizedBox(height: 11),

                  _financialCards(),

                  const SizedBox(height: 25),

                  _sectionHeader(
                    'Delivery analytics',
                    'Monitor package activity and growth',
                    onTap: () {
                      _openDetails(AnalyticsDetailsType.delivery);
                    },
                  ),

                  const SizedBox(height: 11),

                  _rangeSelector(),

                  const SizedBox(height: 11),

                  _chartCard(),

                  const SizedBox(height: 25),

                  _sectionHeader(
                    'Daily operations',
                    'See exactly how many packages you handle and deliver each day',
                  ),

                  const SizedBox(height: 11),

                  _dailyOperationsCard(),

                  const SizedBox(height: 25),

                  _sectionHeader(
                    'Delivery status',
                    'Current package distribution',
                  ),

                  const SizedBox(height: 11),

                  _statusCard(),

                  const SizedBox(height: 25),

                  _sectionHeader(
                    'Platform health',
                    'Users, wallets and withdrawals',
                    onTap: () {
                      _openDetails(AnalyticsDetailsType.platform);
                    },
                  ),

                  const SizedBox(height: 11),

                  _healthCard(),

                  const SizedBox(height: 25),

                  _sectionHeader(
                    'Performance',
                    'Important operating ratios',
                    onTap: () {
                      _openDetails(AnalyticsDetailsType.performance);
                    },
                  ),

                  const SizedBox(height: 11),

                  _metricGrid(),

                  const SizedBox(height: 25),

                  _sectionHeader(
                    'Business insights',
                    'Automatic observations from your data',
                  ),

                  const SizedBox(height: 11),

                  _insightsCard(),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [Color(0xff19152E), Color(0xff111827), Color(0xff10151C)],
        ),

        border: Border.all(color: primary.withOpacity(.20)),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.07),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: primary.withOpacity(.13),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.insights_rounded,
                  color: primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senmi Analytics',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your operations command center',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

                decoration: BoxDecoration(
                  color: green.withOpacity(.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: green.withOpacity(.16)),
                ),

                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: green),
                    SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: green,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            money(totalRevenue),
            style: const TextStyle(
              color: textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Total platform volume',
            style: TextStyle(color: textSecondary, fontSize: 11),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              _heroStat('Packages', packages.length.toString(), primary),

              _heroDivider(),

              _heroStat('Delivered', completed.toString(), green),

              _heroDivider(),

              _heroStat('Active', active.toString(), orange),

              _heroDivider(),

              _heroStat('Customers', customers.length.toString(), blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String title, String value, Color color) {
    return Expanded(
      child: Column(
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
          const SizedBox(height: 3),
          Text(title, style: const TextStyle(color: textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(
      width: 1,
      height: 27,
      margin: const EdgeInsets.symmetric(horizontal: 7),
      color: border,
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
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader(String title, String subtitle, {VoidCallback? onTap}) {
    return Row(
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
                style: const TextStyle(color: textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),

        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: const Row(
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textMuted,
                    size: 9,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // FINANCIAL
  // ============================================================

  Widget _financialCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 11,
      mainAxisSpacing: 11,

      childAspectRatio: 1.42,

      children: [
        _financialCard(
          'Revenue',
          money(totalRevenue),
          Icons.payments_rounded,
          green,
          'Platform volume',
          () => _openDetails(AnalyticsDetailsType.financial),
        ),
        _financialCard(
          'Commission',
          money(totalCommission),
          Icons.account_balance_rounded,
          primary,
          'Senmi earnings',
          () => _openDetails(AnalyticsDetailsType.financial),
        ),
        _financialCard(
          'Rider earnings',
          money(riderEarnings),
          Icons.delivery_dining_rounded,
          blue,
          'Rider share',
          () => _openDetails(AnalyticsDetailsType.financial),
        ),
        _financialCard(
          'Payouts',
          money(payoutTotal),
          Icons.outbound_rounded,
          orange,
          'Processed',
          () => _openDetails(AnalyticsDetailsType.financial),
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
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
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
                Icon(Icons.arrow_outward_rounded, color: textMuted, size: 14),
              ],
            ),

            const Spacer(),

            Text(
              title,
              style: const TextStyle(color: textSecondary, fontSize: 11),
            ),

            const SizedBox(height: 4),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 3),

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
    final trend = trendPackages();

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
  // HEALTH
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
  // INSIGHTS
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

      if (pending > active) {
        insights.add({
          'icon': Icons.schedule_rounded,
          'color': orange,
          'title': 'Packages waiting for riders',
          'message':
              '$pending packages are pending while $active deliveries are currently active.',
        });
      }

      if (pendingWithdrawals > 0) {
        insights.add({
          'icon': Icons.account_balance_wallet_outlined,
          'color': orange,
          'title': 'Withdrawals need attention',
          'message':
              '$pendingWithdrawals rider withdrawal request(s) are currently pending.',
        });
      }

      if (walletBalance > 0) {
        insights.add({
          'icon': Icons.account_balance_rounded,
          'color': cyan,
          'title': 'Rider wallet balance',
          'message':
              '${money(walletBalance)} is currently sitting across rider wallets.',
        });
      }

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
  // DAILY OPERATIONS
  // ============================================================

  List<Map<String, dynamic>> dailyOperations() {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final package in packages) {
      final rawDate =
          package['delivered_at'] ?? package['created_at'] ?? package['date'];

      final parsed = DateTime.tryParse(rawDate?.toString() ?? '');

      if (parsed == null) continue;

      final date = DateTime(
        parsed.toLocal().year,
        parsed.toLocal().month,
        parsed.toLocal().day,
      );

      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(
        key,
        () => {
          'date': key,
          'packages': 0,
          'delivered': 0,
          'active': 0,
          'pending': 0,
          'cancelled': 0,
          'revenue': 0.0,
          'commission': 0.0,
          'rider_earnings': 0.0,
        },
      );

      final day = grouped[key]!;

      day['packages'] = (day['packages'] as int) + 1;

      final status = (package['status'] ?? 'unknown').toString().toLowerCase();

      if (status == 'delivered') {
        day['delivered'] = (day['delivered'] as int) + 1;
      }

      if (status == 'accepted' || status == 'picked_up') {
        day['active'] = (day['active'] as int) + 1;
      }

      if (status == 'pending') {
        day['pending'] = (day['pending'] as int) + 1;
      }

      if (status == 'cancelled') {
        day['cancelled'] = (day['cancelled'] as int) + 1;
      }

      day['revenue'] = (day['revenue'] as double) + d(package['price']);

      day['commission'] =
          (day['commission'] as double) +
          d(package['commission'] ?? package['service_fee']);

      day['rider_earnings'] =
          (day['rider_earnings'] as double) + d(package['rider_earning']);
    }

    final result = grouped.values.toList();

    result.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    return result;
  }

  Map<String, dynamic> get todayOperations {
    final today = DateTime.now();

    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final operations = dailyOperations();

    for (final day in operations) {
      if (day['date'].toString() == key) {
        return day;
      }
    }

    return {
      'date': key,
      'packages': 0,
      'delivered': 0,
      'active': 0,
      'pending': 0,
      'cancelled': 0,
      'revenue': 0.0,
      'commission': 0.0,
      'rider_earnings': 0.0,
    };
  }

  String _formatDay(String date) {
    final parsed = DateTime.tryParse(date);

    if (parsed == null) return date;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  Widget _dailyOperationsCard() {
    final days = dailyOperations();
    final today = todayOperations;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff18152D), Color(0xff111827)],
            ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: primary.withOpacity(.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.today_rounded,
                      color: primary,
                      size: 19,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Today's delivery performance",
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    _formatDay(today['date'].toString()),
                    style: const TextStyle(color: textMuted, fontSize: 10),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  _todayStat(
                    'Packages',
                    '${today['packages']}',
                    primary,
                    Icons.inventory_2_rounded,
                  ),
                  const SizedBox(width: 10),
                  _todayStat(
                    'Delivered',
                    '${today['delivered']}',
                    green,
                    Icons.check_circle_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _todayStat(
                    'Handled',
                    money(d(today['revenue'])),
                    blue,
                    Icons.payments_rounded,
                  ),
                  const SizedBox(width: 10),
                  _todayStat(
                    'Commission',
                    money(d(today['commission'])),
                    orange,
                    Icons.account_balance_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  _smallTodayValue('Active', '${today['active']}', orange),
                  const SizedBox(width: 18),
                  _smallTodayValue('Pending', '${today['pending']}', yellow),
                  const SizedBox(width: 18),
                  _smallTodayValue('Cancelled', '${today['cancelled']}', red),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: cyan,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Daily performance',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${days.length} days',
                    style: const TextStyle(color: textMuted, fontSize: 10),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              if (days.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No daily activity yet.',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                )
              else
                ...days.take(30).map((day) => _dailyRow(day)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _todayStat(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.10)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textMuted, fontSize: 9),
                  ),

                  const SizedBox(height: 3),

                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTodayValue(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 6),

        Text('$title ', style: const TextStyle(color: textMuted, fontSize: 10)),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dailyRow(Map<String, dynamic> day) {
    final delivered = i(day['delivered']);
    final packagesCount = i(day['packages']);

    final deliveryRate = packagesCount == 0
        ? 0.0
        : delivered / packagesCount * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface3.withOpacity(.45),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border.withOpacity(.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: primary,
                  size: 16,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDay(day['date'].toString()),
                      style: const TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$packagesCount packages',
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$delivered delivered',
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${deliveryRate.toStringAsFixed(0)}%',
                    style: const TextStyle(color: textMuted, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _dailyMini('Handled', money(d(day['revenue'])), blue),
              ),

              Expanded(
                child: _dailyMini(
                  'Commission',
                  money(d(day['commission'])),
                  primary,
                ),
              ),

              Expanded(
                child: _dailyMini(
                  'Rider earnings',
                  money(d(day['rider_earnings'])),
                  cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dailyMini(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: textMuted, fontSize: 8)),

        const SizedBox(height: 3),

        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS NAVIGATION
  // ============================================================

  void _openDetails(AnalyticsDetailsType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyticsDetailsScreen(
          type: type,
          analytics: analytics,
          packages: packages,
          riders: riders,
          customers: customers,
          withdrawals: withdrawals,
          wallets: wallets,
        ),
      ),
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

// ============================================================================
// DETAILS TYPE
// ============================================================================

enum AnalyticsDetailsType { financial, delivery, platform, performance }

// ============================================================================
// DETAILS SCREEN
// ============================================================================

class AnalyticsDetailsScreen extends StatelessWidget {
  final AnalyticsDetailsType type;

  final Map<String, dynamic> analytics;

  final List packages;
  final List riders;
  final List customers;
  final List withdrawals;
  final List wallets;

  const AnalyticsDetailsScreen({
    super.key,
    required this.type,
    required this.analytics,
    required this.packages,
    required this.riders,
    required this.customers,
    required this.withdrawals,
    required this.wallets,
  });

  double d(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String money(double value) {
    return '₦${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},')}';
  }

  Map<String, int> statusCounts() {
    final Map<String, int> result = {};

    for (final package in packages) {
      final status = (package['status'] ?? 'unknown').toString().toLowerCase();

      result[status] = (result[status] ?? 0) + 1;
    }

    return result;
  }

  int get completed {
    final apiValue =
        analytics['completed_deliveries'] ?? analytics['completed_packages'];

    if (apiValue is num) {
      return apiValue.toInt();
    }

    return statusCounts()['delivered'] ?? 0;
  }

  int get cancelled {
    return statusCounts()['cancelled'] ?? 0;
  }

  int get active {
    return (statusCounts()['accepted'] ?? 0) +
        (statusCounts()['picked_up'] ?? 0);
  }

  int get pending {
    return statusCounts()['pending'] ?? 0;
  }

  double get revenue {
    final value = analytics['total_revenue'] ?? analytics['revenue'];

    if (value != null) {
      return d(value);
    }

    double total = 0;

    for (final package in packages) {
      total += d(package['price']);
    }

    return total;
  }

  double get commission {
    final value = analytics['total_commission'] ?? analytics['commission'];

    if (value != null) {
      return d(value);
    }

    double total = 0;

    for (final package in packages) {
      total += d(package['commission'] ?? package['service_fee']);
    }

    return total;
  }

  double get riderEarnings {
    final value =
        analytics['rider_earnings'] ?? analytics['total_rider_earnings'];

    if (value != null) {
      return d(value);
    }

    double total = 0;

    for (final package in packages) {
      total += d(package['rider_earning']);
    }

    return total;
  }

  double get avgOrder {
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

  String get title {
    switch (type) {
      case AnalyticsDetailsType.financial:
        return 'Financial details';

      case AnalyticsDetailsType.delivery:
        return 'Delivery details';

      case AnalyticsDetailsType.platform:
        return 'Platform details';

      case AnalyticsDetailsType.performance:
        return 'Performance details';
    }
  }

  String get subtitle {
    switch (type) {
      case AnalyticsDetailsType.financial:
        return 'Revenue and payout breakdown';

      case AnalyticsDetailsType.delivery:
        return 'Package activity and status';

      case AnalyticsDetailsType.platform:
        return 'Users, riders and wallets';

      case AnalyticsDetailsType.performance:
        return 'Key operating metrics';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AnalyticsScreenState.background,

      appBar: AppBar(
        backgroundColor: _AnalyticsScreenState.background,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _AnalyticsScreenState.textPrimary,
          ),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _AnalyticsScreenState.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: _AnalyticsScreenState.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        children: [
          _detailsHero(),

          const SizedBox(height: 22),

          if (type == AnalyticsDetailsType.financial) _financialDetails(),

          if (type == AnalyticsDetailsType.delivery) _deliveryDetails(),

          if (type == AnalyticsDetailsType.platform) _platformDetails(),

          if (type == AnalyticsDetailsType.performance) _performanceDetails(),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS HERO
  // ============================================================

  Widget _detailsHero() {
    String mainValue;

    Color color;

    IconData icon;

    switch (type) {
      case AnalyticsDetailsType.financial:
        mainValue = money(revenue);
        color = _AnalyticsScreenState.green;
        icon = Icons.account_balance_rounded;
        break;

      case AnalyticsDetailsType.delivery:
        mainValue = packages.length.toString();
        color = _AnalyticsScreenState.primary;
        icon = Icons.local_shipping_rounded;
        break;

      case AnalyticsDetailsType.platform:
        mainValue = customers.length.toString();
        color = _AnalyticsScreenState.blue;
        icon = Icons.dashboard_rounded;
        break;

      case AnalyticsDetailsType.performance:
        mainValue =
            '${packages.isEmpty ? 0 : (completed / packages.length * 100).toStringAsFixed(1)}%';
        color = _AnalyticsScreenState.green;
        icon = Icons.speed_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(.14), _AnalyticsScreenState.surface],
        ),

        border: Border.all(color: color.withOpacity(.18)),
      ),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 25),
          ),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainValue,
                style: const TextStyle(
                  color: _AnalyticsScreenState.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: _AnalyticsScreenState.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL DETAILS
  // ============================================================

  Widget _financialDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailSection('Money breakdown', [
          _detailRow(
            'Total revenue',
            money(revenue),
            _AnalyticsScreenState.green,
            Icons.payments_rounded,
          ),
          _detailRow(
            'Senmi commission',
            money(commission),
            _AnalyticsScreenState.primary,
            Icons.account_balance_rounded,
          ),
          _detailRow(
            'Rider earnings',
            money(riderEarnings),
            _AnalyticsScreenState.blue,
            Icons.delivery_dining_rounded,
          ),
          _detailRow(
            'Processed payouts',
            money(payoutTotal),
            _AnalyticsScreenState.orange,
            Icons.outbound_rounded,
          ),
        ]),

        const SizedBox(height: 18),

        _detailSection('Average values', [
          _detailRow(
            'Average order value',
            money(avgOrder),
            _AnalyticsScreenState.cyan,
            Icons.receipt_long_rounded,
          ),
          _detailRow(
            'Revenue per delivery',
            money(completed == 0 ? 0 : revenue / completed),
            _AnalyticsScreenState.green,
            Icons.trending_up_rounded,
          ),
          _detailRow(
            'Commission percentage',
            revenue == 0
                ? '0%'
                : '${(commission / revenue * 100).toStringAsFixed(1)}%',
            _AnalyticsScreenState.primary,
            Icons.percent_rounded,
          ),
        ]),
      ],
    );
  }

  // ============================================================
  // DELIVERY DETAILS
  // ============================================================

  Widget _deliveryDetails() {
    final statuses = statusCounts();

    const order = [
      'pending',
      'paid',
      'accepted',
      'picked_up',
      'delivered',
      'cancelled',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailSection('Delivery overview', [
          _detailRow(
            'Total packages',
            packages.length.toString(),
            _AnalyticsScreenState.primary,
            Icons.inventory_2_rounded,
          ),
          _detailRow(
            'Delivered',
            completed.toString(),
            _AnalyticsScreenState.green,
            Icons.check_circle_rounded,
          ),
          _detailRow(
            'Active',
            active.toString(),
            _AnalyticsScreenState.blue,
            Icons.local_shipping_rounded,
          ),
          _detailRow(
            'Pending',
            pending.toString(),
            _AnalyticsScreenState.orange,
            Icons.schedule_rounded,
          ),
          _detailRow(
            'Cancelled',
            cancelled.toString(),
            _AnalyticsScreenState.red,
            Icons.cancel_rounded,
          ),
        ]),

        const SizedBox(height: 18),

        _detailSection(
          'Status breakdown',
          order.map((status) {
            final value = statuses[status] ?? 0;

            final percentage = packages.isEmpty
                ? 0
                : value / packages.length * 100;

            return _detailRow(
              status.replaceAll('_', ' ').toUpperCase(),
              '$value  (${percentage.toStringAsFixed(1)}%)',
              _statusColor(status),
              Icons.circle,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // PLATFORM DETAILS
  // ============================================================

  Widget _platformDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailSection('Users', [
          _detailRow(
            'Customers',
            customers.length.toString(),
            _AnalyticsScreenState.blue,
            Icons.people_alt_rounded,
          ),
          _detailRow(
            'Riders',
            riders.length.toString(),
            _AnalyticsScreenState.primary,
            Icons.delivery_dining_rounded,
          ),
          _detailRow(
            'Rider / customer',
            customers.isEmpty
                ? '0'
                : (riders.length / customers.length).toStringAsFixed(2),
            _AnalyticsScreenState.cyan,
            Icons.groups_rounded,
          ),
        ]),

        const SizedBox(height: 18),

        _detailSection('Wallets', [
          _detailRow(
            'Wallet accounts',
            wallets.length.toString(),
            _AnalyticsScreenState.cyan,
            Icons.account_balance_wallet_rounded,
          ),
          _detailRow(
            'Current wallet balance',
            money(walletBalance),
            _AnalyticsScreenState.green,
            Icons.account_balance_rounded,
          ),
        ]),

        const SizedBox(height: 18),

        _detailSection('Withdrawals', [
          _detailRow(
            'Total requests',
            withdrawals.length.toString(),
            _AnalyticsScreenState.orange,
            Icons.receipt_long_rounded,
          ),
          _detailRow(
            'Pending',
            withdrawals
                .where(
                  (item) =>
                      (item['status'] ?? '').toString().toLowerCase() ==
                      'pending',
                )
                .length
                .toString(),
            _AnalyticsScreenState.orange,
            Icons.pending_actions_rounded,
          ),
          _detailRow(
            'Processed value',
            money(payoutTotal),
            _AnalyticsScreenState.green,
            Icons.outbound_rounded,
          ),
        ]),
      ],
    );
  }

  // ============================================================
  // PERFORMANCE DETAILS
  // ============================================================

  Widget _performanceDetails() {
    final completion = packages.isEmpty
        ? 0.0
        : completed / packages.length * 100;

    final cancellation = packages.isEmpty
        ? 0.0
        : cancelled / packages.length * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailSection('Operational performance', [
          _detailRow(
            'Completion rate',
            '${completion.toStringAsFixed(1)}%',
            _AnalyticsScreenState.green,
            Icons.task_alt_rounded,
          ),
          _detailRow(
            'Cancellation rate',
            '${cancellation.toStringAsFixed(1)}%',
            _AnalyticsScreenState.red,
            Icons.cancel_outlined,
          ),
          _detailRow(
            'Average order',
            money(avgOrder),
            _AnalyticsScreenState.blue,
            Icons.receipt_long_rounded,
          ),
          _detailRow(
            'Revenue / delivery',
            money(completed == 0 ? 0 : revenue / completed),
            _AnalyticsScreenState.primary,
            Icons.trending_up_rounded,
          ),
          _detailRow(
            'Active deliveries',
            active.toString(),
            _AnalyticsScreenState.orange,
            Icons.local_shipping_outlined,
          ),
        ]),

        const SizedBox(height: 18),

        _performanceIndicator(
          'Completion',
          completion,
          _AnalyticsScreenState.green,
        ),

        const SizedBox(height: 13),

        _performanceIndicator(
          'Cancellation',
          cancellation,
          _AnalyticsScreenState.red,
        ),
      ],
    );
  }

  Widget _performanceIndicator(String title, double value, Color color) {
    final safe = value.clamp(0.0, 100.0) / 100;

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: _AnalyticsScreenState.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AnalyticsScreenState.border),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _AnalyticsScreenState.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: safe.toDouble(),
              minHeight: 8,
              backgroundColor: color.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL SECTION
  // ============================================================

  Widget _detailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: _AnalyticsScreenState.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AnalyticsScreenState.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _AnalyticsScreenState.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),

      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 15),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _AnalyticsScreenState.textSecondary,
                fontSize: 12,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              color: _AnalyticsScreenState.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return _AnalyticsScreenState.green;

      case 'cancelled':
        return _AnalyticsScreenState.red;

      case 'pending':
        return _AnalyticsScreenState.orange;

      case 'paid':
        return _AnalyticsScreenState.blue;

      case 'accepted':
      case 'picked_up':
        return _AnalyticsScreenState.primary;

      default:
        return _AnalyticsScreenState.textSecondary;
    }
  }
}

// ============================================================================
// CHART
// ============================================================================

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double max;

  _LineChartPainter({required this.values, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _AnalyticsScreenState.border
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3.0;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.isEmpty) return;

    final line = Paint()
      ..color = _AnalyticsScreenState.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = _AnalyticsScreenState.primary.withOpacity(.09)
      ..style = PaintingStyle.fill;

    final path = Path();
    final area = Path();

    for (int index = 0; index < values.length; index++) {
      final double x;

      if (values.length == 1) {
        x = size.width / 2;
      } else {
        x = index * size.width / (values.length - 1);
      }

      final normalized = (values[index] / max).clamp(0.0, 1.0).toDouble();

      final y = size.height - normalized * size.height * .85 - 5;

      if (index == 0) {
        path.moveTo(x, y);

        area.moveTo(x, size.height);

        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }

    final lastX = values.length == 1 ? size.width / 2 : size.width;

    area.lineTo(lastX, size.height);

    area.close();

    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);

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

      final y = size.height - normalized * size.height * .85 - 5;

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
