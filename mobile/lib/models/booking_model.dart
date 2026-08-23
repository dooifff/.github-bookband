class Booking {
  final int id;
  final int userId;
  final int roomId;
  final int studioId;
  final String date;
  final String startTime;
  final String endTime;
  final int durationHours;
  final double subtotal;
  final double discount;
  final double total;
  final String status;
  final String? notes;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BookingRoom? room;
  final BookingStudio? studio;

  Booking({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.studioId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    this.notes,
    this.cancelReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.room,
    this.studio,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      roomId: json['room_id'],
      studioId: json['studio_id'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationHours: json['duration_hours'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'],
      notes: json['notes'],
      cancelReason: json['cancel_reason'],
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      room: json['room'] != null ? BookingRoom.fromJson(json['room']) : null,
      studio: json['studio'] != null ? BookingStudio.fromJson(json['studio']) : null,
    );
  }
  
  Booking copyWith({String? status}) {
    return Booking(
      id: id,
      userId: userId,
      roomId: roomId,
      studioId: studioId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      durationHours: durationHours,
      subtotal: subtotal,
      discount: discount,
      total: total,
      status: status ?? this.status,
      notes: notes,
      cancelReason: cancelReason,
      cancelledAt: cancelledAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      room: room,
      studio: studio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'room_id': roomId,
      'studio_id': studioId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status,
      'notes': notes,
      'cancel_reason': cancelReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  String get formattedTotal => 'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  
  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'awaiting_payment': return 'Awaiting Payment';
      case 'paid': return 'Paid';
      case 'confirmed': return 'Confirmed';
      case 'ongoing': return 'Ongoing';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'expired': return 'Expired';
      case 'failed': return 'Failed';
      case 'refunded': return 'Refunded';
      default: return status;
    }
  }
}

class BookingRoom {
  final int id;
  final String name;
  final int capacity;
  
  BookingRoom({
    required this.id,
    required this.name,
    required this.capacity,
  });
  
  factory BookingRoom.fromJson(Map<String, dynamic> json) {
    return BookingRoom(
      id: json['id'],
      name: json['name'],
      capacity: json['capacity'],
    );
  }
}

class BookingStudio {
  final int id;
  final String name;
  final String? logo;
  
  BookingStudio({
    required this.id,
    required this.name,
    this.logo,
  });
  
  factory BookingStudio.fromJson(Map<String, dynamic> json) {
    return BookingStudio(
      id: json['id'],
      name: json['name'],
      logo: json['logo'],
    );
  }
}
