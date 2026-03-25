import 'package:flutter/material.dart';
import 'package:senmi/screen_pages/features/customer/track_package.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../../services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key}); // ✅ FIXED

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final description = TextEditingController();
  final pickup = TextEditingController();
  final delivery = TextEditingController();
  final price = TextEditingController();

  bool loading = false;

  void create() async {
    setState(() => loading = true);

    final res = await ApiService.createPackage({
      "description": description.text,
      "pickup_address": pickup.text,
      "delivery_address": delivery.text,
      "price": double.parse(price.text),
    });

    setState(() => loading = false);

    if (res['id'] != null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Created")));

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Package")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: pickup,
              decoration: const InputDecoration(labelText: "Pickup Address"),
            ),
            TextField(
              controller: delivery,
              decoration: const InputDecoration(labelText: "Delivery Address"),
            ),
            TextField(
              controller: price,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: "Create",
                    onPressed: create,
                  ),
          ],
        ),
      ),
    );
  }
}

class CustomerPackagesScreen extends StatefulWidget {
  const CustomerPackagesScreen({super.key});

  @override
  State<CustomerPackagesScreen> createState() =>
      _CustomerPackagesScreenState();
}

class _CustomerPackagesScreenState extends State<CustomerPackagesScreen> {
  List packages = [];

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future fetchPackages() async {
    var data = await ApiService.getCustomerPackages();
    setState(() {
      packages = data;
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
            MaterialPageRoute(
              builder: (_) => const CreatePackageScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: ListView.builder(
        itemCount: packages.length,
        itemBuilder: (context, index) {
          var p = packages[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackingScreen(packageId: p['id']),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['description'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("📍 Status: ${p['status']}"),
                    const SizedBox(height: 8),
                    Text("💰 ₦${p['price']}"),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}