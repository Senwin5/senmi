import 'package:flutter/material.dart';
import 'package:senmi/services/driver_api_service.dart';

class RideAdminDriverDetailsScreen extends StatefulWidget {
  final String driverId;

  const RideAdminDriverDetailsScreen({super.key, required this.driverId});

  @override
  State<RideAdminDriverDetailsScreen> createState() =>
      _RideAdminDriverDetailsScreenState();
}

class _RideAdminDriverDetailsScreenState
    extends State<RideAdminDriverDetailsScreen> {
  static const Color purple = Color(0xFF7C3AED);
  static const String origin = 'https://www.senmi.com.ng';

  bool isLoading = true;
  bool isUpdatingStatus = false;

  String? errorMessage;
  Map<String, dynamic>? driver;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  String value(dynamic raw, [String fallback = 'Not provided']) {
    if (raw == null || raw.toString().trim().isEmpty) {
      return fallback;
    }
    return raw.toString();
  }

  String? imageUrl(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return null;

    final url = raw.toString().trim();

    if (url.startsWith('https://') || url.startsWith('http://')) {
      return url;
    }

    if (url.startsWith('/')) return '$origin$url';

    return '$origin/$url';
  }

  Future<void> fetchDetails() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await RideService.getAdminDriverDetails(widget.driverId);

      if (!mounted) return;

      setState(() {
        driver = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Color get statusColor {
    switch (value(driver?['status'], '').toLowerCase()) {
      case 'approved':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'rejected':
      case 'suspended':
        return const Color(0xFFDC2626);
      default:
        return purple;
    }
  }

  Future<void> changeDriverStatus(String status) async {
    String rejectionReason = '';

    if (status == 'rejected') {
      final controller = TextEditingController();

      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reject driver'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Explain why this driver is rejected',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      controller.dispose();

      if (reason == null || reason.isEmpty) return;
      rejectionReason = reason;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${status[0].toUpperCase()}${status.substring(1)} driver?'),
        content: Text(
          'Are you sure you want to change this driver’s status to $status?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => isUpdatingStatus = true);

    try {
      await RideService.updateAdminDriverStatus(
        widget.driverId,
        status,
        rejectionReason: rejectionReason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver status updated to $status.')),
      );

      await fetchDetails();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isUpdatingStatus = false);
      }
    }
  }

  void viewPhoto(String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(title),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget photoCard(String title, dynamic rawUrl, IconData fallbackIcon) {
    final url = imageUrl(rawUrl);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url == null
                ? Container(
                    height: 150,
                    width: double.infinity,
                    color: purple.withValues(alpha: 0.08),
                    child: Icon(fallbackIcon, size: 52, color: purple),
                  )
                : InkWell(
                    onTap: () => viewPhoto(title, url),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.network(
                          url,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;

                            return const SizedBox(
                              height: 190,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (_, _, _) => Container(
                            height: 150,
                            width: double.infinity,
                            color: purple.withValues(alpha: 0.08),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined, size: 40),
                                SizedBox(height: 6),
                                Text('Image could not be loaded'),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (url != null) ...[
            const SizedBox(height: 8),
            const Text(
              'Tap image to view and zoom',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget section(String title, List<Widget> children, Color cardColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget detailRow(String label, dynamic rawValue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value(rawValue),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget manageDriverSection(Map<String, dynamic> d, Color cardColor) {
    final currentStatus = value(d['status'], '').toLowerCase();

    // Hide Manage Driver completely once approved.
    if (currentStatus == 'approved') {
      return const SizedBox.shrink();
    }

    return section('Manage Driver', [
      if (isUpdatingStatus)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        )
      else ...[
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => changeDriverStatus('approved'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve Driver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ),
        if (currentStatus != 'rejected')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => changeDriverStatus('rejected'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ),
        if (currentStatus != 'pending')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => changeDriverStatus('pending'),
              icon: const Icon(Icons.pending_outlined),
              label: const Text('Set to Pending'),
            ),
          ),
      ],
    ], cardColor);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF211633);
    final cardColor = isDark ? const Color(0xFF211C2B) : Colors.white;
    final background = isDark
        ? const Color(0xFF121018)
        : const Color(0xFFF8F7FC);

    final d = driver;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Driver Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchDetails,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: fetchDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : d == null
            ? const Center(child: Text('Driver not found.'))
            : RefreshIndicator(
                onRefresh: fetchDetails,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: imageUrl(d['profile_photo']) == null
                                ? null
                                : () => viewPhoto(
                                    'Profile Photo',
                                    imageUrl(d['profile_photo'])!,
                                  ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: purple.withValues(alpha: 0.12),
                              backgroundImage:
                                  imageUrl(d['profile_photo']) != null
                                  ? NetworkImage(imageUrl(d['profile_photo'])!)
                                  : null,
                              child: imageUrl(d['profile_photo']) == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: purple,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            value(d['full_name'], 'Unnamed driver'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            value(d['driver_id']),
                            style: const TextStyle(
                              color: purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              value(d['status'], 'Unknown').toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${((d['rating'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} / 5.0',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${value(d['rating_count'], '0')} ratings)',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (imageUrl(d['profile_photo']) != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Tap profile photo to enlarge',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    section('Personal Information', [
                      detailRow('Full name', d['full_name']),
                      detailRow('Driver ID', d['driver_id']),
                      detailRow('Email', d['email']),
                      detailRow('Phone number', d['phone_number']),
                      detailRow('Address', d['address']),
                      detailRow('City', d['city']),
                      detailRow('State', d['state']),
                      detailRow('Country', d['country']),
                      detailRow('Registered on', d['created_at']),
                    ], cardColor),

                    section('Vehicle Information', [
                      detailRow('Brand', d['vehicle_brand']),
                      detailRow('Model', d['vehicle_model']),
                      detailRow('Color', d['vehicle_color']),
                      detailRow('Year', d['vehicle_year']),
                      detailRow('Plate number', d['plate_number']),
                    ], cardColor),

                    section('Driver Activity', [
                      detailRow('Completed rides', d['completed_rides'] ?? 0),
                      detailRow(
                        'Online now',
                        d['is_online'] == true ? 'Yes' : 'No',
                      ),
                      detailRow('Approval status', d['status']),
                      detailRow('Rejection reason', d['rejection_reason']),
                    ], cardColor),

                    manageDriverSection(d, cardColor),

                    section('Emergency Contact', [
                      detailRow('Contact name', d['emergency_contact_name']),
                      detailRow('Contact phone', d['emergency_contact_phone']),
                      detailRow(
                        'Relationship',
                        d['emergency_contact_relationship'],
                      ),
                    ], cardColor),

                    photoCard(
                      'Profile Photo',
                      d['profile_photo'],
                      Icons.person_outline,
                    ),
                    photoCard(
                      'Driver Licence Photo',
                      d['driver_license_photo'],
                      Icons.badge_outlined,
                    ),
                    photoCard(
                      'Vehicle Photo',
                      d['vehicle_photo'],
                      Icons.directions_car_outlined,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
