import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class OrderItemModel {
  final String menuId;
  final String namaMenu;
  final int hargaSatuan;
  final int qty;
  final String catatan;
  final int subtotal;

  OrderItemModel({
    required this.menuId,
    required this.namaMenu,
    required this.hargaSatuan,
    required this.qty,
    required this.catatan,
    required this.subtotal,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuId: map['menuId'] as String? ?? '',
      namaMenu: map['namaMenu'] as String? ?? '',
      hargaSatuan: (map['hargaSatuan'] as num?)?.toInt() ?? 0,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      catatan: map['catatan'] as String? ?? '',
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'namaMenu': namaMenu,
      'hargaSatuan': hargaSatuan,
      'qty': qty,
      'catatan': catatan,
      'subtotal': subtotal,
    };
  }
}

class OrderModel {
  final String id;
  final String masterOrderId; // ID grup pesanan jika split order dari multi-stand
  final String orderNumber; // Nomor antrean unik per stand per hari (misal: "A-014")
  final String standId; // ID stand yang menangani pesanan ini
  final String namaStand; // Nama stand
  final String penjualId; // UID penjual penanggung jawab
  final String siswaId; // UID siswa pemesan
  final String namaSiswa; // Nama siswa saat memesan (snapshot)
  final String kelasSiswa; // Kelas siswa saat memesan (snapshot)
  final List<OrderItemModel> items;
  final int totalHarga;
  final String paymentMethod;
  final String status;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  OrderModel({
    required this.id,
    this.masterOrderId = '',
    required this.orderNumber,
    this.standId = 'stand_utama',
    this.namaStand = 'Kantin Utama',
    this.penjualId = '',
    required this.siswaId,
    required this.namaSiswa,
    required this.kelasSiswa,
    required this.items,
    required this.totalHarga,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  String get statusLabel => AppConstants.statusLabels[status] ?? status;

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: doc.id,
      masterOrderId: data['masterOrderId'] as String? ?? '',
      orderNumber: data['orderNumber'] as String? ?? '',
      standId: data['standId'] as String? ?? 'stand_utama',
      namaStand: data['namaStand'] as String? ?? 'Kantin Utama',
      penjualId: data['penjualId'] as String? ?? '',
      siswaId: data['siswaId'] as String? ?? '',
      namaSiswa: data['namaSiswa'] as String? ?? '',
      kelasSiswa: data['kelasSiswa'] as String? ?? '',
      items: itemsList,
      totalHarga: (data['totalHarga'] as num?)?.toInt() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? AppConstants.paymentTunaiSaatAmbil,
      status: data['status'] as String? ?? AppConstants.statusMenunggu,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'masterOrderId': masterOrderId,
      'orderNumber': orderNumber,
      'standId': standId,
      'namaStand': namaStand,
      'penjualId': penjualId,
      'siswaId': siswaId,
      'namaSiswa': namaSiswa,
      'kelasSiswa': kelasSiswa,
      'items': items.map((e) => e.toMap()).toList(),
      'totalHarga': totalHarga,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  OrderModel copyWith({
    String? status,
    Timestamp? updatedAt,
  }) {
    return OrderModel(
      id: id,
      masterOrderId: masterOrderId,
      orderNumber: orderNumber,
      standId: standId,
      namaStand: namaStand,
      penjualId: penjualId,
      siswaId: siswaId,
      namaSiswa: namaSiswa,
      kelasSiswa: kelasSiswa,
      items: items,
      totalHarga: totalHarga,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
