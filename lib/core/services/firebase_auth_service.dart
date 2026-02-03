import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===============================
  // EMAIL / PASSWORD AUTH
  // ===============================
  Future<User?> signInWithEmailPassword(String email, String password) async {
    final userCredential =
        await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  Future<User?> signUpWithEmailPassword(
      String email, String password, String role) async {
    final userCredential =
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = userCredential.user;
    if (user != null) {
      await _createUserIfNotExists(user, role);
    }
    return user;
  }

  // ===============================
  // GOOGLE SIGN-IN
  // ===============================
  Future<User?> signInWithGoogle({required String role}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _createUserIfNotExists(user, role);
      }

      return user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // ===============================
  // CREATE USER DOC IF NOT EXISTS
  // ===============================
  Future<void> _createUserIfNotExists(User user, String role) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': role, // "reader" or "vendor"
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ===============================
  // UPDATE USER ROLE
  // ===============================
  Future<void> updateUserRole(String uid, String newRole) async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();

    if (doc.exists) {
      await userRef.update({'role': newRole});
    }
  }

  // ===============================
  // SIGN OUT
  // ===============================
  Future<void> signOut() async {
    await _auth.signOut();
    if (await _googleSignIn.isSignedIn()) await _googleSignIn.signOut();
  }

  // ===============================
  // GET USER ROLE
  // ===============================
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'];
  }

  // ===============================
  // CHECK IF CURRENT USER IS VENDOR
  // ===============================
  Future<bool> isVendor() async {
    final role = await getUserRole();
    return role == 'vendor';
  }

  // ===============================
  // CHECK IF CURRENT USER IS READER
  // ===============================
  Future<bool> isReader() async {
    final role = await getUserRole();
    return role == 'reader';
  }

  // ===============================
  // CHECK IF USER EXISTS
  // ===============================
  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }
}
