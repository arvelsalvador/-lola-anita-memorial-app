import 'package:flutter/material.dart';
import 'package:nita/Pages/Gallery/Model/gallery_model.dart';

class GalleryController extends ChangeNotifier {
  static const GalleryModel data = GalleryModel(
    photos: [
      PhotoItem(
        emoji: '🌺',
        caption: 'Tending her garden, 1978',
        colorHex1: 0xFFD4956A,
        colorHex2: 0xFFB06848,
      ),
      PhotoItem(
        emoji: '🌿',
        caption: 'Family reunion, 1985',
        colorHex1: 0xFF8B9E6A,
        colorHex2: 0xFF6B7E4A,
      ),
      PhotoItem(
        emoji: '🌸',
        caption: 'Wedding anniversary',
        colorHex1: 0xFF7A95B8,
        colorHex2: 0xFF5A75A0,
      ),
      PhotoItem(
        emoji: '🕊️',
        caption: 'Sunday after Mass',
        colorHex1: 0xFFC4836A,
        colorHex2: 0xFFA06048,
      ),
      PhotoItem(
        emoji: '🍚',
        caption: 'Kare-kare Sunday, 1992',
        colorHex1: 0xFF9E8A6A,
        colorHex2: 0xFF7E6A4A,
      ),
      PhotoItem(
        emoji: '📿',
        caption: 'Her rosary, always near',
        colorHex1: 0xFF7A7895,
        colorHex2: 0xFF5A5878,
      ),
    ],
  );
}
