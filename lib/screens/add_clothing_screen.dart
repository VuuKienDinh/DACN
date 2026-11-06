import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../services/clothing_service.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clothing_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_scaffold.dart';

class AddClothingScreen extends StatefulWidget {
  final ClothingItem? editingItem;

  const AddClothingScreen({
    super.key,
    this.editingItem,
  });

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  String _type = 'Áo';
  String _color = 'Trắng';
  late Set<String> _selectedStyles;
  final List<String> _customStyles = [];

  PlatformFile? _selectedImage;
  bool _isSaving = false;

  bool get _isEditing => widget.editingItem != null;

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

  @override
  void initState() {
    super.initState();
    final editing = widget.editingItem;
    _nameController = TextEditingController(text: editing?.name ?? '');
    if (editing != null) {
      if (_types.contains(editing.type)) _type = editing.type;
      if (_colors.contains(editing.color)) _color = editing.color;
      _selectedStyles = editing.styles.toSet();
      for (final st in _selectedStyles) {
        if (!OutfitService.allStyles.contains(st)) {
          _customStyles.add(st);
        }
      }
    } else {
      _selectedStyles = {'Thường ngày'};
    }
  }

  List<String> get _availableStyles => [
        ...OutfitService.allStyles,
        ..._customStyles,
      ];

  void _toggleStyle(String style) {
    setState(() {
      if (_selectedStyles.contains(style)) {
        if (_selectedStyles.length > 1) {
          _selectedStyles.remove(style);
        }
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  Future<void> _addCustomStyleDialog() async {
    final added = await showDialog<String>(
      context: context,
      builder: (_) => const _CustomStyleDialog(),
    );
    if (added == null || added.isEmpty || !mounted) return;

    setState(() {
      if (!OutfitService.allStyles.contains(added) &&
          !_customStyles.contains(added)) {
        _customStyles.add(added);
      }
      _selectedStyles.add(added);
    });
  }

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

    if (!_isEditing &&
        (_selectedImage == null || _selectedImage!.path == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trang phục')),
      );
      return;
    }

    final combinedStyle = _selectedStyles.join(', ');

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        final existing = widget.editingItem!;
        final updateResult = await ClothingService.instance.updateClothing(
          existing: existing,
          name: _nameController.text.trim(),
          type: _type,
          color: _color,
          style: combinedStyle,
          newLocalImagePath: _selectedImage?.path,
          newFileName: _selectedImage?.name,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updateResult.syncedToServer
                  ? 'Đã cập nhật "${updateResult.item.name}" lên SQL Server'
                  : 'Đã cập nhật "${updateResult.item.name}"',
            ),
          ),
        );
        Navigator.pop(context, updateResult.item);
        return;
      }

      final result = await ClothingService.instance.addClothingWithImage(
        name: _nameController.text.trim(),
        type: _type,
        color: _color,
        style: combinedStyle,
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

      Navigator.pop(context, result.item);
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
      fillColor: AppColors.iceSurface.withValues(alpha: 0.85),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa trang phục' : 'Thêm trang phục'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveClothing,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'Lưu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing
                    ? 'Cập nhật thông tin & phong cách'
                    : 'Bổ sung vào tủ đồ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chọn 1 hoặc nhiều phong cách để thuật toán DailyFit phối đồ sát thực tế nhất.',
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
                            color: AppColors.primary.withValues(alpha: 0.24),
                            width: 1.4,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
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
                              )
                            : _isEditing
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(19),
                                    child: buildClothingImage(
                                      widget.editingItem!.imagePath,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 54,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Chọn ảnh trang phục',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Hỗ trợ JPG, PNG, WEBP từ thư viện điện thoại',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    if (_selectedImage != null || _isEditing) ...[
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
                    Text(
                      'Tên trang phục',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: AppColors.text),
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
                    Text(
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
                      dropdownColor: AppColors.surface,
                      style: TextStyle(color: AppColors.text, fontSize: 15),
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
                    Text(
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
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : (isDark
                                      ? AppColors.iceSurface
                                      : AppColors.background),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.subtleBorder,
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
                                      color: AppColors.subtleBorder,
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

                    // Phong cách (đa chọn + tự thêm phong cách riêng)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Phong cách (có thể chọn nhiều)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Text(
                          'Đã chọn ${_selectedStyles.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ví dụ: Áo Polo có thể chọn cùng lúc "Thanh lịch", "Smart Casual", "Hàn Quốc".',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._availableStyles.map((style) {
                          final selected = _selectedStyles.contains(style);
                          return FilterChip(
                            label: Text(style),
                            selected: selected,
                            checkmarkColor: AppColors.white,
                            onSelected: (_) => _toggleStyle(style),
                          );
                        }),
                        ActionChip(
                          avatar: Icon(
                            Icons.add_rounded,
                            size: 17,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Phong cách khác',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _addCustomStyleDialog,
                        ),
                      ],
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
                          _isSaving
                              ? 'Đang lưu trang phục...'
                              : (_isEditing
                                  ? 'Lưu cập nhật trang phục'
                                  : 'Lưu vào tủ đồ'),
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

class _CustomStyleDialog extends StatefulWidget {
  const _CustomStyleDialog();

  @override
  State<_CustomStyleDialog> createState() => _CustomStyleDialogState();
}

class _CustomStyleDialogState extends State<_CustomStyleDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = _controller.text.trim().replaceAll(',', '');
    Navigator.pop(context, val);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Thêm phong cách riêng'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: AppColors.text),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'VD: Bohemian, Hip-hop, Local Brand...',
          filled: true,
          fillColor: AppColors.iceSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
