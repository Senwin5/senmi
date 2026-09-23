// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ChooseCourierType extends StatelessWidget {
  const ChooseCourierType({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;

    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    final borderColor = isDark ? Colors.white24 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Back',
          ),
        ),
        title: Text(
          'Choose Courier Type',
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose how you want to work',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Select the courier service you want to provide with Senmi.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CourierTypeCard(
                          icon: Icons.two_wheeler_rounded,
                          title: 'Ride Driver',
                          subtitle:
                              'Drive passengers and provide ride services through Senmi.',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          accentColor: Colors.deepPurple,
                          onTap: () {
                            Navigator.pop(context, 'ride_driver');
                          },
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _CourierTypeCard(
                          icon: Icons.inventory_2_rounded,
                          title: 'Package Courier',
                          subtitle:
                              'Deliver packages to customers and earn from completed deliveries.',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          accentColor: Colors.deepPurple,
                          onTap: () {
                            Navigator.pop(context, 'rider');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.deepPurple.withOpacity(0.10)
                          : Colors.deepPurple.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.deepPurple,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You will complete a verification profile based on the courier type you select.',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CourierTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _CourierTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accentColor.withOpacity(0.08),
        highlightColor: accentColor.withOpacity(0.04),
        child: Ink(
          height: 265,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accentColor, size: 30),
                ),

                const SizedBox(height: 17),

                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
