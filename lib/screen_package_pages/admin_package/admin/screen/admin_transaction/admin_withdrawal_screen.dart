// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_transaction/admin_withdrawal_details_screen.dart';
import 'package:senmi/services/api_service.dart';

class AdminWithdrawalScreen extends StatefulWidget {
  const AdminWithdrawalScreen({super.key});

  @override
  State<AdminWithdrawalScreen> createState() =>
      _AdminWithdrawalScreenState();
}

class _AdminWithdrawalScreenState extends State<AdminWithdrawalScreen> {
  bool loading = true;
  List<dynamic> withdrawals = [];

  @override
  void initState() {
    super.initState();
    fetchWithdrawals();
  }

  // =========================================================
  // FETCH
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load withdrawals: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
          content: Text(
            "Withdrawal approved and sent to Paystack.",
          ),
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

  Future<void> reject(
    int id,
    String reason,
  ) async {
    try {
      setState(() {
        loading = true;
      });

      await ApiService.rejectWithdrawal(
        id,
        reason,
      );

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
  // APPROVE CONFIRMATION
  // =========================================================

  Future<void> confirmApprove(
    Map<String, dynamic> withdrawal,
  ) async {
    final int id = withdrawal["id"];

    final double amount =
        double.tryParse(
              withdrawal["amount"].toString(),
            ) ??
            0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Approve Withdrawal?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Approve ₦${amount.toStringAsFixed(2)} withdrawal?\n\n"
            "Senmi will send the withdrawal to Paystack. "
            "Paystack will determine the final transfer result.",
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
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
  // REJECT CONFIRMATION
  // =========================================================

  Future<void> confirmReject(
    Map<String, dynamic> withdrawal,
  ) async {
    final int id = withdrawal["id"];

    final double amount =
        double.tryParse(
              withdrawal["amount"].toString(),
            ) ??
            0;

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Reject Withdrawal",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "₦${amount.toStringAsFixed(2)} will be returned to the rider wallet.",
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Reason for rejection",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text.trim().isEmpty
                      ? "Rejected by admin"
                      : controller.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason != null) {
      await reject(id, reason);
    }
  }

  // =========================================================
  // STATUS
  // =========================================================

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;

      case "approved":
        return Colors.blue;

      case "processing":
        return Colors.indigo;

      case "success":
        return Colors.green;

      case "failed":
        return Colors.red;

      case "rejected":
        return Colors.red;

      case "reversed":
        return Colors.deepOrange;

      default:
        return Colors.grey;
    }
  }

  String statusDescription(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Waiting for admin approval";

      case "approved":
        return "Approved for processing";

      case "processing":
        return "Paystack is processing the transfer";

      case "success":
        return "Money successfully transferred";

      case "failed":
        return "Transfer failed and wallet should be refunded";

      case "rejected":
        return "Rejected by Senmi admin";

      case "reversed":
        return "Transfer was reversed and wallet should be refunded";

      default:
        return "Unknown withdrawal status";
    }
  }

  Widget statusBadge(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(.25),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // OPEN DETAILS
  // =========================================================

  void openDetails(Map<String, dynamic> withdrawal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminWithdrawalDetailsScreen(
          withdrawal: withdrawal,
          onRefresh: fetchWithdrawals,
          onApprove: approve,
          onReject: reject,
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        actions: [
          IconButton(
            onPressed: fetchWithdrawals,
            icon: const Icon(
              Icons.refresh,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: fetchWithdrawals,
              child: withdrawals.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            "No withdrawals found",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: withdrawals.length,
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> w =
                            Map<String, dynamic>.from(
                          withdrawals[index],
                        );

                        final amount =
                            double.tryParse(
                                  w["amount"].toString(),
                                ) ??
                                0;

                        final rider =
                            w["rider"]?.toString() ??
                                "Unknown rider";

                        final status =
                            w["status"]?.toString() ??
                                "unknown";

                        final accountName =
                            w["account_name"]?.toString() ??
                                "";

                        final bankAccount =
                            w["bank_account"]?.toString() ??
                                "";

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(18),
                            onTap: () => openDetails(w),
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            statusColor(
                                          status,
                                        ).withOpacity(.10),
                                        child: Icon(
                                          Icons
                                              .account_balance_wallet,
                                          color:
                                              statusColor(
                                            status,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              rider,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 3,
                                            ),
                                            Text(
                                              "Withdrawal #${w["id"]}",
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      statusBadge(status),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  Text(
                                    "₦${amount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    statusDescription(status),
                                    style: TextStyle(
                                      color:
                                          statusColor(status),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  if (accountName.isNotEmpty)
                                    Text(
                                      accountName,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),

                                  if (bankAccount.isNotEmpty)
                                    Text(
                                      "•••• ${bankAccount.length > 4 ? bankAccount.substring(bankAccount.length - 4) : bankAccount}",
                                      style:
                                          const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),

                                  const SizedBox(height: 12),

                                  const Row(
                                    children: [
                                      Text(
                                        "View full withdrawal details",
                                        style: TextStyle(
                                          color:
                                              Colors.blue,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        Icons
                                            .arrow_forward_ios,
                                        size: 14,
                                        color:
                                            Colors.blue,
                                      ),
                                    ],
                                  ),

                                  if (status == "pending") ...[
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              ElevatedButton(
                                            onPressed: () =>
                                                confirmApprove(
                                              w,
                                            ),
                                            style:
                                                ElevatedButton
                                                    .styleFrom(
                                              backgroundColor:
                                                  Colors.green,
                                              foregroundColor:
                                                  Colors.white,
                                            ),
                                            child:
                                                const Text(
                                              "Approve",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child:
                                              OutlinedButton(
                                            onPressed: () =>
                                                confirmReject(
                                              w,
                                            ),
                                            style:
                                                OutlinedButton
                                                    .styleFrom(
                                              foregroundColor:
                                                  Colors.red,
                                              side:
                                                  const BorderSide(
                                                color:
                                                    Colors.red,
                                              ),
                                            ),
                                            child:
                                                const Text(
                                              "Reject",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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