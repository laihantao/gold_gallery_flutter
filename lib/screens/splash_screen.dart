import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/splash_caption.dart';
import '../painters/bg_pattern_painter.dart';
import '../providers/locale_notifier.dart';
import '../services/splash_caption_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _CoinParticle {
  double x;
  double y;
  final double speed;
  final double size;
  double rotation;
  final double rotSpeed;
  final double wobble;
  final double wobbleFreq;
  final double opacity;
  final double phaseOffset;

  _CoinParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.wobble,
    required this.wobbleFreq,
    required this.opacity,
    required this.phaseOffset,
  });
}

class _SparkleParticle {
  final double x;
  final double y;
  double progress; // advances 0 → 1

  _SparkleParticle({required this.x, required this.y}) : progress = 0.0;

  bool get isDone => progress >= 1.0;
}

// ── Coin + sparkle painter ────────────────────────────────────────────────────

class _CoinParticlePainter extends CustomPainter {
  final List<_CoinParticle> coins;
  final List<_SparkleParticle> sparkles;
  final double time; // seconds, used for horizontal wobble

  static const _coinFill = Color(0xFFD4A847);
  static const _coinStroke = Color(0xFF8B6914);
  static const _coinInner = Color(0xFFF0C040);

  const _CoinParticlePainter({
    required this.coins,
    required this.sparkles,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      _drawCoin(canvas, coin);
    }
    for (final sparkle in sparkles) {
      _drawSparkle(canvas, sparkle);
    }
  }

