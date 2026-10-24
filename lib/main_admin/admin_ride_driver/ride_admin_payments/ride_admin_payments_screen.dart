import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminPaymentsScreen extends StatefulWidget {
  const RideAdminPaymentsScreen({
    super.key,
    required String title,
    required IconData icon,
    required String description,
  });

  @override
  State<RideAdminPaymentsScreen> createState() =>
      _RideAdminPaymentsScreenState();
}

class _RideAdminPaymentsScreenState extends State<RideAdminPaymentsScreen> {
  static const Color purple = Color(0xFF7C3AED);

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';

  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  String? errorMessage;

  final List<String> filters = const [
    'All',
    'Paid',
    'Pending',
    'Failed',
    'Cancelled',
  ];

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get pageColor =>
      isDark ? const Color(0xFF121018) : const Color(0xFFF8F7FC);

  Color get cardColor => isDark ? const Color(0xFF211C2B) : Colors.white;

  Color get primaryTextColor => isDark ? Colors.white : const Color(0xFF211633);

  Color get secondaryTextColor => isDark ? Colors.white60 : Colors.black54;

  Color get borderColor => isDark ? Colors.white12 : const Color(0xFFEDE8F5);

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD REAL COMMISSION PAYMENTS FROM DJANGO
  // ============================================================

  Future<void> loadPayments({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await RideService.getAdminCommissionPayments();

      final loadedPayments = response
          .whereType<Map>()
          .map((item) => _normalizePayment(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) return;

      setState(() {
        payments = loadedPayments;
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = _friendlyError(error);
      });
    }
  }

  // ============================================================
  // MAP DJANGO RESPONSE TO THE FIELDS USED BY THIS SCREEN
  // ============================================================

  Map<String, dynamic> _normalizePayment(Map<String, dynamic> json) {
    final reference = (json['reference'] ?? '').toString();
    final databaseId = (json['id'] ?? '').toString();

    final rawStatus = (json['status'] ?? 'pending').toString().toLowerCase();

    final profile = json['driver_profile'];

    final driverName =
        (json['driver_name'] ??
                (profile is Map ? profile['full_name'] : null) ??
                '')
            .toString()
            .trim();

    final driverEmail = (json['driver_email'] ?? '').toString().trim();

    final rideId = json['ride_id'];

    final rawDate = json['paid_at'] ?? json['created_at'];

    return {
      'id': reference.isNotEmpty ? reference : 'PAY-$databaseId',
      'databaseId': databaseId,
      'reference': reference,
      'rideId': rideId?.toString() ?? '',
      'driver': driverName.isNotEmpty
          ? driverName
          : 'Driver #${json['driver_id'] ?? 'Unknown'}',
      'driverEmail': driverEmail,
      'amount': _parseAmount(json['amount']),
      'method': _formatMethod(json['payment_method']),
      'date': _formatDate(rawDate),
      'status': _formatStatus(rawStatus),
      'createdAt': _formatDateTime(json['created_at']),
      'paidAt': _formatDateTime(json['paid_at']),
    };
  }

  double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();

    return double.tryParse(amount?.toString() ?? '') ?? 0.0;
  }

