import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== PLACES OPERATIONS ====================

  // Stream of all places
  Stream<List<Place>> getPlaces() {
    return _db.collection('places').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Place.fromMap(doc.data(), doc.id)).toList());
  }

  // Get places by category
  Stream<List<Place>> getPlacesByCategory(String category) {
    return _db.collection('places')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Place.fromMap(doc.data(), doc.id)).toList());
  }

  // Get places created by a specific user
  Stream<List<Place>> getPlacesByUser(String userId) {
    return _db.collection('places')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Place.fromMap(doc.data(), doc.id)).toList());
  }

  // Search places by name
  Stream<List<Place>> searchPlaces(String query) {
    return _db.collection('places')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Place.fromMap(doc.data(), doc.id)).toList());
  }

  // Add a new place
  Future<String> addPlace(Place place) async {
    DocumentReference docRef = await _db.collection('places').add(place.toMap());
    return docRef.id;
  }

  // Update a place
  Future<void> updatePlace(String id, Place place) async {
    await _db.collection('places').doc(id).update(place.toMap());
  }

  // Delete a place
  Future<void> deletePlace(String id) async {
    await _db.collection('places').doc(id).delete();
  }

  // Get a single place by ID
  Future<Place?> getPlaceById(String id) async {
    DocumentSnapshot doc = await _db.collection('places').doc(id).get();
    if (doc.exists) {
      return Place.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ==================== USER PROFILE OPERATIONS ====================

  // Create or update user profile
  Future<void> createOrUpdateUserProfile(String userId, Map<String, dynamic> profileData) async {
    await _db.collection('users').doc(userId).set(profileData, SetOptions(merge: true));
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  // Stream of user profile
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  // Update notification preferences
  Future<void> updateNotificationPreference(String userId, bool enabled) async {
    await _db.collection('users').doc(userId).update({
      'notificationsEnabled': enabled,
    });
  }
}

