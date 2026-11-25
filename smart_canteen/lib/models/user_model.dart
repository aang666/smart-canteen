import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final String? kelas;
  final String? standId; // ID stand yang dikelola jika role == 'penjual'
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.kelas,
    this.standId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isSiswa => role == AppConstants.roleSiswa;
  bool get isPenjual => role == AppConstants.rolePenjual;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      nama: data['nama'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? AppConstants.roleSiswa,
      kelas: data['kelas'] as String?,
      standId: data['standId'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': role,
      'kelas': kelas,
      'standId': standId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? nama,
    String? email,
    String? role,
    String? kelas,
    String? standId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      kelas: kelas ?? this.kelas,
      standId: standId ?? this.standId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
