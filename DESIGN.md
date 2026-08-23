---
name: In Loving Memory — A Memorial for Lola Anita
description: A trilingual memorial for Lola Anita Daiz Lumbao — cream ground, rose ruled lines, gold diamonds, paper cards, Georgia serif throughout.
colors:
  warm-dark: "#2E1F17"
  warm-mid: "#6B4C3B"
  warm-deep: "#4A2E22"
  rose: "#C4836A"
  rose-deep: "#6B3524"
  rose-light: "#F5E6DF"
  gold: "#C9A96E"
  gold-light: "#F0E4C8"
  cream: "#FAF6F1"
  paper: "#FFFDF9"
  text-dark: "#3D2B1F"
  muted: "#8C7267"
typography:
  display:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "42px"
    fontWeight: 400
    lineHeight: 1.1
  headline:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "26px"
    fontWeight: 700
  title:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "15px"
    fontWeight: 600
  body:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.8
  label:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "10px"
    fontWeight: 500
    letterSpacing: "3px"
  caption:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "12px"
    fontWeight: 400
rounded:
  xs: "6px"
  sm: "12px"
  md: "14px"
  lg: "16px"
  xl: "18px"
  xxl: "20px"
  pill: "24px"
  nav: "32px"
  pill-full: "99px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "26px"
  xxxl: "32px"
components:
  card-ornamental:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.lg}"
  card-cover-leaf:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.xxl}"
    padding: "6px"
  card-group-page:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.md}"
    padding: "12px 4px"
  card-summary:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.md}"
    padding: "14px 12px"
  tray-search:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.md}"
    height: "44px"
  chip-tag:
    backgroundColor: "{colors.gold-light}"
    textColor: "{colors.warm-deep}"
    rounded: "{rounded.xs}"
    padding: "7px 2px"
  chip-tag-rose:
    backgroundColor: "{colors.rose-light}"
    textColor: "{colors.rose-deep}"
    rounded: "{rounded.xs}"
    padding: "7px 2px"
  nav-shell:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.nav}"
  nav-pill-active:
    backgroundColor: "{colors.rose}"
    textColor: "{colors.paper}"
    rounded: "{rounded.pill}"
  btn-outline-rose:
    backgroundColor: "transparent"
    textColor: "{colors.rose-deep}"
    rounded: "{rounded.pill-full}"
    padding: "12px 8px"
---

# Design System: In Loving Memory — A Memorial for Lola Anita

## Overview

**Creative North Star: "The Novena Booklet"**

This is a memorial, not a product: a kept house where a visitor walks in and reads a life. The world is a novena booklet bound for her family — Anita's portrait is the cover leaf, and each family group is its own ruled page, names written on the faint rose ruled lines of a white page rather than seated at benches or joined by stems. The line of descent runs page by page down the booklet: children first, then siblings, then grandchildren. Nothing here is a wireframe: no boxes-and-connector trees, no statistics dashboard. Counts are carved into the ground as printed inscriptions; each page closes with a lone gold diamond, the period, and opens onto the next across a leaf section break.

The materials are warm and domestic: a cream ground, white ornamental cards with hairline borders and soft warm shadows, rose hairlines as the pages' ruled lines and page edges, and gold used sparingly as the ornament metal — the diamond, the hairline rule, the leaf. Every character in the app, from hero name to nav caption, is set in Georgia. The build is code-led throughout; ornament is drawn with 45°-rotated squares, 1px rules, and the leaf motif, never photographic decoration.

**Key Characteristics:**
- The novena booklet: cover leaf → leaf page breaks → ruled group pages → lone diamond page feet, centered on the family tab's warm cream ground.
- Cream ground with paper cards as the only raised surfaces (hairline border + diffuse warm shadow).
- Rose hairlines as ruled lines, page edges, and the active nav state; gold diamonds and 1px rules as ornament.
- Georgia serif everywhere — a single voice, from 42px hero name to 9px chip text.
- Carved inscriptions (hairline rules flanking serif numerals) instead of stat cards.

