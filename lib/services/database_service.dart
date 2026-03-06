import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of places to show in the UI
  Stream<List<Place>> getPlaces() {
    return _db.collection('places').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Place.fromMap(doc.data(), doc.id)).toList());
  }

  // Add a new place (useful for your admin/testing)
  Future<void> addPlace(Place place) {
    return _db.collection('places').add({
      'name': place.name,
      'category': place.category,
      'description': place.description,
      'latitude': place.latitude,
      'longitude': place.longitude,
    });
  }
}