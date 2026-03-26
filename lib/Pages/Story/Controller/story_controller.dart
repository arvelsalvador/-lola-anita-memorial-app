import 'package:flutter/material.dart';
import 'package:nita/Pages/Story/Model/story_model.dart';

class StoryController extends ChangeNotifier {
  static const StoryModel data = StoryModel(
    quote:
        'The kitchen is where love becomes something you can taste. Cook with both hands and an open heart.',
    quoteAttribution: '— Lola Remedios, always',
    about:
        'Lola Remedios lived every one of her 85 years with grace, laughter, and an unshakeable faith. '
        'She was a devoted wife, a nurturing mother, and the heart of a family that spans three generations. '
        'Her hands were always busy — cooking, sewing, or folding in prayer — and her home was always open.\n\n'
        'She believed deeply that family is the greatest treasure, and she gave everything to build one filled with love.',
    timeline: [
      LifeEvent(
        year: '1938',
        title: 'Born in Camarines Norte',
        description:
            'The third of seven children, born in the province she always called home.',
      ),
      LifeEvent(
        year: '1961',
        title: 'Married Lolo Ernesto',
        description:
            'A union of 54 years. Together they raised six children and loved endlessly.',
      ),
      LifeEvent(
        year: '1975',
        title: 'First grandchild born',
        description:
            'She became Lola — a title she wore with more pride than any other.',
      ),
      LifeEvent(
        year: '1998',
        title: 'Celebrated their anniversary',
        description:
            'The whole family gathered to honor 37 years of faithful love.',
      ),
      LifeEvent(
        year: '2023',
        title: 'Peacefully at rest',
        description:
            'Surrounded by family, she returned to God having lived a life full of grace.',
        isLast: true,
      ),
    ],
  );
}
