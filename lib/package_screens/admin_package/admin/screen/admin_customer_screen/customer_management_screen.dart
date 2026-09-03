// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';
import 'customer_details_screen.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  bool isLoading = true;

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];

  final searchController = TextEditingController();

  // ============================================================
  // THEME HELPERS
  // ============================================================

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get _cardColor => Theme.of(context).cardColor;

  Color get _textColor => Theme.of(context).colorScheme.onSurface;

  Color get _mutedTextColor =>
      Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.65) ??
      Colors.grey;

  Color get _borderColor => Theme.of(context).dividerColor.withOpacity(.12);

  Color get _searchBackground => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xff20242D)
      : const Color(0xffF5F7FB);

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

  // ============================================================
  // LOAD CUSTOMERS
  // ============================================================

  Future<void> loadCustomers() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final data = await ApiService.getCustomers();

      if (!mounted) return;

      final list = (data)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        customers = list;
        isLoading = false;
      });

      _search(searchController.text);
    } catch (e) {
      debugPrint("Customer load error: $e");

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load customers: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _search(String query) {
    final q = query.trim().toLowerCase();

    final result = customers.where((customer) {
      final username = (customer["username"] ?? "").toString().toLowerCase();

      final email = (customer["email"] ?? "").toString().toLowerCase();

      final userId = (customer["user_id"] ?? "").toString().toLowerCase();

      final phone = (customer["phone_number"] ?? "").toString().toLowerCase();

      return q.isEmpty ||
          username.contains(q) ||
          email.contains(q) ||
          userId.contains(q) ||
          phone.contains(q);
    }).toList();

    if (mounted) {
      setState(() => filteredCustomers = result);
    }
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(dynamic value) {
    final number =
        double.tryParse(value?.toString().replaceAll(",", "") ?? "") ?? 0;

    return number.toStringAsFixed(2);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _cardColor,
        surfaceTintColor: Colors.transparent,

        title: Text(
          "Customers",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
        ),

        iconTheme: IconThemeData(color: _textColor),
      ),

      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Column(
              children: [
                // ==================================================
                // SEARCH
                // ==================================================
                Container(
                  color: _cardColor,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
                  child: TextField(
                    controller: searchController,
                    onChanged: _search,

                    style: TextStyle(color: _textColor),

                    cursorColor: Theme.of(context).colorScheme.primary,

                    decoration: InputDecoration(
                      hintText: "Search name, email, ID or phone",

                      hintStyle: TextStyle(color: _mutedTextColor),

                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _mutedTextColor,
                      ),

                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                _search("");
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: _mutedTextColor,
                              ),
                            ),

                      filled: true,
                      fillColor: _searchBackground,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(.5),
                        ),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // CUSTOMER LIST
                // ==================================================
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadCustomers,

                    color: Theme.of(context).colorScheme.primary,

                    child: filteredCustomers.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),

                            children: [
                              const SizedBox(height: 120),

                              Icon(
                                Icons.people_outline,
                                size: 54,
                                color: _mutedTextColor,
                              ),

                              const SizedBox(height: 12),

                              Center(
                                child: Text(
                                  "No customers found",
                                  style: TextStyle(color: _mutedTextColor),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),

                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),

                            itemCount: filteredCustomers.length,

                            itemBuilder: (_, index) =>
                                _customerCard(filteredCustomers[index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // CUSTOMER CARD
  // ============================================================

  Widget _customerCard(Map<String, dynamic> customer) {
    final username = (customer["username"] ?? "Customer").toString();

    final userId = (customer["user_id"] ?? "-").toString();

    final email = (customer["email"] ?? "").toString();

    final phone = (customer["phone_number"] ?? "").toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 0,

      color: _cardColor,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _borderColor),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(customerId: customer["id"]),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              // ==================================================
              // CUSTOMER HEADER
              // ==================================================
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,

                    backgroundColor: Colors.blue.withOpacity(.10),

                    child: Text(
                      username.isNotEmpty
                          ? username.substring(0, 1).toUpperCase()
                          : "C",

                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          userId,
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _mutedTextColor,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // EMAIL
              // ==================================================
              if (email.isNotEmpty) _contactRow(Icons.email_outlined, email),

              // ==================================================
              // PHONE
              // ==================================================
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 7),

                _contactRow(Icons.phone_outlined, phone),
              ],

              Divider(height: 25, color: _borderColor),

              // ==================================================
              // CUSTOMER STATS
              // ==================================================
              Row(
                children: [
                  _stat(
                    "Packages",
                    "${customer["total_packages"] ?? 0}",
                    Icons.inventory_2_outlined,
                    Colors.blue,
                  ),

                  _stat(
                    "Spent",
                    "₦${_money(customer["total_spent"])}",
                    Icons.payments_outlined,
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTACT ROW
  // ============================================================

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _mutedTextColor),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(color: _textColor.withOpacity(.78), fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STAT
  // ============================================================

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: TextStyle(color: _mutedTextColor, fontSize: 11),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
