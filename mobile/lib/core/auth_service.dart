import 'package:flutter/foundation.dart';

class UserSession {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  UserSession({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
      );
}

class AuthService {
  UserSession? _currentUser;
  bool _isOfflineMode = false;

  UserSession? get currentUser => _currentUser;
  bool get isOfflineMode => _isOfflineMode;

  /// Scaffold integration to authenticate with Firebase Authentication & Google Sign-In
  /// currently bound to existing web endpoint surveys89.firebaseapp.com
  Future<UserSession?> signInWithGoogle() async {
    // Scaffold: authenticating using GoogleSignIn and FirebaseAuth.
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = UserSession(
      uid: "firebase_user_123",
      displayName: "مشرف كلية التمريض",
      email: "supervisor@uobaghdad.edu.iq",
      photoUrl: "https://via.placeholder.com/150",
    );
    _isOfflineMode = false;
    if (kDebugMode) {
      print("Scaffold Google Auth Sign In: ${_currentUser?.displayName}");
    }
    return _currentUser;
  }

  /// Sets offline access directly (corresponds to offline mode on the Web App)
  void enterOfflineMode() {
    _isOfflineMode = true;
    _currentUser = UserSession(
      uid: "offline_session",
      displayName: "مستخدم غير متصل",
      email: "offline@college.edu.iq",
    );
    if (kDebugMode) {
      print("Offline local session established");
    }
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _isOfflineMode = false;
  }
}
