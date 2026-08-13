import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/models/story_model.dart';

class QuoteCard extends StatelessWidget {
  final String quote, attribution;
  const QuoteCard({super.key, required this.quote, required this.attribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 0.6,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        children: [
          Text(
            '\u201C',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 40,
              color: AppColors.gold,
              height: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: AppTextStyles.serifItalic,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: AppColors.gold.withValues(alpha: 0.4),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.circle,
                  size: 4,
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: AppColors.gold.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            attribution,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineWidget extends StatelessWidget {
  final List<LifeEvent> events;
  const TimelineWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
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
                      Text(e.title, style: AppTextStyles.serifHeading),
                      const SizedBox(height: 4),
                      Text(e.description, style: AppTextStyles.caption),
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

class AboutCard extends StatelessWidget {
  final String text;
  const AboutCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.rose.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Text(text, style: AppTextStyles.serifBody),
    );
  }
}
