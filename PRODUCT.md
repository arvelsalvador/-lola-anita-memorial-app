# Product

## Platform

web

## Users

- Her family — children, grandchildren, siblings, and relatives who want a lasting place to remember her, revisit her story, and see photos of her life.
- Anyone who knew Lola Anita Daiz Lumbao ("Nanay Nita") and wishes to pay respects — the memorial is public, so extended family, friends, and community visitors should all be able to experience it without an account.
- Visitors open the app across devices equally (phones, tablets, desktops) and it is distributed as a hosted website rather than an app-store install.

## Product Purpose

A permanent digital memorial for Lola Anita Daiz Lumbao: a place to keep her story, her words, her family, and her photographs alive. Success means a visitor can honor her memory — light a candle, read about her life, browse the family, and leave feeling her presence and the family's love.

## Positioning

A family-authored, trilingual (English, Tagalog, Bicol) memorial that combines a personal life story and family tree with a shared, live virtual candle that any visitor can light and that persists across every visit. The copy and photos are real family history, not template content.

## Operating Context

- Visitors arrive cold, likely on a mobile browser or shared link, and enter through a splash screen ("Touch to enter").
- The experience is reflective and quiet: reading, viewing photos, lighting a candle.
- Optional background music (Kiss the Rain — Yiruma) accompanies the experience.
- Content is presented in three languages — English, Tagalog, and Bicol — with Tagalog as the default; a toggle switches languages in-app.
- The candle count is stored in Firebase Firestore (`memorial/anita_lumbao`, field `candleCount`), shared across all visitors; the app degrades to a local count when Firebase is unreachable or unconfigured.

## Capabilities and Constraints

- Five tabs: Home (story), Gallery, Family, Tribute, Favorites.
- Home/story: hero with portrait, quote, life timeline, about, cherished memories.
- Gallery: real family photographs grouped by era/occasion (Celebrations, Bahay, Family, Care, Gatherings, Portraits, Last Day), with highlights and a "tap to reveal" remembrance gate.
- Family: family tree rooted at Anita, 32 members across 4 generations, member bios and photos.
- Tribute: farewell message, family quotes, and the shared candle counter.
- Favorites: hobbies, music, TV shows, and small joys.
- Trilingual copy stored as keyed strings in `lib/core/localization/language_provider.dart`; every surface must stay translatable in all three languages.
- Real assets bundled locally: ~90 photographs in `assets/images/gallery/`, portrait/background images, and one audio track.
- Firebase optional: app must boot and run fully when Firebase is absent or unreachable.
- Open data discrepancy to confirm with the family: birth/passing years appear as 1940–2025 in the home hero (`home_controller.dart`) but 1938–2022 on the family page (`family_controller.dart`), while the story copy says she "lived 85 years." Future work must confirm the true years before relying on them.

## Brand Commitments

- Subject: Lola Anita Daiz Lumbao, called "Nanay Nita."
- Titles and taglines already in use: "In Loving Memory" / "Sa Mahal na Alaala" (app title), "Beloved grandmother, keeper of stories."
- Her husband: Lolo Salvador V. Lumbao (54 years of marriage, six children raised together).
- The existing visual language in code (warm cream/rose/gold palette, Georgia serif) is incumbent implementation, not a confirmed brand commitment; changing it is allowed but should be a deliberate decision.

## Evidence on Hand

- ~90 real family photographs in `assets/images/gallery/` (birthdays, home, hospital, family gatherings, portraits, final days).
- `assets/images/backgroundIMG.jpg` and `assets/images/gallery/memorial_header_background_raw.jpg` (header background), `Nanay_dp.jpg` (profile portrait).
- `assets/audio/Kiss the Rain - Yiruma.mp3` (background music).
- Real family member names, roles, and short bios (Ramon, Rosario, Salvador Jr., Maria, Carlo, Ana, Ester, Rodolfo, Sonia, and more).
- Family quotes attributed to Maria (eldest daughter), Carlo (grandson), and Ana (granddaughter).
- No testimonials, press, or third-party reviews exist — future work must not fabricate them.

## Product Principles

1. **Memory over marketing.** This is a memorial, not a product launch; the design and copy must honor her, never sell or sensationalize.
2. **Real family truth.** Every name, date, quote, and photo comes from the family's actual history; verify before changing and never invent details.
3. **A shared ritual.** The candle is a collective act — visitors light one candle and see the shared count grow; preserve that communal feeling.
4. **Speak everyone's language.** All three languages are first-class; no surface may exist in only one.
5. **Graceful even when disconnected.** The experience must work offline-of-network and without Firebase, never showing errors to a mourning visitor.

## Accessibility & Inclusion

- Full trilingual support (English, Tagalog, Bicol) with Tagalog as default is a hard requirement.
- Audience spans generations, including elderly relatives; text legibility, contrast, and tap-target size should be designed generously.
- Public access means no authentication barrier to viewing or lighting a candle.
