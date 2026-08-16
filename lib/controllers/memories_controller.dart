import 'package:flutter/material.dart';
import 'package:nita/models/memories_model.dart';

class MemoriesController extends ChangeNotifier {
  static const MemoriesModel data = MemoriesModel(
    memories: [
      MemoryItem(
        icon: '🍚',
        titleKey: 'memory_1_title',
        bodyKey: 'memory_1_body',
      ),
      MemoryItem(
        icon: '🙏',
        titleKey: 'memory_2_title',
        bodyKey: 'memory_2_body',
      ),
      MemoryItem(
        icon: '✂️',
        titleKey: 'memory_3_title',
        bodyKey: 'memory_3_body',
      ),
      MemoryItem(
        icon: '🌺',
        titleKey: 'memory_4_title',
        bodyKey: 'memory_4_body',
      ),
      MemoryItem(
        icon: '📻',
        titleKey: 'memory_5_title',
        bodyKey: 'memory_5_body',
      ),
      MemoryItem(
        icon: '💌',
        titleKey: 'memory_6_title',
        bodyKey: 'memory_6_body',
      ),
    ],
  );
}
