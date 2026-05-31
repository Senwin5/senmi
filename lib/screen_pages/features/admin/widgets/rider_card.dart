// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/rider_model.dart';

class RiderCard extends StatelessWidget {
  final RiderModel rider;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const RiderCard({
    super.key,
    required this.rider,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  Color statusColor() {
    switch (rider.status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple.shade100,

                    child: Text(
                      rider.username.isNotEmpty
                          ? rider.username[0].toUpperCase()
                          : "R",

                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          rider.username,

                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          rider.email,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: statusColor().withOpacity(0.15),

                      borderRadius:
                          BorderRadius.circular(30),
                    ),

                    child: Text(
                      rider.status.toUpperCase(),

                      style: TextStyle(
                        color: statusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: rider.status == "approved"
                          ? null
                          : onApprove,

                      icon: const Icon(Icons.check),

                      label: const Text("Approve"),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: rider.status == "rejected"
                          ? null
                          : onReject,

                      icon: const Icon(Icons.close),

                      label: const Text("Reject"),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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