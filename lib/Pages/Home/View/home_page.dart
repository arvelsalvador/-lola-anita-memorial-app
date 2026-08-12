import 'package:flutter/material.dart';
import 'package:nita/Pages/Home/Controller/home_controller.dart';
import 'package:nita/Pages/Home/Widget/home_shell.dart';

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
    return HomeShell(
      selectedTab: _controller.selectedTab,
      onTabChanged: _controller.selectTab,
      name: g.name,
      initial: g.initial,
      years: g.years,
      tagline: g.tagline,
    );
  }
}
