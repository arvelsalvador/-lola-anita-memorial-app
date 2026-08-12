import 'package:flutter/material.dart';
import 'package:nita/Pages/Story/Model/story_model.dart';
import 'package:nita/utils/Constants/app_constants.dart';

// ── Quote Card ────────────────────────────────────────────────────────────────
class QuoteCard extends StatelessWidget {
  final String quote, attribution;
  const QuoteCard({super.key, required this.quote, required this.attribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rose.withOpacity(0.15), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            left: -2,
            child: Text(
              '\u201C',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 80,
                color: AppColors.goldLight,
                height: 1,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(quote, style: AppTextStyles.serifItalic),
              const SizedBox(height: 12),
              Text(
                attribution,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Timeline Widget ───────────────────────────────────────────────────────────
class TimelineWidget extends StatelessWidget {
  final List<LifeEvent> events;
  const TimelineWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (i) {
        final e = events[i];
        final isLast = i == events.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Text(
                      e.year,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: e.isLast ? AppColors.gold : AppColors.rose,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e.isLast ? AppColors.gold : AppColors.rose,
                        border: Border.all(color: AppColors.cream, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (e.isLast ? AppColors.gold : AppColors.rose)
                                .withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: AppColors.rose.withOpacity(0.25),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
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

// ── About Card ────────────────────────────────────────────────────────────────
class AboutCard extends StatelessWidget {
  final String text;
  const AboutCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rose.withOpacity(0.12), width: 0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Text(text, style: AppTextStyles.serifBody),
    );
  }
}
