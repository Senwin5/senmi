class RiderWalletScreen extends StatefulWidget {
  @override
  _RiderWalletScreenState createState() => _RiderWalletScreenState();
}

class _RiderWalletScreenState extends State<RiderWalletScreen> {
  double balance = 0;
  double totalEarned = 0;

  @override
  void initState() {
    super.initState();
    fetchWallet();
  }

  fetchWallet() async {
    var data = await ApiService.getWallet();
    setState(() {
      balance = data['balance'];
      totalEarned = data['total_earned'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Balance: ₦$balance", style: TextStyle(fontSize: 22)),
            SizedBox(height: 10),
            Text("Total Earned: ₦$totalEarned"),
          ],
        ),
      ),
    );
  }
}