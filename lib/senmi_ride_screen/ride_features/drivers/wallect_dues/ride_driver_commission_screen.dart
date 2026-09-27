// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:senmi/services/driver_api_service.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverCommissionScreen extends StatefulWidget {
  const RideDriverCommissionScreen({super.key});

  @override
  State<RideDriverCommissionScreen> createState() =>
      _RideDriverCommissionScreenState();
}

class _RideDriverCommissionScreenState extends State<RideDriverCommissionScreen>
    with WidgetsBindingObserver {
  bool loading = true;
  bool paymentLoading = false;

  String? errorMessage;

  double commissionBalance = 0.0;
  double totalCommissionPaid = 0.0;

  List<dynamic> paymentHistory = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadCommissionData();

    // Refresh periodically so the screen reflects payments
    // completed in another Paystack flow.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!paymentLoading) {
        _loadCommissionData(showLoader: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !paymentLoading) {
      _loadCommissionData(showLoader: false);
    }
  }

  // ============================================================
  // LOAD COMMISSION DATA
  // ============================================================

  Future<void> _loadCommissionData({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        RideService.getDriverWallet(),
        RideService.getCommissionHistory(),
      ]);

      final wallet = Map<String, dynamic>.from(results[0] as Map);

      final history = results[1] as List<dynamic>;

      if (!mounted) return;

      setState(() {
        commissionBalance = _toDouble(
          wallet["commission_balance"] ??
              wallet["commission_due"] ??
              wallet["outstanding_commission"] ??
              0,
        );

        totalCommissionPaid = _toDouble(
          wallet["total_commission_paid"] ?? wallet["total_paid"] ?? 0,
        );

        paymentHistory = history;

        loading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // PAY COMMISSION
  // ============================================================

  Future<void> _payCommission() async {
    if (paymentLoading) return;

    if (commissionBalance <= 0) {
      _showMessage("You have no outstanding commission.", isError: false);
      return;
    }

    final paymentMethod = await _showPaymentMethodSheet();

    if (paymentMethod == null) return;

    if (!mounted) return;

    setState(() {
      paymentLoading = true;
    });

    try {
      final result = await RideService.createCommissionPayment(
        paymentMethod: paymentMethod,
      );

      final paymentUrl = result["payment_url"]?.toString();
      final reference = result["reference"]?.toString();

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception("Payment link was not returned by the server.");
      }

      if (!mounted) return;

      final opened = await _openPaystackPayment(paymentUrl);

      if (!mounted) return;

      if (!opened) {
        _showMessage(
          "Unable to open the Paystack payment page.",
          isError: true,
        );

        setState(() {
          paymentLoading = false;
        });

        return;
      }

      // Give the driver a chance to return from Paystack.
      //
      // The webhook is the authoritative payment confirmation.
      // We also verify the reference from Flutter after returning.
      if (reference != null && reference.isNotEmpty) {
        await _waitAndVerify(reference);
      } else {
        await _loadCommissionData(showLoader: false);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(_cleanError(e), isError: true);

      setState(() {
        paymentLoading = false;
      });
    }
  }

  // ============================================================
  // OPEN PAYSTACK
  // ============================================================

  Future<bool> _openPaystackPayment(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ============================================================
  // VERIFY AFTER PAYMENT
  // ============================================================

  Future<void> _waitAndVerify(String reference) async {
    // When the external payment page closes/returns to the app,
    // give Paystack webhook processing a moment.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final result = await RideService.verifyCommissionPayment(reference);

      if (!mounted) return;

      final success =
          result["success"] == true || result["commission_paid"] == true;

      if (success) {
        _showMessage("Commission payment successful.", isError: false);
      }

      await _loadCommissionData(showLoader: false);
    } catch (_) {
      // Verification can temporarily fail if the Paystack
      // transaction/webhook is still being processed.
      //
      // Refresh wallet/history instead of showing a false
      // payment failure.
      await _loadCommissionData(showLoader: false);

      if (!mounted) return;

      if (commissionBalance <= 0) {
        _showMessage("Commission payment confirmed.", isError: false);
      } else {
        _showMessage(
          "Payment is still being verified. Pull down to refresh.",
          isError: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          paymentLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PAYMENT METHOD SHEET
  // ============================================================

  Future<String?> _showPaymentMethodSheet() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pay Commission",
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose how you want to pay Senmi.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),

                const SizedBox(height: 18),

                _paymentMethodTile(
                  context,
                  icon: Icons.credit_card_rounded,
                  title: "Card",
                  subtitle: "Pay securely with your bank card",
                  value: "card",
                ),

                _paymentMethodTile(
                  context,
                  icon: Icons.account_balance_rounded,
                  title: "Bank",
                  subtitle: "Pay directly from your bank",
                  value: "bank",
                ),

                _paymentMethodTile(
                  context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Bank Transfer",
                  subtitle: "Pay using a bank transfer",
                  value: "bank_transfer",
                ),

                _paymentMethodTile(
                  context,
                  icon: Icons.phone_android_rounded,
                  title: "USSD",
                  subtitle: "Pay using your bank USSD code",
                  value: "ussd",
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _paymentMethodTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(context, value);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: senmiRidePurple.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: senmiRidePurple),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(",", "")) ?? 0;
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst("Exception: ", "").trim();

    if (message.isEmpty) {
      return "Unable to load commission information.";
    }

    return message;
  }

  String _formatMoney(double amount) {
    return "₦${amount.toStringAsFixed(2)}";
  }

  String _paymentStatus(dynamic value) {
    final status = value?.toString().toLowerCase() ?? "";

    switch (status) {
      case "paid":
        return "Paid";
      case "pending":
        return "Pending";
      case "failed":
        return "Failed";
      case "cancelled":
        return "Cancelled";
      default:
        return status.isEmpty ? "Unknown" : status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "paid":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "failed":
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return "";

    final date = DateTime.tryParse(value.toString());

    if (date == null) {
      return value.toString();
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, "0");
    final month = local.month.toString().padLeft(2, "0");
    final year = local.year.toString();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;

    final minute = local.minute.toString().padLeft(2, "0");

    final period = local.hour >= 12 ? "PM" : "AM";

    return "$day/$month/$year • "
        "$hour:$minute $period";
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : senmiRidePurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Commission",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: paymentLoading
                ? null
                : () {
                    _loadCommissionData();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: senmiRidePurple),
            )
          : RefreshIndicator(
              color: senmiRidePurple,
              onRefresh: () => _loadCommissionData(showLoader: false),
              child: errorMessage != null
                  ? _buildErrorState()
                  : _buildContent(),
            ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      children: [
        _buildOutstandingCard(),

        const SizedBox(height: 18),

        _buildSummaryCards(),

        const SizedBox(height: 28),

        const Text(
          "Payment History",
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 12),

        if (paymentHistory.isEmpty)
          _buildEmptyHistory()
        else
          ...paymentHistory.map(
            (payment) =>
                _buildHistoryItem(Map<String, dynamic>.from(payment as Map)),
          ),
      ],
    );
  }

  // ============================================================
  // OUTSTANDING CARD
  // ============================================================

  Widget _buildOutstandingCard() {
    final hasBalance = commissionBalance > 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [senmiRidePurple, senmiRideLightPurple],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: senmiRidePurple.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Outstanding Commission",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _formatMoney(commissionBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            hasBalance
                ? "Commission currently owed to Senmi"
                : "You have no outstanding commission",
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasBalance && !paymentLoading ? _payCommission : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: senmiRidePurple,
                disabledBackgroundColor: Colors.white.withOpacity(0.45),
                disabledForegroundColor: Colors.white.withOpacity(0.80),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: paymentLoading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: senmiRidePurple,
                      ),
                    )
                  : Text(
                      hasBalance
                          ? "Pay ${_formatMoney(commissionBalance)}"
                          : "Commission Paid",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.pending_actions_rounded,
            title: "Outstanding",
            value: _formatMoney(commissionBalance),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_outline_rounded,
            title: "Total Paid",
            value: _formatMoney(totalCommissionPaid),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: senmiRidePurple, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Widget _buildHistoryItem(Map<String, dynamic> payment) {
    final status = _paymentStatus(payment["status"]);

    final statusColor = _statusColor(status);

    final amount = _toDouble(payment["amount"] ?? 0);

    final reference = payment["reference"]?.toString() ?? "";

    final paymentMethod =
        payment["payment_method"]
            ?.toString()
            .replaceAll("_", " ")
            .toUpperCase() ??
        "";

    final date = _formatDate(payment["paid_at"] ?? payment["created_at"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == "Paid"
                  ? Icons.check_rounded
                  : status == "Pending"
                  ? Icons.hourglass_top_rounded
                  : Icons.payment_rounded,
              color: statusColor,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Commission Payment",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    Text(
                      _formatMoney(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _statusBadge(status, statusColor),
                    if (paymentMethod.isNotEmpty) _smallBadge(paymentMethod),
                  ],
                ),

                if (date.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],

                if (reference.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    "Ref: $reference",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _smallBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY HISTORY
  // ============================================================

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            "No commission payments yet",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            "Your commission payment history will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline_rounded, size: 58, color: Colors.red.shade300),
        const SizedBox(height: 18),
        const Text(
          "Unable to load commission",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage ?? "Something went wrong.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              _loadCommissionData();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: senmiRidePurple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
