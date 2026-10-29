import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/guide_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/guide_art_precache.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/views/guide/guide_choice_dialog.dart';
import 'package:nita/views/home/home_page.dart';
import 'package:nita/views/splash/visitor_gate_form.dart';
import 'package:nita/widgets/app_brand_bar.dart';

/// The entry screen shown once to new visitors: collects name and address,
/// and upon submission presents the Guide-choice popup on the same page
/// before fading to Home.
class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // The splash already warms these, but keep the dialog safe when this page
    // is opened on its own (deep test harness, future routes). Cache hits make
    // the repeat call effectively free.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheGuideArt(context);
    });
  }

  Future<void> _handleEntered() async {
    if (_submitting || !mounted) return;
    setState(() => _submitting = true);

    final guideController = context.read<GuideController>();
    guideController.setHasEnteredInfo(true);

    // Show the guide-choice popup on the same page
    final wantsGuide = await showGuideChoiceDialog(context);
    guideController.setGuideChoice(wantsGuide);

    if (!mounted) return;

    // Both buttons close popup and go to Home with a fade transition (~400ms)
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(
        const HomePage(),
        duration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmDark,
      body: Column(
        children: [
          const AppBrandBar(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkSoot.withValues(alpha: 0.94),
                    AppColors.darkEmber.withValues(alpha: 0.84),
                    AppColors.warmDark.withValues(alpha: 0.70),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: VisitorGateForm(onEntered: _handleEntered),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
