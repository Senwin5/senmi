import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';
import 'ride_admin_customer_details_screen.dart';

class RideAdminCustomersScreen extends StatefulWidget {
  const RideAdminCustomersScreen({
    super.key,
    required String title,
    required IconData icon,
  });

  @override
  State<RideAdminCustomersScreen> createState() =>
      _RideAdminCustomersScreenState();
}

class _RideAdminCustomersScreenState extends State<RideAdminCustomersScreen> {
  static const Color primaryPurple = Color(0xFF7C3AED);

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadCustomers() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await RideService.getAdminCustomers();

      final loadedCustomers = result.map((item) {
        final customer = Map<String, dynamic>.from(item as Map);

        final joinedValue = customer['joined']?.toString();
        String joinedDate = 'Not available';

        if (joinedValue != null && joinedValue.isNotEmpty) {
          final parsedDate = DateTime.tryParse(joinedValue);

          if (parsedDate != null) {
            joinedDate =
                '${parsedDate.day.toString().padLeft(2, '0')} '
                '${_monthName(parsedDate.month)} ${parsedDate.year}';
          } else {
            joinedDate = joinedValue;
          }
        }

        // Keep the original customer map so that recent rides,
        // ride statuses, payment details, and coordinates are preserved.
        return <String, dynamic>{
          ...customer,
          'id': customer['id']?.toString() ?? '',
          'name': customer['name']?.toString() ?? 'Unknown customer',
          'email': customer['email']?.toString() ?? '',
          'phone': customer['phone']?.toString() ?? '',
          'rides': _toInt(customer['rides']),
          'total_rides': _toInt(customer['total_rides']),
          'active_rides': _toInt(customer['active_rides']),
          'pending_rides': _toInt(customer['pending_rides']),
          'cancelled_rides': _toInt(customer['cancelled_rides']),
          'spent': _toDouble(customer['spent']),
          'status': customer['status']?.toString() ?? 'Active',
          'joined': joinedDate,
          'location': customer['location']?.toString() ?? 'Not provided',
          'recent_rides': _toRideList(
            customer['recent_rides'] ?? customer['rides_list'],
          ),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        customers = loadedCustomers;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static List<Map<String, dynamic>> _toRideList(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((ride) => Map<String, dynamic>.from(ride))
        .toList();
  }

  String _monthName(int month) {
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

    return months[month - 1];
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
          selectedFilter == 'All' ||
          customer['status'].toString().toLowerCase() ==
              selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String formatMoney(dynamic amount) {
    final value = _toDouble(amount);
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
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void openCustomerDetails(Map<String, dynamic> customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideAdminCustomerDetailsScreen(
          customer: Map<String, dynamic>.from(customer),
        ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
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
    final safeName = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

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
        onTap: () => openCustomerDetails(customer),
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
                      safeName,
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
                          'ID: ${customer['id']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      customer['phone'].toString().isEmpty
                          ? 'No phone number'
                          : customer['phone'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      customer['email'].toString().isEmpty
                          ? 'No email address'
                          : customer['email'].toString(),
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

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF211C2B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleCustomers = filteredCustomers;

    final activeCount = customers
        .where((c) => c['status'].toString().toLowerCase() == 'active')
        .length;

    final pendingCount = customers
        .where((c) => c['status'].toString().toLowerCase() == 'pending')
        .length;

    final totalSpent = customers.fold<double>(
      0,
      (sum, customer) => sum + _toDouble(customer['spent']),
    );

    final backgroundColor = isDark
        ? const Color(0xFF121018)
        : const Color(0xFFF8F7FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ride Customers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh customers',
            onPressed: isLoading ? null : loadCustomers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryPurple),
              )
            : errorMessage != null
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load customers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: loadCustomers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: loadCustomers,
                color: primaryPurple,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    Text(
                      'Customer Management',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
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
                        fillColor: isDark
                            ? const Color(0xFF211C2B)
                            : Colors.white,
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
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        if (selectedFilter != 'All' ||
                            searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                selectedFilter = 'All';
                              });
                            },
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (visibleCustomers.isEmpty)
                      _emptyState(
                        icon: Icons.person_search_outlined,
                        title: 'No customers found',
                        message: 'Try another search or filter.',
                      )
                    else
                      ...visibleCustomers.map(
                        (customer) => _customerCard(customer, isDark),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
