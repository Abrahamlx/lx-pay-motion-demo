import 'dart:math' as math;
import 'package:flutter/material.dart';


/// Three bouncing dots (teal, with an amber middle dot). No packages needed.
class LxDotsLoader extends StatefulWidget {
  const LxDotsLoader({
    super.key,
    this.color = const Color(0xFF0B6E6E),
    this.accent = const Color(0xFFFFB020),
    this.dotSize = 12,
  });

  final Color color;
  final Color accent;
  final double dotSize;

  @override
  State<LxDotsLoader> createState() => _LxDotsLoaderState();
}

class _LxDotsLoaderState extends State<LxDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the phone's "reduce motion" setting.
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dotSize;
    return Semantics(
      label: 'Loading',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              // Each dot starts a little after the previous one.
              final t = ((_c.value - i * 0.15) % 1.0 + 1.0) % 1.0;
              final lift = t < 0.5 ? math.sin(t / 0.5 * math.pi) : 0.0;
              return Transform.translate(
                offset: Offset(0, -lift * d),
                child: Container(
                  width: d,
                  height: d,
                  margin: EdgeInsets.symmetric(horizontal: d * 0.35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 1 ? widget.accent : widget.color,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}


/// Ring draws itself, then the checkmark. Use after a successful payment.
class LxSuccessCheck extends StatefulWidget {
  const LxSuccessCheck({
    super.key,
    this.size = 96,
    this.color = const Color(0xFF0B6E6E),
    this.onCompleted,
  });

  final double size;
  final Color color;
  final VoidCallback? onCompleted;

  @override
  State<LxSuccessCheck> createState() => _LxSuccessCheckState();
}

class _LxSuccessCheckState extends State<LxSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
      widget.onCompleted?.call();
    } else {
      _c.forward().whenComplete(() => widget.onCompleted?.call());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Success',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: _CheckPainter(
            Curves.easeInOut.transform(_c.value),
            widget.color,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.p, this.color);
  final double p;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = s.width * 0.07;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke
      ..color = color;

    // Part 1 (first 55%): the ring.
    final ring = (p / 0.55).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(
        center: s.center(Offset.zero),
        radius: (s.width - stroke) / 2,
      ),
      -math.pi / 2,
      2 * math.pi * ring,
      false,
      paint,
    );

    // Part 2 (last 45%): the checkmark.
    final check = ((p - 0.55) / 0.45).clamp(0.0, 1.0);
    if (check > 0) {
      final path = Path()
        ..moveTo(s.width * 0.28, s.height * 0.52)
        ..lineTo(s.width * 0.44, s.height * 0.68)
        ..lineTo(s.width * 0.72, s.height * 0.36);
      final m = path.computeMetrics().first;
      canvas.drawPath(m.extractPath(0, m.length * check), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.p != p || old.color != color;
}


/// Logo scales + fades in (~0.7s), dots bounce underneath, then [onFinished].
/// Keep it short: a splash should never make people wait.
class LxSplash extends StatefulWidget {
  const LxSplash({
    super.key,
    required this.onFinished,
    this.logoAsset = 'assets/images/lx_pay_logo.png',
    this.logoWidth = 220,
  });

  final VoidCallback onFinished;
  final String logoAsset;
  final double logoWidth;

  @override
  State<LxSplash> createState() => _LxSplashState();
}

class _LxSplashState extends State<LxSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.85, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _run();
  }

  Future<void> _run() async {
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      await _c.forward();
    }
    // Replace this pause with your real startup work (token check, etc.).
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // matches the PNG's white background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset(widget.logoAsset, width: widget.logoWidth),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(opacity: _fade, child: const LxDotsLoader()),
          ],
        ),
      ),
    );
  }
}


void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});
  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  bool _splashDone = false;
  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: !_splashDone
          ? LxSplash(onFinished: () => setState(() => _splashDone = true))
          : Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LxDotsLoader(),
                    const SizedBox(height: 48),
                    LxSuccessCheck(key: ValueKey(_replay)),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => setState(() => _replay++),
                      child: const Text('Replay checkmark'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
