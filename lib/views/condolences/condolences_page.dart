import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/condolences_controller.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/views/condolences/candle_section.dart';
import 'package:nita/widgets/page_title_header.dart';

/// The Pakikiramay (condolences) tab: the visitor lights a virtual candle
/// in Nanay's memory. The [CandleSection] lives here and the tab owns it
/// going forward.
class CondolencesPage extends StatelessWidget {
  final ScrollController? controller;

  /// Candle controller, owned by the home shell (composition root)
  /// and injected here — the view never constructs or owns the controller.
  final CondolencesController condolencesController;

  const CondolencesPage({
    super.key,
    this.controller,
    required this.condolencesController,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return CustomScrollView(
      controller: controller,
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: PageTitleHeader(
              title: lang.t('nav_condolences'),
              subtitle: lang.t('condolences_subtitle'),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              CandleSection(condolencesController: condolencesController),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}
