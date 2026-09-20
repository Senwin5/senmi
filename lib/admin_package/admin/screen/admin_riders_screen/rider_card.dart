// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'rider_model.dart';

class RiderCard extends StatelessWidget {
  final RiderModel rider;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const RiderCard({
    super.key,
    required this.rider,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  // ============================================================
  // ACCOUNT STATUS
  // ============================================================

  bool get isDeactivated => !rider.isActive;

  bool get isPending =>
      rider.isActive && rider.status.toLowerCase() == "pending";

  // ============================================================
  // DISPLAY STATUS
  // ============================================================

  String get displayStatus {
    if (isDeactivated) {
      return "DEACTIVATED";
    }

    return rider.status.toUpperCase();
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color statusColor() {
    if (isDeactivated) {
      return Colors.grey;
    }

    switch (rider.status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      case "pending":
        return Colors.orange;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final textColor = theme.colorScheme.onSurface;

    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;

    return Card(
      color: theme.cardColor,
      elevation: isDark ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // =================================================
                  // AVATAR
                  // =================================================
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.deepPurple.withOpacity(0.12),
                    child: ClipOval(
                      child:
                          rider.profileImage != null &&
                              rider.profileImage!.isNotEmpty
                          ? Image.network(
                              rider.profileImage!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) {
                                return Center(
                                  child: Text(
                                    rider.username.isNotEmpty
                                        ? rider.username[0].toUpperCase()
                                        : "R",
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                rider.username.isNotEmpty
                                    ? rider.username[0].toUpperCase()
                                    : "R",
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // =================================================
                  // RIDER INFORMATION
                  // =================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rider.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          rider.email,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          "ID: ${rider.riderId}",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // =================================================
                  // STATUS BADGE
                  // =================================================
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =====================================================
              // ACTION BUTTONS
              //
              // ONLY ACTIVE + PENDING RIDERS
              // =====================================================
              if (isPending && onApprove != null && onReject != null)
                Row(
                  children: [
                    // =================================================
                    // APPROVE
                    // =================================================
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Approve"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // =================================================
                    // REJECT
                    // =================================================
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text("Reject"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
