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

  @override
  void initState() {
    super.initState();
    load();
  }

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
    return '₦${value.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        )}';
  }

  // ============================================================
  // PACKAGE TREND
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
      (_) => <String, dynamic>{
        'count': 0,
        'revenue': 0.0,
      },
    );

    for (final package in packages) {
      final rawDate =
          package['created_at'] ?? package['date'];

      final date = DateTime.tryParse(
        rawDate?.toString() ?? '',
      );

      if (date == null) {
        continue;
      }

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final packageDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final diff = today.difference(packageDate).inDays;

      if (diff >= 0 && diff < days) {
        final index = days - 1 - diff;

        output[index]['count'] =
            (output[index]['count'] as int) + 1;

        output[index]['revenue'] =
            (output[index]['revenue'] as double) +
                d(package['price']);
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
      final status = (
        package['status'] ?? 'unknown'
      ).toString().toLowerCase();

      map[status] = (map[status] ?? 0) + 1;
    }

    return map;
  }

  // ============================================================
  // FINANCIAL GETTERS
  // ============================================================

  double get totalRevenue {
    final apiValue =
        analytics['total_revenue'] ??
        analytics['revenue'];

    if (apiValue != null) {
      return d(apiValue);
    }

    double total = 0.0;

    for (final package in packages) {
      total += d(package['price']);
    }

    return total;
  }

  double get totalCommission {
    final apiValue =
        analytics['total_commission'] ??
        analytics['commission'];

    if (apiValue != null) {
      return d(apiValue);
    }

    double total = 0.0;

    for (final package in packages) {
      total += d(
        package['commission'] ??
            package['service_fee'],
      );
    }

    return total;
  }

  double get riderEarnings {
    final apiValue =
        analytics['rider_earnings'] ??
        analytics['total_rider_earnings'];

    if (apiValue != null) {
      return d(apiValue);
    }

    double total = 0.0;

    for (final package in packages) {
      total += d(package['rider_earning']);
    }

    return total;
  }

  // ============================================================
  // DELIVERY COUNTS
  // ============================================================

  int get completed {
    final apiValue =
        analytics['completed_deliveries'] ??
        analytics['completed_packages'];

    if (apiValue != null) {
      return i(apiValue);
    }

    int total = 0;

    for (final package in packages) {
      if ((package['status'] ?? '')
              .toString()
              .toLowerCase() ==
          'delivered') {
        total++;
      }
    }

    return total;
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
  // AVERAGE ORDER
  // ============================================================

  double get avgOrderValue {
    if (packages.isEmpty) {
      return 0.0;
    }

    double total = 0.0;

    for (final package in packages) {
      total += d(package['price']);
    }

    return total / packages.length;
  }

  // ============================================================
  // WALLET
  // ============================================================

  double get walletBalance {
    double total = 0.0;

    for (final wallet in wallets) {
      total += d(wallet['balance']);
    }

    return total;
  }

  // ============================================================
  // PAYOUT
  // ============================================================

  double get payoutTotal {
    double total = 0.0;

    for (final withdrawal in withdrawals) {
      final status = (
        withdrawal['status'] ?? ''
      ).toString().toLowerCase();

      if (status == 'success' ||
          status == 'processing' ||
          status == 'approved') {
        total += d(withdrawal['amount']);
      }
    }

    return total;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),

        actions: [
          if (refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          IconButton(
            onPressed: load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,

              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(16),

                children: [
                  _header(),

                  const SizedBox(height: 18),

                  if (error != null) _error(),

                  _title(
                    'Financial performance',
                    'Calculated from live API data',
                  ),

                  const SizedBox(height: 10),

                  _financialCards(),

                  const SizedBox(height: 22),

                  _title(
                    'Delivery trend',
                    'Packages created during the selected period',
                  ),

                  const SizedBox(height: 10),

                  _rangeSelector(),

                  const SizedBox(height: 10),

                  _chartCard(),

                  const SizedBox(height: 22),

                  _title(
                    'Delivery status',
                    'Current package distribution',
                  ),

                  const SizedBox(height: 10),

                  _statusCard(),

                  const SizedBox(height: 22),

                  _title(
                    'Platform health',
                    'Users, payouts and wallet position',
                  ),

                  const SizedBox(height: 10),

                  _healthCard(),

                  const SizedBox(height: 22),

                  _title(
                    'Key metrics',
                    'Useful operating ratios',
                  ),

                  const SizedBox(height: 10),

                  _metricGrid(),

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
        gradient: const LinearGradient(
          colors: [
            Color(0xff111827),
            Color(0xff374151),
          ],
        ),

        borderRadius: BorderRadius.circular(24),
      ),

      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Senmi Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Monitor revenue, deliveries, riders and payouts in one place.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          if (refreshing)
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _error() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Some analytics data could not be loaded. Pull down to retry.',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _title(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
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

      physics:
          const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 12,
      mainAxisSpacing: 12,

      childAspectRatio: 1.45,

      children: [
        _card(
          'Revenue',
          money(totalRevenue),
          Icons.payments_rounded,
          Colors.green,
        ),

        _card(
          'Commission',
          money(totalCommission),
          Icons.account_balance_rounded,
          Colors.purple,
        ),

        _card(
          'Rider earnings',
          money(riderEarnings),
          Icons.delivery_dining_rounded,
          Colors.blue,
        ),

        _card(
          'Payouts',
          money(payoutTotal),
          Icons.outbound_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _card(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          CircleAvatar(
            radius: 17,

            backgroundColor:
                color.withOpacity(.10),

            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),

          const Spacer(),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            alignment:
                Alignment.centerLeft,

            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
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
        '7D',
        '30D',
        '90D',
      ].map((value) {
        final selected = range == value;

        return Padding(
          padding:
              const EdgeInsets.only(right: 8),

          child: ChoiceChip(
            label: Text(value),

            selected: selected,

            onSelected: (_) {
              setState(() {
                range = value;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // CHART
  // ============================================================

  Widget _chartCard() {
    final trend = _trendPackages();

    final List<double> values = trend
        .map<double>(
          (item) => d(item['count']),
        )
        .toList();

    final double maxValue = values.isEmpty
        ? 1.0
        : math.max(
            1.0,
            values.reduce(
              (a, b) => math.max(a, b),
            ),
          ).toDouble();

    return Container(
      height: 270,

      padding:
          const EdgeInsets.fromLTRB(
        12,
        18,
        18,
        12,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: Colors.indigo,
              ),

              const SizedBox(width: 8),

              const Text(
                'Packages per day',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                '${packages.length} total',

                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(
                values: values,
                max: maxValue,
              ),

              child:
                  const SizedBox.expand(),
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
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: order.map((status) {
          final int value =
              statuses[status] ?? 0;

          final double ratio =
              packages.isEmpty
                  ? 0.0
                  : value /
                      packages.length;

          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 15,
            ),

            child: _statusRow(
              status,
              value,
              ratio,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusRow(
    String status,
    int value,
    double ratio,
  ) {
    final color =
        _statusColor(status);

    final double safeRatio =
        ratio.clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                status
                    .replaceAll(
                      '_',
                      ' ',
                    )
                    .toUpperCase(),

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Text(
              '$value',

              style: TextStyle(
                color: color,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(20),

          child:
              LinearProgressIndicator(
            minHeight: 7,

            value: safeRatio,

            backgroundColor:
                color.withOpacity(.08),

            valueColor:
                AlwaysStoppedAnimation<Color>(
              color,
            ),
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
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          _healthRow(
            'Customers',
            customers.length,
            Icons.people_alt_rounded,
            Colors.blue,
          ),

          _healthRow(
            'Riders',
            riders.length,
            Icons.delivery_dining_rounded,
            Colors.indigo,
          ),

          _healthRow(
            'Wallets',
            wallets.length,
            Icons.account_balance_wallet_rounded,
            Colors.teal,
          ),

          _healthRow(
            'Pending withdrawals',
            withdrawals
                .where(
                  (withdrawal) =>
                      (withdrawal['status'] ??
                              '')
                          .toString()
                          .toLowerCase() ==
                      'pending',
                )
                .length,
            Icons.pending_actions_rounded,
            Colors.orange,
          ),

          _healthRow(
            'Wallet balance',
            money(walletBalance),
            Icons.account_balance_rounded,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _healthRow(
    String title,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 13,
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 17,

            backgroundColor:
                color.withOpacity(.10),

            child: Icon(
              icon,
              color: color,
              size: 17,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(title),
          ),

          Text(
            value.toString(),

            style: const TextStyle(
              fontWeight:
                  FontWeight.w800,
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
    final double completionRate =
        packages.isEmpty
            ? 0.0
            : (completed /
                    packages.length) *
                100.0;

    final double cancellationRate =
        packages.isEmpty
            ? 0.0
            : (cancelled /
                    packages.length) *
                100.0;

    final double riderPerCustomer =
        customers.isEmpty
            ? 0.0
            : riders.length /
                customers.length;

    return GridView.count(
      crossAxisCount: 2,

      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 12,
      mainAxisSpacing: 12,

      childAspectRatio: 1.5,

      children: [
        _metric(
          'Completion rate',
          '${completionRate.toStringAsFixed(1)}%',
          Colors.green,
        ),

        _metric(
          'Cancellation rate',
          '${cancellationRate.toStringAsFixed(1)}%',
          Colors.red,
        ),

        _metric(
          'Average order',
          money(avgOrderValue),
          Colors.blue,
        ),

        _metric(
          'Riders / customer',
          riderPerCustomer
              .toStringAsFixed(2),
          Colors.purple,
        ),
      ],
    );
  }

  Widget _metric(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: color.withOpacity(.10),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Text(
            title,

            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,

            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      case 'paid':
        return Colors.blue;

      case 'accepted':
      case 'picked_up':
        return Colors.indigo;

      default:
        return Colors.grey;
    }
  }
}

// ================================================================
// LINE CHART PAINTER
// ================================================================

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double max;

  _LineChartPainter({
    required this.values,
    required this.max,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final grid = Paint()
      ..color = Colors.grey.withOpacity(.12)
      ..strokeWidth = 1;

    // ------------------------------------------------------------
    // GRID
    // ------------------------------------------------------------

    for (int i = 0; i < 4; i++) {
      final double y =
          size.height * i / 3.0;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        grid,
      );
    }

    if (values.isEmpty) {
      return;
    }

    // ------------------------------------------------------------
    // LINE
    // ------------------------------------------------------------

    final line = Paint()
      ..color = Colors.indigo
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ------------------------------------------------------------
    // AREA FILL
    // ------------------------------------------------------------

    final fill = Paint()
      ..color =
          Colors.indigo.withOpacity(.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    final area = Path();

    // ------------------------------------------------------------
    // POINTS
    // ------------------------------------------------------------

    for (int index = 0;
        index < values.length;
        index++) {
      final double x;

      if (values.length == 1) {
        x = size.width / 2.0;
      } else {
        x = index *
            size.width /
            (values.length - 1);
      }

      final double normalized =
          (values[index] / max)
              .clamp(0.0, 1.0)
              .toDouble();

      final double y =
          size.height -
          (normalized *
              size.height *
              .85) -
          5.0;

      if (index == 0) {
        path.moveTo(x, y);

        area.moveTo(
          x,
          size.height,
        );

        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }

    // ------------------------------------------------------------
    // CLOSE AREA
    // ------------------------------------------------------------

    final double lastX =
        values.length == 1
            ? size.width / 2.0
            : size.width;

    area.lineTo(
      lastX,
      size.height,
    );

    area.close();

    // ------------------------------------------------------------
    // DRAW
    // ------------------------------------------------------------

    canvas.drawPath(
      area,
      fill,
    );

    canvas.drawPath(
      path,
      line,
    );

    // ------------------------------------------------------------
    // DOTS
    // ------------------------------------------------------------

    final dot = Paint()
      ..color = Colors.indigo;

    for (int index = 0;
        index < values.length;
        index++) {
      final double x;

      if (values.length == 1) {
        x = size.width / 2.0;
      } else {
        x = index *
            size.width /
            (values.length - 1);
      }

      final double normalized =
          (values[index] / max)
              .clamp(0.0, 1.0)
              .toDouble();

      final double y =
          size.height -
          (normalized *
              size.height *
              .85) -
          5.0;

      if (index ==
              values.length - 1 ||
          values.length <= 14) {
        canvas.drawCircle(
          Offset(x, y),
          3.5,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _LineChartPainter oldDelegate,
  ) {
    return oldDelegate.values != values ||
        oldDelegate.max != max;
  }
}