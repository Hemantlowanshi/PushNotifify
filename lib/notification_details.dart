import 'package:flutter/material.dart';

class NotificationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const NotificationDetailsPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Screen: ${data['screen'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 18,),
              ),
              const SizedBox(height: 12),
              Text(
                'Order ID: ${data['order_id'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Status: ${data['status'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
