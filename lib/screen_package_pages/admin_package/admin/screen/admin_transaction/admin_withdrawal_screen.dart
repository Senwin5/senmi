import 'package:flutter/material.dart';
import 'package:senmi/services/admin_service.dart';


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

  Future<void> fetchWithdrawals() async {
    try {
      final data = await AdminService.getAdminWithdrawals();

      setState(() {
        withdrawals = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> approve(int id) async {
    await AdminService.approveWithdrawal(id);
    fetchWithdrawals();
  }

  Future<void> reject(int id) async {
    await AdminService.rejectWithdrawal(id, "Rejected by admin");
    fetchWithdrawals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Withdrawal History")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWithdrawals,
              child: ListView.builder(
                itemCount: withdrawals.length,
                itemBuilder: (context, index) {
                  final w = withdrawals[index];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(w['rider']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Amount: ₦${w['amount']}"),
                          Text("Status: ${w['status']}"),
                          Text("Date: ${w['created_at']}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (w['status'] == "processing")
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () => approve(w['id']),
                            ),
                          if (w['status'] == "processing")
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => reject(w['id']),
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
