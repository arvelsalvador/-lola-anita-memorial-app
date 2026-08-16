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

  String t(String key) {
    final map = switch (_language) {
      AppLanguage.english => en,
      AppLanguage.tagalog => tl,
      AppLanguage.bicol => bi,
    };
    return map[key] ?? key;
  }

  static const Map<String, String> en = {
    'app_title': 'In Loving Memory',
    'nav_home': 'Home',
    'nav_gallery': 'Gallery',
    'nav_memories': 'Memories',
    'nav_tribute': 'Tribute',
    'nav_favorites': 'Favorites',
    'splash_quote': 'Those we love don\'t go away,\nThey walk beside us every day.',
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
    'no_images': 'No images found in gallery.\nTry a full restart after adding images.',
    // Story page
    'story_quote':
        'The kitchen is where love becomes flavor. Cook with both hands and an open heart.',
    'story_quote_attribution': '— Nanay Nita, as she always said',
    'story_about':
        'Lola Anita Daiz Lumbao lived 85 years full of grace, laughter, and steadfast faith. '
        'She was a loving wife, a nurturing mother, and the heart of a family spanning three generations. '
        'Her hands were never idle — cooking, sewing, or folded in prayer — and her home was always open.\n\n'
        'She believed deeply that family was life\'s greatest treasure, and she gave everything to build a home filled with love.',
    'timeline_birth_title': 'Born in Camarines Norte',
    'timeline_birth_desc': 'Third of seven siblings, born in the province she loved.',
    'timeline_marriage_title': 'Married Lolo Salvador V. Lumbao',
    'timeline_marriage_desc':
        '54 years together. They raised six children and loved each other endlessly. '
        'Lolo Salvador passed away from a heart attack.',
    'timeline_first_apo_title': 'Her first grandchild was born',
    'timeline_first_apo_desc': 'She became a Lola — a title she treasured above all.',
    'timeline_anniversary_title': 'The anniversary was celebrated',
    'timeline_anniversary_desc': 'The whole family gathered to honor 37 years of faithful love.',
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
    // Tribute page
    'tribute_message':
        'You taught us that a home is built with warmth, not walls. '
        'Your laugh lives in every room we\'ve ever loved. '
        'Rest now, Lola. We carry you forward.',
    'tribute_until_we_meet': 'Until we meet again',
    'tribute_in_loving_memory': 'IN LOVING MEMORY',
    'family_quote_1': 'Mama was light itself. Every room she entered felt warmer.',
    'family_quote_1_name': 'Maria, her eldest daughter',
    'family_quote_2': 'She never let us leave hungry or unloved. That was her superpower.',
    'family_quote_2_name': 'Carlo, grandson',
    'family_quote_3': 'I will spend my whole life trying to love people the way she loved us.',
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
    'group_gatherings': 'Gatherings',
    'group_portraits': 'Portraits',
    'group_remembrances': 'Remembrances',
    'group_other': 'Other',
    'gallery_all': 'All',
    'gallery_subtitle': 'A lifetime of moments',
    'gallery_highlights': 'Highlights',
    'gallery_photos': 'photos',
    // Gallery locations / dates
    'loc_lipa': 'Lipa City, Batangas',
    'loc_bahay': 'Bahay, Batangas',
    'loc_family_residence': 'Family Residence',
    'loc_batangas_province': 'Batangas Province',
    'date_1': 'Mar 12, 2018',
    'date_2': 'Aug 21, 2011',
    'date_3': 'May 14, 2019',
    'date_4': 'Dec 25, 2020',
  };

  static const Map<String, String> tl = {
    'app_title': 'Sa Mahal na Alaala',
    'nav_home': 'Tahanan',
    'nav_gallery': 'Galeri',
    'nav_memories': 'Mga Alaala',
    'nav_tribute': 'Pagkilala',
    'nav_favorites': 'Mga Paborito',
    'splash_quote': 'Ang mga natin ay hindi nawala,\nSilang laging kasama natin araw-araw.',
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
    'settings_language': 'Wika',
    'settings_english': 'Ingles',
    'settings_tagalog': 'Tagalog',
    'settings_bicol': 'Bikol',
    'candle_light': 'Magliwanag ng kandila',
    'candle_virtual': 'Virtual na kandila na nakasindi sa kanyang alaala',
    'no_images': 'Walang mga larawan sa galeri.\nSubukan ang buong pag-restart pagkatapos magdagdag ng mga larawan.',
    // Story page
    'story_quote':
        'Ang kusina ay kung saan ang pagmamahal ay nagiging lasa. Magluto gamit ang dalawang kamay at bukas na puso.',
    'story_quote_attribution': '— Nanay Nita, palaging sinasabi',
    'story_about':
        'Si Lola Anita Daiz Lumbao ay namuhay ng 85 taon na may biyaya, halakhak, at matibay na pananampalataya. '
        'Isa siyang mapagmahal na asawa, mapag-arugang ina, at puso ng pamilyang umaabot sa tatlong henerasyon. '
        'Laging abala ang kanyang mga kamay — nagluluto, nananahi, o nakatiklop sa panalangin — at ang kanyang tahanan ay laging bukas.\n\n'
        'Malalim ang kanyang paniniwala na ang pamilya ang pinakamahalagang yaman, at ibinigay niya ang lahat upang bumuo ng tahanang puno ng pagmamahal.',
    'timeline_birth_title': 'Ipinanganak sa Camarines Norte',
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
    // Tribute page
    'tribute_message':
        'Itinuro mo sa amin na ang tahanan ay itinatayo sa init ng pagmamahal, hindi sa mga pader. '
        'Ang iyong tawa ay nananatili sa bawat silid na minahal namin. '
        'Magpahinga ka na, Lola. Patuloy ka naming dinadala sa aming mga puso.',
    'tribute_until_we_meet': 'Hanggang sa muli tayong magkita',
    'tribute_in_loving_memory': 'SA MAHAL NA ALAALA',
    'family_quote_1': 'Si Mama mismo ang liwanag. Parang sumisigla ang bawat silid na kanyang pinasukan.',
    'family_quote_1_name': 'Maria, ang panganay niyang anak na babae',
    'family_quote_2': 'Hindi niya kami hinayaang umalis na gutom o walang pagmamahal. Iyon ang kanyang superpower.',
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
    'group_gatherings': 'Mga Pagtitipon',
    'group_portraits': 'Mga Retrato',
    'group_remembrances': 'Mga Paggunita',
    'group_other': 'Iba Pa',
    'gallery_all': 'Lahat',
    'gallery_subtitle': 'Isang buhay ng mga sandali',
    'gallery_highlights': 'Tampok',
    'gallery_photos': 'larawan',
    // Gallery locations / dates
    'loc_lipa': 'Lungsod ng Lipa, Batangas',
    'loc_bahay': 'Bahay, Batangas',
    'loc_family_residence': 'Tirahan ng Pamilya',
    'loc_batangas_province': 'Lalawigang Batangas',
    'date_1': 'Marso 12, 2018',
    'date_2': 'Agosto 21, 2011',
    'date_3': 'Mayo 14, 2019',
    'date_4': 'Disyembre 25, 2020',
  };

  static const Map<String, String> bi = {
    'app_title': 'Sa Mahal na Alaala',
    'nav_home': 'Harong',
    'nav_gallery': 'Galeriya',
    'nav_memories': 'Mga Alaala',
    'nav_tribute': 'Pagkilala',
    'nav_favorites': 'Mga Paborito',
    'splash_quote':
        'An mga namomotan ta dai nawawara,\nSinda yaon sa kataid ta lambang aldaw.',
    'splash_subtitle': 'SA MAHAL NA ALAALA',
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
    'timeline_birth_title': 'Ipinangaki sa Camarines Norte',
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
    'group_gatherings': 'Mga Pagtiripon',
    'group_portraits': 'Mga Retrato',
    'group_remembrances': 'Mga Pagromdom',
    'group_other': 'Iba Pa',
    'gallery_all': 'Gabos',
    'gallery_subtitle': 'Sarong buhay nin mga sandali',
    'gallery_highlights': 'Tampok',
    'gallery_photos': 'mga ladawan',
    // Gallery locations / dates
    'loc_lipa': 'Syudad nin Lipa, Batangas',
    'loc_bahay': 'Bahay, Batangas',
    'loc_family_residence': 'Estaran kan Pamilya',
    'loc_batangas_province': 'Probinsya kan Batangas',
    'date_1': 'Marso 12, 2018',
    'date_2': 'Agosto 21, 2011',
    'date_3': 'Mayo 14, 2019',
    'date_4': 'Disyembre 25, 2020',
  };
}
