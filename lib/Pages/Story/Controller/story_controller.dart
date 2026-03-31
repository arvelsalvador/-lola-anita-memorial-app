import 'package:flutter/material.dart';
import 'package:nita/Pages/Story/Model/story_model.dart';

class StoryController extends ChangeNotifier {
  static const StoryModel data = StoryModel(
    quote:
        'Ang kusina ay kung saan ang pagmamahal ay nagiging lasa. Magluto gamit ang dalawang kamay at bukas na puso.',
    quoteAttribution: '— Lola Remedios, palaging sinasabi',
    about:
        'Si Lola Remedios ay namuhay ng 85 taon na may biyaya, halakhak, at matibay na pananampalataya. '
        'Isa siyang mapagmahal na asawa, mapag-arugang ina, at puso ng pamilyang umaabot sa tatlong henerasyon. '
        'Laging abala ang kanyang mga kamay — nagluluto, nananahi, o nakatiklop sa panalangin — at ang kanyang tahanan ay laging bukas.\n\n'
        'Malalim ang kanyang paniniwala na ang pamilya ang pinakamahalagang yaman, at ibinigay niya ang lahat upang bumuo ng tahanang puno ng pagmamahal.',
    timeline: [
      LifeEvent(
        year: '1938',
        title: 'Ipinanganak sa Camarines Norte',
        description:
            'Ikatlo sa pitong magkakapatid, ipinanganak sa probinsyang mahal niya.',
      ),
      LifeEvent(
        year: '1961',
        title: 'Ikinasal kay Lolo Ernesto',
        description:
            '54 na taon ng pagsasama. Magkasama nilang pinalaki ang anim na anak at nagmahalan ng walang hanggan.',
      ),
      LifeEvent(
        year: '1975',
        title: 'Unang apo ay isinilang',
        description:
            'Naging Lola siya — isang titulong ipinagmamalaki niya higit sa lahat.',
      ),
      LifeEvent(
        year: '1998',
        title: 'Ipinagdiwang ang anibersaryo',
        description:
            'Nagtipon ang buong pamilya upang parangalan ang 37 taon ng tapat na pagmamahalan.',
      ),
      LifeEvent(
        year: '2023',
        title: 'Mapayapang namahinga',
        description:
            'Pinalibutan ng pamilya, siya ay nagbalik sa Diyos matapos ang isang buhay na puno ng biyaya.',
        isLast: true,
      ),
    ],
  );
}
