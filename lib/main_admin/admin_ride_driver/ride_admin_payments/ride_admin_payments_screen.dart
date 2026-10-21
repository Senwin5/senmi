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

    final driverName = (json['driver_name'] ?? '').toString().trim();

    final driverEmail = (json['driver_email'] ?? '').toString().trim();

    final rideId = json['ride_id'];

    final rawDate = json['paid_at'] ?? json['created_at'];

    return {
      // Prefer the Paystack reference as the visible payment ID.
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
  // SUMMARY VALUES FROM THE REAL RESPONSE
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
  // PAYMENT DETAILS
  // ============================================================

  void showPaymentDetails(Map<String, dynamic> payment) {
    final details = <String, String>{
      'Payment reference': payment['reference'].toString(),
      'Database ID': payment['databaseId'].toString(),
      'Driver': payment['driver'].toString(),
      'Driver email': payment['driverEmail'].toString().isEmpty
          ? 'Not available'
          : payment['driverEmail'].toString(),
      'Ride ID': payment['rideId'].toString().isEmpty
          ? 'Account settlement (not ride-specific)'
          : payment['rideId'].toString(),
      'Amount': money(payment['amount']),
      'Payment method': payment['method'].toString(),
      'Status': payment['status'].toString(),
      'Created at': payment['createdAt'].toString(),
      'Paid at': payment['paidAt'].toString(),
    };

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commission Payment Details',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...details.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 115,
                            child: Text(
                              entry.key.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF211633);

    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;

    final visiblePayments = filteredPayments;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121018)
          : const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Commission Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1726) : Colors.white,
        foregroundColor: textColor,
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
                    style: TextStyle(color: textColor),
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
                        Text(errorMessage!, style: TextStyle(color: textColor)),
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
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search reference, ride or driver',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
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
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : textColor,
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
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${visiblePayments.length} records',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
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
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pull down to refresh or try another filter.',
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
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFEDE8F5),
                        ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      payment['date'].toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _PaymentInfoRow(
                            label: 'Ride ID',
                            value: rideId.isEmpty
                                ? 'Account settlement'
                                : rideId,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 8),
                          _PaymentInfoRow(
                            label: 'Driver',
                            value: payment['driver'].toString(),
                            textColor: textColor,
                          ),

                          if (driverEmail.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _PaymentInfoRow(
                              label: 'Email',
                              value: driverEmail,
                              textColor: textColor,
                            ),
                          ],

                          const SizedBox(height: 8),
                          _PaymentInfoRow(
                            label: 'Method',
                            value: payment['method'].toString(),
                            textColor: textColor,
                          ),

                          const Divider(height: 26),

                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commission Amount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    money(payment['amount']),
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
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