  void _drawCoin(Canvas canvas, _CoinParticle coin) {
    final wobbleX =
        coin.wobble * math.sin(time * coin.wobbleFreq + coin.phaseOffset) * 8;
    final cx = coin.x + wobbleX;
    final cy = coin.y;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(coin.rotation);

    // Simulate coin flip by squishing vertically
    final scaleY = math.cos(coin.rotation).abs().clamp(0.3, 1.0);
    canvas.scale(1.0, scaleY);

    final fillPaint = Paint()
      ..color = _coinFill.withValues(alpha: coin.opacity)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = _coinStroke.withValues(alpha: coin.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final innerPaint = Paint()
      ..color = _coinInner.withValues(alpha: coin.opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, coin.size, fillPaint);
    canvas.drawCircle(Offset.zero, coin.size, strokePaint);
    canvas.drawCircle(Offset.zero, coin.size * 0.65, innerPaint);

    // "$" symbol centered in coin
    final tp = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: _coinInner.withValues(alpha: coin.opacity),
          fontSize: coin.size * 0.9,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, _SparkleParticle sparkle) {
    final opacity = (1.0 - sparkle.progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = _coinInner.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const armLength = 12.0;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        Offset(sparkle.x, sparkle.y),
        Offset(
          sparkle.x + armLength * math.cos(angle),
          sparkle.y + armLength * math.sin(angle),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoinParticlePainter old) => true;
}

// ── SplashScreen ──────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final AnimationController _coinsController;
  late final AnimationController _dotsController;

  // ── Logo animations ───────────────────────────────────────────────────────
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _taglineFade;

  // ── Coin state ────────────────────────────────────────────────────────────
  final List<_CoinParticle> _coins = [];
  final List<_SparkleParticle> _sparkles = [];
  final math.Random _rng = math.Random();
  int _frameCount = 0;
  double _screenWidth = 400;
  double _screenHeight = 800;
  bool _coinsSeeded = false;

  // ── Caption (picked once per launch) ─────────────────────────────────────
  late final SplashCaption _caption;

  // ── Dots visibility ───────────────────────────────────────────────────────
  bool _dotsVisible = false;

  @override
  void initState() {
    super.initState();

    // Pick one caption for this launch — synchronous because
    // SplashCaptionService.initialize() was awaited in main().
    _caption = SplashCaptionService.pickRandom();

    // Controllers
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _coinsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Logo: controller starts after 300ms delay.
    // Screen timeline → controller interval mapping (controller = 800ms):
    //   300–900ms screen → 0–600ms controller → interval 0.000–0.750
    //   400–800ms screen → 100–500ms controller → interval 0.125–0.625
    //   600–1000ms screen → 300–700ms controller → interval 0.375–0.875
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 1.0, curve: Curves.elasticOut),
      ),
    );
    _textSlide = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.125, 0.625, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.125, 0.625, curve: Curves.easeOut),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.375, 0.875, curve: Curves.easeOut),
      ),
    );

    // Update coin positions on every animation tick
    _coinsController.addListener(_onCoinTick);

    // Start logo after 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _logoController.forward();
    });

    // Fade in dots after 1000ms
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _dotsVisible = true);
    });

    _initAndNavigate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    if (!_coinsSeeded) {
      _coinsSeeded = true;
      _seedInitialCoins();
    }
  }

  // ── Coin helpers ──────────────────────────────────────────────────────────

  void _seedInitialCoins() {
    for (int i = 0; i < 8; i++) {
      _coins.add(_makeRandomCoin(randomY: true));
    }
  }

  _CoinParticle _makeRandomCoin({bool randomY = false}) {
    return _CoinParticle(
      x: _rng.nextDouble() * _screenWidth,
      y: randomY ? _rng.nextDouble() * _screenHeight : -20.0,
      speed: 1.5 + _rng.nextDouble() * 1.5,
      size: 8.0 + _rng.nextDouble() * 10.0,
      rotation: _rng.nextDouble() * math.pi * 2,
      rotSpeed: (_rng.nextDouble() - 0.5) * 0.1,
      wobble: (_rng.nextDouble() - 0.5) * 2.0,
      wobbleFreq: 1.0 + _rng.nextDouble() * 2.0,
      opacity: 0.5 + _rng.nextDouble() * 0.5,
      phaseOffset: _rng.nextDouble() * math.pi * 2,
    );
  }

  void _onCoinTick() {
    // Advance coins — this runs every animation frame (~60 fps).
    // AnimatedBuilder handles the repaint; no setState needed here.
    for (final coin in _coins) {
      coin.y += coin.speed;
      coin.rotation += coin.rotSpeed;
    }

    // Sparkle when a coin exits the bottom
    final exited =
        _coins.where((c) => c.y > _screenHeight + c.size).toList();
    for (final coin in exited) {
      _sparkles.add(
        _SparkleParticle(x: coin.x, y: _screenHeight - 16),
      );
    }
    _coins.removeWhere((c) => c.y > _screenHeight + c.size);

    // Advance sparkles (1/20 increment → ~333 ms at 60 fps)
    for (final s in _sparkles) {
      s.progress += 1.0 / 20.0;
    }
    _sparkles.removeWhere((s) => s.isDone);

    // Spawn new coin every 20 frames (max 20 on screen)
    _frameCount++;
    if (_frameCount % 20 == 0 && _coins.length < 20) {
      _coins.add(_makeRandomCoin());
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _initAndNavigate() async {
    // All heavy init already runs in main() before runApp().
    // Wait for the minimum display time then navigate.
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) context.go('/');
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _logoController.dispose();
    _coinsController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  // ── Loading dots ──────────────────────────────────────────────────────────

  Widget _buildDots(AurumTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        // Stagger: dot i starts 200ms later within the 1200ms cycle
        final delay = i * (200.0 / 1200.0);
        final phase = (_dotsController.value + delay) % 1.0;
        final sinV = math.sin(phase * math.pi);
        final scale = 0.6 + 0.6 * sinV;
        final opacity = 0.3 + 0.7 * sinV;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Transform.scale(
            scale: scale.clamp(0.6, 1.2),
            child: Opacity(
              opacity: opacity.clamp(0.3, 1.0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>().currentTheme;
    final locale = context.watch<LocaleNotifier>().locale;
    final tagline = _caption.forLocale(locale);

    return Scaffold(
      backgroundColor: theme.primaryBg,
      body: Stack(
        children: [
          // Layer 1: background watermark
          CustomPaint(
            painter: BgPatternPainter(
              color: theme.patternColor,
              opacity: 0.08,
            ),
            child: const SizedBox.expand(),
          ),

          // Layer 2: falling coins + sparkles
          AnimatedBuilder(
            animation: _coinsController,
            builder: (context, child) => CustomPaint(
              painter: _CoinParticlePainter(
                coins: _coins,
                sparkles: _sparkles,
                time: _coinsController.value * 3.0,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // Layer 3: logo + text
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) => Opacity(
                opacity: _logoFade.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo container
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: theme.primaryDark,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.diamond_outlined,
                              size: 48,
                              color: theme.surface,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // "AURUM" — slides up from y+10 → y+0
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textFade.value,
                          child: Text(
                            'AURUM',
                            style: GoogleFonts.fredoka(
                              fontSize: 32,
                              color: theme.inkDark,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Tagline — locale-aware, picked randomly per launch
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Text(
                          tagline,
                          style: GoogleFonts.caveat(
                            fontSize: 16,
                            color: theme.inkLight,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Layer 4: loading dots (bottom centre)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _dotsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) => _buildDots(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
