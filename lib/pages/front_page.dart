import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_page.dart';

class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  _FrontPageState createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  final List<String> _videos = [
    'assets/backgrounds/front_page/front_page_background.mp4',
    'assets/backgrounds/front_page/front_page_background2.mp4',
  ];
  late VideoPlayerController _controller;

  String _currentLanguage = 'bg';

  @override
  void initState() {
    super.initState();
    final random = Random();
    final selectedVideo = _videos[random.nextInt(_videos.length)];
    _controller = VideoPlayerController.asset(selectedVideo)
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  void _switchLanguage(String lang) {
    setState(() {
      _currentLanguage = lang;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background video
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _switchLanguage('bg'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: _currentLanguage == 'bg'
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.network(
                      'https://flagcdn.com/w40/bg.png',
                      width: 40,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _switchLanguage('en'),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: _currentLanguage == 'en'
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.network(
                      'https://flagcdn.com/w40/us.png',
                      width: 40,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(_horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Logo(),
                  const SizedBox(height: 28),
                  _Title(language: _currentLanguage),
                  const SizedBox(height: 16),
                  // Frosted glass effect only behind description
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: _Description(language: _currentLanguage),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  _OpenCalendarButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    label: _currentLanguage == 'bg' ? 'Отвори календара' : 'Open Calendar',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Constants ---
const double _logoSize = 100;
const double _logoIconSize = 60;
const double _logoBorderRadius = 24;
const double _horizontalPadding = 32.0;
const double _buttonPaddingH = 40;
const double _buttonPaddingV = 16;
const double _buttonBorderRadius = 16;
const double _buttonFontSize = 18;
const String _backgroundImage = 'assets/lily_background.jpg';

// --- Private helper widgets ---

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _logoSize,
      height: _logoSize,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(_logoBorderRadius),
      ),
      child: const Icon(
        Icons.local_florist,
        size: _logoIconSize,
        color: Colors.green,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String language;
  const _Title({required this.language});
  @override
  Widget build(BuildContext context) {
    final text = language == 'bg' ? 'Всеки ден Лили' : 'Everyday Lilly';
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }
}

class _Description extends StatelessWidget {
  final String language;
  const _Description({required this.language});
  @override
  Widget build(BuildContext context) {
    final text = language == 'bg'
        ? 'Заснемай снимка всеки ден и виж своето развитие.\nВдъхновено от дъщеря ми Лили.\nОбичам те, Лили <3'
        : 'Capture a photo each day and see your growth journey unfold.\nInspired by my daughter Lilly.\nI love you, Lilly <3';
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black.withOpacity(0.95),
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _OpenCalendarButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const _OpenCalendarButton({required this.onPressed, required this.label});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            horizontal: _buttonPaddingH, vertical: _buttonPaddingV),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: _buttonFontSize),
      ),
    );
  }
}