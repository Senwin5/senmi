import 'package:flutter/material.dart';

class RideAdminAnalyticsScreen extends StatefulWidget {
  const RideAdminAnalyticsScreen({super.key, required String title, required IconData icon, required String description});

  @override
  State<RideAdminAnalyticsScreen> createState() =>
      _RideAdminAnalyticsScreenState();
}

class _RideAdminAnalyticsScreenState extends State<RideAdminAnalyticsScreen> {
  static const Color purple = Color(0xFF7C3AED);

  String _period = '7 days';

  final Map<String, Map<String, dynamic>> _analytics = {
    '7 days': {
      'revenue': 284500.0,
      'rides': 186,
      'completed': 158,
      'cancelled': 28,
      'averageFare': 1800.0,
      'completionRate': 85.0,
      'revenueValues': [28.0, 35.0, 31.0, 46.0, 39.0, 54.0, 51.0],
      'rideValues': [18.0, 25.0, 22.0, 32.0, 27.0, 35.0, 27.0],
      'labels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    },
    '30 days': {
      'revenue': 1124500.0,
      'rides': 742,
      'completed': 638,
      'cancelled': 104,
      'averageFare': 1762.0,
      'completionRate': 86.0,
      'revenueValues': [
        24.0,
        32.0,
        29.0,
        42.0,
        38.0,
        48.0,
        45.0,
        55.0,
        49.0,
        62.0,
        57.0,
        70.0,
      ],
      'rideValues': [
        15.0,
        20.0,
        18.0,
        28.0,
        24.0,
        31.0,
        29.0,
        36.0,
        32.0,
        40.0,
        37.0,
        45.0,
      ],
      'labels': [
        '1',
        '3',
        '5',
        '7',
        '9',
        '11',
        '13',
        '15',
        '17',
        '19',
        '21',
        '23',
      ],
    },
    '90 days': {
      'revenue': 3268000.0,
      'rides': 2184,
      'completed': 1874,
      'cancelled': 310,
      'averageFare': 1744.0,
      'completionRate': 85.8,
      'revenueValues': [
        30.0,
        42.0,
        38.0,
        48.0,
        55.0,
        51.0,
        62.0,
        58.0,
        70.0,
        66.0,
        78.0,
        86.0,
      ],
      'rideValues': [
        19.0,
        26.0,
        23.0,
        31.0,
        35.0,
        33.0,
        40.0,
        38.0,
        45.0,
        43.0,
        51.0,
        57.0,
      ],
      'labels': [
        'W1',
        'W2',
        'W3',
        'W4',
        'W5',
        'W6',
        'W7',
        'W8',
        'W9',
        'W10',
        'W11',
        'W12',
      ],
    },
  };

  final List<Map<String, dynamic>> _drivers = [
    {
      'name': 'David Okafor',
      'rides': 48,
      'rating': 4.9,
      'revenue': 86400.0,
      'initials': 'DO',
    },
    {
      'name': 'Samuel Adeyemi',
      'rides': 42,
      'rating': 4.8,
      'revenue': 75600.0,
      'initials': 'SA',
    },
    {
      'name': 'Emeka Nwosu',
      'rides': 36,
      'rating': 4.7,
      'revenue': 64800.0,
      'initials': 'EN',
    },
    {
      'name': 'Peter Musa',
      'rides': 31,
      'rating': 4.6,
      'revenue': 55800.0,
      'initials': 'PM',
    },
  ];

  Map<String, dynamic> get _current => _analytics[_period]!;

  String _money(num value) {
    return '₦${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _current;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111018)
          : const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text(
          'Ride Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF191622) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF211A2C),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Analytics information',
            icon: const Icon(Icons.info_outline),
            onPressed: _showInformation,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHero(isDark),
            const SizedBox(height: 20),
            _buildPeriodSelector(isDark),
            const SizedBox(height: 20),
            _sectionTitle('Performance overview', isDark),
            const SizedBox(height: 12),
            _buildOverviewCards(data, isDark),
            const SizedBox(height: 24),
            _sectionTitle('Revenue trend', isDark),
            const SizedBox(height: 12),
            _buildChartCard(
              isDark: isDark,
              title: 'Revenue performance',
              subtitle: 'Revenue trend for $_period',
              values: List<double>.from(data['revenueValues']),
              labels: List<String>.from(data['labels']),
              color: purple,
              prefix: '₦',
            ),
            const SizedBox(height: 24),
            _sectionTitle('Ride activity', isDark),
            const SizedBox(height: 12),
            _buildChartCard(
              isDark: isDark,
              title: 'Ride volume',
              subtitle: 'Ride activity for $_period',
              values: List<double>.from(data['rideValues']),
              labels: List<String>.from(data['labels']),
              color: Colors.teal,
              prefix: '',
            ),
            const SizedBox(height: 24),
            _sectionTitle('Ride completion', isDark),
            const SizedBox(height: 12),
            _buildCompletionCard(data, isDark),
            const SizedBox(height: 24),
            _sectionTitle('Top-performing drivers', isDark),
            const SizedBox(height: 12),
            _buildDriversCard(isDark),
            const SizedBox(height: 24),
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF581C87)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ride Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Understand ride demand, revenue and driver performance.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Reporting period: $_period',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.query_stats_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    const periods = ['7 days', '30 days', '90 days'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Row(
        children: periods.map((period) {
          final selected = _period == period;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> data, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.43,
      children: [
        _metricCard(
          title: 'Total revenue',
          value: _money(data['revenue']),
          icon: Icons.account_balance_wallet_outlined,
          color: purple,
          isDark: isDark,
        ),
        _metricCard(
          title: 'Total rides',
          value: '${data['rides']}',
          icon: Icons.directions_car_outlined,
          color: Colors.blue,
          isDark: isDark,
        ),
        _metricCard(
          title: 'Completed rides',
          value: '${data['completed']}',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          isDark: isDark,
        ),
        _metricCard(
          title: 'Average fare',
          value: _money(data['averageFare']),
          icon: Icons.payments_outlined,
          color: Colors.orange,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF211A2C),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF211A2C),
      ),
    );
  }

  Widget _buildChartCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required List<double> values,
    required List<String> labels,
    required Color color,
    required String prefix,
  }) {
    final highest = values.reduce((a, b) => a > b ? a : b);
    final total = values.fold<double>(0, (sum, value) => sum + value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF211A2C),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 155,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarChartPainter(
                values: values,
                color: color,
                gridColor: isDark ? Colors.white12 : Colors.black12,
                labelColor: isDark ? Colors.white54 : Colors.black54,
                labels: labels,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  prefix == '₦'
                      ? 'Combined trend value'
                      : 'Total rides in trend',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              Text(
                prefix == '₦' ? _money(total * 1000) : total.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Peak value: ${prefix == '₦' ? _money(highest * 1000) : highest.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(Map<String, dynamic> data, bool isDark) {
    final completed = data['completed'] as int;
    final cancelled = data['cancelled'] as int;
    final total = completed + cancelled;
    final rate = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 105,
                width: 105,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 10,
                        backgroundColor: isDark
                            ? Colors.white12
                            : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(rate * 100).round()}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF211A2C),
                          ),
                        ),
                        Text(
                          'completed',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(
                      'Completed rides',
                      '$completed',
                      Colors.green,
                      isDark,
                    ),
                    const SizedBox(height: 14),
                    _legendRow(
                      'Cancelled rides',
                      '$cancelled',
                      Colors.redAccent,
                      isDark,
                    ),
                    const SizedBox(height: 14),
                    _legendRow('Total records', '$total', purple, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: rate,
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Completion rate is calculated from completed and cancelled sample rides.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDriversCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEDEAF3),
        ),
      ),
      child: Column(
        children: List.generate(_drivers.length, (index) {
          final driver = _drivers[index];

          return Column(
            children: [
              if (index > 0)
                Divider(
                  height: 22,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      driver['initials'],
                      style: const TextStyle(
                        color: purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${driver['rides']} rides • ★ ${driver['rating']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _money(driver['revenue'] as double),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : purple,
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF201C2B) : const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: purple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This analytics page currently displays illustrative sample data. '
              'Figures, trends and driver rankings will be replaced with '
              'verified ride data during backend integration.',
              style: TextStyle(
                height: 1.4,
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF4C1D95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInformation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About Ride Analytics'),
        content: const Text(
          'This screen previews the planned ride reporting interface. '
          'All displayed values are sample data and are not live business '
          'figures. Backend integration will supply verified statistics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.labelColor,
    required this.labels,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;
  final Color labelColor;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const leftPadding = 5.0;
    const topPadding = 8.0;
    const bottomPadding = 25.0;

    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width - leftPadding * 2;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = topPadding + chartHeight * i / 3;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - leftPadding, y),
        gridPaint,
      );
    }

    final gap = chartWidth / values.length;
    final barWidth = (gap * 0.54).clamp(4.0, 22.0);

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: values.length > 8 ? 8 : 10,
    );

    for (var i = 0; i < values.length; i++) {
      final barHeight = chartHeight * values[i] / safeMax;
      final x = leftPadding + gap * i + (gap - barWidth) / 2;
      final y = topPadding + chartHeight - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(rect, barPaint);

      if (i < labels.length) {
        final text = TextPainter(
          text: TextSpan(text: labels[i], style: labelStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: gap);

        text.paint(
          canvas,
          Offset(
            leftPadding + gap * i + (gap - text.width) / 2,
            size.height - text.height - 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labels != labels;
  }
}
