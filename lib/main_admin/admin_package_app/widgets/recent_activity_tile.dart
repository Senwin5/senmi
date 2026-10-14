// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class RecentActivityTile extends StatelessWidget {

  final String title;
  final String subtitle;
  final IconData icon;

  const RecentActivityTile({
    super.key,
    required this.title,
   required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 0,
      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: ListTile(

        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          child: Icon(icon, color: Colors.deepPurple),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(subtitle),
      ),
    );
  }
}