import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminAnalyticsScreen extends StatefulWidget {
  const RideAdminAnalyticsScreen({
    super.key,
    required String title,
    required IconData icon,
    required String description,
  });

  @override
  State<RideAdminAnalyticsScreen> createState() =>
      _RideAdminAnalyticsScreenState();
}

class _RideAdminAnalyticsScreenState extends State<RideAdminAnalyticsScreen> {
  int _days = 7;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _response = {};

  Map<String, dynamic> get _overview {
    final value =
        _response['overview'] ??
        _response['summary'] ??
        _response['totals'] ??
        _response['statistics'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<Map<String, dynamic>> get _dailyActivity {
    final value =
        _response['daily_activity'] ??
        _response['daily'] ??
        _response['daily_analytics'] ??
        _response['results'] ??
        _response['items'];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _listFromResponse(List<String> keys) {
    for (final key in keys) {
      final value = _response[key];

      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  Map<String, dynamic> get _commissionPayments {
    final value = _response['commission_payments'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  Map<String, dynamic> get _customerPayments {
    final value = _response['customer_payments'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  num _number(dynamic value) {
    if (value is num) return value;

    if (value is String) {
      return num.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    }

    return 0;
  }

  num _metric(List<String> keys, {Map<String, dynamic>? source}) {
    final map = source ?? _overview;

    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return _number(map[key]);
      }
    }

    return 0;
  }

  String _money(dynamic value) {
    final amount = _number(value);
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      buffer.write(integerPart[i]);

      final remaining = integerPart.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '₦${buffer.toString()}.$decimalPart';
  }

  String _integer(dynamic value) {
    return _number(value).round().toString();
  }

  String _percentage(dynamic value) {
    return '${_number(value).toStringAsFixed(1)}%';
  }

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await RideService.getAdminDailyAnalytics(days: _days);

      if (!mounted) return;

      setState(() {
        _response = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changePeriod(int days) async {
    if (_days == days && !_loading) return;

    setState(() {
      _days = days;
    });

    await _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Ride Analytics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            onPressed: _loading ? null : _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading && _response.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _response.isEmpty
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadAnalytics,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      _buildInlineError(),
                      const SizedBox(height: 12),
                    ],
                    if (_loading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                    ],
                    _buildOverviewCards(),
                    const SizedBox(height: 22),
                    _buildDailyActivity(),
                    const SizedBox(height: 22),
                    _buildRevenueCard(),
                    const SizedBox(height: 22),
                    _buildRideStatusCard(),
                    const SizedBox(height: 22),
                    _buildPaymentCard(),
                    const SizedBox(height: 22),
                    _buildPeakHoursCard(),
                    const SizedBox(height: 22),
                    _buildPopularLocationsCard(),
                    const SizedBox(height: 22),
                    _buildDriversCard(),
                    const SizedBox(height: 22),
                    _buildServiceTypesCard(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF673AB7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ride performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Analytics for the last $_days days',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Row(
        children: [
          _periodButton(1, 'Today'),
          _periodButton(7, '7 Days'),
          _periodButton(30, '30 Days'),
          _periodButton(90, '90 Days'),
        ],
      ),
    );
  }

  Widget _periodButton(int days, String label) {
    final selected = _days == days;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changePeriod(days),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF673AB7) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF647087),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final total = _metric(['total', 'total_rides', 'rides']);
    final completed = _metric(['completed', 'completed_rides']);
    final cancelled = _metric(['cancelled', 'cancelled_rides']);
    final pending = _metric(['pending', 'pending_rides']);
    final completionRate = _metric(['completion_rate', 'completed_percentage']);
    final cancellationRate = _metric([
      'cancellation_rate',
      'cancelled_percentage',
    ]);

    final cards = [
      _MetricData(
        title: 'Total rides',
        value: _integer(total),
        icon: Icons.local_taxi_rounded,
        color: const Color(0xFF673AB7),
      ),
      _MetricData(
        title: 'Completed',
        value: _integer(completed),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16865B),
      ),
      _MetricData(
        title: 'Pending',
        value: _integer(pending),
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFE09A19),
      ),
      _MetricData(
        title: 'Cancelled',
        value: _integer(cancelled),
        icon: Icons.cancel_rounded,
        color: const Color(0xFFD64545),
      ),
      _MetricData(
        title: 'Completion rate',
        value: _percentage(completionRate),
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF16865B),
      ),
      _MetricData(
        title: 'Cancellation rate',
        value: _percentage(cancellationRate),
        icon: Icons.trending_down_rounded,
        color: const Color(0xFFD64545),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((data) {
            return SizedBox(width: width, child: _metricCard(data));
          }).toList(),
        );
      },
    );
  }

  Widget _metricCard(_MetricData data) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE9EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.title,
            style: const TextStyle(
              color: Color(0xFF758096),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivity() {
    final rows = _dailyActivity;

    return _sectionCard(
      title: 'Daily ride activity',
      subtitle: 'Ride requests over the selected period',
      icon: Icons.bar_chart_rounded,
      child: rows.isEmpty
          ? _emptyState('No daily activity data available.')
          : Column(
              children: [
                SizedBox(
                  height: 210,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _RideChartPainter(
                      values: rows.map((row) => _number(row['total'])).toList(),
                      labels: rows
                          .map((row) => _formatDate(row['date']))
                          .toList(),
                      barColor: const Color(0xFF673AB7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...rows.reversed.take(7).map((row) {
                  return _dailyRow(row);
                }),
              ],
            ),
    );
  }

  Widget _dailyRow(Map<String, dynamic> row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatDate(row['date']),
              style: const TextStyle(color: Color(0xFF59657A), fontSize: 13),
            ),
          ),
          _smallCount('Total', row['total'], const Color(0xFF673AB7)),
          const SizedBox(width: 12),
          _smallCount('Done', row['completed'], const Color(0xFF16865B)),
          const SizedBox(width: 12),
          _smallCount('Cancelled', row['cancelled'], const Color(0xFFD64545)),
        ],
      ),
    );
  }

