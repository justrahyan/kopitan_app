import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrasi user dan simpan ke Firestore
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
        final docRef = _firestore.collection('users').doc(user.uid);

        await docRef.set({
          'full_name': fullName,
          'username': username,
          'email': email,
          'role': 'user',
          'created_at': FieldValue.serverTimestamp(),
        });

        final checkDoc = await docRef.get();
        if (checkDoc.exists) {
          print(
            '✅ Firestore: Data user berhasil disimpan untuk UID: ${user.uid}',
          );
        } else {
          print('❌ Firestore: Data tidak ditemukan setelah penyimpanan.');
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuth Register Error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ General Register Error: $e');
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
      print('🟢 Login berhasil: ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuth Login Error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ General Login Error: $e');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
