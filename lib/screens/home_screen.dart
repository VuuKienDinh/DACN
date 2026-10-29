
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/dailyfit_bottom_nav.dart';
import 'wardrobe_screen.dart';
import 'add_clothing_screen.dart';
import 'outfit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavigation(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => index == 1
            ? const WardrobeScreen()
            : const OutfitScreen(),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.sage,
              child: Icon(
                icon,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
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
          'DailyFit',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chưa có thông báo mới'),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Xin chào! 👋',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hôm nay bạn muốn mặc gì?',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 25),

              // Banner chính
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.beige,
                      size: 34,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Phong cách mỗi ngày',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Khám phá những bộ trang phục '
                          'phù hợp với phong cách của bạn.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.beige,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () => _onNavigation(2),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Gợi ý phối đồ'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Khám phá DailyFit',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 15),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  _featureCard(
                    icon: Icons.checkroom,
                    title: 'Tủ quần áo',
                    subtitle: 'Quản lý trang phục',
                    onTap: () => _onNavigation(1),
                  ),
                  _featureCard(
                    icon: Icons.add_circle_outline,
                    title: 'Thêm quần áo',
                    subtitle: 'Làm mới tủ đồ',
                    onTap: _openAddClothing,
                  ),
                  _featureCard(
                    icon: Icons.auto_awesome,
                    title: 'Phối đồ',
                    subtitle: 'Gợi ý thông minh',
                    onTap: () => _onNavigation(2),
                  ),
                  _featureCard(
                    icon: Icons.favorite_border,
                    title: 'Phong cách',
                    subtitle: 'Cá nhân hóa',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tính năng đang phát triển',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DailyFitBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavigation,
      ),
    );
  }
}
