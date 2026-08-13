// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  bool loading = true;
  List<Map<String, dynamic>> wallets = [];
  List<Map<String, dynamic>> filtered = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWallets();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchWallets() async {
    try {
      final data = await ApiService.getAdminRiderWallets();
      if (!mounted) return;

      final list = (data)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        wallets = list;
        loading = false;
      });
      _applyFilter(searchController.text);
    } catch (e) {
      debugPrint("Wallet fetch error: $e");
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load rider wallets: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();

    final result = wallets.where((w) {
      final email = (w["email"] ?? "").toString().toLowerCase();
      final username = (w["username"] ?? "").toString().toLowerCase();
      final riderId = (w["rider_id"] ?? w["user_id"] ?? "").toString().toLowerCase();
      return q.isEmpty ||
          email.contains(q) ||
          username.contains(q) ||
          riderId.contains(q);
    }).toList();

    if (mounted) setState(() => filtered = result);
  }

  double _number(dynamic value) =>
      double.tryParse(value?.toString().replaceAll(",", "") ?? "") ?? 0;

  String _money(dynamic value) => _number(value).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Rider Wallets",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWallets,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: TextField(
                      controller: searchController,
                      onChanged: _applyFilter,
                      decoration: InputDecoration(
                        hintText: "Search email, name or rider ID",
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  _applyFilter("");
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _summary(
                          "Riders",
                          filtered.length.toString(),
                          Icons.people_alt_outlined,
                          Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        _summary(
                          "Visible balance",
                          "₦${filtered.fold<double>(0, (s, w) => s + _number(w["balance"])).toStringAsFixed(2)}",
                          Icons.account_balance_wallet_outlined,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Icon(Icons.wallet_outlined,
                                  size: 52, color: Colors.grey),
                              SizedBox(height: 12),
                              Center(child: Text("No rider wallets found")),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                            itemCount: filtered.length,
                            itemBuilder: (_, index) =>
                                _walletCard(filtered[index]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summary(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: color, fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletCard(Map<String, dynamic> w) {
    final email = (w["email"] ?? "No email").toString();
    final username = (w["username"] ?? "").toString();
    final riderId = (w["rider_id"] ?? w["user_id"] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.withOpacity(.10),
                child: Text(
                  (username.isNotEmpty ? username : email)
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (username.isNotEmpty)
                      Text(username,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: username.isEmpty ? 15 : 12)),
                    if (riderId.isNotEmpty)
                      Text(riderId,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _moneyBox("Available balance", _money(w["balance"]), Colors.green),
              const SizedBox(width: 10),
              _moneyBox("Total earned", _money(w["total_earned"]), Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moneyBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withOpacity(.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 11)),
            const SizedBox(height: 5),
            Text("₦$value",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