  String _formatMethod(dynamic method) {
    switch ((method ?? '').toString().toLowerCase()) {
      case 'card':
        return 'Card';
      case 'bank':
        return 'Bank';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ussd':
        return 'USSD';
      default:
        final value = (method ?? 'Unknown').toString();
        return value.isEmpty ? 'Unknown' : value;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty
            ? 'Unknown'
            : '${status[0].toUpperCase()}${status.substring(1)}';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Date unavailable';
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

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

    final date = parsed.toLocal();

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not available';
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final date = parsed.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${date.day}/${twoDigits(date.month)}/${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  // ============================================================
  // FILTER AND SEARCH
  // ============================================================

  List<Map<String, dynamic>> get filteredPayments {
    final query = searchController.text.trim().toLowerCase();

    return payments.where((payment) {
      final matchesStatus =
          selectedFilter == 'All' || payment['status'] == selectedFilter;

      final searchableFields = [
        payment['id'],
        payment['reference'],
        payment['rideId'],
        payment['driver'],
        payment['driverEmail'],
        payment['method'],
        payment['status'],
      ];

      final matchesSearch = searchableFields.any(
        (field) => (field ?? '').toString().toLowerCase().contains(query),
      );

      return matchesStatus && matchesSearch;
    }).toList();
  }

  // ============================================================
  // SUMMARY VALUES
  // ============================================================

  double get totalPaid {
    return payments
        .where((payment) => payment['status'] == 'Paid')
        .fold<double>(0, (sum, payment) => sum + (payment['amount'] as double));
  }

  int get pendingCount =>
      payments.where((p) => p['status'] == 'Pending').length;

  int get failedCount => payments.where((p) => p['status'] == 'Failed').length;

  // ============================================================
  // MONEY FORMATTER
  // ============================================================

  String money(dynamic amount) {
    final value = _parseAmount(amount);
    final rounded = value.round();
    final digits = rounded.toString();
    final result = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(digits[i]);
    }

    return '₦$result';
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  Color statusColor(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFF059669);
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Failed':
        return const Color(0xFFDC2626);
      case 'Cancelled':
        return Colors.grey;
      default:
        return purple;
    }
  }

  // ============================================================
  // FULL-SCREEN PAYMENT DETAILS
  // ============================================================

  void showPaymentDetails(Map<String, dynamic> payment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RideAdminPaymentDetailsScreen(
          payment: payment,
          money: money,
          statusColor: statusColor,
        ),
      ),
    );
  }

  // ============================================================
  // SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final visiblePayments = filteredPayments;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: const Text(
          'Commission Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh payments',
            onPressed: isLoading ? null : () => loadPayments(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => loadPayments(showLoading: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (isLoading && payments.isEmpty) ...[
                const SizedBox(height: 100),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Loading commission payments...',
                    style: TextStyle(color: primaryTextColor),
                  ),
                ),
                const SizedBox(height: 100),
              ] else ...[
                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unable to load payments',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          errorMessage!,
                          style: TextStyle(color: primaryTextColor),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => loadPayments(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _PaymentSummaryCard(
                      title: 'Commission Collected',
                      value: money(totalPaid),
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF059669),
                      isDark: isDark,
                    ),
                    _PaymentSummaryCard(
                      title: 'Pending',
                      value: '$pendingCount',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFD97706),
                      isDark: isDark,
                    ),
                    _PaymentSummaryCard(
                      title: 'Failed',
                      value: '$failedCount',
                      icon: Icons.error_outline,
                      color: const Color(0xFFDC2626),
                      isDark: isDark,
                    ),
                    _PaymentSummaryCard(
                      title: 'Transactions',
                      value: '${payments.length}',
                      icon: Icons.receipt_long_outlined,
                      color: purple,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Driver Commission Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search reference, ride or driver',
                    hintStyle: TextStyle(color: secondaryTextColor),
                    prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: purple, width: 1.4),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      final selected = selectedFilter == filter;

                      return ChoiceChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => selectedFilter = filter);
                        },
                        selectedColor: purple,
                        backgroundColor: cardColor,
                        showCheckmark: false,
                        side: BorderSide(
                          color: selected ? purple : borderColor,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Text(
                      'Payment Records',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${visiblePayments.length} records',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (visiblePayments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 54,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          payments.isEmpty
                              ? 'No commission payments found'
                              : 'No matching payments',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pull down to refresh or try another filter.',
                          style: TextStyle(color: secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...visiblePayments.map((payment) {
                    final status = payment['status'].toString();
                    final color = statusColor(status);
                    final rideId = payment['rideId'].toString();
                    final driverEmail = payment['driverEmail'].toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.025),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment['id'].toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      payment['date'].toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              _PaymentStatusBadge(status: status, color: color),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _PaymentInfoRow(
                            label: 'Ride ID',
                            value: rideId.isEmpty
                                ? 'Account settlement'
                                : rideId,
                            textColor: primaryTextColor,
                          ),

                          const SizedBox(height: 8),

                          _PaymentInfoRow(
                            label: 'Driver',
                            value: payment['driver'].toString(),
                            textColor: primaryTextColor,
                          ),

                          if (driverEmail.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _PaymentInfoRow(
                              label: 'Email',
                              value: driverEmail,
                              textColor: primaryTextColor,
                            ),
                          ],

                          const SizedBox(height: 8),

                          _PaymentInfoRow(
                            label: 'Method',
                            value: payment['method'].toString(),
                            textColor: primaryTextColor,
                          ),

                          Divider(height: 26, color: borderColor),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Commission Amount',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      money(payment['amount']),
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => showPaymentDetails(payment),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: const Text('Details'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: purple,
                                  side: const BorderSide(color: purple),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SEPARATE FULL-SCREEN PAYMENT DETAILS PAGE
// ============================================================

class RideAdminPaymentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  final String Function(dynamic) money;
  final Color Function(String) statusColor;

  const RideAdminPaymentDetailsScreen({
    super.key,
    required this.payment,
    required this.money,
    required this.statusColor,
  });

  static const Color purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF121018)
        : const Color(0xFFF8F7FC);

    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;

    final textColor = isDark ? Colors.white : const Color(0xFF211633);

    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    final borderColor = isDark ? Colors.white12 : const Color(0xFFEDE8F5);

    final status = payment['status'].toString();
    final color = statusColor(status);

    final rideId = payment['rideId'].toString();

    final details = <Map<String, String>>[
      {
        'label': 'Payment reference',
        'value': _displayValue(payment['reference']),
      },
      {'label': 'Database ID', 'value': _displayValue(payment['databaseId'])},
      {'label': 'Driver', 'value': _displayValue(payment['driver'])},
      {'label': 'Driver email', 'value': _displayValue(payment['driverEmail'])},
      {
        'label': 'Ride ID',
        'value': rideId.isEmpty
            ? 'Account settlement (not ride-specific)'
            : rideId,
      },
      {'label': 'Amount', 'value': money(payment['amount'])},
      {'label': 'Payment method', 'value': _displayValue(payment['method'])},
      {'label': 'Status', 'value': status},
      {'label': 'Created at', 'value': _displayValue(payment['createdAt'])},
      {'label': 'Paid at', 'value': _displayValue(payment['paidAt'])},
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payment Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Payment overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: purple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Commission Payment',
                    style: TextStyle(fontSize: 15, color: mutedColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    money(payment['amount']),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PaymentStatusBadge(status: status, color: color),
                  const SizedBox(height: 14),
                  Text(
                    _displayValue(payment['reference']),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Transaction Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: details.map((detail) {
                  return _PaymentDetailRow(
                    label: detail['label']!,
                    value: detail['value']!,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    dividerColor: borderColor,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Payments'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: purple,
                  side: const BorderSide(color: purple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _displayValue(dynamic value) {
    if (value == null) return 'Not available';

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return 'Not available';
    }

    return text;
  }
}

// ============================================================
// PAYMENT STATUS BADGE
// ============================================================

class _PaymentStatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _PaymentStatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _PaymentSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _PaymentSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF211C2B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFEDE8F5),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 25),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF211633),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAYMENT INFORMATION ROW
// ============================================================

class _PaymentInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;

  const _PaymentInfoRow({
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.65),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DETAILS INFORMATION ROW
// ============================================================

class _PaymentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color mutedColor;
  final Color dividerColor;

  const _PaymentDetailRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 125,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: dividerColor),
      ],
    );
  }
}
