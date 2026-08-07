import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:senmi/screen_package_pages/features/rider/rider_package/rider_package_detail.dart';
import 'package:senmi/services/api_service.dart';

class RiderHistoryScreen extends StatefulWidget {
  const RiderHistoryScreen({super.key});

  @override
  State<RiderHistoryScreen> createState() => _RiderHistoryScreenState();
}

class _RiderHistoryScreenState extends State<RiderHistoryScreen> {
  List transactions = [];
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
      final tx = await ApiService.getTransactions();

      if (!mounted) return;

      setState(() {
        transactions = tx;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = "Unable to load transaction history";
      });
    }
  }

  Color getTransactionColor(String type) {
    if (type == "withdrawal") {
      return Colors.red;
    }

    return const Color.fromARGB(255, 73, 135, 76);
  }

  IconData getTransactionIcon(String type) {
    if (type == "withdrawal") {
      return Icons.arrow_upward;
    }

    return Icons.two_wheeler;
  }

  String formatTransactionDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return "";
    }

    try {
      final date = DateTime.parse(value.toString());

      return DateFormat("dd MMM yyyy, hh:mm a").format(date.toLocal());
    } catch (e) {
      return value.toString();
    }
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
          ? Center(
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
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
            )
          : RefreshIndicator(
              onRefresh: fetchTransactions,

              child: transactions.isEmpty
                  ? ListView(
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
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),

                                const SizedBox(height: 16),

                                Text(
                                  "No transactions found",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,

                      itemBuilder: (context, index) {
                        final tx = transactions[index];

                        final type = (tx['type'] ?? '')
                            .toString()
                            .toLowerCase();

                        final transactionType = (tx['icon_type'] ?? type)
                            .toString()
                            .toLowerCase();

                        final color = getTransactionColor(transactionType);

                        final icon = getTransactionIcon(transactionType);

                        final amount = (tx['amount'] ?? 0).toDouble();

                        final isCredit = type == 'credit';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDark ? Colors.grey[900] : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 6),

                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),

                            onTap: () async {
                              // Only delivery transactions have a package
                              final packageId = tx['package_id'];

                              if (packageId == null ||
                                  packageId.toString().isEmpty) {
                                return;
                              }

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RiderPackageDetailScreen(
                                    packageId: packageId.toString(),

                                    // History is showing an old/completed delivery,
                                    // so this should normally be false.
                                    hasActiveDelivery: false,
                                  ),
                                ),
                              );
                            },

                            child: Padding(
                              padding: const EdgeInsets.all(12),

                              child: Row(
                                children: [
                                  // =========================
                                  // ICON
                                  // =========================
                                  CircleAvatar(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          tx['title'] ?? 'Transaction',

                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        if (tx['package_id'] != null)
                                          Text(
                                            "Package: ${tx['package_id']}",

                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),

                                        const SizedBox(height: 4),

                                        Text(
                                          formatTransactionDate(tx['date']),

                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // =========================
                                  // AMOUNT + ARROW
                                  // =========================
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,

                                    children: [
                                      Text(
                                        "${isCredit ? '+' : '-'}₦${amount.toStringAsFixed(2)}",

                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: color,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      if (tx['package_id'] != null)
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
                      },
                    ),
            ),
    );
  }
}
