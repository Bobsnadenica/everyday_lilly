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

  static const double _flagWidth = 40;
  static const double _flagHeight = 24;

  static final BoxDecoration _flagBorder = BoxDecoration(
    border: Border.all(color: Colors.green, width: 2),
    borderRadius: BorderRadius.circular(4),
  );

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  void _initializeVideoController() {
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
    if (_currentLanguage == lang) return;
    setState(() {
      _currentLanguage = lang;
    });
  }

  Widget _buildFlagButton(String lang, CustomPainter painter) {
    final bool isSelected = _currentLanguage == lang;
    return GestureDetector(
      onTap: () => _switchLanguage(lang),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: isSelected ? _flagBorder : null,
        child: SizedBox(
          width: _flagWidth,
          height: _flagHeight,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
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
            top: 50,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFlagButton('bg', BGFlagPainter()),
                _buildFlagButton('en', USFlagPainter()),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(_horizontalPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Logo(),
                  const SizedBox(height: 28),
                  _Title(language: _currentLanguage),
                  const SizedBox(height: 16),
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
                        MaterialPageRoute(builder: (_) => HomePage()),
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
        ? 'Заснемай снимка всеки ден и виж развитието на своята лилия.\nВдъхновено от дъщеря ми Лили.\nОбичам те, Лили <3'
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
// --- Custom Painters for Flags ---

class BGFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // White stripe (top third)
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height / 3), paint);
    // Green stripe (middle third)
    paint.color = Colors.green;
    canvas.drawRect(Rect.fromLTWH(0, size.height / 3, size.width, size.height / 3), paint);
    // Red stripe (bottom third)
    paint.color = Colors.red;
    canvas.drawRect(Rect.fromLTWH(0, 2 * size.height / 3, size.width, size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class USFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw red background
    final redPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), redPaint);

    // Draw white stripes (7 total, starting with red at top)
    final stripeHeight = size.height / 13;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (int i = 1; i < 13; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        whitePaint,
      );
    }

    // Draw blue canton
    final cantonWidth = size.width * 0.4;
    final cantonHeight = stripeHeight * 7;
    final bluePaint = Paint()..color = Colors.blue[800] ?? Colors.blue..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, cantonWidth, cantonHeight), bluePaint);

    // Draw white circles for stars (6 rows of 5, 5 rows of 4, simplified)
    final starRadius = stripeHeight * 0.20;
    final rowCount = 9;
    final colCountOdd = 6;
    final colCountEven = 5;
    for (int row = 0; row < rowCount; row++) {
      final isOddRow = row % 2 == 0;
      final starsInRow = isOddRow ? colCountOdd : colCountEven;
      final y = (row + 1) * cantonHeight / (rowCount + 1);
      for (int col = 0; col < starsInRow; col++) {
        final x = (col + 1) * cantonWidth / (starsInRow + 1);
        canvas.drawCircle(Offset(x, y), starRadius, whitePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}