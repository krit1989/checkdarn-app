import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../utils/helpers.dart';

class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'events';

  /// Create a new event
  static Future<String?> createEvent(EventModel event) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(event.toJson());
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  /// Get all events
  static Future<List<EventModel>> getAllEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  /// Get events within radius
  static Future<List<EventModel>> getEventsInRadius(
    double latitude,
    double longitude,
    double radiusInMeters,
  ) async {
    try {
      final allEvents = await getAllEvents();

      return allEvents.where((event) {
        final distance = Helpers.calculateDistance(
          latitude,
          longitude,
          event.latitude,
          event.longitude,
        );
        return distance <= radiusInMeters;
      }).toList();
    } catch (e) {
      print('Error getting events in radius: $e');
      return [];
    }
  }

  /// Get events by category
  static Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting events by category: $e');
      return [];
    }
  }

  /// Get event by ID
  static Future<EventModel?> getEventById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (doc.exists) {
        return EventModel.fromJson({...doc.data()!, 'id': doc.id});
      }

      return null;
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }

  /// Update event
  static Future<bool> updateEvent(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection(_collection).doc(id).update(updates);
      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    }
  }

  /// Delete event
  static Future<bool> deleteEvent(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  /// Verify event (increment verification count)
  static Future<bool> verifyEvent(String id) async {
    try {
      final event = await getEventById(id);
      if (event != null) {
        await updateEvent(id, {
          'verificationCount': event.verificationCount + 1,
          'isVerified':
              event.verificationCount + 1 >= 3, // Verified if 3+ confirmations
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying event: $e');
      return false;
    }
  }

  /// Report false event (increment false report count)
  static Future<bool> reportFalseEvent(String id) async {
    try {
      final event = await getEventById(id);
      if (event != null) {
        await updateEvent(id, {'falseReportCount': event.falseReportCount + 1});

        // Delete event if too many false reports
        if (event.falseReportCount + 1 >= 5) {
          await deleteEvent(id);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error reporting false event: $e');
      return false;
    }
  }

  /// Get events stream for real-time updates
  static Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Get recent events (last 24 hours)
  static Future<List<EventModel>> getRecentEvents() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThan: yesterday.millisecondsSinceEpoch)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting recent events: $e');
      return [];
    }
  }
}
