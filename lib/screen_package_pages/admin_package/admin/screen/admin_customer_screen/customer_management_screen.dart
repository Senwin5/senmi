import 'package:flutter/material.dart';
import 'package:senmi/services/admin_service.dart';
import 'customer_details_screen.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  bool isLoading = true;

  List customers = [];
  List filteredCustomers = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    setState(() => isLoading = true);

    try {
      final data = await AdminService.getCustomers();

      customers = data;
      filteredCustomers = data;
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;

    setState(() => isLoading = false);
  }

  void searchCustomers(String query) {
    query = query.toLowerCase();

    filteredCustomers = customers.where((customer) {
      return customer['username'].toString().toLowerCase().contains(query) ||
          customer['email'].toString().toLowerCase().contains(query) ||
          customer['user_id'].toString().toLowerCase().contains(query) ||
          customer['phone_number'].toString().toLowerCase().contains(query);
    }).toList();

    setState(() {});
  }

  Widget customerCard(Map customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailsScreen(customerId: customer['id']),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      customer['username'].toString().isNotEmpty
                          ? customer['username'][0].toUpperCase()
                          : "C",
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          customer['username'].toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          customer['user_id'].toString(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(customer['email'] ?? ""),

              const SizedBox(height: 6),

              Text(customer['phone_number'] ?? ""),

              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    children: [
                      const Text("Packages"),

                      Text(
                        "${customer['total_packages']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      const Text("Spent"),

                      Text(
                        "₦${customer['total_spent']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Management")),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(
              controller: searchController,

              onChanged: searchCustomers,

              decoration: InputDecoration(
                hintText: "Search customer...",
                prefixIcon: const Icon(Icons.search),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadCustomers,

                    child: filteredCustomers.isEmpty
                        ? const Center(child: Text("No customers found"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),

                            itemCount: filteredCustomers.length,

                            itemBuilder: (context, index) {
                              return customerCard(filteredCustomers[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
