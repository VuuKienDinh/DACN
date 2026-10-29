import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/clothing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_scaffold.dart';

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _type = 'Áo';
  String _color = 'Trắng';
  String _style = 'Thường ngày';

  PlatformFile? _selectedImage;
  bool _isSaving = false;

  static const List<String> _types = [
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

  static const List<String> _colors = [
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

  static const List<String> _styles = [
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

  // Chọn ảnh tương thích với phiên bản file_picker hiện tại
  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (!mounted || file == null) return;

      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đọc đường dẫn ảnh')),
        );
        return;
      }

      setState(() {
        _selectedImage = file;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  Future<void> _saveClothing() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null || _selectedImage!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trang phục')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ClothingService.instance.addClothingWithImage(
        name: _nameController.text.trim(),
        type: _type,
        color: _color,
        style: _style,
        localImagePath: _selectedImage!.path!,
        fileName: _selectedImage!.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.syncedToServer
                ? 'Đã lưu "${result.item.name}" lên máy chủ SQL Server'
                : 'Đã lưu "${result.item.name}" vào bộ nhớ trên thiết bị (Offline)',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu quần áo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.iceSurface.withValues(alpha: 0.75),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Thêm trang phục'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bổ sung vào tủ đồ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tải ảnh và phân loại để DailyFit gợi ý trang phục chuẩn xác hơn.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                padding: const EdgeInsets.all(18),
                enableBlur: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Khu vực chọn ảnh
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 230,
                        decoration: BoxDecoration(
                          color: AppColors.iceSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            width: 1.4,
                          ),
                        ),
                        child: _selectedImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 54,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Chọn ảnh trang phục',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hỗ trợ JPG, PNG, WEBP từ thư viện điện thoại',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(19),
                                child: Image.file(
                                  File(_selectedImage!.path!),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) {
                                    return const Center(
                                      child: Text('Không thể hiển thị ảnh'),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Chọn ảnh khác'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Tên trang phục
                    const Text(
                      'Tên trang phục',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration(
                        hint: 'Ví dụ: Áo sơ mi Oxford xanh nhạt',
                        icon: Icons.checkroom_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên trang phục';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Loại trang phục
                    const Text(
                      'Danh mục',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      isExpanded: true,
                      decoration: _inputDecoration(hint: 'Chọn danh mục'),
                      items: _types.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Chọn màu sắc trực quan
                    const Text(
                      'Màu sắc chủ đạo',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colors.map((colorName) {
                        final selected = colorName == _color;
                        final swatch = AppColors.swatchForName(colorName);
                        return InkWell(
                          onTap: () => setState(() => _color = colorName),
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.black.withValues(alpha: 0.08),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: swatch,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.black.withValues(alpha: 0.18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  colorName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Phong cách
                    const Text(
                      'Phong cách',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _styles.map((style) {
                        return ChoiceChip(
                          label: Text(style),
                          selected: _style == style,
                          onSelected: (_) {
                            setState(() => _style = style);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveClothing,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'Đang lưu trang phục...' : 'Lưu vào tủ đồ',
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
