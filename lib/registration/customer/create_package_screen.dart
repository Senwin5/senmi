import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Created")));

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
            TextField(controller: description, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: pickup, decoration: const InputDecoration(labelText: "Pickup Address")),
            TextField(controller: delivery, decoration: const InputDecoration(labelText: "Delivery Address")),
            TextField(controller: price, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : CustomButton(text: "Create", onPressed: create)
          ],
        ),
      ),
    );
  }
}

class CustomerPackagesScreen extends StatefulWidget {
  @override
  _CustomerPackagesScreenState createState() => _CustomerPackagesScreenState();
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
      body: ListView.builder(
        itemCount: packages.length,
        itemBuilder: (context, index) {
          var p = packages[index];

          // 👇 YOUR CARD GOES HERE
          return Card(
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
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("📍 Status: ${p['status']}"),
                  const SizedBox(height: 8),
                  Text("💰 ₦${p['price']}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingScreen(packageId: p['id']),
      ),
    );
  },
  child: Card(
    // your card here
  ),
)

floatingActionButton: FloatingActionButton(
  onPressed: () {
    // go to create package
  },
  child: Icon(Icons.add),
),