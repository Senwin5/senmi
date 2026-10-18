import 'package:flutter/material.dart';

class RideAdminCustomersScreen extends StatefulWidget {
  const RideAdminCustomersScreen({super.key, required String title, required IconData icon});

  @override
  State<RideAdminCustomersScreen> createState() =>
      _RideAdminCustomersScreenState();
}

class _RideAdminCustomersScreenState extends State<RideAdminCustomersScreen> {
  static const Color primaryPurple = Color(0xFF7C3AED);

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';

  final List<Map<String, dynamic>> customers = [
    {
      'id': 'CUS-1001',
      'name': 'Michael Johnson',
      'email': 'michael@example.com',
      'phone': '+234 801 234 5678',
      'rides': 24,
      'spent': 186500.0,
      'status': 'Active',
      'joined': '12 Jan 2026',
      'location': 'Lagos, Nigeria',
    },
    {
      'id': 'CUS-1002',
      'name': 'Grace Williams',
      'email': 'grace@example.com',
      'phone': '+234 802 345 6789',
      'rides': 18,
      'spent': 142000.0,
      'status': 'Active',
      'joined': '18 Feb 2026',
      'location': 'Abuja, Nigeria',
    },
    {
      'id': 'CUS-1003',
      'name': 'David Okafor',
      'email': 'david@example.com',
      'phone': '+234 803 456 7890',
      'rides': 0,
      'spent': 0.0,
      'status': 'Pending',
      'joined': '04 Mar 2026',
      'location': 'Port Harcourt, Nigeria',
    },
    {
      'id': 'CUS-1004',
      'name': 'Sarah Adeyemi',
      'email': 'sarah@example.com',
      'phone': '+234 804 567 8901',
      'rides': 42,
      'spent': 328000.0,
      'status': 'Active',
      'joined': '22 Dec 2025',
      'location': 'Ibadan, Nigeria',
    },
    {
      'id': 'CUS-1005',
      'name': 'Daniel Ibrahim',
      'email': 'daniel@example.com',
      'phone': '+234 805 678 9012',
      'rides': 7,
      'spent': 41500.0,
      'status': 'Suspended',
      'joined': '15 Mar 2026',
      'location': 'Kano, Nigeria',
    },
    {
      'id': 'CUS-1006',
      'name': 'Esther Okoro',
      'email': 'esther@example.com',
      'phone': '+234 806 789 0123',
      'rides': 12,
      'spent': 97500.0,
      'status': 'Active',
      'joined': '28 Apr 2026',
      'location': 'Lagos, Nigeria',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredCustomers {
    final query = searchController.text.trim().toLowerCase();

    return customers.where((customer) {
      final matchesSearch =
          customer['name'].toString().toLowerCase().contains(query) ||
          customer['email'].toString().toLowerCase().contains(query) ||
          customer['phone'].toString().toLowerCase().contains(query) ||
          customer['id'].toString().toLowerCase().contains(query);

      final matchesFilter =
          selectedFilter == 'All' || customer['status'] == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String formatMoney(dynamic amount) {
    final value = (amount as num).toDouble();
    final wholeAmount = value.toStringAsFixed(0);
    final formatted = StringBuffer();

    for (int i = 0; i < wholeAmount.length; i++) {
      if (i > 0 && (wholeAmount.length - i) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(wholeAmount[i]);
    }

    return '₦${formatted.toString()}';
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void showCustomerDetails(Map<String, dynamic> customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = customer['status'].toString();
    final color = statusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF211C2B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryPurple.withValues(alpha: 0.12),
                      child: Text(
                        customer['name']
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: primaryPurple,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'].toString(),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            customer['id'].toString(),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),
                const Text(
                  'Customer Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                _detailRow(
                  Icons.email_outlined,
                  'Email address',
                  customer['email'].toString(),
                ),
                _detailRow(
                  Icons.phone_outlined,
                  'Phone number',
                  customer['phone'].toString(),
                ),
                _detailRow(
                  Icons.location_on_outlined,
                  'Location',
                  customer['location'].toString(),
                ),
                _detailRow(
                  Icons.calendar_today_outlined,
                  'Date joined',
                  customer['joined'].toString(),
                ),

                const SizedBox(height: 18),
                const Text(
                  'Ride Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Total rides',
                        customer['rides'].toString(),
                        Icons.local_taxi_outlined,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        'Total spent',
                        formatMoney(customer['spent']),
                        Icons.payments_outlined,
                        isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: primaryPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close details'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF30283D) : const Color(0xFFF8F7FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryPurple, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF211C2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleCustomers = filteredCustomers;

    final activeCount = customers.where((c) => c['status'] == 'Active').length;
    final pendingCount = customers
        .where((c) => c['status'] == 'Pending')
        .length;
    customers.where((c) => c['status'] == 'Suspended').length;

    final totalSpent = customers.fold<double>(
      0,
      (sum, customer) => sum + (customer['spent'] as num).toDouble(),
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121018)
          : const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Ride Customers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark
            ? const Color(0xFF121018)
            : const Color(0xFFF8F7FC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              'Customer Management',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildStatCard(
                  title: 'Total customers',
                  value: customers.length.toString(),
                  icon: Icons.people_outline,
                  color: primaryPurple,
                  isDark: isDark,
                ),
                _buildStatCard(
                  title: 'Active customers',
                  value: activeCount.toString(),
                  icon: Icons.person_outline,
                  color: Colors.green,
                  isDark: isDark,
                ),
                _buildStatCard(
                  title: 'Pending accounts',
                  value: pendingCount.toString(),
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                  isDark: isDark,
                ),
                _buildStatCard(
                  title: 'Total ride spending',
                  value: formatMoney(totalSpent),
                  icon: Icons.payments_outlined,
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 26),

            Text(
              'Customers',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name, ID, email or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF211C2B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All'),
                  _filterChip('Active'),
                  _filterChip('Pending'),
                  _filterChip('Suspended'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${visibleCustomers.length} customer(s)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (selectedFilter != 'All' || searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      searchController.clear();
                      setState(() => selectedFilter = 'All');
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            if (visibleCustomers.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF211C2B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 46,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No customers found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try another search or filter.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...visibleCustomers.map(
                (customer) => _customerCard(customer, isDark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: primaryPurple.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected ? primaryPurple : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected
              ? primaryPurple.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.25),
        ),
        onSelected: (_) {
          setState(() => selectedFilter = label);
        },
      ),
    );
  }

  Widget _customerCard(Map<String, dynamic> customer, bool isDark) {
    final status = customer['status'].toString();
    final color = statusColor(status);
    final name = customer['name'].toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? const Color(0xFF211C2B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showCustomerDetails(customer),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: primaryPurple.withValues(alpha: 0.12),
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer['id'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      customer['phone'].toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${customer['rides']} rides',
                    style: const TextStyle(
                      color: primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      customer['email'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
