import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrasi user dengan role default: "user"
  Future<User?> registerUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Simpan data user ke Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'full_name': fullName,
          'username': username,
          'email': email,
          'role': 'user', // default role
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth Register Error: ${e.message}');
      return null;
    } catch (e) {
      print('General Register Error: $e');
      return null;
    }
  }

  /// Login user
  Future<User?> loginUser(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth Login Error: ${e.message}');
      return null;
    } catch (e) {
      print('General Login Error: $e');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Cek user login saat ini
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
