import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../services/clothing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clothing_card.dart';
import '../widgets/state_views.dart';
import 'add_clothing_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';
  bool _isLoading = false;

  static const List<String> _categories = [
    'Tất cả',
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ClothingService.instance.items.value.isEmpty &&
          ClothingService.instance.syncStatus.value == BackendSyncStatus.idle) {
        _loadClothes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClothes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ClothingService.instance.loadClothes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải tủ đồ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteClothing(ClothingItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text('Xóa trang phục'),
        content: Text('Bạn có chắc muốn xóa "${item.name}" khỏi tủ đồ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ClothingService.instance.deleteClothing(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa "${item.name}"')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa quần áo: $e')),
        );
      }
    }
  }

  Future<void> _openAddClothing() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddClothingScreen()),
    );
    if (added == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ClothingService.instance;

    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          service.items,
          service.syncStatus,
          service.statusMessage,
        ]),
        builder: (context, _) {
          final items = service.items.value;
          final keyword = _searchController.text.trim().toLowerCase();

          final filteredItems = items.where((item) {
            final matchesKeyword = keyword.isEmpty ||
                item.name.toLowerCase().contains(keyword) ||
                item.color.toLowerCase().contains(keyword) ||
                item.style.toLowerCase().contains(keyword);

            final matchesCategory = _selectedCategory == 'Tất cả' ||
                item.type == _selectedCategory;

            return matchesKeyword && matchesCategory;
          }).toList();

          final isConnected =
              service.syncStatus.value == BackendSyncStatus.connected;

          return Column(
            children: [
              if (_isLoading)
                const LinearProgressIndicator(
                  minHeight: 2.5,
                  color: AppColors.primary,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Tủ đồ + Nút thêm nhanh
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tủ đồ của tôi',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${items.length} món đồ · ${isConnected ? "Đã kết nối SQL Server" : "Lưu cục bộ & Mẫu thử"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đồng bộ lại',
                          onPressed: _isLoading ? null : _loadClothes,
                          icon: const Icon(
                            Icons.sync_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _openAddClothing,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 19),
                          label: const Text('Thêm đồ'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Ô tìm kiếm kính mờ
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên, màu sắc hoặc phong cách...',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                        filled: true,
                        fillColor: AppColors.white.withValues(alpha: 0.9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.14),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Thanh lọc loại trang phục
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách lưới trang phục
              Expanded(
                child: filteredItems.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 128),
                        children: [
                          GlassEmptyStateCard(
                            icon: Icons.checkroom_outlined,
                            title: items.isEmpty
                                ? 'Tủ đồ của bạn đang trống'
                                : 'Không tìm thấy trang phục phù hợp',
                            subtitle: items.isEmpty
                                ? 'Chụp hoặc chọn ảnh trang phục của bạn, hoặc nạp bộ sưu tập mẫu để trải nghiệm phối đồ ngay.'
                                : 'Thử xoá bộ lọc hoặc nhập từ khoá khác.',
                            actionLabel: items.isEmpty
                                ? 'Thêm trang phục đầu tiên'
                                : 'Đặt lại bộ lọc',
                            onAction: items.isEmpty
                                ? _openAddClothing
                                : () {
                                    _searchController.clear();
                                    setState(() {
                                      _selectedCategory = 'Tất cả';
                                    });
                                  },
                          ),
                          if (items.isEmpty) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  await service.restoreSampleWardrobe();
                                },
                                icon: const Icon(Icons.auto_awesome_rounded),
                                label: const Text('Nạp 12 trang phục mẫu thử'),
                              ),
                            ),
                          ],
                        ],
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadClothes,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 128),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ClothingCard(
                              item: item,
                              onDelete: () => _deleteClothing(item),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
