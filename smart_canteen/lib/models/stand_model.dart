import 'package:cloud_firestore/cloud_firestore.dart';

class StandModel {
  final String id;
  final String namaStand;
  final String standCode; // Misal: "A", "B", "C" untuk prefiks nomor antrean
  final String penjualId; // UID penjual penanggung jawab stand
  final String namaPenjual;
  final String deskripsi;
  final bool isOpen;
  final String gambarUrl;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  StandModel({
    required this.id,
    required this.namaStand,
    required this.standCode,
    required this.penjualId,
    required this.namaPenjual,
    required this.deskripsi,
    required this.isOpen,
    required this.gambarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory StandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StandModel(
      id: doc.id,
      namaStand: data['namaStand'] as String? ?? '',
      standCode: data['standCode'] as String? ?? 'A',
      penjualId: data['penjualId'] as String? ?? '',
      namaPenjual: data['namaPenjual'] as String? ?? '',
      deskripsi: data['deskripsi'] as String? ?? '',
      isOpen: data['isOpen'] as bool? ?? true,
      gambarUrl: data['gambarUrl'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'namaStand': namaStand,
      'standCode': standCode,
      'penjualId': penjualId,
      'namaPenjual': namaPenjual,
      'deskripsi': deskripsi,
      'isOpen': isOpen,
      'gambarUrl': gambarUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StandModel copyWith({
    String? id,
    String? namaStand,
    String? standCode,
    String? penjualId,
    String? namaPenjual,
    String? deskripsi,
    bool? isOpen,
    String? gambarUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return StandModel(
      id: id ?? this.id,
      namaStand: namaStand ?? this.namaStand,
      standCode: standCode ?? this.standCode,
      penjualId: penjualId ?? this.penjualId,
      namaPenjual: namaPenjual ?? this.namaPenjual,
      deskripsi: deskripsi ?? this.deskripsi,
      isOpen: isOpen ?? this.isOpen,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
