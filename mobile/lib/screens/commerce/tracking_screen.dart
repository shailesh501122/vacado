import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../main_shell.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Map<String, dynamic>? _data;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _refresh() async {
    try {
      final data = await context.read<OrderRepository>().tracking(widget.orderId);
      if (!mounted) return;
      setState(() => _data = data);
    } catch (_) {}
  }

  String _eta(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds - m * 60;
    return '$m min ${s.toString().padLeft(2, '0')} s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_data?['etaSecondsRemaining'] as num?)?.toInt() ?? 240;
    final rider = _data?['rider'] as Map<String, dynamic>?;
    final events = (_data?['events'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: VTokens.bg,
      body: Stack(
        children: [
          _fakeMap(),
          Positioned(
            top: 50, left: 14,
            child: VBackButton(floating: true, onTap: () {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
            }),
          ),
          Positioned(
            top: 410, left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              decoration: const BoxDecoration(
                color: VTokens.bg,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Color(0x2E0F172A), blurRadius: 40, offset: Offset(0, -20))],
              ),
              child: ListView(
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VTokens.line, borderRadius: BorderRadius.circular(99)))),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ARRIVING IN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: VTokens.green700, letterSpacing: .5)),
                          Text(_eta(remaining), style: AppTheme.serif(size: 38, letterSpacing: -1)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [
                          CircleAvatar(radius: 3, backgroundColor: VTokens.green),
                          SizedBox(width: 6),
                          Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: VTokens.green700)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _timeline(events),
                  const SizedBox(height: 14),
                  _riderCard(rider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fakeMap() => Container(
    height: 460,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFFE0F2FE), Color(0xFFDCFCE7), Color(0xFFFEF3C7)],
      ),
    ),
    child: CustomPaint(
      painter: _MapPainter(),
      child: Stack(
        children: [
          Positioned(
            top: 200, right: 80,
            child: Column(children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: VTokens.ink, shape: BoxShape.circle),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: VTokens.shadow1),
                child: const Text('Home', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
          Positioned(
            top: 320, left: 130,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: VTokens.green, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: VTokens.green.withOpacity(.6), blurRadius: 18, spreadRadius: -4, offset: const Offset(0, 8))],
              ),
              child: const Icon(Icons.local_shipping_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _timeline(List events) {
    if (events.isEmpty) {
      events = [
        {'kind': 'placed',  'title': 'Order confirmed',     'subtitle': 'paid via GPay'},
        {'kind': 'packed',  'title': 'Packed at warehouse', 'subtitle': '6 items + ice pack'},
        {'kind': 'ofd',     'title': 'Out for delivery',    'subtitle': 'rider Rahul · MH 12 RP'},
      ];
    }
    final extended = [
      ...events,
      {'kind': 'delivered', 'title': 'Delivered', 'subtitle': 'leave at door', 'done': false},
    ];
    return Stack(
      children: [
        Positioned(left: 7, top: 8, bottom: 8, child: Container(width: 2, color: VTokens.line)),
        Column(
          children: List.generate(extended.length, (i) {
            final e = extended[i];
            final isFuture = i == extended.length - 1;
            final active = i == extended.length - 2;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16, height: 16, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFuture ? Colors.white : (active ? VTokens.green : VTokens.green700),
                      shape: BoxShape.circle,
                      border: isFuture ? Border.all(color: VTokens.line, width: 2) : null,
                      boxShadow: active ? [BoxShadow(color: VTokens.green.withOpacity(.2), blurRadius: 0, spreadRadius: 4)] : null,
                    ),
                    child: isFuture ? const SizedBox.shrink() : (active ? const SizedBox.shrink() : const Icon(Icons.check_rounded, size: 10, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['title'] as String,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isFuture ? VTokens.ink3 : VTokens.ink)),
                        const SizedBox(height: 1),
                        Text((e['subtitle'] as String?) ?? '', style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _riderCard(Map<String, dynamic>? rider) {
    final name = (rider?['name'] as String?) ?? 'Rahul';
    final initials = name.isNotEmpty ? name.substring(0, name.length > 2 ? 2 : 1).toUpperCase() : 'RH';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VTokens.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VTokens.line2),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)]),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(initials, style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w900, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name · your rider', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            Text.rich(TextSpan(children: [
              const WidgetSpan(child: Icon(Icons.star, size: 10, color: VTokens.amber500)),
              TextSpan(text: ' ${(rider?['rating'] as num?)?.toString() ?? '4.9'} · 1.2k deliveries', style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
            ])),
          ],
        )),
        Container(
          width: 38, height: 38, alignment: Alignment.center,
          decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.call_rounded, color: VTokens.green700, size: 18),
        ),
        const SizedBox(width: 8),
        Container(
          width: 38, height: 38, alignment: Alignment.center,
          decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: VTokens.green700, size: 18),
        ),
      ]),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-20, 380)
      ..quadraticBezierTo(80, 320, 160, 280)
      ..quadraticBezierTo(240, 240, 320, 200)
      ..quadraticBezierTo(380, 160, 420, 100);
    canvas.drawPath(path, paint);

    final green = Paint()..color = VTokens.green..strokeWidth = 4..style = PaintingStyle.stroke;
    final greenPath = Path()
      ..moveTo(60, 380)
      ..quadraticBezierTo(130, 340, 160, 300)
      ..quadraticBezierTo(200, 240, 260, 220);
    canvas.drawPath(greenPath, green);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}
