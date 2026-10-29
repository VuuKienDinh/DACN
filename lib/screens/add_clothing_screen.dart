
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/clothing_api_service.dart';
import '../models/clothing_item.dart';
import '../services/clothing_service.dart';
import '../theme/app_theme.dart';

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  State<AddClothingScreen> createState() =>
      _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _type = 'Áo';
  String _color = 'Trắng';
  String _style = 'Thường ngày';

  PlatformFile? _selectedImage;
  bool _isSaving = false;


  final List<String> _types = [
    'Áo',
    'Áo khoác',
    'Quần',
    'Váy',
    'Đầm',
    'Đồ bộ',
    'Giày',
    'Dép',
    'Túi xách',
    'Nón / Mũ',
    'Phụ kiện',
  ];



  final List<String> _colors = [
    'Trắng',
    'Đen',
    'Xám',
    'Xanh dương',
    'Xanh lá',
    'Đỏ',
    'Hồng',
    'Vàng',
    'Cam',
    'Tím',
    'Nâu',
    'Be',
    'Kem',
    'Khác',
  ];



  final List<String> _styles = [
    'Thường ngày',
    'Thanh lịch',
    'Công sở',
    'Thể thao',
    'Đường phố',
    'Năng động',
    'Tối giản',
    'Vintage',
    'Hàn Quốc',
    'Nữ tính',
    'Cá tính',
    'Dự tiệc',
  ];


  // CHỌN ẢNH - GIỮ CÁCH GỌI TRONG CODE CŨ
  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (!mounted) return;

      if (file == null) return;

      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đọc đường dẫn ảnh'),
          ),
        );
        return;
      }

      setState(() {
        _selectedImage = file;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
        ),
      );
    }
  }

  // LƯU QUẦN ÁO


  Future<void> _saveClothing() async {
    if (_isSaving) return;

    // Kiểm tra thông tin đã nhập
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra ảnh đã chọn
    if (_selectedImage == null ||
        _selectedImage!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh quần áo'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // BƯỚC 1: Upload ảnh lên Backend
      final imagePath = await ClothingApiService()
          .uploadImage(
        _selectedImage!.path!,
        _selectedImage!.name,
      );

      // BƯỚC 2: Tạo đối tượng quần áo
      final clothing = ClothingItem(
        id: '',
        name: _nameController.text.trim(),
        type: _type,
        color: _color,
        style: _style,
        imagePath: imagePath,
      );

      // BƯỚC 3: Lưu thông tin vào SQL Server
      await ClothingService.instance
          .addClothing(clothing);

      if (!mounted) return;

      // BƯỚC 4: Quay về màn hình tủ đồ
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu quần áo: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }



  // Ô NHẬP LIỆU
  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  // DROPDOWN LOẠI VÀ MÀU SẮC
  Widget _buildDropdown(
      String label,
      String value,
      List<String> options,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: _inputDecoration(
            hint: 'Chọn $label',
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thêm quần áo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm trang phục mới',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Làm mới bộ sưu tập thời trang của bạn.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    // KHU VỰC CHỌN ẢNH
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.sage
                              .withValues(alpha: 0.35),
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                        child: _selectedImage == null
                            ? const Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 60,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Chọn ảnh trang phục',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Nhấn để chọn ảnh từ điện thoại',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                            : ClipRRect(
                          borderRadius:
                          BorderRadius.circular(18),
                          child: Image.file(
                            File(_selectedImage!.path!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Text(
                                  'Không thể hiển thị ảnh',
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    if (_selectedImage != null) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thay đổi ảnh'),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // TÊN QUẦN ÁO
                    const Text(
                      'Tên quần áo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization:
                      TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        hint: 'Ví dụ: Áo sơ mi trắng',
                        icon: Icons.checkroom,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Vui lòng nhập tên quần áo';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // LOẠI QUẦN ÁO
                    _buildDropdown(
                      'Loại quần áo',
                      _type,
                      _types,
                          (value) {
                        if (value != null) {
                          setState(() {
                            _type = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // MÀU SẮC
                    _buildDropdown(
                      'Màu sắc',
                      _color,
                      _colors,
                          (value) {
                        if (value != null) {
                          setState(() {
                            _color = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // PHONG CÁCH
                    const Text(
                      'Phong cách',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _styles.map((style) {
                        final selected = _style == style;

                        return ChoiceChip(
                          label: Text(style),
                          selected: selected,
                          selectedColor: AppColors.sage,
                          onSelected: (_) {
                            setState(() {
                              _style = style;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    // NÚT LƯU
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                        _isSaving ? null : _saveClothing,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving
                              ? 'Đang lưu...'
                              : 'Lưu vào tủ đồ',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
