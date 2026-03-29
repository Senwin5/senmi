import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/track_package.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../../services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final description = TextEditingController();
  final pickup = TextEditingController();
  final delivery = TextEditingController();
  final price = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  void create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final res = await ApiService.createPackage({
      "description": description.text,
      "pickup_address": pickup.text,
      "delivery_address": delivery.text,
      "price": double.tryParse(price.text) ?? 0,
    });

    setState(() => loading = false);

    if (res['id'] != null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Package created!")));
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to create package.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Package")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(description, "Description", Icons.description),
                  const SizedBox(height: 12),
                  _buildTextField(pickup, "Pickup Address", Icons.location_on),
                  const SizedBox(height: 12),
                  _buildTextField(delivery, "Delivery Address", Icons.location_city),
                  const SizedBox(height: 12),
                  _buildTextField(price, "Price", Icons.attach_money, isNumber: true),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(text: "Create", onPressed: create, fullWidth: true,padding: const EdgeInsets.all(16),),
                  ),
                ],
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }
}

class CustomerPackagesScreen extends StatefulWidget {
  const CustomerPackagesScreen({super.key});

  @override
  State<CustomerPackagesScreen> createState() => _CustomerPackagesScreenState();
}

class _CustomerPackagesScreenState extends State<CustomerPackagesScreen> {
  List packages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future fetchPackages() async {
    setState(() => loading = true);
    var data = await ApiService.getCustomerPackages();
    setState(() {
      packages = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Packages")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePackageScreen()),
          ).then((_) => fetchPackages());
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPackages,
              child: packages.isEmpty
                  ? const Center(child: Text("No packages yet. Tap + to create one."))
                  : ListView.builder(
                      itemCount: packages.length,
                      itemBuilder: (context, index) {
                        var p = packages[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TrackingScreen(packageId: p['id'])),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['description'],
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text("Status: ${p['status']}"),
                                    backgroundColor: Colors.blue.shade100,
                                  ),
                                  const SizedBox(height: 8),
                                  Text("💰 ₦${p['price']}", style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}