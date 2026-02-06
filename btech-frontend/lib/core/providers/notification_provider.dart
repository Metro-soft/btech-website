import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../network/auth_service.dart';

class NotificationProvider with ChangeNotifier {
  late socket_io.Socket _socket;
  final AuthService _authService = AuthService();

  final List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isConnected = false;
  bool _isLoading = false;
  String _activeFilter = 'ALL'; // ALL, UNREAD, AI, SYSTEM

  bool get isLoading => _isLoading;

  String get activeFilter => _activeFilter;
  bool get isConnected => _isConnected;
  int get unreadCount => _unreadCount;

  List<dynamic> get notifications {
    if (_activeFilter == 'ALL') return _notifications;
    if (_activeFilter == 'UNREAD') {
      return _notifications.where((n) => n['isRead'] == false).toList();
    }
    if (_activeFilter == 'AI') {
      return _notifications.where((n) => n['type'] == 'AI_INSIGHT').toList();
    }
    // Generic type matching for others
    return _notifications.where((n) => n['type'] == _activeFilter).toList();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  // Initialize Socket Connection
  Future<void> initSocket() async {
    final token = await _authService.getToken();
    if (token == null) return;

    // Configure Socket
    _socket = socket_io.io(
        'http://172.31.235.222:5000',
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .build());

    _socket.connect();

    _socket.onConnect((_) {
      debugPrint('Socket Connected');
      _isConnected = true;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      debugPrint('Socket Disconnected');
      _isConnected = false;
      notifyListeners();
    });

    // Listen for new notifications
    _socket.on('notification', (data) {
      debugPrint('New Notification: $data');
      _notifications.insert(0, data); // Add to top
      _unreadCount++;
      notifyListeners();
    });

    // Listen for unread count updates
    _socket.on('unread_count', (data) {
      if (data != null && data['count'] != null) {
        _unreadCount = data['count'];
        notifyListeners();
      }
    });
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.authenticatedRequest(
        'GET',
        '/notifications',
      );

      if (response.statusCode == 200) {
        // Assuming response body is list of notifications
        // Or { data: [...] } depending on API
        // Let's assume standard response
        final data = response
            .data; // You might need jsonDecode depending on AuthService wrapper
        if (data is List) {
          _notifications.clear();
          _notifications.addAll(data);
        } else if (data['data'] is List) {
          _notifications.clear();
          _notifications.addAll(data['data']);
        }

        // Recalculate unread
        _unreadCount = _notifications.where((n) => n['isRead'] == false).length;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic Update
    final index = _notifications.indexWhere((n) => n['_id'] == id);
    if (index != -1) {
      _notifications[index]['isRead'] = true;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();

      // Persist to backend
      try {
        await _authService.authenticatedRequest(
          'PUT',
          '/notifications/$id/read',
        );
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
        // Optionally revert optimistic update here if critical
      }
    }
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
