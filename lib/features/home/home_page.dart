import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/features/home/home_controller.dart';
import 'package:nita/features/home/home_shell.dart';
import 'package:nita/core/localization/language_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = HomeController.grandmother;
    final lang = context.watch<LanguageProvider>();

    return HomeShell(
      selectedTab: _controller.selectedTab,
      onTabChanged: _controller.selectTab,
      name: g.name,
      initial: g.initial,
      years: g.years,
      tagline: lang.t('hero_tagline'),
    );
  }
}
