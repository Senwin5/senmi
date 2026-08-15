// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:senmi/screen_package_pages/features/rider/rider_history/rider_withdrawal_detail.dart';
import 'package:senmi/screen_package_pages/features/rider/rider_package/rider_package_detail.dart';
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

  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _accountController = TextEditingController();

  double get avgEarning {
    if (totalDeliveries == 0) {
      return 0;
    }

    return totalEarned / totalDeliveries;
  }

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }
  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  String _toStringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  // ============================================================
  // FETCH WALLET
  // ============================================================

  Future<void> fetchWallet() async {
    if (!mounted) {
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final wallet = await ApiService.getWallet();
      final tx = await ApiService.getTransactions();
      final earningsData = await ApiService.getEarnings();

      if (!mounted) {
        return;
      }

      final walletBalance = _toDouble(wallet['balance']);

      final earnings = _toDouble(earningsData['total_earnings']);

      final deliveries = _toInt(
        earningsData['total_deliveries'] ??
            earningsData['deliveries'] ??
            earningsData['completed_deliveries'] ??
            0,
      );

      final List<Map<String, dynamic>> parsedTransactions = [];

      for (final item in tx.take(4)) {
        if (item is Map) {
          parsedTransactions.add(Map<String, dynamic>.from(item));
        }
      }

      setState(() {
        balance = walletBalance;
        totalEarned = earnings;
        totalDeliveries = deliveries;
        transactions = parsedTransactions;
        loading = false;
      });
    } catch (e) {
      debugPrint('FETCH WALLET ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        errorMessage = "Couldn't load wallet";
      });
    }
  }

  // =========================================
  // WITHDRAW
  // =========================================

  Future<void> withdraw() async {
    if (isSubmitting) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    List<Map<String, dynamic>> banks = [];

    String? selectedBankCode;
    String? selectedBankName;
    String? accountName;

    bool verifying = false;
    bool isLoading = false;

    // ============================================================
    // LOAD BANKS
    // ============================================================

    try {
      final response = await ApiService.getBanks();

      for (final bank in response) {
        banks.add(Map<String, dynamic>.from(bank));
      }

      for (final bank in banks) {
        bank['code'] = _toStringValue(bank['code']);
        bank['name'] = _toStringValue(bank['name']);
      }
    } catch (e) {
      debugPrint('GET BANKS ERROR: $e');

      if (mounted) {
        setState(() {
          isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load banks"),
            backgroundColor: Colors.red,
          ),
        );
      }

      _amountController.dispose();
      _accountController.dispose();

      return;
    }

    if (!mounted) {
      _amountController.dispose();
      _accountController.dispose();
      return;
    }

    setState(() {
      isSubmitting = false;
    });

    // ============================================================
    // BOTTOM SHEET
    // ============================================================

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetBuilderContext, setStateDialog) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.80,
              minChildSize: 0.65,
              maxChildSize: 0.95,
              builder: (scrollContext, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(scrollContext).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // TITLE
                      // ==================================================
                      const Text(
                        "Withdraw",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Available Balance: ₦${balance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // REMAINING BALANCE
                      // ==================================================
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _amountController,
                        builder: (amountContext, value, child) {
                          final amount =
                              double.tryParse(value.text.trim()) ?? 0;

                          final remaining = balance - amount;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              remaining >= 0
                                  ? "Remaining Balance: ₦${remaining.toStringAsFixed(2)}"
                                  : "Insufficient balance",
                              style: TextStyle(
                                color: remaining >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),

                      // ==================================================
                      // AMOUNT
                      // ==================================================
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Enter Amount",
                          prefixText: "₦ ",
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==================================================
                      // BANK
                      // ==================================================
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Select Bank",
                          prefixIcon: Icon(Icons.account_balance_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: banks.map<DropdownMenuItem<String>>((bank) {
                          return DropdownMenuItem<String>(
                            value: bank['code'].toString(),
                            child: Text(
                              bank['name'].toString(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value == null) {
                            return;
                          }

                          Map<String, dynamic>? selectedBank;

                          for (final bank in banks) {
                            if (bank['code'].toString() == value) {
                              selectedBank = bank;
                              break;
                            }
                          }

                          setStateDialog(() {
                            selectedBankCode = value;
                            selectedBankName = selectedBank?['name']
                                ?.toString();
                            accountName = null;
                          });

                          // Resolve account if already entered.
                          if (_accountController.text.trim().length == 10) {
                            setStateDialog(() {
                              verifying = true;
                            });

                            try {
                              final name = await ApiService.resolveAccount(
                                accountNumber: _accountController.text.trim(),
                                bankCode: value,
                              );

                              if (!sheetContext.mounted) {
                                return;
                              }

                              setStateDialog(() {
                                accountName = name;
                                verifying = false;
                              });
                            } catch (e) {
                              debugPrint("RESOLVE ACCOUNT ERROR: $e");

                              if (!sheetContext.mounted) {
                                return;
                              }

                              setStateDialog(() {
                                verifying = false;
                                accountName = null;
                              });
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 15),

                      // ==================================================
                      // ACCOUNT NUMBER
                      // ==================================================
                      TextField(
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: "Account Number",
                          counterText: "",
                          prefixIcon: Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) async {
                          setStateDialog(() {
                            accountName = null;
                          });

                          if (value.length == 10 && selectedBankCode != null) {
                            setStateDialog(() {
                              verifying = true;
                            });

                            try {
                              final name = await ApiService.resolveAccount(
                                accountNumber: value,
                                bankCode: selectedBankCode!,
                              );

                              if (!sheetContext.mounted) {
                                return;
                              }

                              setStateDialog(() {
                                accountName = name;
                                verifying = false;
                              });
                            } catch (e) {
                              debugPrint("RESOLVE ACCOUNT ERROR: $e");

                              if (!sheetContext.mounted) {
                                return;
                              }

                              setStateDialog(() {
                                verifying = false;
                                accountName = null;
                              });
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // VERIFYING
                      // ==================================================
                      if (verifying)
                        const Column(
                          children: [
                            LinearProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              "Verifying account...",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                      // ==================================================
                      // ACCOUNT NAME
                      // ==================================================
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
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Account Name",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      accountName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // WITHDRAW BUTTON
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            disabledBackgroundColor: Colors.deepPurple.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  // ==============================
                                  // VALIDATE AMOUNT
                                  // ==============================

                                  final amt =
                                      double.tryParse(
                                        _amountController.text.trim(),
                                      ) ??
                                      0;

                                  final accountNumber = _accountController.text
                                      .trim();

                                  if (amt <= 0) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Enter a valid withdrawal amount",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // ==============================
                                  // ACCOUNT NUMBER
                                  // ==============================

                                  if (accountNumber.length != 10) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Enter a valid 10-digit account number",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // ==============================
                                  // BANK
                                  // ==============================

                                  if (selectedBankCode == null) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please select a bank"),
                                      ),
                                    );
                                    return;
                                  }

                                  if (selectedBankName == null ||
                                      selectedBankName!.trim().isEmpty) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please select a valid bank",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // ==============================
                                  // ACCOUNT VERIFICATION
                                  // ==============================

                                  if (accountName == null ||
                                      accountName!.trim().isEmpty) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please verify the account first",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // ==============================
                                  // BALANCE
                                  // ==============================

                                  if (amt > balance) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text("Insufficient balance"),
                                      ),
                                    );
                                    return;
                                  }

                                  // ==============================
                                  // SHOW LOADING
                                  // ==============================

                                  setStateDialog(() {
                                    isLoading = true;
                                  });

                                  // ==============================
                                  // CONFIRM
                                  // ==============================

                                  final confirmed = await showDialog<bool>(
                                    context: sheetContext,
                                    builder: (dialogContext) {
                                      return AlertDialog(
                                        title: const Text("Confirm Withdrawal"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Amount: ₦${amt.toStringAsFixed(2)}",
                                            ),
                                            const SizedBox(height: 8),
                                            Text("Bank: $selectedBankName"),
                                            const SizedBox(height: 8),
                                            Text("Account: $accountNumber"),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Account Name: $accountName",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(
                                                dialogContext,
                                              ).pop(false);
                                            },
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(
                                                dialogContext,
                                              ).pop(true);
                                            },
                                            child: const Text("Confirm"),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  // ==============================
                                  // CANCELLED
                                  // ==============================

                                  if (confirmed != true) {
                                    setStateDialog(() {
                                      isLoading = false;
                                    });
                                    return;
                                  }

                                  // ==============================
                                  // SUBMIT WITHDRAWAL
                                  // ==============================

                                  try {
                                    debugPrint(
                                      "========== WITHDRAW START ==========",
                                    );
                                    debugPrint("Amount: $amt");
                                    debugPrint("Account: $accountNumber");
                                    debugPrint("Bank Code: $selectedBankCode");
                                    debugPrint("Bank Name: $selectedBankName");
                                    debugPrint("Account Name: $accountName");

                                    await ApiService.withdraw(
                                      amount: amt,
                                      accountNumber: accountNumber,
                                      bankCode: selectedBankCode!,
                                      bankName: selectedBankName!,
                                      accountName: accountName!,
                                    );

                                    debugPrint(
                                      "========== WITHDRAW SUCCESS ==========",
                                    );

                                    // ============================
                                    // CLOSE SHEET
                                    // ============================

                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }

                                    // ============================
                                    // REFRESH
                                    // ============================

                                    if (mounted) {
                                      await fetchWallet();

                                      if (!mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Withdrawal submitted — awaiting approval",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint(
                                      "========== WITHDRAW ERROR ==========",
                                    );
                                    debugPrint(e.toString());

                                    if (!sheetContext.mounted) {
                                      return;
                                    }

                                    setStateDialog(() {
                                      isLoading = false;
                                    });

                                    final error = e.toString();

                                    // ==========================
                                    // EXISTING WITHDRAWAL
                                    // ==========================

                                    if (error.contains(
                                      "already have a withdrawal being processed",
                                    )) {
                                      if (sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop();
                                      }

                                      if (!mounted) {
                                        return;
                                      }

                                      await showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            title: const Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.orange,
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "Withdrawal Pending",
                                                  ),
                                                ),
                                              ],
                                            ),
                                            content: const Text(
                                              "You already have a withdrawal request being processed.\n\n"
                                              "Please wait for the current withdrawal to be completed "
                                              "before requesting another one.",
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                },
                                                child: const Text("OK"),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      return;
                                    }

                                    // ==========================
                                    // OTHER ERRORS
                                    // ==========================

                                    if (!mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error.replaceFirst("Exception: ", ""),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
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
        );
      },
    );
  }

  // ============================================================
  // TRANSACTION COLOR
  // ============================================================

  Color getTransactionColor(String type) {
    final lowerType = type.toLowerCase();

    if (lowerType.contains("withdraw") ||
        lowerType.contains("payment sent") ||
        lowerType == "debit") {
      return Colors.red;
    }

    return Colors.green;
  }

  // ============================================================
  // TRANSACTION ICON
  // ============================================================

  IconData getTransactionIcon(String type) {
    final lowerType = type.toLowerCase();

    if (lowerType.contains("withdraw") ||
        lowerType.contains("payment sent") ||
        lowerType == "debit") {
      return Icons.arrow_upward;
    }

    return Icons.arrow_downward;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // ERROR
    // ==========================================================

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Wallet", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple,
          iconTheme: const IconThemeData(color: Colors.white),
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
                  textAlign: TextAlign.center,
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

    // ==========================================================
    // MAIN SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text(
          "Wallet Earning",
          style: TextStyle(color: Colors.white),
        ),
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
                    // ==================================================
                    // BALANCE HEADER
                    // ==================================================
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
                                onPressed: () {
                                  setState(() {
                                    showBalance = !showBalance;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Total Earned: ₦${totalEarned.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white70),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: (balance <= 0 || isSubmitting)
                                  ? null
                                  : withdraw,
                              icon: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_upward,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                isSubmitting ? "Loading..." : "Withdraw",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                disabledBackgroundColor: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // STATISTICS
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // ============================================
                          // DELIVERIES
                          // ============================================
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
                                    Icons.two_wheeler,
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

                          // ============================================
                          // AVG EARNING
                          // ============================================
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
                                    "Avg Earning / Delivery",
                                    style: TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 4),

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

                    // ==================================================
                    // TRANSACTIONS
                    // ==================================================
                    if (transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 10),

                            Text(
                              "No transactions yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];

                        final type = _toStringValue(tx['type']);

                        final amount = _toDouble(tx['amount']);

                        final date = _toStringValue(tx['date']);

                        final title = _toStringValue(tx['title']);

                        final packageId = tx['package_id'];

                        final color = getTransactionColor(type);

                        final icon = getTransactionIcon(type);

                        final transactionType = _toStringValue(
                          tx['icon_type'] ?? tx['type'],
                        ).toLowerCase();

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            // ==========================================
                            // TAP TRANSACTION
                            // ==========================================
                            onTap: () async {
                              // ========================================
                              // WITHDRAWAL
                              // ========================================

                              if (transactionType == 'withdrawal') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RiderWithdrawalDetailScreen(
                                      transaction: tx,
                                    ),
                                  ),
                                );

                                return;
                              }

                              // ========================================
                              // PACKAGE
                              // ========================================

                              if (packageId == null ||
                                  packageId.toString().isEmpty) {
                                return;
                              }

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RiderPackageDetailScreen(
                                    packageId: packageId.toString(),
                                    hasActiveDelivery: false,
                                  ),
                                ),
                              );
                            },

                            // ==========================================
                            // ICON
                            // ==========================================
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Icon(icon, color: color),
                            ),

                            // ==========================================
                            // TITLE
                            // ==========================================
                            title: Text(
                              title.isNotEmpty
                                  ? title
                                  : type == 'credit'
                                  ? 'Delivery Earnings'
                                  : 'Withdrawal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // ==========================================
                            // SUBTITLE
                            // ==========================================
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (packageId != null)
                                  Text(
                                    "Package: $packageId",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),

                                if (date.isNotEmpty) Text(date),
                              ],
                            ),

                            // ==========================================
                            // AMOUNT
                            // ==========================================
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${type == 'credit' ? '+' : '-'}₦${amount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                if (packageId != null) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ],
                              ],
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
