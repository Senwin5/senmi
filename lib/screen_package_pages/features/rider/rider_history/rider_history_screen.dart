import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:senmi/screen_package_pages/features/rider/rider_wallet/rider_withdrawal_detail.dart';
import 'package:senmi/screen_package_pages/features/rider/rider_package/rider_package_detail.dart';
import 'package:senmi/services/api_service.dart';

class RiderHistoryScreen extends StatefulWidget {
  const RiderHistoryScreen({super.key});

  @override
  State<RiderHistoryScreen> createState() => _RiderHistoryScreenState();
}

class _RiderHistoryScreenState extends State<RiderHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];

  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getTransactions();

      debugPrint("TRANSACTIONS RAW: $response");

      // Convert List<dynamic> -> List<Map<String, dynamic>>
      final parsedTransactions = (response)
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      debugPrint("PARSED TRANSACTIONS: $parsedTransactions");

      if (!mounted) return;

      setState(() {
        transactions = parsedTransactions;
        loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("HISTORY ERROR: $e");
      debugPrint("$stackTrace");

      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = "Unable to load transaction history";
      });
    }
  }

  Color getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case "withdrawal":
      case "debit":
        return Colors.red;

      case "delivery":
      case "credit":
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  IconData getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case "withdrawal":
      case "debit":
        return Icons.arrow_upward;

      case "delivery":
      case "credit":
        return Icons.two_wheeler;

      default:
        return Icons.receipt_long;
    }
  }

  String formatTransactionDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "";
    }

    try {
      final date = DateTime.parse(value.toString());

      return DateFormat("dd MMM yyyy, hh:mm a").format(date.toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  double getAmount(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Transaction History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTransactions,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: fetchTransactions,
              child: transactions.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                          context,
                          transactions[index],
                          isDark,
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    Map<String, dynamic> tx,
    bool isDark,
  ) {
    final type = (tx['type'] ?? '').toString().toLowerCase();

    final iconType = (tx['icon_type'] ?? type).toString().toLowerCase();

    final title = (tx['title'] ?? 'Transaction').toString();

    final description = (tx['description'] ?? '').toString();

    final packageId = tx['package_id'];

    final amount = getAmount(tx['amount']);

    final date = formatTransactionDate(tx['date']);

    final isCredit = type == 'credit';

    final color = getTransactionColor(iconType);

    final icon = getTransactionIcon(iconType);

    final isWithdrawal = iconType == 'withdrawal';

    final isDelivery = packageId != null && packageId.toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isDark ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        // Only delivery/package transactions are clickable.
        onTap: isWithdrawal
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RiderWithdrawalDetailScreen(transaction: tx),
                  ),
                );
              }
            : isDelivery
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RiderPackageDetailScreen(
                      packageId: packageId.toString(),
                      hasActiveDelivery: false,
                    ),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // =========================
              // ICON
              // =========================
              CircleAvatar(
                radius: 24,
                // ignore: deprecated_member_use
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),

              const SizedBox(width: 12),

              // =========================
              // DETAILS
              // =========================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // DELIVERY
                    if (isDelivery)
                      Text(
                        "Package: ${packageId.toString()}",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    // WITHDRAWAL
                    else if (isWithdrawal)
                      Text(
                        description.isNotEmpty
                            ? description
                            : "Withdrawal request",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                      )
                    // OTHER TRANSACTION
                    else if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                    const SizedBox(height: 5),

                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =========================
              // AMOUNT
              // =========================
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isCredit ? '+' : '-'}₦${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Only package transactions get arrow.
                  if (isDelivery)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),

                const SizedBox(height: 16),

                Text(
                  "No transactions found",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 20),

            Text(
              errorMessage ?? "Unable to load transactions",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Please check your connection and try again",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: fetchTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
