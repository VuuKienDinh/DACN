
import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../services/clothing_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clothing_card.dart';
import 'add_clothing_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'Tất cả';


  final List<String> _categories = [
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteClothing(ClothingItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa quần áo'),
        content: Text(
          'Bạn có chắc muốn xóa "${item.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ClothingService.instance.deleteClothing(item.id);
    }
  }

  void _openAddClothing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddClothingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tủ quần áo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<ClothingItem>>(
        valueListenable: ClothingService.instance.items,
        builder: (context, items, child) {
          final keyword =
          _searchController.text.trim().toLowerCase();

          final filteredItems = items.where((item) {
            final matchesName =
            item.name.toLowerCase().contains(keyword);

            final matchesCategory =
                _selectedCategory == 'Tất cả' ||
                    item.type == _selectedCategory;

            return matchesName && matchesCategory;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20, 12, 20, 10,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${items.length} món đồ trong tủ',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _searchController,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm quần áo...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              category == _selectedCategory;

                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: AppColors.sage,
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

              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.checkroom_outlined,
                          size: 75,
                          color: AppColors.sage,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          items.isEmpty
                              ? 'Tủ đồ của bạn đang trống'
                              : 'Không tìm thấy quần áo',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          items.isEmpty
                              ? 'Hãy thêm món đồ đầu tiên!'
                              : 'Thử thay đổi bộ lọc hoặc từ khóa.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(16),
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
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openAddClothing,
        icon: const Icon(Icons.add),
        label: const Text('Thêm quần áo'),
      ),
    );
  }
}
