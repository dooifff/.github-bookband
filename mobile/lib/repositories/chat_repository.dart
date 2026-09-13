import '../services/api_service.dart';

class ChatRepository {
  final ApiService _api;

  ChatRepository(this._api);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'success': false, 'data': null};
  }

  /// Get chat rooms for the current user
  Future<Map<String, dynamic>> getChatRooms() async {
    return _asMap(await _api.get('/chat'));
  }

  /// Get messages of a chat room
  Future<Map<String, dynamic>> getChatMessages(int roomId, {int page = 1}) async {
    return _asMap(await _api.get(
      '/chat/rooms/$roomId/messages',
      queryParameters: {'page': page},
    ));
  }

  /// Send a message to a chat room
  Future<Map<String, dynamic>> sendChatMessage(
    int roomId,
    String message, {
    String type = 'text',
    String? fileUrl,
  }) async {
    return _asMap(await _api.post('/chat/rooms/$roomId/messages', data: {
      'message': message,
      'type': type,
      if (fileUrl != null) 'file_url': fileUrl,
    }));
  }

  /// Mark all messages in a room as read
  Future<void> markChatAsRead(int roomId) async {
    await _api.post('/chat/rooms/$roomId/read');
  }

  /// Total unread messages for the current user
  Future<int> getUnreadCount() async {
    final response = _asMap(await _api.get('/chat/unread-count'));
    final data = response['data'];
    if (data is Map) {
      return (data['count'] ?? data['unread_count'] ?? 0) as int;
    }
    return 0;
  }

  /// Create (or reuse) the chat room attached to a booking
  Future<Map<String, dynamic>> createRoom({required int bookingId}) async {
    return _asMap(await _api.post('/chat/rooms', data: {
      'booking_id': bookingId,
    }));
  }
}
