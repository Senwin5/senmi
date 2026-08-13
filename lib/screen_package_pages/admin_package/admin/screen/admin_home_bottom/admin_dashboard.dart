// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_customer_screen/customer_management_screen.dart';
import 'package:senmi/services/api_service.dart';
import 'package:web_socket_channel/io.dart';

import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_package/admin_packages.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_analytics/analytics_screen.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_notifications/notifications.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_riders_screen/admin_riders_screen.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_transaction/admin_wallet_screen.dart';
import 'package:senmi/screen_package_pages/admin_package/admin/screen/admin_transaction/admin_withdrawal_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool loading = true;
  bool refreshing = false;
  String? error;

  Map<String, dynamic> dashboard = {};
  List packages = [];
  List ridersList = [];
  List customers = [];
  List wallets = [];
  List withdrawals = [];

  IOWebSocketChannel? channel;
  StreamSubscription? socketSubscription;
  Timer? reconnectTimer;

  int get totalRiders =>
      _int(dashboard['total_riders'], fallback: ridersList.length);

  int get pendingRiders => _int(dashboard['pending_riders']);

  int get activeDeliveries => _int(dashboard['active_deliveries']);

  int get completedDeliveries => _int(dashboard['completed_deliveries']);

  int get availablePackages => _int(dashboard['available_packages']);

  int get totalCustomers => customers.length;

  int get walletCount =>
      _int(dashboard['wallet_count'], fallback: wallets.length);

  int get pendingWithdrawals => _int(
    dashboard['pending_withdrawals'],
    fallback: withdrawals
        .where((w) => (w['status'] ?? '').toString().toLowerCase() == 'pending')
        .length,
  );

  double get walletBalance =>
      wallets.fold<double>(0, (sum, w) => sum + _double(w['balance']));

  double get totalEarned =>
      wallets.fold<double>(0, (sum, w) => sum + _double(w['total_earned']));

  double get packageRevenue =>
      packages.fold<double>(0, (sum, p) => sum + _double(p['price']));

  @override
  void initState() {
    super.initState();
    loadDashboard();
    _connectSocket();
  }

  @override
  void dispose() {
    socketSubscription?.cancel();
    channel?.sink.close();
    reconnectTimer?.cancel();
    super.dispose();
  }

  int _int(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> loadDashboard({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    } else if (mounted) {
      setState(() => refreshing = true);
    }

    try {
      final results = await Future.wait([
        ApiService.getAdminDashboard(),
        ApiService.getAdminPackages(),
        ApiService.getRiders(),
        ApiService.getCustomers(),
        ApiService.getAdminRiderWallets(),
        ApiService.getAdminWithdrawals(),
      ]);

      if (!mounted) return;

      setState(() {
        dashboard = Map<String, dynamic>.from(results[0] as Map);
        packages = List.from(results[1] as List);
        ridersList = List.from(results[2] as List);
        customers = List.from(results[3] as List);
        wallets = List.from(results[4] as List);
        withdrawals = List.from(results[5] as List);
        loading = false;
        refreshing = false;
        error = null;
      });
    } catch (e) {
      debugPrint('Admin dashboard load error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
        error = e.toString();
      });
    }
  }

  void _connectSocket() {
    try {
      channel = IOWebSocketChannel.connect(
        'wss://www.senmi.com.ng/ws/admin-dashboard/',
      );

      socketSubscription = channel!.stream.listen(
        (message) {
          debugPrint('Dashboard live event: $message');

          try {
            jsonDecode(message.toString());
          } catch (_) {}

          loadDashboard(showLoader: false);
        },
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    reconnectTimer?.cancel();
    reconnectTimer = Timer(const Duration(seconds: 8), _connectSocket);
  }

  void _go(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  String _money(double value) {
    final whole = value.round().toString();
    final chars = whole.split('');
    final out = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      final reverseIndex = chars.length - i;

      out.write(chars[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        out.write(',');
      }
    }

    return '₦${out.toString()}';
  }

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get _cardColor => Theme.of(context).cardColor;

  Color get _textColor => Theme.of(context).colorScheme.onSurface;

  Color get _mutedTextColor =>
      Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(.65) ??
      Colors.grey;

  Color get _borderColor => Theme.of(context).dividerColor.withOpacity(.12);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _cardColor,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Senmi Admin',
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Operations overview',
              style: TextStyle(color: _mutedTextColor, fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (refreshing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

          IconButton(
            tooltip: 'Analytics',
            onPressed: () => _go(const AnalyticsScreen()),
            icon: Icon(Icons.insights_rounded, color: _textColor),
          ),

          IconButton(
            tooltip: 'Refresh',
            onPressed: () => loadDashboard(showLoader: false),
            icon: Icon(Icons.refresh_rounded, color: _textColor),
          ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => loadDashboard(showLoader: false),
              color: Theme.of(context).colorScheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _hero(),

                  const SizedBox(height: 18),

                  if (error != null) _errorCard(),

                  _sectionTitle('Business overview', 'Live platform totals'),

                  const SizedBox(height: 10),

                  _statsGrid(),

                  const SizedBox(height: 22),

                  _sectionTitle(
                    'Money overview',
                    'Current internal wallet position',
                  ),

                  const SizedBox(height: 10),

                  _moneyOverview(),

                  const SizedBox(height: 22),

                  _sectionTitle(
                    'Delivery operations',
                    'What is happening right now',
                  ),

                  const SizedBox(height: 10),

                  _operations(),

                  const SizedBox(height: 22),

                  _sectionTitle(
                    'Attention needed',
                    'Items that may require admin action',
                  ),

                  const SizedBox(height: 10),

                  _attention(),

                  const SizedBox(height: 22),

                  _sectionTitle('Quick actions', 'Jump directly to a task'),

                  const SizedBox(height: 10),

                  _quickActions(),

                  const SizedBox(height: 22),

                  _sectionTitle(
                    'Recent deliveries',
                    'Latest packages received by the API',
                  ),

                  const SizedBox(height: 10),

                  _recentPackages(),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff581C87), Color(0xff7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff581C87).withOpacity(_isDark ? .35 : .18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good to see you 👋',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Senmi is running',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$activeDeliveries active deliveries • '
                  '$pendingRiders riders awaiting review',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.two_wheeler, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _errorCard() {
    final errorColor = Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorColor.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Some live data could not be loaded. Pull down to retry.',
              style: TextStyle(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: TextStyle(color: _mutedTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATS GRID
  // ============================================================

  Widget _statsGrid() {
    final items = [
      _Stat(
        'Customers',
        totalCustomers,
        Icons.people_alt_rounded,
        Colors.blue,
        () => _go(const CustomerManagementScreen()),
      ),
      _Stat(
        'Riders',
        totalRiders,
        Icons.delivery_dining_rounded,
        Colors.indigo,
        () => _go(const AdminRidersScreen()),
      ),
      _Stat(
        'Completed',
        completedDeliveries,
        Icons.task_alt_rounded,
        Colors.green,
        () => _go(const AdminPackagesScreen()),
      ),
      _Stat(
        'Available',
        availablePackages,
        Icons.inventory_2_rounded,
        Colors.orange,
        () => _go(const AdminPackagesScreen()),
      ),
      _Stat(
        'Wallets',
        walletCount,
        Icons.account_balance_wallet_rounded,
        Colors.teal,
        () => _go(const AdminWalletScreen()),
      ),
      _Stat(
        'Withdrawals',
        pendingWithdrawals,
        Icons.payments_rounded,
        Colors.red,
        () => _go(const AdminWithdrawalScreen()),
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) {
        final x = items[i];

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: x.onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor),
              boxShadow: [
                if (!_isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(.035),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: x.color.withOpacity(.10),
                  child: Icon(x.icon, color: x.color, size: 19),
                ),

                const Spacer(),

                Text(
                  x.value.toString(),
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(x.title, style: TextStyle(color: _mutedTextColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MONEY
  // ============================================================

  Widget _moneyOverview() {
    return Row(
      children: [
        Expanded(
          child: _moneyCard(
            'Wallet balance',
            _money(walletBalance),
            Icons.account_balance_wallet_rounded,
            Colors.green,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _moneyCard(
            'Rider earnings',
            _money(totalEarned),
            Icons.trending_up_rounded,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _moneyCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),

          const SizedBox(height: 12),

          Text(title, style: TextStyle(color: _mutedTextColor, fontSize: 12)),

          const SizedBox(height: 4),

          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: _textColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPERATIONS
  // ============================================================

  Widget _operations() {
    final total = activeDeliveries + availablePackages + completedDeliveries;

    final activeRatio = total == 0 ? 0.0 : activeDeliveries / total;

    final completedRatio = total == 0 ? 0.0 : completedDeliveries / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          _progressRow(
            'Active deliveries',
            activeDeliveries,
            activeRatio,
            Colors.indigo,
          ),

          const SizedBox(height: 18),

          _progressRow(
            'Available packages',
            availablePackages,
            total == 0 ? 0 : availablePackages / total,
            Colors.orange,
          ),

          const SizedBox(height: 18),

          _progressRow(
            'Completed deliveries',
            completedDeliveries,
            completedRatio,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String title, int value, double ratio, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              value.toString(),
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio.clamp(0, 1),
            backgroundColor: color.withOpacity(.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ATTENTION
  // ============================================================

  Widget _attention() {
    final cards = <Widget>[
      if (pendingRiders > 0)
        _attentionTile(
          Icons.person_search_rounded,
          '$pendingRiders rider application'
              '${pendingRiders == 1 ? '' : 's'} pending',
          'Review rider profiles',
          Colors.orange,
          () => _go(const AdminRidersScreen()),
        ),

      if (pendingWithdrawals > 0)
        _attentionTile(
          Icons.payments_outlined,
          '$pendingWithdrawals withdrawal'
              '${pendingWithdrawals == 1 ? '' : 's'} awaiting review',
          'Open withdrawals',
          Colors.red,
          () => _go(const AdminWithdrawalScreen()),
        ),

      if (availablePackages > 0)
        _attentionTile(
          Icons.inventory_2_outlined,
          '$availablePackages package'
              '${availablePackages == 1 ? '' : 's'} waiting for a rider',
          'Open packages',
          Colors.blue,
          () => _go(const AdminPackagesScreen()),
        ),
    ];

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.withOpacity(.12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'No urgent admin actions right now.',
                style: TextStyle(color: _textColor),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: cards
          .map(
            (e) =>
                Padding(padding: const EdgeInsets.only(bottom: 10), child: e),
          )
          .toList(),
    );
  }

  Widget _attentionTile(
    IconData icon,
    String title,
    String action,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.10),
              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(action, style: TextStyle(color: color, fontSize: 12)),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: _mutedTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _quickActions() {
    final actions = [
      _Action(
        'Riders',
        Icons.delivery_dining_rounded,
        Colors.indigo,
        () => _go(const AdminRidersScreen()),
      ),
      _Action(
        'Packages',
        Icons.inventory_2_rounded,
        Colors.orange,
        () => _go(const AdminPackagesScreen()),
      ),
      _Action(
        'Withdrawals',
        Icons.payments_rounded,
        Colors.red,
        () => _go(const AdminWithdrawalScreen()),
      ),
      _Action(
        'Wallets',
        Icons.account_balance_wallet_rounded,
        Colors.teal,
        () => _go(const AdminWalletScreen()),
      ),
      _Action(
        'Notifications',
        Icons.notifications_rounded,
        Colors.blue,
        () => _go(const AdminNotificationScreen()),
      ),
      _Action(
        'Analytics',
        Icons.insights_rounded,
        Colors.purple,
        () => _go(const AnalyticsScreen()),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((a) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: a.onTap,
          child: Container(
            width: 105,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                Icon(a.icon, color: a.color),

                const SizedBox(height: 7),

                Text(
                  a.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // RECENT PACKAGES
  // ============================================================

  Widget _recentPackages() {
    final sortedPackages = List.from(packages);

    sortedPackages.sort((a, b) {
      final dateA =
          DateTime.tryParse((a['created_at'] ?? a['date'] ?? '').toString()) ??
          DateTime(1970);

      final dateB =
          DateTime.tryParse((b['created_at'] ?? b['date'] ?? '').toString()) ??
          DateTime(1970);

      return dateB.compareTo(dateA);
    });

    final recent = sortedPackages.take(5).toList();

    if (recent.isEmpty) {
      return _empty('No package records available.');
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: recent.map((p) {
          final id = (p['package_id'] ?? p['id'] ?? 'Package').toString();

          final status = (p['status'] ?? 'unknown').toString();

          final amount = _double(p['price']);

          final rider = (p['rider'] ?? 'Unassigned').toString();

          final statusColor = _statusColor(status);

          return ListTile(
            dense: true,

            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(.10),
              child: Icon(Icons.two_wheeler, color: statusColor, size: 19),
            ),

            title: Text(
              id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
            ),

            subtitle: Text(
              '$rider • ${status.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _mutedTextColor),
            ),

            trailing: Text(
              _money(amount),
              style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: _mutedTextColor)),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'success':
        return Colors.green;

      case 'paid':
      case 'accepted':
      case 'picked_up':
        return Colors.blue;

      case 'pending':
        return Colors.orange;

      case 'cancelled':
      case 'failed':
        return Colors.red;

      default:
        return _mutedTextColor;
    }
  }
}

// ============================================================
// STAT MODEL
// ============================================================

class _Stat {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _Stat(this.title, this.value, this.icon, this.color, this.onTap);
}

// ============================================================
// ACTION MODEL
// ============================================================

class _Action {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _Action(this.title, this.icon, this.color, this.onTap);
}
