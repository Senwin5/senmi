// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/services/api_service.dart';

class RiderWalletScreen extends StatefulWidget {
  const RiderWalletScreen({super.key});

  @override
  State<RiderWalletScreen> createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  double balance = 0;
  double totalEarned = 0;
  int totalDeliveries = 0;

  List<Map<String, dynamic>> transactions = [];

  bool loading = true;
  bool showBalance = true;
  String? errorMessage;
  bool isSubmitting = false;

  double get avgEarning =>
      totalDeliveries == 0 ? 0 : totalEarned / totalDeliveries;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  Future fetchWallet() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final wallet = await ApiService.getWallet();
      final tx = await ApiService.getTransactions();
      final earningsData = await ApiService.getEarnings();

      if (!mounted) return;

      setState(() {
        balance = (wallet['balance'] ?? 0).toDouble();
        totalEarned = (earningsData['total_earnings'] ?? 0).toDouble();

        totalDeliveries =
            (earningsData['total_deliveries'] ??
                    earningsData['deliveries'] ??
                    earningsData['completed_deliveries'] ??
                    0)
                .toInt();

        transactions = List<Map<String, dynamic>>.from(tx);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = "Couldn't load wallet";
      });
    }
  }

  void withdraw() async {
    final amountController = TextEditingController();
    final accountController = TextEditingController();

    List banks = [];
    String? selectedBankCode;
    String? accountName;

    bool verifying = false;
    bool isLoading = false;

    try {
      banks = await ApiService.getBanks();
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            minChildSize: 0.65,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // EVERYTHING that was previously inside your Column
                    // starts here
                    const Text(
                      "Withdraw",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: amountController,
                      builder: (_, value, _) {
                        final amount = double.tryParse(value.text) ?? 0;
                        final remaining = balance - amount;

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            remaining >= 0
                                ? "Remaining Balance: ₦${remaining.toStringAsFixed(2)}"
                                : "Insufficient balance",
                            style: TextStyle(
                              color: remaining >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        prefixText: "₦ ",
                      ),
                    ),

                    TextField(
                      controller: accountController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "Account Number",
                        counterText: "",
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      onChanged: (value) async {
                        if (value.length == 10 && selectedBankCode != null) {
                          setStateDialog(() {
                            verifying = true;
                            accountName = null;
                          });

                          try {
                            final name = await ApiService.resolveAccount(
                              accountNumber: value,
                              bankCode: selectedBankCode!,
                            );

                            setStateDialog(() {
                              accountName = name;
                              verifying = false;
                            });
                          } catch (_) {
                            setStateDialog(() {
                              verifying = false;
                              accountName = null;
                            });
                          }
                        }
                      },
                    ),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Bank",
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      items: banks.map<DropdownMenuItem<String>>((bank) {
                        return DropdownMenuItem<String>(
                          value: bank['code'],
                          child: Text(
                            bank['name'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setStateDialog(() {
                          selectedBankCode = value;
                          accountName = null;
                        });

                        if (accountController.text.length == 10 &&
                            value != null) {
                          setStateDialog(() => verifying = true);

                          try {
                            final name = await ApiService.resolveAccount(
                              accountNumber: accountController.text,
                              bankCode: value,
                            );

                            setStateDialog(() {
                              accountName = name;
                              verifying = false;
                            });
                          } catch (_) {
                            setStateDialog(() {
                              verifying = false;
                              accountName = null;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    if (verifying) const LinearProgressIndicator(),

                    if (accountName != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                accountName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                final amt =
                                    double.tryParse(amountController.text) ?? 0;

                                if (amt <= 0 ||
                                    accountController.text.isEmpty ||
                                    selectedBankCode == null ||
                                    accountName == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Fill all fields"),
                                    ),
                                  );
                                  return;
                                }

                                if (amt > balance) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Insufficient balance"),
                                    ),
                                  );
                                  return;
                                }

                                setStateDialog(() {
                                  isLoading = true;
                                });

                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Confirm Withdrawal"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Amount: ₦${amt.toStringAsFixed(2)}",
                                        ),
                                        Text(
                                          "Account: ${accountController.text}",
                                        ),
                                        Text("Account Name: $accountName"),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Confirm"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) {
                                  setStateDialog(() {
                                    isLoading = false;
                                  });
                                  return;
                                }
                                try {
                                  await ApiService.withdraw(
                                    amount: amt,
                                    accountNumber: accountController.text,
                                    bankCode: selectedBankCode!,
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                } finally {
                                  if (mounted) {
                                    setStateDialog(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Withdraw",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Wallet", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),

                Text(
                  errorMessage!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Check your internet connection and try again",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: fetchWallet,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                                  Icon(
                                    Icons.payments,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Avg Earning / Delivery",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    totalDeliveries == 0
                                        ? "₦0"
                                        : "₦${avgEarning.toStringAsFixed(0)}",
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

                        final type = tx['type'] ?? '';
                        final amount = tx['amount'] ?? 0;
                        final date = tx['date'] ?? '';

                        final color = getTransactionColor(type);
                        final icon = getTransactionIcon(type);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              // ignore: deprecated_member_use
                              backgroundColor: color.withOpacity(0.2),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(type),
                            subtitle: Text(date),
                            trailing: Text(
                              "₦$amount",
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
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
