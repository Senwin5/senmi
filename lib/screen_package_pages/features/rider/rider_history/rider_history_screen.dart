import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    return Icons.local_shipping;
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

                        final transactionType = tx['icon_type'] ?? 'delivery';

                        final color = getTransactionColor(transactionType);

                        final icon = getTransactionIcon(transactionType);

                        final amount = (tx['amount'] ?? 0).toDouble();

                        final isCredit = tx['type'] == 'credit';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),

                          color: isDark ? Colors.grey[900] : Colors.white,

                          margin: const EdgeInsets.symmetric(vertical: 6),

                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),

                            // =========================
                            // ICON
                            // =========================
                            leading: CircleAvatar(
                              backgroundColor:
                                  // ignore: deprecated_member_use
                                  color.withOpacity(0.15),

                              child: Icon(icon, color: color),
                            ),

                            // =========================
                            // TITLE
                            // =========================
                            title: Text(
                              tx['title'] ?? 'Transaction',

                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,

                                fontWeight: FontWeight.bold,

                                fontSize: 16,
                              ),
                            ),

                            // =========================
                            // DETAILS
                            // =========================
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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

                            // =========================
                            // AMOUNT
                            // =========================
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,

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
