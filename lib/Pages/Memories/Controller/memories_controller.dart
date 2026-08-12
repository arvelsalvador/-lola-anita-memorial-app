import 'package:flutter/material.dart';
import 'package:nita/Pages/Memories/Model/memories_model.dart';

class MemoriesController extends ChangeNotifier {
  static const MemoriesModel data = MemoriesModel(
    memories: [
      MemoryItem(
        icon: '🍚',
        title: 'Sunday Kare-Kare',
        body:
            'Every Sunday after Mass, the whole family gathered around her table. Her kare-kare was the reason we never wanted to leave.',
      ),
      MemoryItem(
        icon: '🙏',
        title: 'The Rosary by Her Bed',
        body:
            'She prayed for every grandchild by name, every single night. We all felt it — even from miles away.',
      ),
      MemoryItem(
        icon: '✂️',
        title: 'Stitches and Stories',
        body:
            'She could sew anything. And while her hands worked, she told stories of the old days that made us laugh until we cried.',
      ),
      MemoryItem(
        icon: '🌺',
        title: 'Her Garden',
        body:
            'Every flower she grew was tended like family. She knew every plant by name, and spoke to them like old friends.',
      ),
      MemoryItem(
        icon: '📻',
        title: 'Old Songs at Dusk',
        body:
            'As the sun set, she would hum old kundiman melodies in the kitchen. The house felt complete in those moments.',
      ),
      MemoryItem(
        icon: '💌',
        title: 'Letters to the Grandchildren',
        body:
            'Even in her later years, she wrote letters by hand. Each one was different — she noticed everything about us.',
      ),
    ],
  );
}