## Colors

A warm, low-contrast domestic palette: cream and paper grounds, brown inks, a rose accent that speaks for warmth and activity, and a gold that appears only as ornament metal and hairline rules.

### Primary
- **Rose** (#C4836A): the voice of warmth and the active state. Solid rose fills only the selected bottom-nav pill; elsewhere it appears as hairlines (group page edges at 35% alpha, ruled lines at 12%, borders at 12–20% alpha), small icons (hearts, chevrons), and section-label ink.
- **Rose Deep** (#6B3524): ink on rose-tinted fills — tag-chip text, avatar initials and icons, and the outline of the secondary pill button.
- **Rose Light** (#F5E6DF): the tint side of the avatar gradient and the rose chip fill; always at reduced alpha (0.6) when used as a fill.

### Secondary
- **Gold** (#C9A96E): the ornament metal. Diamonds, divider rules, leaf icons, and hairline frames — at 16–30% alpha for lines and borders, 60–70% for diamonds, solid only at the group page-edge center and in small icons.
- **Gold Light** (#F0E4C8): tint fills (quote card at 35% alpha) and pale ink on dark grounds (brand wordmark, hero years).

### Neutral
- **Cream** (#FAF6F1): the app-wide page ground (scaffold default). The Family tab uses a slightly warmer cream (#FBF3EC) for its own ground — the same role, one step warmer.
- **Paper** (#FFFDF9): the only card fill in the app — every group page and cover leaf is paper. Also serves as ink on dark grounds (nav labels, hero name, white on rose).
- **Warm Dark** (#2E1F17): the deepest brown — hero ground, top-bar-adjacent dark grounds, and the tint of every shadow. The slim brand bar sits on a darker espresso (#1C1713).
- **Warm Mid** (#6B4C3B): body-text brown.
- **Warm Deep** (#4A2E22): emphasis brown on light fills (gold chip text, quote inset text).
- **Text Dark** (#3D2B1F): heading ink — titles, numerals, names.
- **Muted** (#8C7267): caption and meta ink — the quietest text role.

Note: **terracotta** (#CB6A4B) is declared in the token source but unused anywhere in the shipped build; it is deliberately not recorded as a system token.

### Named Rules
**The Warm Ground Rule.** Content always rests on cream (#FAF6F1) or warm dark (#2E1F17); paper (#FFFDF9) is reserved for raised cards and ink on dark — never the page ground.

**The Rose Moment Rule.** Rose is the color of the active state and of family warmth. Solid rose fills appear only on the selected nav pill and the "+N pa" chip; everywhere else rose is a hairline, a tint, or a small accent. Rarity is what makes the active state read.

## Typography

**Display Font:** Georgia (fallback Times New Roman, serif)
**Body Font:** Georgia (fallback Times New Roman, serif)
**Label Font:** Georgia (fallback Times New Roman, serif) — there is no second voice

**Character:** The whole app is one serif voice — the quiet, carved confidence of a memorial plaque. Weights carry the hierarchy (light display, regular body, 600–700 for names and titles); italics mark quoted or spoken words (quotes, roles, subtitles). Letter-spacing grows as type shrinks, so tiny labels stay legible and dignified.

### Hierarchy
- **Display** (400, 42px, line-height 1.1; 36px under 380px): the hero name "Anita Daiz Lumbao" — fitted and scaled down to fit, never wrapped.
- **Headline** (700, 26px): page titles, e.g. the Family tab header flanked by leaf icons.
- **Carved Numeral** (600, 24px, line-height 1.1): the large counts inside the stats lintel — engraved serif figures over tracked labels.
- **Title** (600, 15px): card titles (memory-card headings); 18px (600) for Anita's name on the cover leaf; 17px (700) for the feature-card heading; 13.5px (600) for group-page headings; 13px (600) for ruled-entry names; 12.5px (600) for "view all" summary labels (rose deep).
- **Body** (400, 14px, line-height 1.8): long-form story text, warm mid brown.
- **Italic** (400 italic, 16px, line-height 1.7): quotation cards; 13.5px italic for the family subtitle; 13px italic rose for the cover-leaf role; 11px italic muted for group counts; 10.5px italic warm mid for member roles; 16px (14px under 380px) pale gold for the hero tagline.
- **Label** (500, 10px, letter-spacing 3px, uppercase, rose): section headings ("HER WORDS") with a leading leaf and trailing rule; the lintel's printed labels sit slightly larger (10.5px, 500, letter-spacing 1.2px, warm mid).
- **Caption** (400, 12px, muted): memory-card bodies, the cover-leaf meta row (11.5px), and secondary copy.
- **Micro** (600, 9px): tag chips and nav captions (nav captions at 9px, letter-spacing 0.5px). Gold era headers on memory cards run 12px (300, letter-spacing 4px).

### Named Rules
**The One Voice Rule.** Every character in the app is Georgia — set globally in the theme, then explicitly on every label, chip, and caption. On platforms where Georgia is unavailable, the fallback is Times New Roman then serif; no sans-serif face ever appears. Introducing a second voice is a deliberate redesign, not a styling choice.

## Layout

One centered column on a warm ground, capped at 1050px on desktop and 750px on tablet (full width on mobile); the floating bottom nav is capped at 500px, the hero content at 720px. Page padding steps up with width: 16px mobile / 24px tablet / 32px desktop; the Family tab uses 20px horizontal / 12px vertical.

The vertical rhythm is a 4–8–12–16–20–26–32 step scale. On the Family tab: header → 20 → search tray → 18 → stats lintel → 26 → the booklet. The booklet is a centered column of pages: the cover leaf, then for each group a heading → 3 → italic count → 12 → the rose page edge → 14 → the white ruled page; pages close with a lone diamond (5px, 60% alpha, 20px of clearance) and open across leaf section breaks (1px rose hairlines at 30% alpha, 14px of vertical padding). Summary pages seat one centered "view all" entry capped at 280px. Content ends with generous bottom clearance (the story page reserves 100px above the floating nav).

### Named Rules
**The Carved, Not Boxed, Rule.** Counts and statistics are inscriptions, not cards: serif numerals bound between two 1px gold rules (30% alpha). If a number is worth showing, it is carved into the ground — it never gets a raised card of its own.

**The Booklet Rule.** The family is a novena booklet, not a tree: Anita is the cover leaf, and each group is a page whose names sit on faint rose ruled lines (1px, 12% alpha). Pages open across leaf section breaks and close with a lone gold diamond — the period. No stems, benches, or connector geometry.

## Elevation & Depth

The system is gently layered, never flat and never hard-edged: the cream ground holds paper cards that float on diffuse warm shadows. Depth is conveyed by one soft shadow recipe with four intensity steps, all tinted with the warm dark brown rather than black.

### Shadow Vocabulary
- **Whisper** (warmDark 3%, blur 8px, offset 0/2): the search tray — a shadow that barely lifts the field off the ground.
- **Soft** (warmDark 4%, blur 8px, offset 0/3): group pages and summary entries; memory cards step up to 5% alpha, 14px blur, offset 0/5.
- **Raised** (warmDark 6%, blur 12px, offset 0/4): the default ornamental card; Anita's cover leaf sits one step higher (7% alpha, 14px blur).
- **Floating** (warmDark 12%, blur 24px, offset 0/8): the bottom nav — the only element that floats high enough to read as a separate layer.
- **Quote Glow** (gold 10%, blur 14px, offset 0/6): quote cards carry a faint gold-tinted shadow instead of the brown one.

### Named Rules
**The Diffuse Shadow Rule.** Shadows are soft, warm, and directional-down: warm-dark tint, 8–24px blur, 2–8px downward offset, 3–12% opacity. Hard offset shadows, colored glows (beyond the one gold quote shadow), and shadows without blur do not exist in this world.

## Shapes

Form language is soft and domestic: rounded corners everywhere, hairlines as edges, and the 45° diamond as the signature geometry. Radius scale: 6px chips, 12px quote insets, 14px group pages/tray/summary entries, 15px cover-leaf inner frame, 16px standard cards, 18px feature and quote cards, 20px cover leaf, 24px nav pill, 32px nav shell, and 99px pills for buttons and filters.

Borders are always hairlines: 0.5–1px at 12–30% alpha — gold for ornament-framed cards, rose for family and story cards, a faint warm beige (#E0D6CC) for the feature card. The cover leaf doubles the language with an inner hairline frame (0.8px, gold 16%) inside its outer frame (1px, gold 30%).

The avatar is a circle: a rose-to-gold diagonal gradient (rose light → gold light at 60% alpha) ringed by a gold hairline (0.6px, 20% alpha), carrying initials in rose deep — 34px on ruled lines, 40px on summary entries, 60px on the cover leaf.

### Named Rules
**The Hairline Rule.** A border is a suggestion of an edge, never a frame: 0.5–1px at 12–30% alpha. Opaque or thick borders are not part of the system.

**The Diamond Rule.** The signature ornament is the gold diamond — a 45°-rotated square (5–8px across the system), rendered at 60–70% alpha and solid only at the group page-edge center (6px). It marks centers and ends: divider centerpieces, the center of each rose page edge, the lone period at each page foot (5px, 60% alpha), and the cover leaf's crest.

## Components

### Buttons
- **Shape:** full pills (99px radius).
- **Filter Pills:** white fill with a gold hairline (0.8px, 35–40% alpha); selected state flips to a solid warm brown (#A26747) with white ink, border dropped. 14px icon + 12px semibold label, 13px/7px padding.
- **Secondary (outline):** transparent fill, rose-deep outline (1px, 45% alpha), rose-deep ink, 13px icon + 11.5px semibold label, 12px/8px padding — used for "open photos" actions.
- **Hover / Focus:** taps use the theme's Material ink ripple on the same pill silhouette; no state shadows.

### Chips
- **Style:** tiny 9px Georgia semibold tags with 0.5px hairline borders at 20% alpha, 6px radius, 7px/2px padding, letter-spacing 0.3px.
- **Variants:** gold chip (gold-light fill at 50%, warm-deep text) for regular tags; rose chip (rose-light fill at 60%, rose-deep text) for "+N pa" extras.

### Cards / Containers
- **Corner Style:** 14–20px by tier; the standard recipe is the OrnamentalCard (16px).
- **Background:** paper (#FFFDF9) always.
- **Border:** hairline — gold by default, rose for family/story cards (12–14% alpha), double gold hairline on the cover leaf.
- **Shadow Strategy:** one of the four warm shadow steps, matching the card's role (see Elevation & Depth).
- **Internal Padding:** 16px standard, 18px feature, 20px about card, 12px/4px group pages, 14px/12px summary entries, 6px cover leaf (with 14px/18px/14px/14px inside the inner frame).

### Inputs / Fields
- **The Search Tray:** a slim 44px-tall paper field with a gold hairline (0.8px, 28% alpha), 14px radius, and a whisper shadow (3%, blur 8, offset 0/2). A 19px search icon and a 19px tune (filter) icon at warm-mid 75% frame a muted Georgia hint text (13.5px). There is no visible focus treatment in the build — the field is a quiet place-card, not a control.

### Navigation
- **Style:** a floating paper shell (32px radius, rose hairline at 15%, floating shadow) capped at 500px, holding five equal tabs. The active tab is a solid rose pill (24px radius) with white ink; inactive tabs are muted icons (20px) with 9px tracked labels. Switching animates at 180ms with easeOutCubic; the hero above collapses/expands at 280ms with the same curve.

### The Ornament Divider
- Thin gold lines flanking a centerpiece, with a 10px gap and 10–12px between components. Centerpieces: the 6px diamond at 70% alpha (default), a 4px dot at 50% alpha, or the upright leaf (14px, rotated 90°). The lintel's parting diamond is the bare diamond alone (lines at length 0, gap 10). Quote cards use a short 24px version with the dot centerpiece.

### The Stats Lintel
- An inscription, not a card: a 1px gold rule (30% alpha), then two flanks each holding a 24px semibold serif numeral (text dark, line-height 1.1) over a 10.5px tracked label (warm mid, letter-spacing 1.2, up to two lines), parted by a bare gold diamond, then a closing 1px rule. The lintel carries no icons — the printed numerals and their labels are the header.

### The Family Booklet ("The Novena Booklet")
- **The cover leaf:** Anita's portrait card, full width of the page — 20px radius, double gold hairline frame (outer 1px at 30%, inner 0.8px at 16%), a gold diamond crest (8px, 65% alpha) at the top edge and a spa flourish at the top right, a 60px rose-light portrait circle ringed by a gold hairline (0.8px, 25% alpha) carrying initials in 21px bold rose deep, her name at 18px semibold, the role in 13px rose italic with an 11px heart, and a muted meta row (11.5px) with 3px dots separating the years and photo count.
- **Page breaks:** a leaf (14px gold) between two rose hairlines (1px, 30% alpha, 12px gaps) — the section break that closes one page and opens the next; the booklet closes on the same leaf divider it opened with.
- **Group pages:** a heading (13.5px semibold label with a 13px gold leaf, then an 11px italic count), the rose page edge — a 1px rose line (35% alpha) spanning the width with a solid 6px gold diamond at its center — and beneath it the white page (14px radius, rose hairline 0.7px at 14%, soft shadow, 12px/4px padding) holding the names.
- **Ruled entries:** each member's line — a 34px gradient avatar, the name at 13px semibold, the role in 10.5px italic warm mid, tags trailing on the line — separated by faint rose ruled lines (1px, 12% alpha) like the rules of a notebook page.
- **Page feet:** a lone gold diamond (5px, 60% alpha) closes every group page — the period at the end of the page, followed by 20px of clearance before the next leaf break.
- **Summary pages:** unexpanded groups seat one centered "view all" entry (capped at 280px): a 40px avatar with a people glyph, a rose-deep 12.5px semibold label, a 10.5px muted count, and an 18px rose chevron (70% alpha).

## Do's and Don'ts

### Do:
- **Do** set every raised surface on paper (#FFFDF9) with a hairline border (0.5–1px, 12–30% alpha) and one of the four warm shadow steps.
- **Do** set the page ground on cream and let the hero and brand bar sit on warm dark — the world alternates between these two grounds only.
- **Do** render the family as a novena booklet: a cover leaf, then ruled pages whose names sit on faint rose lines (1px, 12% alpha), opened by leaf section breaks and closed by lone gold diamonds.
- **Do** center the gold diamond (6px, 60–70% alpha) wherever a line needs a middle — dividers, page edges, lintels — and let a smaller one (5px) stand alone as the page foot.
- **Do** keep all type in Georgia with the serif fallback, and let letter-spacing carry the small sizes (3px at 10px labels, 4px at 12px years).
- **Do** use the 4–8–12–16–20–26–32 spacing rhythm and the 20px family-page gutter.

### Don't:
- **Don't** use hard offset shadows, opaque borders, or black-tinted shadows — the shadow vocabulary is diffuse, warm, and downward only.
- **Don't** introduce a sans-serif face; the One Voice Rule holds at every size, including chips and nav captions.
- **Don't** turn the family back into boxes, benches, and connector stems — the booklet of ruled pages is the only permitted family geometry.
- **Don't** raise statistics into cards; counts are carved between hairline rules.
- **Don't** use the cream family-page ground for cards — paper is the only card fill.
- **Don't** let the lintel sprout icons again — the printed header is bare numerals and labels between gold rules.
