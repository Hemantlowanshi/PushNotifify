import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No notifications',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              throw Exception('Manual Test Error');
            },
            child: const Text('Manual Error'),
          ),
            ElevatedButton(
              onPressed: () {
                try {
                  throw Exception('Network request failed');
                } catch (error, stackTrace) {
                  FirebaseCrashlytics.instance.recordError(
                    error,
                    stackTrace,
                    reason: 'API request failed',
                  );
                }
              },
              child: const Text('Test Network Issue'),
            ),
          ],
        ),
      ),
    );
  }
}