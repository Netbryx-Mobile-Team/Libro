import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:libro/core/models/user_model.dart';
import 'package:libro/core/services/firestore_service.dart';

abstract class BaseAuthRepository {
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String userType,
    required String phone,
    String? cnic,
    String? shopName,
    String? shopAddress,
  });

  Future<User?> signInWithGoogle({
    required String userType,
    String? shopName,
    String? shopAddress,
    String? cnic,
    String? phone,
  });

  Future<UserModel?> getUserData(String uid);
  Future<void> signOut();

  Stream<User?> get authStateChanges;
  User? getCurrentUser();
}

class AuthRepository implements BaseAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final String _userCollection = 'users';

  AuthRepository(this._firebaseAuth, this._firestoreService);

  FirestoreService get firestoreService => _firestoreService;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? getCurrentUser() => _firebaseAuth.currentUser;

  // -------------------
  // EMAIL/PASSWORD LOGIN
  // -------------------
  @override
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // -------------------
  // EMAIL/PASSWORD SIGNUP WITH EMAIL & ROLE CHECK
  // -------------------
  @override
  Future<UserModel?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String userType,
    required String phone,
    String? cnic,
    String? shopName,
    String? shopAddress,
  }) async {
    // 1️⃣ Check if email already exists
    final existingUsers = await _firestoreService.getCollectionWhere(
      collection: _userCollection,
      field: 'email',
      isEqualTo: email,
    );

    if (existingUsers.isNotEmpty) {
      final existingRole = existingUsers.first['userType'] ?? '';
      if (existingRole != userType) {
        throw Exception(
          'This email is already registered as "$existingRole". Cannot register as "$userType".'
        );
      } else {
        throw Exception('This email is already registered. Please login.');
      }
    }

    // 2️⃣ Create Firebase Auth account
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      final newUser = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        userType: userType,
        phone: phone,
        cnic: cnic,
        shopName: shopName,
        shopAddress: shopAddress,
      );

      // 3️⃣ Write user data to Firestore
      await _firestoreService.setDocument(
        collection: _userCollection,
        documentId: user.uid,
        data: newUser.toMap(),
      );

      // ✅ Return the full user data immediately
      return newUser;
    }

    return null;
  }

  // -------------------
  // GOOGLE SIGNUP/LOGIN WITH EMAIL & ROLE CHECK
  // -------------------
  @override
  Future<User?> signInWithGoogle({
    required String userType,
    String? shopName,
    String? shopAddress,
    String? cnic,
    String? phone,
  }) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final docRef = _firestoreService.docRef(_userCollection, user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Check email conflict
        final existingUsers = await _firestoreService.getCollectionWhere(
          collection: _userCollection,
          field: 'email',
          isEqualTo: user.email,
        );

        if (existingUsers.isNotEmpty) {
          final existingRole = existingUsers.first['userType'] ?? '';
          if (existingRole != userType) {
            throw Exception(
              'This email is already registered as "$existingRole". Cannot register as "$userType".'
            );
          }
        }

        // Create Firestore user
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'No Name',
          userType: userType,
          phone: phone ?? '',
          cnic: cnic,
          shopName: shopName,
          shopAddress: shopAddress,
          profileImageBase64: null,
        );
        await docRef.set(newUser.toMap());
      }
    }

    return user;
  }

  // -------------------
  // GET USER DATA
  // -------------------
  @override
  Future<UserModel?> getUserData(String uid) async {
    final data = await _firestoreService.getDocument(
      collection: _userCollection,
      documentId: uid,
    );
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  // -------------------
  // SIGN OUT
  // -------------------
  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      }
    } catch (e) {
      print("Logout error: $e");
    }
  }
}
