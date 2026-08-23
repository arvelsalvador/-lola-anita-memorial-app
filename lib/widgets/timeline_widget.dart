import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/home_model.dart';

/// Vertical timeline of life events: year rail with dot markers (a leaf
/// medallion on the first event) and the event title + description.
class TimelineWidget extends StatelessWidget {
  final List<LifeEvent> events;
  const TimelineWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Column(
      children: List.generate(events.length, (i) {
        final e = events[i];
        final isFirst = i == 0;
        final isLast = i == events.length - 1;
        final markerColor = e.isLast ? AppColors.gold : AppColors.rose;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(
                      e.year,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: markerColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // First event gets a larger "medallion" marker with a
                    // leaf icon, matching the reference design. Every
                    // other event keeps the original small dot.
                    if (isFirst)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: markerColor,
                          border: Border.all(color: AppColors.cream, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: markerColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: markerColor,
                          border: Border.all(color: AppColors.cream, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: markerColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.rose.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 20,
                    top: isFirst ? 6 : 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t(e.titleKey),
                        style: AppTextStyles.serifHeading,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.t(e.descriptionKey),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
