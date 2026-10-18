import 'package:flutter/material.dart';

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

  final List<Map<String, dynamic>> samplePayments = [
    {
      'id': 'PAY-1001',
      'rideId': 'RIDE-1001',
      'passenger': 'John Okafor',
      'driver': 'Michael James',
      'amount': 8500,
      'method': 'Card',
      'date': '18 Oct 2026',
      'status': 'Paid',
    },
    {
      'id': 'PAY-1002',
      'rideId': 'RIDE-1002',
      'passenger': 'Grace Adeyemi',
      'driver': 'Daniel Musa',
      'amount': 4200,
      'method': 'Wallet',
      'date': '18 Oct 2026',
      'status': 'Pending',
    },
    {
      'id': 'PAY-1003',
      'rideId': 'RIDE-1003',
      'passenger': 'David Eze',
      'driver': 'Samuel Bello',
      'amount': 3500,
      'method': 'Transfer',
      'date': '17 Oct 2026',
      'status': 'Paid',
    },
    {
      'id': 'PAY-1004',
      'rideId': 'RIDE-1004',
      'passenger': 'Sarah Ibrahim',
      'driver': 'Not assigned',
      'amount': 2800,
      'method': 'Wallet',
      'date': '17 Oct 2026',
      'status': 'Failed',
    },
    {
      'id': 'PAY-1005',
      'rideId': 'RIDE-1005',
      'passenger': 'Peter Williams',
      'driver': 'Emeka Nwosu',
      'amount': 3000,
      'method': 'Card',
      'date': '16 Oct 2026',
      'status': 'Paid',
    },
  ];

  final List<String> filters = const ['All', 'Paid', 'Pending', 'Failed'];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredPayments {
    final query = searchController.text.trim().toLowerCase();

    return samplePayments.where((payment) {
      final matchesStatus =
          selectedFilter == 'All' || payment['status'] == selectedFilter;

      final matchesSearch =
          payment['id'].toString().toLowerCase().contains(query) ||
          payment['rideId'].toString().toLowerCase().contains(query) ||
          payment['passenger'].toString().toLowerCase().contains(query) ||
          payment['driver'].toString().toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFF059669);
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Failed':
        return const Color(0xFFDC2626);
      default:
        return purple;
    }
  }

  String money(dynamic amount) {
    final value = (amount as num).toInt();
    final digits = value.toString();
    final result = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(digits[i]);
    }

    return '₦$result';
  }

  void showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...payment.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.key == 'amount'
                                ? money(entry.value)
                                : entry.value.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF211633);

    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;

    final payments = filteredPayments;

    final totalPaid = samplePayments
        .where((p) => p['status'] == 'Paid')
        .fold<num>(0, (sum, p) => sum + (p['amount'] as num));

    final pendingCount = samplePayments
        .where((p) => p['status'] == 'Pending')
        .length;

    final failedCount = samplePayments
        .where((p) => p['status'] == 'Failed')
        .length;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121018)
          : const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Ride Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1C1726) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _PaymentSummaryCard(
                        title: 'Total Paid',
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
                        value: '${samplePayments.length}',
                        icon: Icons.receipt_long_outlined,
                        color: purple,
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Transactions',
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
                      hintText: 'Search payment, ride or customer',
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
                        '${payments.length} records',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (payments.isEmpty)
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
                            'No payments found',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Try another search or filter.'),
                        ],
                      ),
                    )
                  else
                    ...payments.map((payment) {
                      final status = payment['status'] as String;
                      final color = statusColor(status);

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        payment['id'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        payment['date'] as String,
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
                              value: payment['rideId'] as String,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 8),
                            _PaymentInfoRow(
                              label: 'Passenger',
                              value: payment['passenger'] as String,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 8),
                            _PaymentInfoRow(
                              label: 'Driver',
                              value: payment['driver'] as String,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 8),
                            _PaymentInfoRow(
                              label: 'Method',
                              value: payment['method'] as String,
                              textColor: textColor,
                            ),

                            const Divider(height: 26),

                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Amount',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