  Widget _smallCount(String label, dynamic value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _integer(value),
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A93A4), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildRevenueCard() {
    final fares = _metric([
      'completed_fares',
      'total_fares',
      'total_revenue',
      'revenue',
      'total_earnings',
      'earnings',
    ]);

    final driverEarnings = _metric([
      'driver_earnings',
      'total_driver_earnings',
    ]);

    final serviceFees = _metric([
      'service_fees_from_completed_rides',
      'service_fees',
      'commission',
      'total_commission',
    ]);

    final daily = _dailyActivity;

    return _sectionCard(
      title: 'Revenue overview',
      subtitle: 'Completed ride fares and earnings',
      icon: Icons.payments_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completed ride fares',
                  style: TextStyle(color: Color(0xFF52617A), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  _money(fares),
                  style: const TextStyle(
                    color: Color(0xFF673AB7),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _valueRow(
            'Driver earnings',
            _money(driverEarnings),
            color: const Color(0xFF16865B),
          ),
          _valueRow(
            'Service fees from completed rides',
            _money(serviceFees),
            color: const Color(0xFF9B63C6),
          ),
          if (daily.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Daily completed fares',
              style: TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 175,
              width: double.infinity,
              child: CustomPaint(
                painter: _RideChartPainter(
                  values: daily
                      .map(
                        (row) => _number(
                          row['completed_fares'] ??
                              row['total_fares'] ??
                              row['revenue'],
                        ),
                      )
                      .toList(),
                  labels: daily.map((row) => _formatDate(row['date'])).toList(),
                  barColor: const Color(0xFF16865B),
                  showCurrency: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRideStatusCard() {
    final statuses = [
      _StatusData(
        'Pending',
        _metric(['pending', 'pending_rides']),
        const Color(0xFFE09A19),
      ),
      _StatusData(
        'Accepted',
        _metric(['accepted', 'accepted_rides']),
        const Color(0xFF673AB7),
      ),
      _StatusData(
        'Arrived',
        _metric(['arrived', 'arrived_rides']),
        const Color(0xFF9B63C6),
      ),
      _StatusData(
        'Started',
        _metric(['started', 'started_rides']),
        const Color(0xFF0E9AA7),
      ),
      _StatusData(
        'Completed',
        _metric(['completed', 'completed_rides']),
        const Color(0xFF16865B),
      ),
      _StatusData(
        'Cancelled',
        _metric(['cancelled', 'cancelled_rides']),
        const Color(0xFFD64545),
      ),
    ];

    final maxValue = statuses.fold<num>(
      1,
      (previous, item) => item.value > previous ? item.value : previous,
    );

    return _sectionCard(
      title: 'Ride status breakdown',
      subtitle: 'Requests grouped by their current or final status',
      icon: Icons.donut_large_rounded,
      child: Column(
        children: statuses.map((item) {
          final fraction = (item.value / maxValue).toDouble();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Color(0xFF59657A),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      _integer(item.value),
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEEF1F6),
                    valueColor: AlwaysStoppedAnimation<Color>(item.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentCard() {
    final commission = _commissionPayments;
    final customer = _customerPayments;

    final commissionTotal = _number(commission['total']);
    final commissionPaid = _number(commission['paid']);
    final commissionPending = _number(commission['pending']);
    final commissionFailed = _number(commission['failed']);
    final commissionCancelled = _number(commission['cancelled']);

    final paidAmount = _number(commission['paid_amount']);
    final pendingAmount = _number(commission['pending_amount']);

    return _sectionCard(
      title: 'Payment analytics',
      subtitle: 'Commission payments and customer payment information',
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commission payments',
            style: TextStyle(
              color: Color(0xFF344054),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _valueRow('Total payments', _integer(commissionTotal)),
          _valueRow(
            'Paid payments',
            _integer(commissionPaid),
            color: const Color(0xFF16865B),
          ),
          _valueRow(
            'Pending payments',
            _integer(commissionPending),
            color: const Color(0xFFE09A19),
          ),
          _valueRow(
            'Failed payments',
            _integer(commissionFailed),
            color: const Color(0xFFD64545),
          ),
          _valueRow(
            'Cancelled payments',
            _integer(commissionCancelled),
            color: const Color(0xFF7B8495),
          ),
          const Divider(height: 26),
          _valueRow(
            'Commission paid amount',
            _money(paidAmount),
            color: const Color(0xFF16865B),
          ),
          _valueRow(
            'Commission pending amount',
            _money(pendingAmount),
            color: const Color(0xFFE09A19),
          ),
          if (customer.isNotEmpty) ...[
            const Divider(height: 26),
            const Text(
              'Customer payments',
              style: TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ...customer.entries.map((entry) {
              final value = entry.value;

              return _valueRow(
                _humanize(entry.key),
                value is num || value is String
                    ? _integer(value)
                    : value is Map
                    ? 'Details available'
                    : value is List
                    ? '${value.length} records'
                    : value?.toString() ?? '—',
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPeakHoursCard() {
    final peakHours = _listFromResponse(['peak_hours', 'hourly_activity']);

    return _sectionCard(
      title: 'Peak hours',
      subtitle: 'When ride requests are most frequent',
      icon: Icons.schedule_rounded,
      child: peakHours.isEmpty
          ? _emptyState('No peak-hour data available.')
          : Column(
              children: peakHours.map((item) {
                final label =
                    item['hour'] ??
                    item['time'] ??
                    item['label'] ??
                    item['period'] ??
                    'Unknown';

                final count =
                    item['total'] ??
                    item['count'] ??
                    item['rides'] ??
                    item['requests'] ??
                    0;

                return _valueRow(_formatHour(label), _integer(count));
              }).toList(),
            ),
    );
  }

  Widget _buildPopularLocationsCard() {
    final pickups = _listFromResponse(['popular_pickups', 'pickup_locations']);

    final destinations = _listFromResponse([
      'popular_destinations',
      'destination_locations',
    ]);

    return _sectionCard(
      title: 'Popular locations',
      subtitle: 'Most common pickup points and destinations',
      icon: Icons.location_on_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular pickups',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 10),
          if (pickups.isEmpty)
            _emptyState('No pickup data available.')
          else
            ...pickups.take(5).map((item) => _locationRow(item)),
          const Divider(height: 28),
          const Text(
            'Popular destinations',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 10),
          if (destinations.isEmpty)
            _emptyState('No destination data available.')
          else
            ...destinations.take(5).map((item) => _locationRow(item)),
        ],
      ),
    );
  }

  Widget _locationRow(Map<String, dynamic> item) {
    final name =
        item['location'] ??
        item['name'] ??
        item['address'] ??
        item['pickup_location'] ??
        item['destination'] ??
        item['label'] ??
        'Unknown location';

    final count =
        item['total'] ??
        item['count'] ??
        item['rides'] ??
        item['ride_count'] ??
        item['frequency'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: Color(0xFF7C8BA5), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              name.toString(),
              style: const TextStyle(color: Color(0xFF59657A), fontSize: 13),
            ),
          ),
          if (count != null)
            Text(
              _integer(count),
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriversCard() {
    final drivers = _listFromResponse([
      'drivers',
      'driver_analytics',
      'top_drivers',
    ]);

    return _sectionCard(
      title: 'Driver performance',
      subtitle: 'Driver activity in the selected period',
      icon: Icons.person_pin_circle_rounded,
      child: drivers.isEmpty
          ? _emptyState('No driver performance data available.')
          : Column(
              children: drivers.map((driver) {
                final name =
                    driver['name'] ??
                    driver['driver_name'] ??
                    driver['full_name'] ??
                    driver['username'] ??
                    'Driver';

                final rides =
                    driver['completed'] ??
                    driver['completed_rides'] ??
                    driver['total_rides'] ??
                    driver['rides'] ??
                    driver['total'] ??
                    0;

                final earnings =
                    driver['earnings'] ??
                    driver['driver_earnings'] ??
                    driver['total_earnings'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEDF0F5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE7EEFF),
                        child: Text(
                          name.toString().isNotEmpty
                              ? name.toString()[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            color: Color(0xFF673AB7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF172033),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_integer(rides)} completed/recorded rides',
                              style: const TextStyle(
                                color: Color(0xFF7B8495),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (earnings != null)
                        Text(
                          _money(earnings),
                          style: const TextStyle(
                            color: Color(0xFF16865B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildServiceTypesCard() {
    final types = _listFromResponse([
      'service_types',
      'ride_types',
      'services',
    ]);

    return _sectionCard(
      title: 'Service types',
      subtitle: 'Ride requests by service category',
      icon: Icons.category_rounded,
      child: types.isEmpty
          ? _emptyState('No service-type data available.')
          : Column(
              children: types.map((item) {
                final name =
                    item['name'] ??
                    item['service_type'] ??
                    item['type'] ??
                    item['label'] ??
                    'Other';

                final count =
                    item['total'] ??
                    item['count'] ??
                    item['rides'] ??
                    item['ride_count'] ??
                    0;

                return _valueRow(name.toString(), _integer(count));
              }).toList(),
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE9EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7).withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF673AB7), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8495),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _valueRow(
    String label,
    String value, {
    Color color = const Color(0xFF172033),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF657087), fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF8992A3), fontSize: 13),
      ),
    );
  }

  Widget _buildInlineError() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Refresh failed: $_error',
              style: const TextStyle(color: Color(0xFFC0392B), fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Color(0xFFD64545),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load ride analytics',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF172033),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF657087), fontSize: 13),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final raw = value.toString();
    final parsed = DateTime.tryParse(raw);

    if (parsed == null) return raw;

    return '${parsed.day}/${parsed.month}';
  }

  String _formatHour(dynamic value) {
    if (value == null) return 'Unknown hour';

    final raw = value.toString();

    if (raw.contains(':')) return raw;

    final hour = int.tryParse(raw);

    if (hour == null || hour < 0 || hour > 23) {
      return raw;
    }

    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:00 $suffix';
  }

  String _humanize(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _MetricData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatusData {
  final String label;
  final num value;
  final Color color;

  const _StatusData(this.label, this.value, this.color);
}

class _RideChartPainter extends CustomPainter {
  final List<num> values;
  final List<String> labels;
  final Color barColor;
  final bool showCurrency;

  _RideChartPainter({
    required this.values,
    required this.labels,
    required this.barColor,
    this.showCurrency = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) {
      _drawEmpty(canvas, size);
      return;
    }

    const leftPadding = 8.0;
    const rightPadding = 8.0;
    const topPadding = 25.0;
    const bottomPadding = 33.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final maxValue = math.max(
      1.0,
      values.fold<double>(
        0,
        (previous, item) =>
            item.toDouble() > previous ? item.toDouble() : previous,
      ),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFE8ECF3)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight * i / 4);

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final slotWidth = chartWidth / values.length;
    final barWidth = math.min(26.0, slotWidth * 0.58);

    for (int i = 0; i < values.length; i++) {
      final value = values[i].toDouble();
      final barHeight = chartHeight * value / maxValue;

      final centerX = leftPadding + (slotWidth * i) + (slotWidth / 2);

      final rect = Rect.fromLTWH(
        centerX - barWidth / 2,
        topPadding + chartHeight - barHeight,
        barWidth,
        math.max(0, barHeight),
      );

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        barPaint,
      );

      if (values.length <= 10) {
        final amountLabel = showCurrency
            ? _compactCurrency(value)
            : value.round().toString();

        _drawText(
          canvas,
          amountLabel,
          Offset(centerX, math.max(0, rect.top - 17)),
          fontSize: 9,
          color: const Color(0xFF68758C),
          align: TextAlign.center,
        );
      }

      final label = i < labels.length ? labels[i] : '';

      final shouldShowLabel =
          values.length <= 10 ||
          i == 0 ||
          i == values.length - 1 ||
          i % math.max(1, (values.length / 6).ceil()) == 0;

      if (shouldShowLabel) {
        _drawText(
          canvas,
          label,
          Offset(centerX, size.height - 17),
          fontSize: 9,
          color: const Color(0xFF7B8495),
          align: TextAlign.center,
        );
      }
    }
  }

  void _drawEmpty(Canvas canvas, Size size) {
    _drawText(
      canvas,
      'No chart data',
      Offset(size.width / 2, size.height / 2),
      fontSize: 13,
      color: const Color(0xFF8992A3),
      align: TextAlign.center,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: 100);

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  String _compactCurrency(double value) {
    if (value >= 1000000) {
      return '₦${(value / 1000000).toStringAsFixed(1)}m';
    }

    if (value >= 1000) {
      return '₦${(value / 1000).toStringAsFixed(1)}k';
    }

    return '₦${value.round()}';
  }

  @override
  bool shouldRepaint(covariant _RideChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.barColor != barColor ||
        oldDelegate.showCurrency != showCurrency;
  }
}
