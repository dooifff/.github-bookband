import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studiobook/models/booking_model.dart';
import 'package:studiobook/models/studio_model.dart';
import 'package:studiobook/widgets/booking_card.dart';

void main() {
  group('Studio.fromJson', () {
    test('parses studio payload with rooms, images and equipment', () {
      final studio = Studio.fromJson({
        'id': 1,
        'owner_id': 2,
        'name': 'Studio A',
        'slug': 'studio-a',
        'city': 'Jakarta',
        'average_rating': 4.5,
        'total_reviews': 10,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'rooms': [
          {'id': 7, 'studio_id': 1, 'name': 'Ruang 1', 'capacity': 4, 'price_per_hour': 100000}
        ],
        'images': [
          {'id': 3, 'studio_id': 1, 'url': 'https://example.com/a.jpg'}
        ],
        'equipment': [
          {'id': 9, 'name': 'Drum Set'}
        ],
        'opening_hours': [
          {'id': 4, 'day_of_week': 1, 'open_time': '09:00', 'close_time': '21:00'}
        ],
      });

      expect(studio.name, 'Studio A');
      expect(studio.rooms.single.name, 'Ruang 1');
      expect(studio.images.single.url, 'https://example.com/a.jpg');
      expect(studio.equipment.single.name, 'Drum Set');
      expect(studio.openingHours.single.isClosed, isFalse);
      expect(studio.isFavorited, isFalse);
    });

    test('tolerates a partial payload', () {
      final studio = Studio.fromJson({'id': 5, 'name': 'Studio B'});

      expect(studio.id, 5);
      expect(studio.rooms, isEmpty);
      expect(studio.images, isEmpty);
    });
  });

  group('Booking.fromJson', () {
    test('reads nested pricing, room and studio relations', () {
      final booking = Booking.fromJson({
        'id': 1,
        'booking_code': 'BK-1234',
        'date': '2026-09-20',
        'start_time': '10:00',
        'end_time': '12:00',
        'duration_hours': 2,
        'status': 'paid',
        'created_at': '2026-09-13T00:00:00Z',
        'updated_at': '2026-09-13T00:00:00Z',
        'pricing': {'subtotal': 200000, 'discount': 20000, 'total': 180000},
        'room': {'id': 7, 'name': 'Ruang 1', 'capacity': 4},
        'studio': {'id': 3, 'name': 'Studio A'},
      });

      expect(booking.bookingCode, 'BK-1234');
      expect(booking.total, 180000);
      expect(booking.totalAmount, 180000);
      expect(booking.bookingDate, '2026-09-20');
      expect(booking.roomId, 7);
      expect(booking.studioId, 3);
      expect(booking.studio?.name, 'Studio A');
    });
  });

  testWidgets('BookingCard renders the booking summary', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BookingCard(
          bookingCode: 'BK-1234',
          customerName: 'Budi',
          studioName: 'Studio A',
          roomName: 'Ruang 1',
          date: '2026-09-20',
          startTime: '10:00',
          endTime: '12:00',
          status: 'confirmed',
          totalPrice: 180000,
        ),
      ),
    ));

    expect(find.text('Studio A'), findsOneWidget);
    expect(find.text('Ruang 1'), findsOneWidget);
    expect(find.text('BK-1234'), findsOneWidget);
    expect(find.text('Dikonfirmasi'), findsOneWidget);
  });
}
