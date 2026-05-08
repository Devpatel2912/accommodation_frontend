import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/api_config.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  RealtimeChannel? _adminChannel;
  RealtimeChannel? _userChannel;

  final _adminNotificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _userNotificationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get adminNotifications => _adminNotificationController.stream;
  Stream<Map<String, dynamic>> get userNotifications => _userNotificationController.stream;

  Future<void> init() async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: ApiConfig.supabaseUrl,
      anonKey: ApiConfig.supabaseAnonKey,
    );

    _isInitialized = true;
  }

  void subscribeToAdminNotifications() {
    _adminChannel = Supabase.instance.client.channel('admin-notifications');
    
    _adminChannel!.onBroadcast(
      event: 'new_request',
      callback: (payload) {
        print('🔔 Admin Notification: New Request Received');
        _adminNotificationController.add(payload);
      },
    ).subscribe();
  }

  void subscribeToUserNotifications(String userId) {
    _userChannel = Supabase.instance.client.channel('user-notifications-$userId');
    
    _userChannel!.onBroadcast(
      event: 'status_update',
      callback: (payload) {
        print('🔔 User Notification: Request Status Updated');
        _userNotificationController.add(payload);
      },
    ).subscribe();
  }

  void unsubscribe() {
    _adminChannel?.unsubscribe();
    _userChannel?.unsubscribe();
  }
}
