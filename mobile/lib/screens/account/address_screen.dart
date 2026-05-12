import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../../widgets/primitives.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});
  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AddressProvider>().refresh());
  }

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAddressSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AddressProvider>();
    return Scaffold(
      backgroundColor: VTokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(children: [
                VBackButton(onTap: () => Navigator.maybePop(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery addresses', style: AppTheme.serif(size: 22, letterSpacing: -.3)),
                      Padding(padding: const EdgeInsets.only(top: 1),
                        child: Text('${p.addresses.length} saved', style: const TextStyle(fontSize: 11, color: VTokens.ink3))),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _miniMap(),
                  _addTile(),
                  ..._savedList(p.addresses),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMap() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
    child: Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE0F2FE), Color(0xFFDCFCE7)]),
      ),
      child: Stack(
        children: [
          CustomPaint(painter: _MiniMapPainter(), size: Size.infinite),
          const Positioned(top: 36, left: 90, child: CircleAvatar(radius: 14, backgroundColor: VTokens.green, child: Icon(Icons.home_rounded, color: Colors.white, size: 14))),
          Positioned(bottom: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: VTokens.shadow1),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 12, color: VTokens.green700),
                SizedBox(width: 6),
                Text('Use current location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _addTile() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
    child: GestureDetector(
      onTap: _openAdd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VTokens.green25, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VTokens.green50, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38, alignment: Alignment.center,
            decoration: const BoxDecoration(color: VTokens.green, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a new address', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                SizedBox(height: 1),
                Text('Save once · use anywhere', style: TextStyle(fontSize: 11, color: VTokens.ink2)),
              ],
            ),
          ),
        ]),
      ),
    ),
  );

  List<Widget> _savedList(List<Address> list) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
        child: const Text('SAVED ADDRESSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
      ),
      if (list.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Text('No addresses yet — tap "Add a new address" to get started.', style: TextStyle(color: VTokens.ink3)),
        ),
      for (final a in list) Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: _addressCard(a),
      ),
    ];
  }

  Widget _addressCard(Address a) {
    IconData icon = Icons.home_rounded;
    if (a.icon == 'work') icon = Icons.work_outline_rounded;
    if (a.icon == 'heart') icon = Icons.favorite_border_rounded;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VTokens.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: a.isDefault ? VTokens.green : VTokens.line2, width: a.isDefault ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36, alignment: Alignment.center,
                decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: VTokens.green700, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(a.tag, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 6),
                      if (a.isDefault) const VBadge(label: 'DEFAULT'),
                    ]),
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(a.fullLine, style: const TextStyle(fontSize: 12, color: VTokens.ink2, height: 1.4))),
                    Text('${a.city} ${a.pincode}', style: const TextStyle(fontSize: 12, color: VTokens.ink2, height: 1.4)),
                    if (a.phone != null)
                      Padding(padding: const EdgeInsets.only(top: 6), child: Text(a.phone!, style: const TextStyle(fontSize: 11, color: VTokens.ink3))),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: VTokens.line2)),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 14, color: VTokens.ink2),
                label: const Text('Edit', style: TextStyle(color: VTokens.ink2, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
            Container(width: 1, height: 16, color: VTokens.line2),
            Expanded(
              child: a.isDefault
                ? TextButton.icon(
                    onPressed: () => context.read<AddressProvider>().delete(a.id),
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: VTokens.rose700),
                    label: const Text('Delete', style: TextStyle(color: VTokens.rose700, fontWeight: FontWeight.w800, fontSize: 12)),
                  )
                : TextButton.icon(
                    onPressed: () => context.read<AddressProvider>().setDefault(a.id),
                    icon: const Icon(Icons.flag_outlined, size: 14, color: VTokens.ink2),
                    label: const Text('Set default', style: TextStyle(color: VTokens.ink2, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 10..style = PaintingStyle.stroke;
    final p1 = Path()
      ..moveTo(-20, 100)
      ..quadraticBezierTo(80, 60, 180, 80)
      ..quadraticBezierTo(280, 100, 380, 50);
    canvas.drawPath(p1, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();
  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _tag = TextEditingController(text: 'Home');
  final _line1 = TextEditingController();
  final _city = TextEditingController(text: 'Bangalore');
  final _pin = TextEditingController(text: '560038');
  String _icon = 'home';
  bool _busy = false;

  Future<void> _save() async {
    if (_line1.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await context.read<AddressProvider>().create({
        'tag': _tag.text.trim(),
        'icon': _icon,
        'line1': _line1.text.trim(),
        'city': _city.text.trim(),
        'pincode': _pin.text.trim(),
        'isDefault': true,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        decoration: const BoxDecoration(
          color: VTokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VTokens.line, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 12),
            Text('Add address', style: AppTheme.serif(size: 24, letterSpacing: -.3)),
            const SizedBox(height: 12),
            Row(children: [
              for (final t in ['home', 'work', 'heart']) Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() { _icon = t; _tag.text = t == 'home' ? 'Home' : (t == 'work' ? 'Work' : "Mom's"); }),
                  child: VChip(label: t.toUpperCase(), active: _icon == t),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _field('Address tag', _tag),
            const SizedBox(height: 10),
            _field('Street, building, area', _line1, maxLines: 2),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field('City', _city)),
              const SizedBox(width: 10),
              SizedBox(width: 110, child: _field('Pincode', _pin)),
            ]),
            const SizedBox(height: 16),
            PrimaryBtn(label: _busy ? 'Saving…' : 'Save address', fullWidth: true, onPressed: _busy ? null : _save),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) => TextField(
    controller: c,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: VTokens.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VTokens.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VTokens.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VTokens.green, width: 1.5)),
    ),
  );
}
