// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, emailNotVerified }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _emailVerified = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isEmailVerified => _emailVerified;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    _authService.authStateChanges.listen(
      (User? firebaseUser) async {
        try {
          if (firebaseUser == null) {
            _status = AuthStatus.unauthenticated;
            _user = null;
            _emailVerified = false;
          } else {
            // Reload user to get latest emailVerified status
            try {
              await firebaseUser.reload();
              final refreshedUser = FirebaseAuth.instance.currentUser;
              _emailVerified = refreshedUser?.emailVerified ?? false;
            } catch (e) {
              // If reload fails, use the current verification status
              _emailVerified = firebaseUser.emailVerified;
            }
            
            // Only update user profile if not already set (to avoid overwriting after login)
            if (_user == null || _user?.uid != firebaseUser.uid) {
              try {
                _user = await _authService.getCurrentUserProfile();
              } catch (e) {
                // If we can't get user profile from Firestore, create a basic one from auth data
                _user = UserModel(
                  uid: firebaseUser.uid,
                  email: firebaseUser.email ?? '',
                  displayName: firebaseUser.displayName ?? '',
                  createdAt: DateTime.now(),
                );
              }
            }
            
            // Set authenticated only if email is verified
            if (_emailVerified) {
              _status = AuthStatus.authenticated;
            } else {
              // User is logged in but email is not verified
              _status = AuthStatus.emailNotVerified;
            }
          }
          notifyListeners();
        } catch (e) {
          // Handle any unexpected errors in the auth flow
          _status = AuthStatus.unauthenticated;
          _user = null;
          _emailVerified = false;
          notifyListeners();
        }
      },
      onError: (error) {
        // Handle stream errors gracefully
        _status = AuthStatus.unauthenticated;
        _user = null;
        _emailVerified = false;
        notifyListeners();
      },
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        _clearError();
        notifyListeners();
        return true;
      }
      _setError('Sign in failed.');
      return false;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> resendVerificationEmail() async {
    await _authService.resendVerificationEmail();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading();
    try {
      await _authService.resetPassword(email);
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> updateNotificationPreference(bool value) async {
    if (_user == null) return;
    await _authService.updateUserProfile(_user!.uid, {
      'notificationsEnabled': value,
    });
    _user = _user!.copyWith(notificationsEnabled: value);
    notifyListeners();
  }

  Future<void> updateLocationPreference(bool value) async {
    if (_user == null) return;
    await _authService.updateUserProfile(_user!.uid, {
      'locationEnabled': value,
    });
    _user = _user!.copyWith(locationEnabled: value);
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}