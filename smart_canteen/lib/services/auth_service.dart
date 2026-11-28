import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../models/stand_model.dart';
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

  // Registrasi khusus penjual (membuat akun, data stand baru, dan profil penjual)
  Future<UserModel> registerSeller({
    required String nama,
    required String namaStand,
    required String deskripsiStand,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Gagal membuat akun.');
    }

    // Hitung jumlah stand yang sudah ada untuk menentukan huruf standCode (A, B, C, ...)
    final standsSnap = await _db.collection(AppConstants.colStands).get();
    final count = standsSnap.docs.length;
    final standCode = String.fromCharCode(65 + (count % 26));
    final standDoc = _db.collection(AppConstants.colStands).doc();
    final standId = standDoc.id;

    final standModel = StandModel(
      id: standId,
      namaStand: namaStand.trim(),
      standCode: standCode,
      penjualId: user.uid,
      namaPenjual: nama.trim(),
      deskripsi: deskripsiStand.trim(),
      isOpen: true,
      gambarUrl: '',
    );

    final userModel = UserModel(
      uid: user.uid,
      nama: nama.trim(),
      email: email.trim(),
      role: AppConstants.rolePenjual,
      standId: standId,
    );

    final batch = _db.batch();
    batch.set(standDoc, standModel.toMap());
    batch.set(_db.collection(AppConstants.colUsers).doc(user.uid), userModel.toMap());
    await batch.commit();

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
