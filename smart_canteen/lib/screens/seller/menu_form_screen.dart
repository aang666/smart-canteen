import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/menu_model.dart';
import '../../services/menu_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class MenuFormScreen extends StatefulWidget {
  final String standId;
  final String namaStand;
  final MenuModel? existingMenu;

  const MenuFormScreen({
    super.key,
    required this.standId,
    required this.namaStand,
    this.existingMenu,
  });

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuService = MenuService();
  final _storageService = StorageService();

  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _stokController;
  late TextEditingController _gambarUrlController;

  String _selectedCategory = AppConstants.editableCategories.first;
  bool _isAvailable = true;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMenu;
    _namaController = TextEditingController(text: m?.namaMenu ?? '');
    _deskripsiController = TextEditingController(text: m?.deskripsi ?? '');
    _hargaController = TextEditingController(text: m != null ? m.harga.toString() : '');
    _stokController = TextEditingController(text: m != null ? m.stock.toString() : '20');
    _gambarUrlController = TextEditingController(text: m?.gambarUrl ?? '');
    if (m != null && AppConstants.editableCategories.contains(m.kategori)) {
      _selectedCategory = m.kategori;
    }
    _isAvailable = m?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _gambarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _selectedImageBytes = bytes;
      _isUploadingImage = true;
    });

    try {
      // Upload otomatis ke ImgBB
      final uploadedUrl = await _storageService.uploadXFileToImgBB(file: picked);
      setState(() {
        _gambarUrlController.text = uploadedUrl;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil diunggah ke ImgBB!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload ke ImgBB: $e. Anda tetap bisa memasukkan link URL manual.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final harga = int.parse(_hargaController.text.trim());
      final stok = int.parse(_stokController.text.trim());

      final menuData = MenuModel(
        id: widget.existingMenu?.id ?? '',
        standId: widget.standId,
        namaStand: widget.namaStand,
        namaMenu: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        kategori: _selectedCategory,
        harga: harga,
        stock: stok,
        gambarUrl: _gambarUrlController.text.trim(),
        isAvailable: _isAvailable,
      );

      if (widget.existingMenu == null) {
        await _menuService.addMenu(menuData);
      } else {
        await _menuService.updateMenu(menuData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingMenu == null ? 'Menu berhasil ditambahkan' : 'Menu berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan menu: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMenu != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu' : 'Tambah Menu Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Bagian Foto Produk (ImgBB Integrasi)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (_gambarUrlController.text.isNotEmpty || _selectedImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: _selectedImageBytes != null
                              ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                              : Image.network(_gambarUrlController.text, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image)),
                        ),
                      )
                    else
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 6),
                            Text('Belum ada foto menu', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            icon: _isUploadingImage
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: Text(_isUploadingImage ? 'Mengunggah ke ImgBB...' : 'Pilih Foto (Upload ke ImgBB)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Kolom URL Gambar alternatif
                    TextFormField(
                      controller: _gambarUrlController,
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Atau masukkan Direct Image URL (ImgBB/Web)',
                        hintText: 'https://i.ibb.co/.../gambar.jpg',
                        prefixIcon: Icon(Icons.link_rounded, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Formulir Data Menu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _namaController,
                      label: 'Nama Menu',
                      hint: 'Contoh: Nasi Goreng Spesial',
                      prefixIcon: Icons.restaurant_menu_rounded,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama menu wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    // Dropdown Kategori
                    const Text('Kategori Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: Icon(Icons.category_outlined, size: 20, color: AppColors.textSecondary),
                      ),
                      items: AppConstants.editableCategories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _deskripsiController,
                      label: 'Deskripsi Singkat',
                      hint: 'Komposisi, rasa, sambal, dll.',
                      maxLines: 2,
                      prefixIcon: Icons.description_outlined,
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _hargaController,
                            label: 'Harga (Rupiah)',
                            hint: '13000',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.payments_outlined,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Harga wajib diisi';
                              final h = int.tryParse(val.trim());
                              if (h == null || h <= 0) return 'Harga tidak valid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _stokController,
                            label: 'Stok Awal',
                            hint: '20',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.inventory_2_outlined,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Stok wajib diisi';
                              final s = int.tryParse(val.trim());
                              if (s == null || s < 0) return 'Stok tidak valid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Switch Ketersediaan Menu
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Status Menu Tersedia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Jika dinonaktifkan, siswa tidak dapat memesan menu ini.', style: TextStyle(fontSize: 11.5)),
                      value: _isAvailable,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isAvailable = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: isEditing ? 'Simpan Perubahan' : 'Tambah Menu ke Stand',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
