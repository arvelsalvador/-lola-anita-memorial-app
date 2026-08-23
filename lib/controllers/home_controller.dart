import 'package:flutter/material.dart';
import 'package:nita/models/home_model.dart';

class HomeController extends ChangeNotifier {
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    if (_selectedTab != index && index >= 0 && index <= 4) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  static const HomeModel grandmother = HomeModel(
    name: 'Anita Daiz Lumbao',
    initial: 'A',
    birthYear: 1940,
    passingYear: 2025,
  );

  // --- Story data (merged from story_controller.dart) ---
  static const StoryModel data = StoryModel(
    quoteKey: 'story_quote',
    quoteAttributionKey: 'story_quote_attribution',
    aboutKey: 'story_about',
    favorites:
        'Mga Paborito at Gawi ni Nanay:\n'
        'Mahilig si Nanay manood ng TV, lalo na ang Eat Bulaga at mga palabas tungkol sa kalikasan gaya ng Nat Geo Wild at mga hayop. '
        'Isa rin siyang masigasig na kusinera, paborito niyang lutuin ang sa natong (laing) at iba pang masasarap na putahe.\n\n'
        'Pangunahing gawain niya ang pagtutupi ng damit at pagdarasal. Hindi rin mawawala ang kape sa kanyang araw, lalo na ang Coffee Mate, Coffee Combo, o gatas na Bear Brand.\n\n'
        'Makadyos si Nanay—palaging nagdarasal gabi-gabi at aktibong dumadalo sa simbahan, lalo na tuwing Simbang Gabi.\n\n'
        'Masayahin siya, laging handang makinig at tumulong kapag may problema, at mapagbigay lalo na pagdating sa pagkain.\n'
        'Ipinagmamalaki niya ang kanyang mga apo at laging proud sa kanila.',
    timeline: [
      LifeEvent(
        year: '1940',
        titleKey: 'timeline_birth_title',
        descriptionKey: 'timeline_birth_desc',
      ),
      LifeEvent(
        year: '1961',
        titleKey: 'timeline_marriage_title',
        descriptionKey: 'timeline_marriage_desc',
      ),
      LifeEvent(
        year: '1975',
        titleKey: 'timeline_first_apo_title',
        descriptionKey: 'timeline_first_apo_desc',
      ),
      LifeEvent(
        year: '1998',
        titleKey: 'timeline_anniversary_title',
        descriptionKey: 'timeline_anniversary_desc',
      ),
      LifeEvent(
        year: '2025',
        titleKey: 'timeline_passing_title',
        descriptionKey: 'timeline_passing_desc',
        isLast: true,
      ),
    ],
  );
}
