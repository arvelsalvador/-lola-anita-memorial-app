import 'package:flutter/material.dart';
import 'package:nita/models/favorites_model.dart';

class FavoritesController extends ChangeNotifier {
  static const FavoritesModel data = FavoritesModel(
    sections: [
      FavoriteSection(
        iconKey: 'spa',
        titleKey: 'section_hobbies',
        itemKeys: [
          'fav_hobby_1',
          'fav_hobby_2',
          'fav_hobby_3',
          'fav_hobby_4',
          'fav_hobby_5',
        ],
      ),
      FavoriteSection(
        iconKey: 'music',
        titleKey: 'section_music',
        itemKeys: ['fav_music_1', 'fav_music_2', 'fav_music_3'],
      ),
      FavoriteSection(
        iconKey: 'tv',
        titleKey: 'section_tv_shows',
        itemKeys: ['fav_tv_1', 'fav_tv_2', 'fav_tv_3'],
      ),
      FavoriteSection(
        iconKey: 'heart',
        titleKey: 'section_more',
        itemKeys: ['fav_more_1', 'fav_more_2', 'fav_more_3'],
      ),
    ],
  );
}
