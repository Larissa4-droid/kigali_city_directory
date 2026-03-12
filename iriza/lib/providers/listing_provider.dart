// lib/providers/listing_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';
import '../services/listing_service.dart';

enum ListingStatus { initial, loading, loaded, error }

class ListingProvider extends ChangeNotifier {
  final ListingService _service = ListingService();

  List<ListingModel> _allListings = [];
  List<ListingModel> _userListings = [];
  List<ListingModel> _filteredListings = [];
  final List<String> _bookmarkedIds = [];

  ListingStatus _status = ListingStatus.initial;
  String? _errorMessage;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  StreamSubscription<List<ListingModel>>? _listingsSubscription;
  StreamSubscription<List<ListingModel>>? _userListingsSubscription;

  List<ListingModel> get allListings => _allListings;
  List<ListingModel> get userListings => _userListings;
  List<ListingModel> get filteredListings => _filteredListings;
  List<ListingModel> get bookmarkedListings =>
      _allListings.where((l) => _bookmarkedIds.contains(l.id)).toList();
  ListingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _status == ListingStatus.loading;

  bool isBookmarked(String id) => _bookmarkedIds.contains(id);

  // Initialize and subscribe to listings
  void initListings() {
    print('Initializing listings stream...');
    _status = ListingStatus.loading;
    notifyListeners();

    _listingsSubscription?.cancel();
    _listingsSubscription = _service.streamAllListings().listen(
      (listings) {
        print('Received ${listings.length} listings from stream');
        _allListings = listings;
        _applyFilters();
        _status = ListingStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        print('Error in listings stream: $e');
        _status = ListingStatus.error;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  void initUserListings(String uid) {
    print('Initializing user listings stream for uid: $uid');
    _userListingsSubscription?.cancel();
    _userListingsSubscription = _service.streamUserListings(uid).listen(
      (listings) {
        print('Received ${listings.length} user listings from stream');
        _userListings = listings;
        notifyListeners();
      },
      onError: (e) {
        print('Error in user listings stream: $e');
      },
    );
  }

  void _applyFilters() {
    List<ListingModel> result = List.from(_allListings);
    print('Applying filters to ${_allListings.length} listings');

    // Category filter
    if (_selectedCategory != 'All') {
      result = result.where((l) => l.category == _selectedCategory).toList();
      print('After category filter: ${result.length} listings');
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((l) =>
          l.name.toLowerCase().contains(query) ||
          l.category.toLowerCase().contains(query) ||
          l.address.toLowerCase().contains(query) ||
          l.description.toLowerCase().contains(query)).toList();
      print('After search filter: ${result.length} listings');
    }

    _filteredListings = result;
    print('Final filtered listings: ${_filteredListings.length}');
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void toggleBookmark(String id) {
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    notifyListeners();
  }

  Future<bool> createListing(ListingModel listing) async {
    try {
      print('Creating listing: ${listing.name}');
      await _service.createListing(listing);
      print('Listing created successfully');
      return true;
    } catch (e) {
      print('Error creating listing: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateListing(String id, Map<String, dynamic> data) async {
    try {
      print('Provider: Updating listing: $id');
      print('Provider: Update data: $data');
      await _service.updateListing(id, data);
      print('Provider: Listing updated successfully');
      return true;
    } catch (e) {
      print('Provider: Error updating listing: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    try {
      print('Provider: Deleting listing: $id');
      await _service.deleteListing(id);
      print('Provider: Listing deleted successfully');
      return true;
    } catch (e) {
      print('Provider: Error deleting listing: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addReview(ReviewModel review) async {
    try {
      print('Adding review for listing: ${review.listingId}');
      await _service.addReview(review);
      print('Review added successfully');
      return true;
    } catch (e) {
      print('Error adding review: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Stream<List<ReviewModel>> streamReviews(String listingId) {
    return _service.streamReviews(listingId);
  }

  Future<void> seedSampleData(String uid, String userName) async {
    await _service.seedSampleData(uid, userName);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    _userListingsSubscription?.cancel();
    super.dispose();
  }
}