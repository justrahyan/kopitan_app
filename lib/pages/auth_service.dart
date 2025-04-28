import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user biasa
  Future<User?> registerUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Tambahkan data user ke Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'full_name': fullName,
          'username': username,
          'email': email,
          'role': 'user', // <-- Tambah role user otomatis di sini
          'created_at': DateTime.now(),
        });
      }

      return user;
    } catch (e) {
      print('Register Error: $e');
      return null;
    }
  }

  // Login user
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
