import 'package:flutter/material.dart';
import 'package:senmi/widgets/custom_buttom.dart';
import '../../../services/api_service.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  final description = TextEditingController();

  // PICKUP
  final pickupAddress = TextEditingController();
  final senderName = TextEditingController();
  final senderPhone = TextEditingController();

  // DROPOFF
  final deliveryAddress = TextEditingController();
  final receiverName = TextEditingController();
  final receiverPhone = TextEditingController();

  final price = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  void create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final res = await ApiService.createPackage({
      "description": description.text,
      "pickup_address": pickupAddress.text,
      "delivery_address": deliveryAddress.text,
      "price": double.tryParse(price.text) ?? 0,

      // 🔥 NEW FIELDS (make sure your Django API supports them)
      "sender_name": senderName.text,
      "sender_phone": senderPhone.text,
      "receiver_name": receiverName.text,
      "receiver_phone": receiverPhone.text,
    });

    setState(() => loading = false);

    if (res['id'] != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Package created!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to create package.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Add Package"),
        backgroundColor: const Color(0xFF5F5FFF),
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 🚚 IMAGE
                  Image.asset("assets/images/delivery.png", height: 120),

                  const SizedBox(height: 20),

                  // 📦 DESCRIPTION
                  _sectionCard(
                    title: "Package Info",
                    children: [
                      _input(description, "Description", Icons.description),
                      const SizedBox(height: 12),
                      _input(price, "Price", Icons.attach_money, isNumber: true),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 📍 PICKUP SECTION
                  _sectionCard(
                    title: "Pick-up details",
                    children: [
                      _input(pickupAddress, "Pick-up Address", Icons.location_on),
                      const SizedBox(height: 12),
                      _input(senderName, "Sender Name", Icons.person),
                      const SizedBox(height: 12),
                      _input(senderPhone, "Sender Phone", Icons.phone, isNumber: true),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 📍 DROPOFF SECTION
                  _sectionCard(
                    title: "Drop-off details",
                    children: [
                      _input(deliveryAddress, "Drop-off Address", Icons.location_on),
                      const SizedBox(height: 12),
                      _input(receiverName, "Receiver Name", Icons.person),
                      const SizedBox(height: 12),
                      _input(receiverPhone, "Receiver Phone", Icons.phone, isNumber: true),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🚀 BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: "Create Package",
                      onPressed: create,
                      fullWidth: true,
                      padding: const EdgeInsets.all(16),
                    ),
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

  // 🔹 SECTION CARD (like your screenshot)
  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // 🔹 INPUT FIELD
  Widget _input(TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF5F5FFF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }
}