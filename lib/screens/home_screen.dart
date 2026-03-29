import 'package:flutter/material.dart';
import 'my_words_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final PageController _page;

  @override
  void initState() { super.initState(); _page = PageController(); }
  @override
  void dispose() { _page.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageView(
      controller: _page,
      onPageChanged: (i) => setState(() => _tab = i),
      children: const [MyWordsScreen(), SearchScreen()],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) {
        setState(() => _tab = i);
        _page.animateToPage(i,
            duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      },
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFF1A1A2E).withOpacity(0.1),
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: "Lug'atim"),
        NavigationDestination(
            icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: "Qidiruv"),
      ],
    ),
  );
}
