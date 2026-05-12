import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = context.read<CouponRepository>();
      final list = await repo.list();
      if (!mounted) return;
      setState(() { _coupons = list; _loading = false; });
    });
  }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VTokens.bg,
      body: Column(
        children: [
          _hero(),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: VTokens.green))
              : ListView(
                padding: const EdgeInsets.only(bottom: 60),
                children: [
                  _enterCode(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: const Text('AVAILABLE COUPONS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
                  ),
                  ..._coupons.map((c) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: _couponCard(c),
                  )),
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.fromLTRB(16, 50, 16, 22),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [VTokens.green900, VTokens.green700, VTokens.green800],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Text('Offers & coupons', style: AppTheme.serif(size: 22, color: Colors.white, letterSpacing: -.3)),
        ]),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("YOU'VE SAVED", style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12, fontWeight: FontWeight.w800)),
                  Text('₹ 2,148', style: AppTheme.serif(size: 44, color: Colors.white, letterSpacing: -1)),
                  const SizedBox(height: 2),
                  Text('across 23 orders this year', style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Text('${_coupons.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(.7))),
              ]),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _enterCode() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VTokens.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VTokens.line, width: 1.5, style: BorderStyle.solid),
      ),
      child: Row(children: [
        const Icon(Icons.confirmation_number_outlined, color: VTokens.green700, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Have a code? Enter it here',
              hintStyle: TextStyle(fontSize: 13, color: VTokens.ink3)),
          ),
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: VTokens.ink, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          ),
          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ]),
    ),
  );

  Widget _couponCard(Map<String, dynamic> c) {
    final orange = c['tone'] == 'orange';
    final stripBg = orange
      ? const LinearGradient(colors: [Color(0xFFFFE0CC), Color(0xFFFFD0A8)])
      : const LinearGradient(colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]);
    final color = orange ? const Color(0xFFB65419) : VTokens.green700;

    return Container(
      decoration: BoxDecoration(
        color: VTokens.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VTokens.line2),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 70,
              decoration: BoxDecoration(gradient: stripBg),
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(c['code'] as String,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color, letterSpacing: .5)),
              ),
            ),
            Container(
              width: 1,
              decoration: const BoxDecoration(
                color: VTokens.line,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: VTokens.ink, height: 1.2)),
                    if (c['subtitle'] != null) ...[
                      const SizedBox(height: 4),
                      Text(c['subtitle'] as String, style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Terms & conditions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: VTokens.green700, size: 14),
                        ]),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: c['code'] as String));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied ${c['code']}')));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: VTokens.green50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Tap to copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
