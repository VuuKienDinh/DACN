
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/clothing_item.dart';
import '../models/outfit_suggestion.dart';
import '../services/clothing_service.dart';
import '../services/outfit_service.dart';
import '../theme/app_theme.dart';

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  String _occasion = 'Đi học';
  List<OutfitSuggestion> _suggestions = [];
  bool _hasGenerated = false;

  final List<String> _occasions = [
    'Đi học',
    'Đi làm',
    'Đi chơi',
    'Dự tiệc',
    'Thể thao',
    'Hẹn hò',
  ];

  void _generate() {
    final clothes = ClothingService.instance.items.value;

    final results = OutfitService.generateOutfits(
      clothes,
      _occasion,
    );

    setState(() {
      _suggestions = results;
      _hasGenerated = true;
    });
  }

  Widget _buildClothingImage(ClothingItem item) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(item.imagePath),
            height: 105,
            width: 105,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                height: 105,
                width: 105,
                color: AppColors.sage,
                child: const Icon(Icons.checkroom),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 105,
          child: Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildOutfitCard(
      OutfitSuggestion suggestion,
      int index,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Outfit ${index + 1}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Chip(
                avatar: const Icon(
                  Icons.star,
                  size: 17,
                  color: AppColors.primary,
                ),
                label: Text(
                  '${suggestion.score.toStringAsFixed(0)} điểm',
                ),
                backgroundColor: AppColors.sage,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: suggestion.items
                .map(_buildClothingImage)
                .toList(),
          ),

          const SizedBox(height: 15),

          const Text(
            'Vì sao phù hợp?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            suggestion.reason,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gợi ý phối đồ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hôm nay bạn muốn mặc gì?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn hoàn cảnh để DailyFit gợi ý '
                  'trang phục phù hợp.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn chuẩn bị đi đâu?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _occasions.map((occasion) {
                      return ChoiceChip(
                        label: Text(occasion),
                        selected: _occasion == occasion,
                        selectedColor: AppColors.sage,
                        onSelected: (_) {
                          setState(() {
                            _occasion = occasion;
                            _suggestions = [];
                            _hasGenerated = false;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Tạo gợi ý phối đồ'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            if (_hasGenerated) ...[
              const Text(
                'Outfit dành cho bạn',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),

              if (_suggestions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.checkroom_outlined,
                        size: 55,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Chưa đủ quần áo để phối đồ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hãy thêm áo, quần hoặc váy, '
                            'và giày vào tủ đồ.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._suggestions.asMap().entries.map(
                      (entry) => _buildOutfitCard(
                    entry.value,
                    entry.key,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
