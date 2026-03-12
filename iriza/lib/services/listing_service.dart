// lib/services/listing_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'listings';
  static const String _reviewsCollection = 'reviews';

  // Stream all listings (real-time)
  Stream<List<ListingModel>> streamAllListings() {
    print('Service: Setting up all listings stream');
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          print('Service: All listings stream emitted ${snap.docs.length} listings');
          return snap.docs.map(ListingModel.fromFirestore).toList();
        });
  }

  // Stream listings by user
  Stream<List<ListingModel>> streamUserListings(String uid) {
    print('Service: Setting up user listings stream for uid: $uid');
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          print('Service: User listings stream emitted ${snap.docs.length} listings');
          return snap.docs.map(ListingModel.fromFirestore).toList();
        });
  }

  // Get single listing
  Future<ListingModel?> getListing(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }

  // Create listing
  Future<String> createListing(ListingModel listing) async {
    print('Service: Creating listing with ID: ${listing.id}');
    await _firestore.collection(_collection).doc(listing.id).set(listing.toMap());
    print('Service: Listing saved to Firestore');
    return listing.id;
  }

  // Update listing
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    print('Service: Updating listing: $id');
    print('Service: Update data: $data');
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('Service: Listing updated successfully in Firestore');
  }

  // Delete listing
  Future<void> deleteListing(String id) async {
    print('Service: Deleting listing: $id');
    await _firestore.collection(_collection).doc(id).delete();
    print('Service: Listing document deleted');
    
    // Also delete reviews
    print('Service: Deleting associated reviews...');
    final reviews = await _firestore
        .collection(_reviewsCollection)
        .where('listingId', isEqualTo: id)
        .get();
    print('Service: Found ${reviews.docs.length} reviews to delete');
    for (final doc in reviews.docs) {
      await doc.reference.delete();
    }
    print('Service: All reviews deleted');
  }

  // Search listings
  Future<List<ListingModel>> searchListings(String query) async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();
    return snapshot.docs.map(ListingModel.fromFirestore).toList();
  }

  // Get listings by category
  Stream<List<ListingModel>> streamListingsByCategory(String category) {
    if (category == 'All') return streamAllListings();
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ListingModel.fromFirestore).toList());
  }

  // Add review
  Future<void> addReview(ReviewModel review) async {
    print('Service: Adding review with ID: ${review.id}');
    await _firestore.collection(_reviewsCollection).doc(review.id).set(review.toMap());
    print('Service: Review saved to Firestore');

    // Update listing rating
    print('Service: Updating listing rating...');
    final reviews = await _firestore
        .collection(_reviewsCollection)
        .where('listingId', isEqualTo: review.listingId)
        .get();

    if (reviews.docs.isNotEmpty) {
      double total = 0;
      for (final doc in reviews.docs) {
        total += (doc.data()['rating'] ?? 0.0).toDouble();
      }
      final avgRating = total / reviews.docs.length;
      print('Service: New average rating: $avgRating (${reviews.docs.length} reviews)');
      await _firestore.collection(_collection).doc(review.listingId).update({
        'rating': avgRating,
        'reviewCount': reviews.docs.length,
      });
      print('Service: Listing rating updated');
    }
  }

  // Stream reviews for a listing
  Stream<List<ReviewModel>> streamReviews(String listingId) {
    print('Service: Setting up reviews stream for listing: $listingId');
    return _firestore
        .collection(_reviewsCollection)
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          print('Service: Received ${snap.docs.length} reviews from stream');
          return snap.docs.map(ReviewModel.fromFirestore).toList();
        });
  }

  // Seed sample data for Kigali
  Future<void> seedSampleData(String uid, String userName) async {
    final existingDocs = await _firestore.collection(_collection).limit(1).get();
    if (existingDocs.docs.isNotEmpty) return; // Already seeded

    final sampleListings = [
      ListingModel(
        id: 'sample-1',
        name: 'Kimironko Café',
        category: 'Cafés',
        address: 'Kimironko, Kigali',
        contactNumber: '+250 788 123 456',
        description: 'Popular neighborhood café offering fresh coffee pastries and light meals in a cozy setting.',
        latitude: -1.9356,
        longitude: 30.1027,
        createdBy: uid,
        createdByName: userName,
        createdAt: DateTime.now(),
        rating: 4.3,
        reviewCount: 45,
      ),
      ListingModel(
        id: 'sample-2',
        name: 'Green Bean Coffee',
        category: 'Cafés',
        address: 'Kacyiru, Kigali',
        contactNumber: '+250 788 234 567',
        description: 'Specialty coffee roasters serving premium Rwandan single-origin beans.',
        latitude: -1.9441,
        longitude: 30.0619,
        createdBy: uid,
        createdByName: userName,
        createdAt: DateTime.now(),
        rating: 4.0,
        reviewCount: 38,
      ),
      ListingModel(
        id: 'sample-3',
        name: 'Umuganda Coffee',
        category: 'Cafés',
        address: 'Remera, Kigali',
        contactNumber: '+250 788 345 678',
        description: 'Community café with workspace and excellent Rwandan coffee.',
        latitude: -1.9547,
        longitude: 30.1152,
        createdBy: uid,
        createdByName: userName,
        createdAt: DateTime.now(),
        rating: 4.4,
        reviewCount: 62,
      ),
      ListingModel(
        id: 'sample-4',
        name: 'King Faisal Hospital',
        category: 'Hospitals',
        address: 'Kacyiru, Kigali',
        contactNumber: '+250 252 582 421',
        description: 'Leading referral hospital providing comprehensive medical services.',
        latitude: -1.9392,
        longitude: 30.0617,
        createdBy: uid,
        createdByName: userName,
        createdAt: DateTime.now(),
        rating: 4.1,
        reviewCount: 120,
      ),
      ListingModel(
        id: 'sample-5',
        name: 'Kigali Public Library',
        category: 'Libraries',
        address: 'Nyarugenge, Kigali',
        contactNumber: '+250 252 571 201',
        description: 'Modern public library with extensive collection and digital resources.',
        latitude: -1.9490,
        longitude: 30.0587,
        createdBy: uid,
        createdByName: userName,
        createdAt: DateTime.now(),
        rating: 4.5,
        reviewCount: 88,
      ),
      ListingModel(
        id: 'sample-6',
        name: 'Nyandungu Urban Wetland',
        category: 'Parks',
        address: 'Kicukiro, Kigali',
        contactNumber: '+250 788 456 789',
        description: 'Beautiful urban eco-park featuring walking trails through restored wetlands.',
        latitude: -1.9825,
        longitude: 30.1012,
        createdBy: uid,
        createdByName: userName,
        createdAt: DateTime.now(),
        rating: 4.7,
        reviewCount: 215,
      ),
      ListingModel(
        id: 'sample-7',
        name: 'Kigali Genocide Memorial',
        category: 'Tourist Attractions',
        address: 'Gisozi, Kigali',
        contactNumber: '+250 252 502 094',
        description: 'National memorial site honoring victims of the 1994 Genocide against the Tutsi.',
        latitude: -1.9293,
        longitude: 30.0607,
        createdBy: uid,
        createdByName: userName,
        createdAt: DateTime.now(),
        rating: 4.9,
        reviewCount: 540,
      ),
    ];

    for (final listing in sampleListings) {
      await _firestore.collection(_collection).doc(listing.id).set(listing.toMap());
    }
  }
}