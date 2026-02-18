import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _inlineButtonKey = GlobalKey();
  final GlobalKey _floatingButtonKey = GlobalKey();

  double _inlineOpacity = 1.0;
  double _floatingOpacity = 0.0;

  bool _isScrollable = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  void _checkIfScrollable() {
    if (!_scrollController.hasClients) return;

    final isScrollable = _scrollController.position.maxScrollExtent > 0;

    setState(() {
      _isScrollable = isScrollable;
    });

    if (isScrollable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateButtonVisibility();
      });
    }
  }

  void _onScroll() {
    if (!_isScrollable) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateButtonVisibility();
    });
  }

  void _updateButtonVisibility() {
    final inlineBox =
        _inlineButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final floatingBox =
        _floatingButtonKey.currentContext?.findRenderObject() as RenderBox?;

    if (inlineBox == null || floatingBox == null) return;

    final inlinePosition = inlineBox.localToGlobal(Offset.zero).dy;
    final floatingPosition = floatingBox.localToGlobal(Offset.zero).dy;

    final reachedFixedPosition = inlinePosition <= floatingPosition;

    setState(() {
      if (reachedFixedPosition) {
        _inlineOpacity = 1.0;
        _floatingOpacity = 0.0;
      } else {
        _inlineOpacity = 0.0;
        _floatingOpacity = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinned Bottom Button')),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Column(
                    spacing: 12,
                    children: List.generate(
                      20,
                      (index) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 205, 206, 207),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(width: 1, color: Colors.black),
                        ),
                        child: Text(
                          "Random List Item $index",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    key: _inlineButtonKey,
                    width: double.infinity,
                    child: Opacity(
                      opacity: _inlineOpacity,
                      child: _buildButton(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text("Random content at the bottom of the page."),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            Positioned(
              left: 8,
              right: 8,
              bottom: 16,
              child: Opacity(
                key: _floatingButtonKey,
                opacity: _floatingOpacity,
                child: IgnorePointer(
                  ignoring: _floatingOpacity == 0.0,
                  child: _buildButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        backgroundColor: const Color(0xFFD97757),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        "Pinned Button",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
