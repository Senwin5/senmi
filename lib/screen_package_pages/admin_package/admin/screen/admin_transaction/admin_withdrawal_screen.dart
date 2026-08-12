// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

class AdminWithdrawalScreen extends StatefulWidget {
  const AdminWithdrawalScreen({super.key});

  @override
  State<AdminWithdrawalScreen> createState() => _AdminWithdrawalScreenState();
}

class _AdminWithdrawalScreenState extends State<AdminWithdrawalScreen> {
  bool loading = true;
  List withdrawals = [];

  @override
  void initState() {
    super.initState();
    fetchWithdrawals();
  }

  // =========================================================
  // FETCH WITHDRAWALS
  // =========================================================

  Future<void> fetchWithdrawals() async {
    try {
      final data = await ApiService.getAdminWithdrawals();

      if (!mounted) return;

      setState(() {
        withdrawals = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("Withdrawal fetch error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load withdrawals: $e")));
    }
  }

  // =========================================================
  // APPROVE
  // =========================================================

  Future<void> approve(int id) async {
    try {
      setState(() {
        loading = true;
      });

      await ApiService.approveWithdrawal(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Withdrawal approved and sent for processing."),
          backgroundColor: Colors.green,
        ),
      );

      await fetchWithdrawals();
    } catch (e) {
      debugPrint("Approve withdrawal error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Approval failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // REJECT
  // =========================================================

  Future<void> reject(int id) async {
    try {
      setState(() {
        loading = true;
      });

      await ApiService.rejectWithdrawal(id, "Rejected by admin");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Withdrawal rejected and money returned to rider wallet.",
          ),
          backgroundColor: Colors.orange,
        ),
      );

      await fetchWithdrawals();
    } catch (e) {
      debugPrint("Reject withdrawal error: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rejection failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // CONFIRM APPROVE
  // =========================================================

  Future<void> confirmApprove(int id, double amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Approve Withdrawal?"),
          content: Text(
            "Are you sure you want to approve "
            "₦${amount.toStringAsFixed(2)}?\n\n"
            "The withdrawal will be sent to Paystack for processing.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Approve"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await approve(id);
    }
  }

  // =========================================================
  // CONFIRM REJECT
  // =========================================================

  Future<void> confirmReject(int id, double amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Withdrawal?"),
          content: Text(
            "Reject ₦${amount.toStringAsFixed(2)} withdrawal?\n\n"
            "The money will be returned to the rider wallet.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                "Reject",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await reject(id);
    }
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget statusBadge(String status) {
    Color color;

    switch (status) {
      case "pending":
        color = Colors.orange;
        break;

      case "approved":
        color = Colors.blue;
        break;

      case "processing":
        color = Colors.indigo;
        break;

      case "success":
        color = Colors.green;
        break;

      case "failed":
        color = Colors.red;
        break;

      case "rejected":
        color = Colors.red;
        break;

      case "reversed":
        color = Colors.deepOrange;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Withdrawals",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWithdrawals,
              child: withdrawals.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            "No withdrawals found",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: withdrawals.length,
                      itemBuilder: (context, index) {
                        final w = withdrawals[index];

                        final int id = w['id'];

                        final double amount =
                            double.tryParse(w['amount'].toString()) ?? 0;

                        final String rider =
                            w['rider']?.toString() ?? "Unknown rider";

                        final String status =
                            w['status']?.toString() ?? "unknown";

                        final String date = w['created_at']?.toString() ?? "";

                        final String accountName =
                            w['account_name']?.toString() ?? "";

                        final String bankAccount =
                            w['bank_account']?.toString() ?? "";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ==========================
                                // RIDER
                                // ==========================
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rider,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Withdrawal #$id",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    statusBadge(status),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // ==========================
                                // AMOUNT
                                // ==========================
                                Text(
                                  "₦${amount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // ==========================
                                // BANK
                                // ==========================
                                if (accountName.isNotEmpty)
                                  Text(
                                    "Account: $accountName",
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                if (bankAccount.isNotEmpty)
                                  Text(
                                    "Bank Account: $bankAccount",
                                    style: const TextStyle(fontSize: 14),
                                  ),

                                const SizedBox(height: 8),

                                Text(
                                  "Date: $date",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // ==========================
                                // ACTIONS
                                // ==========================
                                if (status == "pending")
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              confirmApprove(id, amount),
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Approve",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 13,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              confirmReject(id, amount),
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            "Reject",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 13,
                                            ),
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                // ==========================
                                // PROCESSING
                                // ==========================
                                if (status == "processing")
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Payment is being processed by Paystack...",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // ==========================
                                // SUCCESS
                                // ==========================
                                if (status == "success")
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Withdrawal completed successfully.",
                                        ),
                                      ],
                                    ),
                                  ),

                                // ==========================
                                // FAILED
                                // ==========================
                                if (status == "failed")
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Failed: ${w['reason'] ?? 'Unknown error'}",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
