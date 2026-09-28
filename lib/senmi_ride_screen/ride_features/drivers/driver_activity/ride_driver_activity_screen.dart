import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

const Color senmiRidePurple = Color(0xFF581C87);
const Color senmiRideLightPurple = Color(0xFF7C3AED);

class RideDriverActivityScreen extends StatefulWidget {
  const RideDriverActivityScreen({super.key});

  @override
  State<RideDriverActivityScreen> createState() =>
      _RideDriverActivityScreenState();
}

class _RideDriverActivityScreenState extends State<RideDriverActivityScreen> {
  bool loading = true;
  bool refreshing = false;

  String? errorMessage;

  Map<String, dynamic> stats = {};
  Map<String, dynamic> wallet = {};
  List<dynamic> rideHistory = [];

  // Added only for Pending rides.
  List<dynamic> activeRides = [];

  int selectedPeriod = 0;

  final List<String> periods = ['Today', 'Yesterday', 'This Week', 'All Time'];

  // ============================================================
  // RIDE ACTIVITY FILTER
  // ============================================================

  // all = Total Rides
  // completed = Completed
  // cancelled = Cancelled
  // pending = Pending
  String selectedRideFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  // ============================================================
  // LOAD ACTIVITY
  // ============================================================

  Future<void> _loadActivity({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        refreshing = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      /*
       * These methods already have concrete return types:
       *
       * getDriverStats()          -> Map<String, dynamic>
       * getDriverRideHistory()    -> List<dynamic>
       * getDriverWallet()         -> Map<String, dynamic>
       * getDriverActiveRides()    -> List<dynamic>
       */

      final loadedStats = await RideService.getDriverStats();
      final loadedHistory = await RideService.getDriverRideHistory();
      final loadedWallet = await RideService.getDriverWallet();

      // Pending/current rides come from the active rides endpoint.
      List<dynamic> loadedActiveRides = [];

      try {
        loadedActiveRides = await RideService.getDriverActiveRides();
      } catch (e) {
        debugPrint('Driver Active Rides Error: $e');

        // Do not break the entire Activity screen if active rides
        // fail to load. Other activity data will still work.
        loadedActiveRides = [];
      }

      if (!mounted) return;

      setState(() {
        stats = loadedStats;
        rideHistory = loadedHistory;
        wallet = loadedWallet;
        activeRides = loadedActiveRides;

        loading = false;
        refreshing = false;
      });
    } catch (e) {
      debugPrint('Driver Activity Error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
        refreshing = false;
        errorMessage = "Couldn't load driver activity.";
      });
    }
  }

  // ============================================================
  // GENERIC HELPERS
  // ============================================================

  dynamic _getValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key];
      }
    }

    return null;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    final text = value
        .toString()
        .replaceAll('₦', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(text) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // SELECTED API STATS
  // ============================================================

  Map<String, dynamic> _selectedStats() {
    if (stats.isEmpty) {
      return {};
    }

    String key;

    if (selectedPeriod == 0) {
      key = 'today';
    } else if (selectedPeriod == 1) {
      key = 'yesterday';
    } else if (selectedPeriod == 2) {
      key = 'week';
    } else {
      key = 'all_time';
    }

    final periodData = stats[key];

    if (periodData is Map) {
      return Map<String, dynamic>.from(periodData);
    }

    if (selectedPeriod == 2) {
      final thisWeek = stats['this_week'];

      if (thisWeek is Map) {
        return Map<String, dynamic>.from(thisWeek);
      }
    }

    return stats;
  }

  // ============================================================
  // FILTER RIDES BY PERIOD
  // ============================================================

  List<Map<String, dynamic>> _filteredRides() {
    final List<Map<String, dynamic>> rides = [];

    for (final item in rideHistory) {
      if (item is Map) {
        rides.add(Map<String, dynamic>.from(item));
      }
    }

    // All Time
    if (selectedPeriod == 3) {
      return rides;
    }

    final now = DateTime.now();

    final todayStart = DateTime(now.year, now.month, now.day);

    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    return rides.where((ride) {
      final date = _rideDate(ride);

      if (date == null) {
        return false;
      }

      if (selectedPeriod == 0) {
        return !date.isBefore(todayStart);
      }

      if (selectedPeriod == 1) {
        return !date.isBefore(yesterdayStart) && date.isBefore(todayStart);
      }

      if (selectedPeriod == 2) {
        return !date.isBefore(weekStart);
      }

      return true;
    }).toList();
  }

  // ============================================================
  // NEW: DISPLAYED RIDES
  // ============================================================

  List<Map<String, dynamic>> _displayedRides() {
    // ----------------------------------------------------------
    // PENDING
    // ----------------------------------------------------------
    //
    // Pending/current rides come from:
    //
    // getDriverActiveRides()
    //
    // We do not use rideHistory for Pending because rideHistory
    // is the historical endpoint.
    //
    if (selectedRideFilter == 'pending') {
      final List<Map<String, dynamic>> pending = [];

      for (final item in activeRides) {
        if (item is Map) {
          pending.add(Map<String, dynamic>.from(item));
        }
      }

      return pending;
    }

    // ----------------------------------------------------------
    // TOTAL RIDES
    // ----------------------------------------------------------

    final rides = _filteredRides();

    if (selectedRideFilter == 'all') {
      return rides;
    }

    // ----------------------------------------------------------
    // COMPLETED
    // ----------------------------------------------------------

    if (selectedRideFilter == 'completed') {
      return rides.where((ride) {
        return _rideStatus(ride).toLowerCase().trim() == 'completed';
      }).toList();
    }

    // ----------------------------------------------------------
    // CANCELLED
    // ----------------------------------------------------------

    if (selectedRideFilter == 'cancelled') {
      return rides.where((ride) {
        final status = _rideStatus(ride).toLowerCase().trim();

        return status == 'cancelled' || status == 'canceled';
      }).toList();
    }

    return rides;
  }

  // ============================================================
  // SELECT RIDE FILTER
  // ============================================================

  void _selectRideFilter(String filter) {
    setState(() {
      /*
       * If the user taps the currently selected card again,
       * return to Total Rides / all activity.
       */
      if (selectedRideFilter == filter && filter != 'all') {
        selectedRideFilter = 'all';
      } else {
        selectedRideFilter = filter;
      }
    });
  }

  // ============================================================
  // RIDE DATE
  // ============================================================

  DateTime? _rideDate(Map<String, dynamic> ride) {
    /*
     * This matches your working History screen:
     *
     * completed_at
     * cancelled_at
     * created_at
     */

    final value =
        ride['completed_at'] ?? ride['cancelled_at'] ?? ride['created_at'];

    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed?.toLocal();
  }

  // ============================================================
  // EARNINGS
  // ============================================================

  double _getEarnings() {
    final rides = _filteredRides();

    /*
     * Your History screen confirms that the driver's
     * actual earning field is:
     *
     * driver_earning
     *
     * Use that instead of guessing between many fields.
     */

    if (rideHistory.isNotEmpty) {
      double total = 0.0;

      for (final ride in rides) {
        total += _toDouble(ride['driver_earning']);
      }

      return total;
    }

    // Fallback to stats if there is no ride history.
    final data = _selectedStats();

    return _toDouble(
      _getValue(data, [
        'earnings',
        'total_earnings',
        'total_earning',
        'earned',
        'gross_earnings',
        'revenue',
      ]),
    );
  }

  // ============================================================
  // COMMISSION / DUE
  // ============================================================

  double _getCommission() {
    /*
     * This is copied from your WORKING
     * RideDriverCommissionScreen.
     *
     * Do not calculate this from ride history.
     * This is the driver's current outstanding balance.
     */

    return _toDouble(
      wallet['commission_balance'] ??
          wallet['commission_due'] ??
          wallet['outstanding_commission'] ??
          0,
    );
  }

  // ============================================================
  // NET
  // ============================================================

  double _getNetEarnings() {
    final data = _selectedStats();

    final net = _getValue(data, ['net_earnings', 'net_income', 'take_home']);

    if (net != null) {
      return _toDouble(net);
    }

    /*
     * commission_balance is the current outstanding account
     * balance, not necessarily the commission for Today,
     * Yesterday or This Week.
     *
     * Therefore don't subtract the lifetime/current Due from
     * a period's earnings.
     */

    return _getEarnings();
  }

  // ============================================================
  // COMPLETED
  // ============================================================

  int _getCompleted() {
    final rides = _filteredRides();

    if (rideHistory.isNotEmpty) {
      int count = 0;

      for (final ride in rides) {
        final status = ride['status']?.toString().toLowerCase().trim() ?? '';

        if (status == 'completed') {
          count++;
        }
      }

      return count;
    }

    final data = _selectedStats();

    return _toInt(
      _getValue(data, [
        'completed',
        'completed_rides',
        'total_completed',
        'completed_trips',
      ]),
    );
  }

  // ============================================================
  // TOTAL RIDES
  // ============================================================

  int _getTotalRides() {
    if (rideHistory.isNotEmpty) {
      return _filteredRides().length;
    }

    final data = _selectedStats();

    return _toInt(
      _getValue(data, ['total_rides', 'rides', 'total_trips', 'ride_count']),
    );
  }

  // ============================================================
  // CANCELLED
  // ============================================================

  int _getCancelled() {
    final rides = _filteredRides();

    if (rideHistory.isNotEmpty) {
      int count = 0;

      for (final ride in rides) {
        final status = ride['status']?.toString().toLowerCase().trim() ?? '';

        if (status == 'cancelled' || status == 'canceled') {
          count++;
        }
      }

      return count;
    }

    final data = _selectedStats();

    return _toInt(
      _getValue(data, [
        'cancelled',
        'cancelled_rides',
        'canceled',
        'canceled_rides',
      ]),
    );
  }

  // ============================================================
  // PENDING
  // ============================================================

  int _getPending() {
    /*
     * Pending/current rides come directly from:
     *
     * /ride/rides/driver/active/
     *
     * through:
     *
     * RideService.getDriverActiveRides()
     *
     * This keeps Pending separate from historical rides.
     */

    return activeRides.length;
  }

  // ============================================================
  // RIDE EARNING
  // ============================================================

  double _rideEarning(Map<String, dynamic> ride) {
    /*
     * Confirmed from your working History screen.
     */

    return _toDouble(ride['driver_earning']);
  }

  // ============================================================
  // RIDE STATUS
  // ============================================================

  String _rideStatus(Map<String, dynamic> ride) {
    return ride['status']?.toString() ?? 'Unknown';
  }

  // ============================================================
  // RIDE ID
  // ============================================================

  String _rideId(Map<String, dynamic> ride) {
    return ride['ride_id']?.toString() ?? '-';
  }

  // ============================================================
  // PICKUP
  // ============================================================

  String _pickup(Map<String, dynamic> ride) {
    return ride['pickup_address']?.toString() ??
        ride['pickup']?.toString() ??
        'Pickup location unavailable';
  }

  // ============================================================
  // DESTINATION
  // ============================================================

  String _destination(Map<String, dynamic> ride) {
    return ride['destination_address']?.toString() ??
        ride['destination']?.toString() ??
        'Destination unavailable';
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} '
        '$hour:$minute $period';
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Driver Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: senmiRidePurple),
            )
          : RefreshIndicator(
              color: senmiRidePurple,
              onRefresh: () => _loadActivity(refresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(isDark),

                    const SizedBox(height: 18),

                    if (errorMessage != null) _buildErrorCard(isDark),

                    _buildEarningsCard(isDark),

                    const SizedBox(height: 16),

                    _buildRideStatistics(isDark),

                    const SizedBox(height: 22),

                    _buildRideHistory(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PERIOD SELECTOR
  // ============================================================

  Widget _buildPeriodSelector(bool isDark) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedPeriod == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedPeriod = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? senmiRidePurple
                    : isDark
                    ? const Color(0xFF242424)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? senmiRidePurple
                      : isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                periods[index],
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : isDark
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage ?? 'Something went wrong.',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EARNINGS CARD
  // ============================================================

  Widget _buildEarningsCard(bool isDark) {
    final earnings = _getEarnings();
    final commission = _getCommission();
    final net = _getNetEarnings();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [senmiRidePurple, senmiRideLightPurple],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${periods[selectedPeriod]} Earnings',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            _money(earnings),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _earningItem('Due', _money(commission))),
              Expanded(child: _earningItem('Net', _money(net))),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EARNING ITEM
  // ============================================================

  Widget _earningItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RIDE STATISTICS
  // ============================================================

  Widget _buildRideStatistics(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ride Statistics',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),

        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _statCard(
              'Completed',
              _getCompleted().toString(),
              Icons.check_circle_outline,
              isDark,
              'completed',
            ),

            _statCard(
              'Total Rides',
              _getTotalRides().toString(),
              Icons.directions_car_outlined,
              isDark,
              'all',
            ),

            _statCard(
              'Cancelled',
              _getCancelled().toString(),
              Icons.cancel_outlined,
              isDark,
              'cancelled',
            ),

            _statCard(
              'Pending',
              _getPending().toString(),
              Icons.pending_actions_outlined,
              isDark,
              'pending',
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    bool isDark,
    String filter,
  ) {
    final selected = selectedRideFilter == filter;

    return GestureDetector(
      onTap: () => _selectRideFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? senmiRidePurple.withValues(alpha: isDark ? 0.20 : 0.08)
              : isDark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? senmiRidePurple : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: senmiRidePurple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: senmiRidePurple, size: 23),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),

                  if (selected) ...[
                    const SizedBox(height: 3),
                    const Text(
                      'Showing',
                      style: TextStyle(
                        fontSize: 10,
                        color: senmiRidePurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RIDE HISTORY
  // ============================================================

  Widget _buildRideHistory(bool isDark) {
    final rides = _displayedRides();

    String activityTitle;

    if (selectedRideFilter == 'completed') {
      activityTitle = 'Completed Rides';
    } else if (selectedRideFilter == 'cancelled') {
      activityTitle = 'Cancelled Rides';
    } else if (selectedRideFilter == 'pending') {
      activityTitle = 'Pending Rides';
    } else {
      activityTitle = 'Ride Activity';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              activityTitle,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            Text(
              '${rides.length} ride${rides.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (rides.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 45,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),

                const SizedBox(height: 10),

                Text(
                  selectedRideFilter == 'pending'
                      ? 'No pending rides'
                      : 'No ride activity',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  selectedRideFilter == 'pending'
                      ? 'There are no active or pending rides.'
                      : 'There are no rides for this selection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            itemCount: rides.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _rideCard(rides[index], isDark);
            },
          ),
      ],
    );
  }

  // ============================================================
  // RIDE CARD
  // ============================================================

  Widget _rideCard(Map<String, dynamic> ride, bool isDark) {
    final date = _rideDate(ride);
    final earning = _rideEarning(ride);
    final status = _rideStatus(ride);

    Color statusColor;

    final lowerStatus = status.toLowerCase();

    if (lowerStatus == 'completed') {
      statusColor = Colors.green;
    } else if (lowerStatus == 'cancelled' || lowerStatus == 'canceled') {
      statusColor = Colors.red;
    } else if (lowerStatus == 'pending' ||
        lowerStatus == 'accepted' ||
        lowerStatus == 'arrived' ||
        lowerStatus == 'started' ||
        lowerStatus == 'active') {
      statusColor = Colors.orange;
    } else {
      statusColor = senmiRidePurple;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: senmiRidePurple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_taxi_outlined,
                  color: senmiRidePurple,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride #${_rideId(ride)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _money(earning),
                style: const TextStyle(
                  color: senmiRidePurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location, size: 17, color: Colors.green),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  _pickup(ride),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: Colors.red,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  _destination(ride),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
