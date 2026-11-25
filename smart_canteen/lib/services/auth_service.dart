import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream perubahan status autentikasi
  Stream<User?> authChanges() => _auth.authStateChanges();

  // Pengguna yang sedang login saat ini
  User? get currentUser => _auth.currentUser;

  // Stream data profil pengguna dari Firestore
  Stream<UserModel?> userProfileStream(String uid) {
    return _db.collection(AppConstants.colUsers).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // Mendapatkan profil pengguna satu kali
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Registrasi khusus siswa (role selalu 'siswa' di backend)
  Future<UserModel> registerStudent({
    required String nama,
    required String email,
    required String password,
    required String kelas,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Gagal membuat akun.');
    }

    final userModel = UserModel(
      uid: user.uid,
      nama: nama.trim(),
      email: email.trim(),
      role: AppConstants.roleSiswa,
      kelas: kelas.trim(),
    );

    await _db.collection(AppConstants.colUsers).doc(user.uid).set(userModel.toMap());

    return userModel;
  }

  // Login menggunakan Email & Password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Logout
  Future<void> logout() => _auth.signOut();
}
