import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/guide_art_precache.dart';
import 'package:nita/views/guide/guide_content.dart';

/// Shows the guide-choice popup as a modal dialog with a dark scrim,
/// cream ornamental card, waving mascot on the left, left-aligned title & body,
/// warm brown pill action button with arrow, and a top-right close button.
///
/// Returns true if the user tapped "Yes, show me", false if "No, thanks" or 'X'.
Future<bool> showGuideChoiceDialog(BuildContext context) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.60),
    barrierLabel: 'Guide choice',
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, anim1, anim2) => const _GuideChoiceDialogWidget(),
  );

  return result ?? false;
}

class _GuideChoiceDialogWidget extends StatelessWidget {
  const _GuideChoiceDialogWidget();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final media = MediaQuery.sizeOf(context);
    final isCompact = media.width < 400;

    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    // Decorative warm organic backdrop circle on the left
                    Positioned(
                      left: -20,
                      top: 15,
                      bottom: 5,
                      width: isCompact ? 140 : 180,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF3E7DC,
                          ).withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.all(
                            Radius.elliptical(180, 220),
                          ),
                        ),
                      ),
                    ),

                    // Decorative subtle leaf motif at bottom left
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Opacity(
                        opacity: 0.45,
                        child: Icon(
                          Icons.spa_rounded,
                          size: isCompact ? 28 : 34,
                          color: const Color(0xFFC7AFA1),
                        ),
                      ),
                    ),

                    // Main content layout: Mascot on left, content & buttons on right
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 10 : 18,
                        isCompact ? 20 : 26,
                        isCompact ? 16 : 24,
                        isCompact ? 16 : 22,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Mascot
                          SizedBox(
                            width: isCompact ? 115 : 160,
                            child: Image.asset(
                              GuideArt.wave.asset,
                              height: isCompact ? 175 : 215,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              gaplessPlayback: true,
                              frameBuilder: guideArtFrameBuilder,
                            ),
                          ),
                          SizedBox(width: isCompact ? 10 : 18),

                          // Right Column: Title, Body, Action buttons
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  lang.t('guide_choice_title'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 16 : 19.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2E1C14),
                                    height: 1.2,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 6 : 9),

                                // Body
                                Text(
                                  lang.t('guide_choice_body'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 12 : 13.5,
                                    color: const Color(0xFF756257),
                                    height: 1.4,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 14 : 18),

                                // Primary pill button with arrow
                                SizedBox(
                                  width: double.infinity,
                                  height: isCompact ? 42 : 46,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B4536),
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      elevation: 2,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            lang.t('guide_choice_yes'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: isCompact ? 13.5 : 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Secondary text button
                                Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF756257),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 12,
                                      ),
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      lang.t('guide_choice_no'),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: isCompact ? 12.5 : 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF756257),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top-right close button ('X')
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(false),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFE4D8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFDCCFC3),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF5A443B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
