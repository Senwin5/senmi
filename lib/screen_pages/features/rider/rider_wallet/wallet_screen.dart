// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class RiderWalletScreen extends StatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  State<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  double balance = 0;
  double totalEarned = 0;
  int totalDeliveries = 0;

  List transactions = [];
  bool loading = true;
  bool showBalance = true;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future fetchWallet() async {
    setState(() => loading = true);

    try {
      final wallet = await ApiService.getWallet();
      final tx = await ApiService.getTransactions();
      final earningsData = await ApiService.getEarnings();

      if (!mounted) return;

      setState(() {
        balance = wallet['balance']?.toDouble() ?? 0;
        totalEarned = (earningsData['total_earnings'] ?? 0).toDouble();

        totalDeliveries =
            (earningsData['total_deliveries'] ??
                    earningsData['deliveries'] ??
                    earningsData['completed_deliveries'] ??
                    0)
                .toInt();

        transactions = tx;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load wallet: $e")));
    }
  }

  void withdraw() async {
    final amountController = TextEditingController();
    final accountController = TextEditingController();

    List banks = [];
    String? selectedBankCode;
    bool isLoading = false;

    try {
      banks = await ApiService.getBanks();

      // ✅ FIX: ensure all bank codes are strings
      banks = banks.map((b) {
        b['code'] = b['code'].toString();
        return b;
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load banks")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Withdraw",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      prefixText: "₦ ",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Account Number",
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    hint: const Text("Select Bank"),
                    initialValue: selectedBankCode,
                    isExpanded: true,
                    items: banks.map<DropdownMenuItem<String>>((bank) {
                      return DropdownMenuItem(
                        value: bank['code'].toString(), // ✅ FIX
                        child: Text(
                          bank['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedBankCode = val;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  if (isLoading) const CircularProgressIndicator(),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final amt =
                                  double.tryParse(amountController.text) ?? 0;

                              if (amt <= 0 ||
                                  accountController.text.isEmpty ||
                                  selectedBankCode == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Fill all fields correctly"),
                                  ),
                                );
                                return;
                              }

                              setStateDialog(() => isLoading = true);

                              try {
                                await ApiService.withdraw(
                                  amount: amt,
                                  accountNumber: accountController.text,
                                  bankCode: selectedBankCode!
                                      .toString(), // ✅ FIX
                                );

                                if (!mounted) return;

                                Navigator.pop(context);
                                fetchWallet();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Withdrawal successful"),
                                  ),
                                );
                              } catch (e) {
                                setStateDialog(() => isLoading = false);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            },
                      child: const Text("Withdraw"),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void openWithdrawDialog() async {
    final amountController = TextEditingController();
    final accountController = TextEditingController();

    List banks = await ApiService.getBanks();

    String? selectedBankCode;
    String? accountName;
    bool verifying = false;
    bool loading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Withdraw"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount"),
                  ),
                  TextField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Account Number",
                    ),
                    onChanged: (value) async {
                      if (value.length == 10 && selectedBankCode != null) {
                        setStateDialog(() => verifying = true);

                        try {
                          final name = await ApiService.resolveAccount(
                            accountNumber: value,
                            bankCode: selectedBankCode!.toString(), // ✅ FIX
                          );

                          setStateDialog(() {
                            accountName = name;
                            verifying = false;
                          });
                        } catch (e) {
                          setStateDialog(() {
                            accountName = null;
                            verifying = false;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    hint: const Text("Select Bank"),
                    initialValue: selectedBankCode,
                    items: banks.map<DropdownMenuItem<String>>((bank) {
                      return DropdownMenuItem(
                        value: bank['code'].toString(), // ✅ FIX
                        child: Text(
                          bank['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedBankCode = val;
                        accountName = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (verifying) const CircularProgressIndicator(),
                  if (accountName != null)
                    Text(
                      accountName!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final amt = double.tryParse(amountController.text) ?? 0;

                        if (amt <= 0 ||
                            accountController.text.isEmpty ||
                            selectedBankCode == null ||
                            accountName == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Complete all fields"),
                            ),
                          );
                          return;
                        }

                        setStateDialog(() => loading = true);

                        try {
                          await ApiService.withdraw(
                            amount: amt,
                            accountNumber: accountController.text,
                            bankCode: selectedBankCode!.toString(), // ✅ FIX
                          );

                          Navigator.pop(context);
                          fetchWallet();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Withdrawal successful"),
                            ),
                          );
                        } catch (e) {
                          setStateDialog(() => loading = false);

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                child: const Text("Withdraw"),
              ),
            ],
          );
        },
      ),
    );
  }

  Color getTransactionColor(String type) {
    return type.toLowerCase().contains("withdraw") ||
            type.toLowerCase().contains("payment sent")
        ? Colors.red
        : Colors.green;
  }

  IconData getTransactionIcon(String type) {
    return type.toLowerCase().contains("withdraw") ||
            type.toLowerCase().contains("payment sent")
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Wallet", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchWallet),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurple],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Available Balance",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                showBalance
                                    ? "₦${balance.toStringAsFixed(2)}"
                                    : "****",
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  showBalance
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    setState(() => showBalance = !showBalance),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Total Earned: ₦${totalEarned.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: balance <= 0 ? null : withdraw,
                            icon: const Icon(Icons.arrow_upward),
                            label: const Text(
                              "Withdraw",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.deepPurple,
                                    Colors.deepPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.local_shipping,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Deliveries",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalDeliveries.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.deepPurpleAccent,
                                    Colors.deepPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.payments,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Per Delivery",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalDeliveries == 0
                                        ? "₦0"
                                        : "₦${(totalEarned / totalDeliveries).toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final color = getTransactionColor(tx['type'] ?? '');
                        final icon = getTransactionIcon(tx['type'] ?? '');

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              // ignore: deprecated_member_use
                              backgroundColor: color.withOpacity(0.2),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(tx['type'] ?? ''),
                            subtitle: Text(tx['date'] ?? ''),
                            trailing: Text(
                              "₦${tx['amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
