import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/place_model.dart';

class AppProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Places state
  List<Place> _places = [];
  List<Place> _myPlaces = [];
  List<Place> _filteredPlaces = [];
  bool _isLoading = false;
  String? _dbError;
  
  // Auth state
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isEmailVerified = false;
  
  // Search and filter state
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  // Notification state
  bool _notificationsEnabled = false;

  StreamSubscription<List<Place>>? _placesSub;
  StreamSubscription<List<Place>>? _myPlacesSub;
  StreamSubscription<User?>? _authSub;

  // Getters
  List<Place> get places => _searchQuery.isEmpty && _selectedCategory == 'All' 
      ? _places 
      : _filteredPlaces;
  List<Place> get myPlaces => _myPlaces;
  bool get isLoading => _isLoading;
  String? get dbError => _dbError;
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isEmailVerified => _isEmailVerified;
  bool get isAuthenticated => _currentUser != null;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get notificationsEnabled => _notificationsEnabled;

  AppProvider() {
    // Listen to auth state
    _authSub = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        _isEmailVerified = user.emailVerified;
        _startPlacesListener();
        _loadUserProfile();
      } else {
        _cancelPlacesListener();
        _clearUserData();
      }
      notifyListeners();
    });
  }

  void _startPlacesListener() {
    if (_placesSub != null) return;

    _placesSub = _dbService.getPlaces().listen((data) {
      _places = data;
      _applyFilters();
      notifyListeners();
    }, onError: (err) {
      _dbError = err.toString();
      debugPrint('DatabaseService.getPlaces error: $_dbError');
      notifyListeners();
    });

    // Listen to user's places
    if (_currentUser != null) {
      _myPlacesSub = _dbService.getPlacesByUser(_currentUser!.uid).listen((data) {
        _myPlaces = data;
        notifyListeners();
      });
    }
  }

  void _cancelPlacesListener() {
    _placesSub?.cancel();
    _myPlacesSub?.cancel();
    _placesSub = null;
    _myPlacesSub = null;
    _places = [];
    _myPlaces = [];
    _filteredPlaces = [];
    notifyListeners();
  }

  void _clearUserData() {
    _currentUser = null;
    _userProfile = null;
    _isEmailVerified = false;
    _notificationsEnabled = false;
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser != null) {
      _dbService.getUserProfileStream(_currentUser!.uid).listen((profile) {
        _userProfile = profile;
        _notificationsEnabled = profile?['notificationsEnabled'] ?? false;
        notifyListeners();
      });
    }
  }

  void _applyFilters() {
    List<Place> result = List.from(_places);
    
    // Apply category filter
    if (_selectedCategory != 'All') {
      result = result.where((place) => place.category == _selectedCategory).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((place) => 
        place.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    _filteredPlaces = result;
  }

  // Search and Filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _filteredPlaces = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _placesSub?.cancel();
    _myPlacesSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  // ==================== AUTHENTICATION ====================

  // LOGIN FUNCTION
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      _currentUser = cred.user;
      _isEmailVerified = cred.user?.emailVerified ?? false;
      
      debugPrint('Signed in: ${cred.user?.uid} / ${cred.user?.email}');
      
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // SIGNUP FUNCTION + EMAIL VERIFICATION
  Future<String?> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send verification email
      await result.user?.sendEmailVerification();
      
      // Create user profile in Firestore
      await _dbService.createOrUpdateUserProfile(result.user!.uid, {
        'email': email,
        'createdAt': DateTime.now(),
        'notificationsEnabled': false,
      });
      
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    }
  }

  // LOGOUT FUNCTION
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _userProfile = null;
    _isEmailVerified = false;
    _cancelPlacesListener();
    notifyListeners();
  }

  // CHECK EMAIL VERIFIED
  Future<void> checkEmailVerified() async {
    if (_currentUser != null) {
      await _currentUser!.reload();
      _currentUser = _auth.currentUser;
      _isEmailVerified = _currentUser?.emailVerified ?? false;
      notifyListeners();
    }
  }

  // RELOAD USER
  Future<void> reloadUser() async {
    await _currentUser?.reload();
    _currentUser = _auth.currentUser;
    notifyListeners();
  }

  // ==================== CRUD OPERATIONS ====================

  // Add a new place
  Future<String?> addPlace({
    required String name,
    required String category,
    required String address,
    required String contactNumber,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    if (_currentUser == null) return 'User not authenticated';
    
    _isLoading = true;
    notifyListeners();
    
    try {
      Place place = Place(
        id: '',
        name: name,
        category: category,
        address: address,
        contactNumber: contactNumber,
        description: description,
        latitude: latitude,
        longitude: longitude,
        createdBy: _currentUser!.uid,
        timestamp: DateTime.now(),
      );
      
      await _dbService.addPlace(place);
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Update a place
  Future<String?> updatePlace({
    required String id,
    required String name,
    required String category,
    required String address,
    required String contactNumber,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    if (_currentUser == null) return 'User not authenticated';
    
    _isLoading = true;
    notifyListeners();
    
    try {
      Place place = Place(
        id: id,
        name: name,
        category: category,
        address: address,
        contactNumber: contactNumber,
        description: description,
        latitude: latitude,
        longitude: longitude,
        createdBy: _currentUser!.uid,
        timestamp: DateTime.now(),
      );
      
      await _dbService.updatePlace(id, place);
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Delete a place
  Future<String?> deletePlace(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _dbService.deletePlace(id);
      
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // Get place by ID
  Future<Place?> getPlaceById(String id) async {
    return await _dbService.getPlaceById(id);
  }

  // ==================== SETTINGS ====================

  // Update notification preference
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_currentUser == null) return;
    
    _notificationsEnabled = enabled;
    await _dbService.updateNotificationPreference(_currentUser!.uid, enabled);
    notifyListeners();
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;
    
    await _dbService.createOrUpdateUserProfile(_currentUser!.uid, data);
    notifyListeners();
  }
}

