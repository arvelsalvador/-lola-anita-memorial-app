import 'package:flutter/material.dart';

enum AppLanguage { english, tagalog, bicol }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.tagalog;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  bool get isEnglish => _language == AppLanguage.english;
  bool get isTagalog => _language == AppLanguage.tagalog;
  bool get isBicol => _language == AppLanguage.bicol;

  /// Looks up [key] in the active language map. Placeholders like
  /// `{count}` are substituted from [params] (e.g. `t('memories_count',
  /// {'count': '6'})`). Unknown keys fall back to the key itself.
  String t(String key, [Map<String, String>? params]) {
    final map = switch (_language) {
      AppLanguage.english => en,
      AppLanguage.tagalog => tl,
      AppLanguage.bicol => bi,
    };
    var text = map[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return text;
  }

  static const Map<String, String> en = {
    'app_title': 'In Loving Memory',
    'nav_home': 'Home',
    'nav_gallery': 'Gallery',
    'nav_family': 'Family',
    'nav_tribute': 'Tribute',
    'nav_favorites': 'Favorites',
    'splash_quote':
        'Those we love don\'t go away,\nThey walk beside us every day.',
    'splash_subtitle': 'IN LOVING MEMORY',
    'splash_tap': 'Touch to enter',
    'hero_tagline': 'Beloved grandmother, keeper of stories',
    'section_her_words': 'Her words',
    'section_her_journey': 'Her journey',
    'section_about_her': 'About her',
    'section_cherished_memories': 'Cherished memories',
    'section_final_tribute': 'A final tribute',
    'section_words_family': 'Words from the family',
    'section_hobbies': 'Hobbies',
    'section_music': 'Music',
    'section_tv_shows': 'TV Shows',
    'section_more': 'More',
    'settings_language': 'Language',
    'settings_english': 'English',
    'settings_tagalog': 'Tagalog',
    'settings_bicol': 'Bicol',
    'candle_light': 'Light a candle',
    'candle_virtual': 'Virtual candle lit in her memory',
    'no_images':
        'No images found in gallery.\nTry a full restart after adding images.',
    // Story page
    'story_quote':
        'The kitchen is where love becomes flavor. Cook with both hands and an open heart.',
    'story_quote_attribution': '— Nanay Nita, as she always said',
    'story_about':
        'Lola Anita Daiz Lumbao lived 85 years full of grace, laughter, and steadfast faith. '
        'She was a loving wife, a nurturing mother, and the heart of a family spanning three generations. '
        'Her hands were never idle — cooking, sewing, or folded in prayer — and her home was always open.\n\n'
        'She believed deeply that family was life\'s greatest treasure, and she gave everything to build a home filled with love.',
    'timeline_birth_title':
        'Born in Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'timeline_birth_desc':
        'Third of seven siblings, born in the province she loved.',
    'timeline_marriage_title': 'Married Lolo Salvador V. Lumbao',
    'timeline_marriage_desc':
        '54 years together. They raised six children and loved each other endlessly. '
        'Lolo Salvador passed away from a heart attack.',
    'timeline_first_apo_title': 'Her first grandchild was born',
    'timeline_first_apo_desc':
        'She became a Lola — a title she treasured above all.',
    'timeline_anniversary_title': 'The anniversary was celebrated',
    'timeline_anniversary_desc':
        'The whole family gathered to honor 37 years of faithful love.',
    'timeline_passing_title': 'Peacefully laid to rest',
    'timeline_passing_desc':
        'Surrounded by family, she returned to God after a life full of grace.',
    // Memories page
    'memory_1_title': 'Sunday Kare-Kare',
    'memory_1_body':
        'Every Sunday after Mass, the whole family gathered around her table. '
        'Her kare-kare was the reason we never wanted to leave.',
    'memory_2_title': 'The Rosary by Her Bed',
    'memory_2_body':
        'She prayed for every grandchild by name, every single night. '
        'We all felt it — even from miles away.',
    'memory_3_title': 'Stitches and Stories',
    'memory_3_body':
        'She could sew anything. And while her hands worked, she told stories '
        'of the old days that made us laugh until we cried.',
    'memory_4_title': 'Her Garden',
    'memory_4_body':
        'Every flower she grew was tended like family. She knew every plant by name, '
        'and spoke to them like old friends.',
    'memory_5_title': 'Old Songs at Dusk',
    'memory_5_body':
        'As the sun set, she would hum old kundiman melodies in the kitchen. '
        'The house felt complete in those moments.',
    'memory_6_title': 'Letters to the Grandchildren',
    'memory_6_body':
        'Even in her later years, she wrote letters by hand. '
        'Each one was different — she noticed everything about us.',
    // Memories page header
    'memories_subtitle': 'Moments we will never forget',
    'memories_count': '{count} memories',
    'memories_photos_in_gallery': '{count} photos in Gallery',
    'mem_filter_all': 'All',
    'mem_filter_life': 'Life',
    'mem_filter_family': 'Family',
    'mem_filter_celebrations': 'Celebrations',
    'mem_feature_title': 'Stories we share',
    'mem_feature_body':
        'Memories, laughter, and lessons of a life given and inherited. '
        'Her love continues to guide us to this day.',
    'mem_feature_quote':
        '\u201C The simple days with her were the sweetest memories. \u2665 \u201D',
    'mem_open_photos': 'Open the photos',
    'mem_view_gallery': 'View in Gallery',
    'mem_photo_count': '{count} photos',
    // Family page
    'family_name': 'The Lumbao Family',
    'family_subtitle': 'The people who built her world',
    'family_search_hint': 'Search for a family member',
    'family_filter_all': 'All',
    'family_filter_direct': 'Direct Family',
    'family_filter_apo': 'Grandchildren',
    'family_stat_members': '{count} family members',
    'family_stat_children': '{count} children',
    'family_stat_years': '{count} years together',
    'family_stat_generations': '{count} generations',
    'family_stat_siblings': '{count} siblings',
    'family_intro_title': 'Family was her greatest treasure',
    'family_intro_body':
        'She built a home filled with love — a family spanning three generations, '
        'bound by her warmth, her faith, and her cooking. '
        'Everyone who entered her home became family.',
    'family_role_husband': 'Husband',
    'family_role_daughter': 'Eldest daughter',
    'family_role_grandson': 'Grandson',
    'family_role_granddaughter': 'Granddaughter',
    'family_role_son': 'Son',
    'family_role_sister': 'Sister',
    'family_role_brother': 'Brother',
    // Family groups (tree layout)
    'family_group_children': 'Children',
    'family_group_children_sub': 'children',
    'family_group_siblings': 'Siblings',
    'family_group_siblings_sub': 'siblings',
    'family_group_grandchildren': 'Grandchildren',
    'family_group_grandchildren_sub': 'members',
    'family_group_nieces_nephews': 'Nieces & Nephews',
    'family_group_nieces_nephews_sub': 'nieces & nephews',
    'family_group_other_relatives': 'Other Relatives',
    'family_group_other_relatives_sub': 'members',
    'family_root_subtitle': 'Center of our family',
    'family_view_all_grandchildren': 'View all grandchildren',
    'family_view_all_nieces_nephews': 'View all nieces & nephews',
    'family_view_all_relatives': 'View all relatives',
    'family_members_word': 'members',
    'family_photos_with': 'photos together',
    'family_age_years': '{count} years old',
    'family_age_months': '{count} months old',
    'family_extra_count': '+{count} more',
    'family_sheet_close': 'Close',
    'family_sheet_about': 'About',
    'family_view_full_tree': 'View the full family tree',
    'family_tree_tap_hint': 'Tap a name to see memories',
    'family_tree_unlinked': 'Other Grandchildren',
    'family_footer_note': 'Family members can be connected to memories.',
    'family_member_salvador_bio':
        'Her devoted husband. Fifty-four years of marriage, six children raised '
        'together, and a love that never faded.',
    'family_member_maria_bio':
        'Her eldest daughter, who carries her warmth and her wisdom.',
    'family_member_carlo_bio':
        'Her grandson, who learned that love, not walls, is what builds a home.',
    'family_member_ana_bio':
        'Her granddaughter, who lives to love people the way Lola loved them.',
    'family_member_ramon_bio':
        'Their eldest son. Named for the strength she saw in every new beginning.',
    'family_member_rosario_bio':
        'Their daughter, whose name means rosary — a prayer answered.',
    'family_member_salvador_jr_bio':
        'Their youngest son, who carries his father\'s name and his mother\'s heart.',
    'family_member_ester_bio':
        'Her sister, a quiet companion through every season of life.',
    'family_member_rodolfo_bio':
        'Her brother, whose steady presence anchored the family.',
    'family_member_sonia_bio':
        'Her sister, whose laughter filled every gathering.',
    // Tribute page
    'tribute_message':
        'You taught us that a home is built with warmth, not walls. '
        'Your laugh lives in every room we\'ve ever loved. '
        'Rest now, Lola. We carry you forward.',
    'tribute_until_we_meet': 'Until we meet again',
    'tribute_in_loving_memory': 'IN LOVING MEMORY',
    'family_quote_1':
        'Mama was light itself. Every room she entered felt warmer.',
    'family_quote_1_name': 'Maria, her eldest daughter',
    'family_quote_2':
        'She never let us leave hungry or unloved. That was her superpower.',
    'family_quote_2_name': 'Carlo, grandson',
    'family_quote_3':
        'I will spend my whole life trying to love people the way she loved us.',
    'family_quote_3_name': 'Ana, granddaughter',
    'candle_lit': 'Candle Lit in Her Memory',
    'candle_thank_you': '🕊️ Thank You',
    // Favorites page
    'fav_hobby_1': 'Gardening',
    'fav_hobby_2': 'Cooking traditional dishes',
    'fav_hobby_3': 'Sewing',
    'fav_hobby_4': 'Attending church',
    'fav_hobby_5': 'Storytelling with grandchildren',
    'fav_music_1': 'Kundiman classics',
    'fav_music_2': 'Religious hymns',
    'fav_music_3': 'Folk songs',
    'fav_tv_1': 'Maalaala Mo Kaya',
    'fav_tv_2': 'Eat Bulaga',
    'fav_tv_3': 'Kapuso Mo, Jessica Soho',
    'fav_more_1': 'Warm coffee in the morning',
    'fav_more_2': 'Family reunions',
    'fav_more_3': 'Sunsets in the province',
    // Gallery groups
    'group_celebrations': 'Celebrations',
    'group_bahay': 'Bahay',
    'group_family': 'Family',
    'group_care': 'Care',
    'group_gatherings': 'Dining',
    'group_portraits': 'Portraits',
    'group_remembrances': 'Last Day',
    'group_other': 'Other',
    'gallery_all': 'All',
    'gallery_subtitle': 'Memories that continue to live',
    'gallery_highlights': 'Highlights',
    'gallery_highlights_title': 'Featured memories',
    'gallery_curated_memory': 'Curated memory',
    'gallery_play_all': 'Play all',
    'gallery_photos': 'photos',
    'gallery_all_photos_label': 'All Photos',
    'gallery_search_hint': 'Search photos',
    'gallery_clear_all': 'Clear all',
    'gallery_tap_to_reveal': 'Tap to reveal',
    'gallery_choose_music': 'Choose Music',
    // Remembrances candle gate
    'remembrance_gate_label': 'In Memoriam',
    'remembrance_gate_title': 'In her final days, she was never alone.',
    'remembrance_gate_subtitle': 'Tap the candle to light it in her memory.',
    'remembrance_gate_lit': 'Her memory lives on in us.',
    'remembrance_gate_held': ', held with love.',
    'remembrance_gate_tap_hint': 'Tap anywhere to light the candle',
    'remembrance_gate_waiting': 'Her photos will fade in gently...',
    'remembrance_gate_please_tap': 'Please tap',
    // Gallery locations / dates
    'loc_lipa': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_bahay': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_family_residence': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_batangas_province': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'date_1': 'Mar 12, 2018',
    'date_2': 'Aug 21, 2011',
    'date_3': 'May 14, 2019',
    'date_4': 'Dec 25, 2020',
  };

  static const Map<String, String> tl = {
    'app_title': 'Sa Mahal na Alaala',
    'nav_home': 'Tahanan',
    'nav_gallery': 'Galeri',
    'nav_family': 'Pamilya',
    'nav_tribute': 'Pagkilala',
    'nav_favorites': 'Mga Paborito',
    'splash_quote':
        'Ang mga natin ay hindi nawala,\nSilang laging kasama natin araw-araw.',
    'splash_subtitle': 'SA MAHAL NA ALAALA',
    'splash_tap': 'Pindutin upang pumasok',
    'hero_tagline': 'Minamahal na lola, tagapagkuwento ng mga alaala',
    'section_her_words': 'Kanyang mga salita',
    'section_her_journey': 'Kanyang paglalakbay',
    'section_about_her': 'Tungkol sa kanya',
    'section_cherished_memories': 'Mga mahalagang alaala',
    'section_final_tribute': 'Huling pagkilala',
    'section_words_family': 'Mga salita ng pamilya',
    'section_hobbies': 'Mga libangan',
    'section_music': 'Musika',
    'section_tv_shows': 'Mga palabas sa TV',
    'section_more': 'Higit pa',
    'family_tree_tap_hint': 'I-tap ang pangalan para makita ang mga alaala',
    'family_tree_unlinked': 'Iba pang mga Apo',
    'settings_language': 'Wika',
    'settings_english': 'Ingles',
    'settings_tagalog': 'Tagalog',
    'settings_bicol': 'Bikol',
    'candle_light': 'Magliwanag ng kandila',
    'candle_virtual': 'Virtual na kandila na nakasindi sa kanyang alaala',
    'no_images':
        'Walang mga larawan sa galeri.\nSubukan ang buong pag-restart pagkatapos magdagdag ng mga larawan.',
    // Story page
    'story_quote':
        'Ang kusina ay kung saan ang pagmamahal ay nagiging lasa. Magluto gamit ang dalawang kamay at bukas na puso.',
    'story_quote_attribution': '— Nanay Nita, palaging sinasabi',
    'story_about':
        'Si Lola Anita Daiz Lumbao ay namuhay ng 85 taon na may biyaya, halakhak, at matibay na pananampalataya. '
        'Isa siyang mapagmahal na asawa, mapag-arugang ina, at puso ng pamilyang umaabot sa tatlong henerasyon. '
        'Laging abala ang kanyang mga kamay — nagluluto, nananahi, o nakatiklop sa panalangin — at ang kanyang tahanan ay laging bukas.\n\n'
        'Malalim ang kanyang paniniwala na ang pamilya ang pinakamahalagang yaman, at ibinigay niya ang lahat upang bumuo ng tahanang puno ng pagmamahal.',
    'timeline_birth_title':
        'Ipinanganak sa Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'timeline_birth_desc':
        'Ikatlo sa pitong magkakapatid, ipinanganak sa probinsyang mahal niya.',
    'timeline_marriage_title': 'Ikinasal kay Lolo Salvador V. Lumbao',
    'timeline_marriage_desc':
        '54 na taon ng pagsasama. Magkasama nilang pinalaki ang anim na anak at nagmahalan ng walang hanggan. '
        'Pumanaw si Lolo Salvador dahil sa atake sa puso.',
    'timeline_first_apo_title': 'Unang apo ay isinilang',
    'timeline_first_apo_desc':
        'Naging Lola siya — isang titulong ipinagmamalaki niya higit sa lahat.',
    'timeline_anniversary_title': 'Ipinagdiwang ang anibersaryo',
    'timeline_anniversary_desc':
        'Nagtipon ang buong pamilya upang parangalan ang 37 taon ng tapat na pagmamahalan.',
    'timeline_passing_title': 'Mapayapang namahinga',
    'timeline_passing_desc':
        'Pinalibutan ng pamilya, siya ay nagbalik sa Diyos matapos ang isang buhay na puno ng biyaya.',
    // Memories page
    'memory_1_title': 'Lingguhang Kare-Kare',
    'memory_1_body':
        'Tuwing Linggo pagkatapos ng Misa, nagtitipon ang buong pamilya sa kanyang hapag. '
        'Ang kanyang kare-kare ang dahilan kung bakit ayaw naming umalis.',
    'memory_2_title': 'Ang Rosaryo sa Kanyang Higaan',
    'memory_2_body':
        'Idinadalangin niya ang bawat apo sa pangalan, tuwing gabi. '
        'Nadarama naming lahat iyon — kahit mula sa malayo.',
    'memory_3_title': 'Tahi at Mga Kuwento',
    'memory_3_body':
        'Kaya niyang manahi ng kahit ano. At habang gumagalaw ang kanyang mga kamay, '
        'nagkukuwento siya ng mga lumang araw na nagpapatawa sa amin hanggang sa mapaluha kami.',
    'memory_4_title': 'Ang Kanyang Hardin',
    'memory_4_body':
        'Bawat bulaklak na itinanim niya ay inalagaan na parang pamilya. Kilala niya ang bawat halaman '
        'sa pangalan, at kinakausap na parang matalik na kaibigan.',
    'memory_5_title': 'Mga Lumang Awit sa Takipsilim',
    'memory_5_body':
        'Habang lumulubog ang araw, humuhuni siya ng mga lumang kundiman sa kusina. '
        'Kumpleto ang pakiramdam ng bahay sa mga sandaling iyon.',
    'memory_6_title': 'Mga Liham sa mga Apo',
    'memory_6_body':
        'Kahit sa kanyang huling mga taon, sumusulat pa rin siya ng mga liham sa pamamagitan ng kamay. '
        'Magkakaiba ang bawat isa — napapansin niya ang lahat tungkol sa amin.',
    // Memories page header
    'memories_subtitle': 'Mga sandaling hindi malilimutan',
    'memories_count': '{count} na alaala',
    'memories_photos_in_gallery': '{count} larawan sa Galeri',
    'mem_filter_all': 'Lahat',
    'mem_filter_life': 'Buhay',
    'mem_filter_family': 'Pamilya',
    'mem_filter_celebrations': 'Pagdiriwang',
    'mem_feature_title': 'Mga kuwentong pinagsasaluhan',
    'mem_feature_body':
        'Mga alaala, tawa, at aral ng buhay na inilaan at minana. '
        'Ang kanyang pag-ibig ang patuloy na gabay namin hanggang ngayon.',
    'mem_feature_quote':
        '\u201C Ang mga simpleng araw kasama siya ang pinakamatamis na alaala. \u2665 \u201D',
    'mem_open_photos': 'Buksan ang mga larawan',
    'mem_view_gallery': 'Tingnan sa Galeri',
    'mem_photo_count': '{count} na larawan',
    // Family page
    'family_name': 'Ang Pamilyang Lumbao',
    'family_subtitle': 'Mga taong bumuo ng kanyang mundo',
    'family_search_hint': 'Maghanap ng kapamilya',
    'family_filter_all': 'Lahat',
    'family_filter_direct': 'Direktang pamilya',
    'family_filter_apo': 'Mga Apo',
    'family_stat_members': '{count} miyembro ng pamilya',
    'family_stat_children': '{count} na anak',
    'family_stat_years': '{count} taon na magkasama',
    'family_stat_generations': '{count} henerasyon',
    'family_stat_siblings': '{count} magkakapatid',
    'family_intro_title': 'Ang pamilya ang kanyang pinakamalaking kayamanan',
    'family_intro_body':
        'Nagtayo siya ng tahanang puno ng pagmamahal — isang pamilyang umaabot '
        'sa tatlong henerasyon, na pinagbuklod ng kanyang init, pananampalataya, '
        'at pagluluto. Ang sinumang pumasok sa kanyang tahanan ay naging pamilya.',
    'family_role_husband': 'Asawa',
    'family_role_daughter': 'Panganay na anak na babae',
    'family_role_grandson': 'Apo',
    'family_role_granddaughter': 'Apo',
    'family_role_son': 'Anak na lalaki',
    'family_role_sister': 'Kapatid na babae',
    'family_role_brother': 'Kapatid na lalaki',
    // Family groups (tree layout)
    'family_group_children': 'Mga Anak',
    'family_group_children_sub': 'anak',
    'family_group_siblings': 'Mga Kapatid',
    'family_group_siblings_sub': 'kapatid',
    'family_group_grandchildren': 'Mga Apo',
    'family_group_grandchildren_sub': 'miyembro',
    'family_group_nieces_nephews': 'Mga Pamangkin',
    'family_group_nieces_nephews_sub': 'pamangkin',
    'family_group_other_relatives': 'Iba pang Kamag-anak',
    'family_group_other_relatives_sub': 'miyembro',
    'family_root_subtitle': 'Sentro ng aming pamilya',
    'family_view_all_grandchildren': 'Tingnan ang lahat ng apo',
    'family_view_all_nieces_nephews': 'Tingnan ang lahat ng pamangkin',
    'family_view_all_relatives': 'Tingnan ang lahat ng kamag-anak',
    'family_members_word': 'miyembro',
    'family_photos_with': 'larawan kasama',
    'family_age_years': '{count} taong gulang',
    'family_age_months': '{count} buwan',
    'family_extra_count': '+{count} pa',
    'family_sheet_close': 'Isara',
    'family_sheet_about': 'Tungkol sa Kanya',
    'family_view_full_tree': 'Tingnan ang buong family tree',
    'family_footer_note':
        'Ang mga miyembro ng pamilya ay maaaring ikonekta sa mga alaala.',
    'family_member_salvador_bio':
        'Ang kanyang tapat na asawa. Limampu\'t apat na taon ng pagsasama, '
        'anim na anak na magkasamang pinalaki, at pagmamahal na hindi kumupas.',
    'family_member_maria_bio':
        'Ang kanyang panganay na anak na babae, na nagdadala ng kanyang init '
        'at karunungan.',
    'family_member_carlo_bio':
        'Ang kanyang apo, na natutunan na ang pagmamahal, hindi ang mga pader, '
        'ang nagtatayo ng tahanan.',
    'family_member_ana_bio':
        'Ang kanyang apo, na nabubuhay upang mahalin ang mga tao sa paraang '
        'minahal sila ni Lola.',
    'family_member_ramon_bio':
        'Ang kanilang panganay na anak na lalaki. Pinangalanan sa lakas na '
        'nakita niya sa bawat bagong simula.',
    'family_member_rosario_bio':
        'Ang kanilang anak na babae, na ang pangalan ay nangangahulugang rosaryo — '
        'isang dasal na sinagot.',
    'family_member_salvador_jr_bio':
        'Ang kanilang bunso na anak na lalaki, na nagdadala ng pangalan ng kanyang '
        'ama at ang puso ng kanyang ina.',
    'family_member_ester_bio':
        'Ang kanyang kapatid, isang tahimik na kasama sa bawat panahon ng buhay.',
    'family_member_rodolfo_bio':
        'Ang kanyang kapatid na lalaki, na matatag na presensya na nag-angat sa pamilya.',
    'family_member_sonia_bio':
        'Ang kanyang kapatid na babae, na ang tawa ay pumupuno sa bawat pagtitipon.',

    // Tribute page
    'tribute_message':
        'Itinuro mo sa amin na ang tahanan ay itinatayo sa init ng pagmamahal, hindi sa mga pader. '
        'Ang iyong tawa ay nananatili sa bawat silid na minahal namin. '
        'Magpahinga ka na, Lola. Patuloy ka naming dinadala sa aming mga puso.',
    'tribute_until_we_meet': 'Hanggang sa muli tayong magkita',
    'tribute_in_loving_memory': 'SA MAHAL NA ALAALA',
    'family_quote_1':
        'Si Mama mismo ang liwanag. Parang sumisigla ang bawat silid na kanyang pinasukan.',
    'family_quote_1_name': 'Maria, ang panganay niyang anak na babae',
    'family_quote_2':
        'Hindi niya kami hinayaang umalis na gutom o walang pagmamahal. Iyon ang kanyang superpower.',
    'family_quote_2_name': 'Carlo, apo',
    'family_quote_3':
        'Gugugulin ko ang buong buhay ko sa pagsisikap na mahalin ang mga tao sa paraang minahal niya kami.',
    'family_quote_3_name': 'Ana, apo',
    'candle_lit': 'Kandilang Nakasindi sa Kanyang Alaala',
    'candle_thank_you': '🕊️ Salamat',
    // Favorites page
    'fav_hobby_1': 'Paghahalaman',
    'fav_hobby_2': 'Pagluluto ng mga tradisyonal na pagkain',
    'fav_hobby_3': 'Pagtatahi',
    'fav_hobby_4': 'Pagsisimba',
    'fav_hobby_5': 'Pagkukuwento sa mga apo',
    'fav_music_1': 'Mga klasikong kundiman',
    'fav_music_2': 'Mga himno sa simbahan',
    'fav_music_3': 'Mga awiting bayan',
    'fav_tv_1': 'Maalaala Mo Kaya',
    'fav_tv_2': 'Eat Bulaga',
    'fav_tv_3': 'Kapuso Mo, Jessica Soho',
    'fav_more_1': 'Mainit na kape sa umaga',
    'fav_more_2': 'Mga pagkikita-kita ng pamilya',
    'fav_more_3': 'Mga paglubog ng araw sa probinsya',
    // Gallery groups
    'group_celebrations': 'Mga Pagdiriwang',
    'group_bahay': 'Bahay',
    'group_family': 'Pamilya',
    'group_care': 'Pag-aalaga',
    'group_gatherings': 'Pag-Kain',
    'group_portraits': 'Mga Retrato',
    'group_remembrances': 'Huling Araw',
    'group_other': 'Iba Pa',
    'gallery_all': 'Lahat',
    'gallery_subtitle': 'Mga alaala na patuloy na nabubuhay',
    'gallery_highlights': 'Tampok',
    'gallery_highlights_title': 'Mga Tampok na Alaala',
    'gallery_curated_memory': 'Piniling alaala',
    'gallery_play_all': 'I-play lahat',
    'gallery_photos': 'larawan',
    'gallery_all_photos_label': 'Lahat ng Larawan',
    'gallery_search_hint': 'Maghanap ng litrato',
    'gallery_clear_all': 'I-clear lahat',
    'gallery_tap_to_reveal': 'Pindutin upang makita',
    'gallery_choose_music': 'Pumili ng Musika',
    // Remembrances candle gate
    'remembrance_gate_label': 'Sa Pag-alaala',
    'remembrance_gate_title':
        'Sa kanyang huling mga araw, hindi siya nag-iisa.',
    'remembrance_gate_subtitle':
        'Pindutin ang kandila upang sindihan ito bilang alaala sa kanya.',
    'remembrance_gate_lit':
        'Ang kanyang alaala ay patuloy na nabubuhay sa atin.',
    'remembrance_gate_held': ', itinuring nang may pagmamahal.',
    'remembrance_gate_tap_hint':
        'Pindutin kahit saan upang sindihan ang kandila',
    'remembrance_gate_waiting':
        'Unti-unting lilitaw ang kanyang mga larawan...',
    'remembrance_gate_please_tap': 'Pindutin po',
    // Gallery locations / dates
    'loc_lipa': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_bahay': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_family_residence': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_batangas_province': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'date_1': 'Marso 12, 2018',
    'date_2': 'Agosto 21, 2011',
    'date_3': 'Mayo 14, 2019',
    'date_4': 'Disyembre 25, 2020',
  };

  static const Map<String, String> bi = {
    'app_title': 'Sa Mahal na Alaala',
    'nav_home': 'Harong',
    'nav_gallery': 'Galeriya',
    'nav_family': 'Pamilya',
    'nav_tribute': 'Pagkilala',
    'nav_favorites': 'Mga Paborito',
    'splash_quote':
        'An mga namomotan ta dai nawawara,\nSinda yaon sa kataid ta lambang aldaw.',
    'splash_subtitle': 'SA MAHAL NA ALAALA',
    'family_tree_tap_hint':
        'Pindota an pangaran tanganing mahiling an mga alaala',
    'family_tree_unlinked': 'Iba Pang mga Apo',
    'splash_tap': 'Pindota tang makalaog',
    'hero_tagline': 'Namomotan na lola, paratipig kan mga istorya',
    'section_her_words': 'An saiyang mga tataramon',
    'section_her_journey': 'An saiyang pagbiyahe',
    'section_about_her': 'Manungod sa saiya',
    'section_cherished_memories': 'Mga mamomoton na alaala',
    'section_final_tribute': 'Huring pagkilala',
    'section_words_family': 'Mga tataramon kan pamilya',
    'section_hobbies': 'Mga libangan',
    'section_music': 'Musika',
    'section_tv_shows': 'Mga palabas sa TV',
    'section_more': 'Dakul pa',
    'settings_language': 'Tataramon',
    'settings_english': 'Ingles',
    'settings_tagalog': 'Tagalog',
    'settings_bicol': 'Bikol',
    'candle_light': 'Pagsindihan an kandila',
    'candle_virtual': 'Virtual na kandila na sinindihan sa saiyang alaala',
    'no_images':
        'Mayong mga ladawan sa galeriya.\nSubaron an bilog na pag-restart pakadugang nin mga ladawan.',
    // Story page
    'story_quote':
        'An kusina iyo kun saen an pagkamoot nagigin namit. Magluto gamit an duwang kamot asin bukas na puso.',
    'story_quote_attribution': '— Nanay Nita, arog kan dati niyang sinasabi',
    'story_about':
        'Si Lola Anita Daiz Lumbao nabuhay nin 85 na taon na may biyaya, katawa, asin matibay na pagtubod. '
        'Saro siyang mamomoton na agom, maingat na ina, asin puso kan pamilyang umabot sa tulong henerasyon. '
        'Dai nagpapahingalo an saiyang mga kamot — nagluluto, nagtatahi, o nakatupi sa pag-ampo — asin an saiyang harong pirmeng bukas.\n\n'
        'Hararom an saiyang pagtubod na an pamilya iyo an pinakamahalagang kayamanan, asin itinao niya an gabos tanganing magtugdok nin harong na pano nin pagkamoot.',
    'timeline_birth_title':
        'Ipinangaki sa Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'timeline_birth_desc':
        'Ikatolo sa pitong magturugang, ipinangaki sa probinsya na namomotan niya.',
    'timeline_marriage_title': 'Nagpakasal ki Lolo Salvador V. Lumbao',
    'timeline_marriage_desc':
        '54 na taon na magkaibanan. Magkairibanan sindang nagpadakula nin anom na aki asin nagkamutan nin daing katapusan. '
        'Nagadan si Lolo Salvador huli sa atake sa puso.',
    'timeline_first_apo_title': 'Ipinangaki an enot niyang apo',
    'timeline_first_apo_desc':
        'Nagin Lola siya — sarong titulo na pinakapahalagahan niya.',
    'timeline_anniversary_title': 'Kinaselbrar an anibersaryo',
    'timeline_anniversary_desc':
        'Nagtipon an bilog na pamilya tanganing parangalan an 37 na taon nin matibay na pagkamoot.',
    'timeline_passing_title': 'Mapayapang nagpahingalo',
    'timeline_passing_desc':
        'Napapalibutan kan pamilya, nagbalik siya sa Diyos pagkatapos nin buhay na pano nin biyaya.',
    // Memories page
    'memory_1_title': 'Kare-Kare sa Domingo',
    'memory_1_body':
        'Lambang Domingo pakalihis kan Misa, nagtitiripon an bilog na pamilya sa saiyang lamesa. '
        'An saiyang kare-kare an dahilan kun taano ta dai kami nagugustong maghali.',
    'memory_2_title': 'An Rosaryo sa Saiyang Higdaan',
    'memory_2_body':
        'Nangadye siya para sa lambang apo sa pangaran, lambang banggi. '
        'Nararamdaman mi gabos iyan — maski hali sa harayo.',
    'memory_3_title': 'Tahi asin mga Uusipon',
    'memory_3_body':
        'Kaya niyang magtahi nin ano man. Mantang naghihiro an saiyang mga kamot, '
        'nagkukuwento siya kan mga enot na aldaw na nagpatawa sa samo sagkod na magtangis kami.',
    'memory_4_title': 'An Saiyang Hardin',
    'memory_4_body':
        'An lambang burak na itinanom niya inaataman na arog kan pamilya. Bisto niya an lambang tinanom '
        'sa pangaran, asin kinakaulay na arog kan gurang nang amigo.',
    'memory_5_title': 'Mga Daang Awit sa Takipsilim',
    'memory_5_body':
        'Kun naglulubog na an saldang, naghuhuni siya nin mga daang kundiman sa kusina. '
        'Kumpleto an pagmati kan harong sa mga oras na idto.',
    'memory_6_title': 'Mga Surat sa mga Apo',
    'memory_6_body':
        'Maski sa huri niyang mga taon, nagsusurat pa siya nin mga surat gamit an kamot. '
        'Magkakaiba an lambang saro — naririsa niya an gabos manungod sa samo.',
    // Memories page header
    'memories_subtitle': 'Mga sandaling dai malilingawan',
    'memories_count': '{count} na alaala',
    'memories_photos_in_gallery': '{count} ladawan sa Galeriya',
    'mem_filter_all': 'Gabos',
    'mem_filter_life': 'Buhay',
    'mem_filter_family': 'Pamilya',
    'mem_filter_celebrations': 'Selebrasyon',
    'mem_feature_title': 'Mga usipon na pinagsasaro',
    'mem_feature_body':
        'Mga alaala, tawa, asin aral nin buhay na itinao asin namana. '
        'An saiyang pagkamoot an padagos na giya samo sagkod ngunyan.',
    'mem_feature_quote':
        '\u201C An mga simpleng aldaw kaiba siya an pinakamatamis na alaala. \u2665 \u201D',
    'mem_open_photos': 'Buksan an mga ladawan',
    'mem_view_gallery': 'Helingon sa Galeriya',
    'mem_photo_count': '{count} na ladawan',
    // Family page
    'family_name': 'An Pamilyang Lumbao',
    'family_subtitle': 'An mga tawong nagtugdok kan saiyang kinaban',
    'family_search_hint': 'Maghanap nin kapamilya',
    'family_filter_all': 'Gabos',
    'family_filter_direct': 'Direktang pamilya',
    'family_filter_apo': 'Mga Apo',
    'family_stat_members': '{count} miyembro kan pamilya',
    'family_stat_children': '{count} na aki',
    'family_stat_years': '{count} na taon na magkaibanan',
    'family_stat_generations': '{count} na henerasyon',
    'family_stat_siblings': '{count} na magturugang',
    'family_intro_title': 'An pamilya an pinakadakulang kayamanan niya',
    'family_intro_body':
        'Nagtugdok siya nin harong na pano nin pagkamoot — sarong pamilyang '
        'umabot sa tulong henerasyon, na pinagkaibanan kan saiyang init, '
        'pagtubod, asin pagluto. An siisay man na naglaog sa saiyang harong '
        'nagin pamilya.',
    'family_role_husband': 'Agom',
    'family_role_daughter': 'Panganay na aking babae',
    'family_role_grandson': 'Apo',
    'family_role_granddaughter': 'Apo',
    'family_role_son': 'Anak na lalaki',
    'family_role_sister': 'Kapatid na babae',
    'family_role_brother': 'Kapatid na lalaki',
    // Family groups (tree layout)
    'family_group_children': 'Mga Aki',
    'family_group_children_sub': 'aki',
    'family_group_siblings': 'Mga Magturugang',
    'family_group_siblings_sub': 'magturugang',
    'family_group_grandchildren': 'Mga Apo',
    'family_group_grandchildren_sub': 'miyembro',
    'family_group_nieces_nephews': 'Mga Pamangkin',
    'family_group_nieces_nephews_sub': 'pamangkin',
    'family_group_other_relatives': 'Iba Pang Kamag-anak',
    'family_group_other_relatives_sub': 'miyembro',
    'family_root_subtitle': 'Sentro kan samong pamilya',
    'family_view_all_grandchildren': 'Helingon an gabos na apo',
    'family_view_all_nieces_nephews': 'Helingon an gabos na pamangkin',
    'family_view_all_relatives': 'Helingon an gabos na kamag-anak',
    'family_members_word': 'miyembro',
    'family_photos_with': 'ladawan kaiba',
    'family_age_years': '{count} na taon',
    'family_age_months': '{count} na bulan',
    'family_extra_count': '+{count} pa',
    'family_sheet_close': 'Isara',
    'family_sheet_about': 'Tungkol Saiya',
    'family_view_full_tree': 'Helingon an bilog na family tree',
    'family_footer_note':
        'An mga miyembro kan pamilya puedeng ikonektar sa mga alaala.',
    'family_member_salvador_bio':
        'An saiyang maimbod na agom. Singkuwenta kuwatro na taon nin pagsasaro, '
        'anom na aki na magkaibanan na pinadakula, asin pagkamoot na dai naglupad.',
    'family_member_maria_bio':
        'An saiyang panganay na aking babae, na nagdadara kan saiyang init '
        'asin kadunungan.',
    'family_member_carlo_bio':
        'An saiyang apo, na nanudan na an pagkamoot, bakong an mga lanob, '
        'an nagtutugdok nin harong.',
    'family_member_ana_bio':
        'An saiyang apo, na nabubuhay tanganing mamoot sa mga tao siring kan '
        'pagkamoot ni Lola sa sainda.',
    'family_member_ramon_bio':
        'An saiyang panganay na aking lalaki. Pinangalanan sa luwas na '
        'nakita niya sa gabos na bagong simula.',
    'family_member_rosario_bio':
        'An saiyang aking babae, na an pangalan ay nangangahulugang rosaryo — '
        'sarong pagkamoot na sinagot.',
    'family_member_salvador_jr_bio':
        'An saiyang bunso na aking lalaki, na nagdadara kan pangalan kan saiyang '
        'amá asin puso kan saiyang iná.',
    'family_member_ester_bio':
        'An saiyang magturugang, isang tahimik na kasama sa gabos na panahon nin buhay.',
    'family_member_rodolfo_bio':
        'An saiyang magturugang na lalaki, na matatag na presensya na nag-angat sa pamilya.',
    'family_member_sonia_bio':
        'An saiyang magturugang na babae, na an tawa ay pumupuno sa gabos na pagtitipon.',

    // Tribute page
    'tribute_message':
        'Itinukdo mo sa samo na an harong itinutugdok sa init kan pagkamoot, bakong sa mga lanob. '
        'An saimong tawa yaon pa sa lambang kuwarto na namotan mi. '
        'Magpahingalo ka na, Lola. Padagos ka ming dinadara sa samong puso.',
    'tribute_until_we_meet': 'Hanggang sa magkita giraray kita',
    'tribute_in_loving_memory': 'SA MAHAL NA ALAALA',
    'family_quote_1':
        'Si Mama an liwanag mismo. An lambang kuwarto na laogan niya nagigin mainit asin maliwanag.',
    'family_quote_1_name': 'Maria, an panganay niyang aking babae',
    'family_quote_2':
        'Dai niya kami pinapahali na gutom o daing pagkamoot. Iyan an saiyang superpower.',
    'family_quote_2_name': 'Carlo, apo',
    'family_quote_3':
        'Gugugolon ko an bilog kong buhay tanganing magmoot sa mga tawo siring kan pagkamoot niya sa samo.',
    'family_quote_3_name': 'Ana, apo',
    'candle_lit': 'Kandilang Sinindihan sa Saiyang Alaala',
    'candle_thank_you': '🕊️ Salamat',
    // Favorites page
    'fav_hobby_1': 'Pagtatanom',
    'fav_hobby_2': 'Pagluto nin mga tradisyonal na pagkakan',
    'fav_hobby_3': 'Pagtatahi',
    'fav_hobby_4': 'Pagsimba',
    'fav_hobby_5': 'Pagkuwento sa mga apo',
    'fav_music_1': 'Mga klasikong kundiman',
    'fav_music_2': 'Mga himno sa simbahan',
    'fav_music_3': 'Mga awit kan banwaan',
    'fav_tv_1': 'Maalaala Mo Kaya',
    'fav_tv_2': 'Eat Bulaga',
    'fav_tv_3': 'Kapuso Mo, Jessica Soho',
    'fav_more_1': 'Mainit na kape sa aga',
    'fav_more_2': 'Mga pagtiripon kan pamilya',
    'fav_more_3': 'Mga paglubog kan saldang sa probinsya',
    // Gallery groups
    'group_celebrations': 'Mga Selebrasyon',
    'group_bahay': 'Harong',
    'group_family': 'Pamilya',
    'group_care': 'Pag-ataman',
    'group_gatherings': 'Pag-Kakan',
    'group_portraits': 'Mga Retrato',
    'group_remembrances': 'Huring Aldaw',
    'group_other': 'Iba Pa',
    'gallery_all': 'Gabos',
    'gallery_subtitle': 'Mga pagromdom na padagos na nabubuhay',
    'gallery_highlights': 'Tampok',
    'gallery_highlights_title': 'Mga Tampok na Alaala',
    'gallery_curated_memory': 'Piling pagromdom',
    'gallery_play_all': 'I-play gabos',
    'gallery_photos': 'mga ladawan',
    'gallery_all_photos_label': 'Gabos na Ladawan',
    'gallery_search_hint': 'Maghanap nin ladawan',
    'gallery_clear_all': 'I-clear gabos',
    'gallery_tap_to_reveal': 'Pindota tanganing mahiling',
    'gallery_choose_music': 'Pumili nin Musika',
    // Remembrances candle gate
    'remembrance_gate_label': 'Sa Pagromdom',
    'remembrance_gate_title': 'Sa saiyang huring mga aldaw, dai siya nag-iisa.',
    'remembrance_gate_subtitle':
        'Pindota an kandila tanganing sindihan iyan sa pagromdom sa saiya.',
    'remembrance_gate_lit': 'Padagos na nabubuhay sa sato an saiyang memorya.',
    'remembrance_gate_held': ', iningatan may pagkamoot.',
    'remembrance_gate_tap_hint':
        'Pindota kun saen man tanganing sindihan an kandila',
    'remembrance_gate_waiting': 'Marahan na lalataw an saiyang mga ladawan...',
    'remembrance_gate_please_tap': 'Pindota tabi',
    // Gallery locations / dates
    'loc_lipa': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_bahay': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_family_residence': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'loc_batangas_province': 'Purok 3, Barangay 7, Mercedes, Camarines Norte',
    'date_1': 'Marso 12, 2018',
    'date_2': 'Agosto 21, 2011',
    'date_3': 'Mayo 14, 2019',
    'date_4': 'Disyembre 25, 2020',
  };

  /// Debug-only check: confirms en/tl/bi all define the exact same set of
  /// translation keys. Call this once (e.g. in main() before runApp, guarded
  /// by `if (kDebugMode)`) to catch missing translations before they ship
  /// as a raw key like 'gallery_search_hint' showing up on screen.
  static void debugCheckTranslationKeysMatch() {
    final enKeys = en.keys.toSet();
    final tlKeys = tl.keys.toSet();
    final biKeys = bi.keys.toSet();
    final allKeys = {...enKeys, ...tlKeys, ...biKeys};

    final missingFromEn = allKeys.difference(enKeys);
    final missingFromTl = allKeys.difference(tlKeys);
    final missingFromBi = allKeys.difference(biKeys);

    if (missingFromEn.isEmpty &&
        missingFromTl.isEmpty &&
        missingFromBi.isEmpty) {
      debugPrint('✓ LanguageProvider: all translation maps are in sync.');
      return;
    }
    if (missingFromEn.isNotEmpty) {
      debugPrint('⚠ Missing from en: $missingFromEn');
    }
    if (missingFromTl.isNotEmpty) {
      debugPrint('⚠ Missing from tl: $missingFromTl');
    }
    if (missingFromBi.isNotEmpty) {
      debugPrint('⚠ Missing from bi: $missingFromBi');
    }
  }
}
