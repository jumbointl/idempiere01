import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';

class NotificationModel {
  final String title;
  final String message;
  final DateTime timestamp;

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
  });
}

class NotificationScreen extends StatelessWidget {
  static const route = '/notifications';

  NotificationScreen({super.key});

  final List<NotificationModel> _notifications = [
    NotificationModel(
      title: "Payment Received",
      message: "You’ve received ৳500 from Rakib",
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      title: "Offer Alert",
      message: "Get 10% cashback on mobile recharge!",
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ),
    NotificationModel(
      title: "Security Alert",
      message: "New login from a new device",
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  Map<String, List<NotificationModel>> _groupedNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return {
      "Today": _notifications.where((n) => n.timestamp.isAfter(today)).toList(),
      "Yesterday": _notifications
          .where(
            (n) =>
                n.timestamp.isAfter(yesterday) && n.timestamp.isBefore(today),
          )
          .toList(),
      "Earlier": _notifications
          .where((n) => n.timestamp.isBefore(yesterday))
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedNotifications();

    return Scaffold(
      appBar: buildNewAppBar(
        context,
        child: CustomAppBar(title: 'Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries
            .where((entry) => entry.value.isNotEmpty)
            .map((entry) => _buildGroup(entry.key, entry.value, context))
            .toList(),
      ),
    );
  }

  Widget _buildGroup(
    String title,
    List<NotificationModel> notifications,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        ...notifications.map((n) => _buildNotificationCard(n, context)),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel n, BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: .15,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.notifications, color: context.primaryColor),
        title: Text(n.title, style: context.bodyLarge),
        subtitle: Text(n.message, style: context.bodyMedium),
        trailing: Text(
          _formatTime(n.timestamp),
          style: context.labelSmall.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
  }
}
