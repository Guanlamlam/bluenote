import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _projectId = 'universitycommunity-6ae90'; // replace if needed
  static AuthClient? _client;

  // Initialize client (only once)
  static Future<void> _initialize() async {
    if (_client == null) {
      final serviceAccountJson = await rootBundle.loadString('assets/service-account.json'); // your path
      final serviceAccount = ServiceAccountCredentials.fromJson(serviceAccountJson);
      _client = await clientViaServiceAccount(
        serviceAccount,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );
    }
  }

  // Public method you call from anywhere
  static Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    await _initialize();

    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

    final message = {
      "message": {
        "token": targetToken,
        "notification": {
          "title": title,
          "body": body,
        },
        "android": {
          "priority": "high",
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
            }
          }
        }
      }
    };

    final response = await _client!.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('✅ Notification sent successfully');
    } else {
      print('❌ Failed to send notification');
      print('Status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }
}