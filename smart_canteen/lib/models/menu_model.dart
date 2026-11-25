import 'package:cloud_firestore/cloud_firestore.dart';

class MenuModel {
  final String id;
  final String standId; // ID stand pemilik menu
  final String namaStand; // Nama stand (denormalisasi)
  final String namaMenu;
  final String deskripsi;
  final String kategori;
  final int harga;
  final int stock;
  final String gambarUrl;
  final bool isAvailable;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  MenuModel({
    required this.id,
    this.standId = 'stand_utama',
    this.namaStand = 'Kantin Utama',
    required this.namaMenu,
    required this.deskripsi,
    required this.kategori,
    required this.harga,
    required this.stock,
    required this.gambarUrl,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  bool get canOrder => isAvailable && stock > 0;

  factory MenuModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MenuModel(
      id: doc.id,
      standId: data['standId'] as String? ?? 'stand_utama',
      namaStand: data['namaStand'] as String? ?? 'Kantin Utama',
      namaMenu: data['namaMenu'] as String? ?? '',
      deskripsi: data['deskripsi'] as String? ?? '',
      kategori: data['kategori'] as String? ?? 'Makanan Berat',
      harga: (data['harga'] as num?)?.toInt() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      gambarUrl: data['gambarUrl'] as String? ?? '',
      isAvailable: data['isAvailable'] as bool? ?? true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'standId': standId,
      'namaStand': namaStand,
      'namaMenu': namaMenu,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'harga': harga,
      'stock': stock,
      'gambarUrl': gambarUrl,
      'isAvailable': isAvailable,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MenuModel copyWith({
    String? id,
    String? standId,
    String? namaStand,
    String? namaMenu,
    String? deskripsi,
    String? kategori,
    int? harga,
    int? stock,
    String? gambarUrl,
    bool? isAvailable,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return MenuModel(
      id: id ?? this.id,
      standId: standId ?? this.standId,
      namaStand: namaStand ?? this.namaStand,
      namaMenu: namaMenu ?? this.namaMenu,
      deskripsi: deskripsi ?? this.deskripsi,
      kategori: kategori ?? this.kategori,
      harga: harga ?? this.harga,
      stock: stock ?? this.stock,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
