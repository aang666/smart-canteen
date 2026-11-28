import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kelasController = TextEditingController();
  final _namaStandController = TextEditingController();
  final _deskripsiStandController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String _selectedRole = 'siswa'; // 'siswa' atau 'penjual'
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _namaController.dispose();
    _kelasController.dispose();
    _namaStandController.dispose();
    _deskripsiStandController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedRole == 'siswa') {
        await _authService.registerStudent(
          nama: _namaController.text,
          email: _emailController.text,
          password: _passwordController.text,
          kelas: _kelasController.text,
        );
      } else {
        await _authService.registerSeller(
          nama: _namaController.text,
          namaStand: _namaStandController.text,
          deskripsiStand: _deskripsiStandController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email sudah terdaftar. Silakan login.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Kata sandi terlalu lemah (minimal 6 karakter).';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Format email tidak valid.';
        } else {
          _errorMessage = 'Pendaftaran gagal: ${e.message ?? e.code}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
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
    final isSiswa = _selectedRole == 'siswa';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isSiswa ? 'Daftar Akun Siswa' : 'Daftar Stand Penjual'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tab Pemilihan Role: Siswa vs Penjual
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'siswa';
                                _errorMessage = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSiswa ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSiswa
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 18,
                                    color: isSiswa ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Siswa',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSiswa ? FontWeight.bold : FontWeight.w500,
                                      color: isSiswa ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'penjual';
                                _errorMessage = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isSiswa ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isSiswa
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 18,
                                    color: !isSiswa ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Penjual Stand',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: !isSiswa ? FontWeight.bold : FontWeight.w500,
                                      color: !isSiswa ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isSiswa ? 'Buat Akun Siswa' : 'Daftarkan Stand Kantin',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSiswa
                        ? 'Lengkapi data diri Anda untuk mulai memesan di kantin.'
                        : 'Lengkapi identitas pemilik dan stand Anda untuk mulai berjualan.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Nama Lengkap / Nama Pemilik
                  CustomTextField(
                    controller: _namaController,
                    label: isSiswa ? 'Nama Lengkap' : 'Nama Pemilik / Penjual',
                    hint: isSiswa ? 'Contoh: Ahmad Fauzi' : 'Contoh: Ibu Siti Aminah',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return isSiswa ? 'Nama lengkap wajib diisi' : 'Nama pemilik wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Khusus Siswa: Kelas
                  if (isSiswa) ...[
                    CustomTextField(
                      controller: _kelasController,
                      label: 'Kelas / Jurusan',
                      hint: 'Contoh: XII RPL 2',
                      prefixIcon: Icons.school_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Kelas wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Khusus Penjual: Nama Stand & Deskripsi
                  if (!isSiswa) ...[
                    CustomTextField(
                      controller: _namaStandController,
                      label: 'Nama Stand Kantin',
                      hint: 'Contoh: Dapur Sedap Bu Siti',
                      prefixIcon: Icons.store_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama stand wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _deskripsiStandController,
                      label: 'Deskripsi Stand',
                      hint: 'Contoh: Menyediakan aneka nasi, lauk pauk, dan es teh segar',
                      prefixIcon: Icons.info_outline_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Deskripsi stand wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: isSiswa ? 'nama@sekolah.sch.id' : 'penjual@kantin.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!val.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Kata Sandi',
                    hint: 'Minimal 6 karakter',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kata sandi wajib diisi';
                      }
                      if (val.length < 6) {
                        return 'Kata sandi minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  CustomButton(
                    text: isSiswa ? 'Daftar sebagai Siswa' : 'Daftar & Buka Stand',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
