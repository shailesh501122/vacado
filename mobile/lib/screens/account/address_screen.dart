import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../../widgets/location_picker.dart';
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

  Future<void> _openAdd() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (picked == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAddressSheet(coords: picked),
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
            child: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a new address', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                SizedBox(height: 1),
                Text('Locate on map → fill in flat / building details', style: TextStyle(fontSize: 11, color: VTokens.ink2)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: VTokens.green700),
        ]),
      ),
    ),
  );

  List<Widget> _savedList(List<Address> list) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
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
                onPressed: () => context.read<AddressProvider>().delete(a.id),
                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: VTokens.rose700),
                label: const Text('Delete', style: TextStyle(color: VTokens.rose700, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
            Container(width: 1, height: 16, color: VTokens.line2),
            Expanded(
              child: a.isDefault
                ? const SizedBox.shrink()
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

// ─── Add-address bottom sheet ────────────────────────────
class _AddAddressSheet extends StatefulWidget {
  final LatLng coords;
  const _AddAddressSheet({required this.coords});
  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController(text: 'Bangalore');
  final _pin = TextEditingController(text: '560038');
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _icon = 'home';
  String _tag = 'Home';
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _busy = true; _error = null; });
    try {
      await context.read<AddressProvider>().create({
        'tag': _tag,
        'icon': _icon,
        'line1': _line1.text.trim(),
        if (_line2.text.trim().isNotEmpty) 'line2': _line2.text.trim(),
        'city': _city.text.trim(),
        'pincode': _pin.text.trim(),
        if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
        'latitude': widget.coords.latitude,
        'longitude': widget.coords.longitude,
        'isDefault': true,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', '').replaceFirst('ApiException(', '').replaceAll(')', ''));
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VTokens.line, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 12),
              Text('Add address', style: AppTheme.serif(size: 24, letterSpacing: -.3)),
              const SizedBox(height: 4),
              Text(
                '${widget.coords.latitude.toStringAsFixed(5)}, ${widget.coords.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 11, color: VTokens.ink3, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in const [
                  ['home',  'HOME',  'Home'],
                  ['work',  'WORK',  'Work'],
                  ['heart', 'OTHER', 'Other'],
                ])
                  GestureDetector(
                    onTap: () => setState(() { _icon = t[0]; _tag = t[2]; }),
                    child: VChip(label: t[1], active: _icon == t[0]),
                  ),
              ]),
              const SizedBox(height: 14),
              _field('Flat / House / Building', _line1, required: true, maxLines: 2),
              const SizedBox(height: 10),
              _field('Floor / Landmark (optional)', _line2),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field('City', _city, required: true)),
                const SizedBox(width: 10),
                SizedBox(width: 120, child: _field('Pincode', _pin, required: true)),
              ]),
              const SizedBox(height: 10),
              _field('Phone (optional)', _phone),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: VTokens.rose700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: VTokens.rose700, fontSize: 12))),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryBtn(label: _busy ? 'Saving…' : 'Save address', fullWidth: true, onPressed: _busy ? null : _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1, bool required = false}) => TextFormField(
    controller: c,
    maxLines: maxLines,
    validator: required ? (v) {
      final s = (v ?? '').trim();
      if (label.startsWith('City') && s.length < 2) return 'Enter city';
      if (label.startsWith('Pincode') && s.length < 3) return 'Enter a valid pincode';
      if (s.isEmpty) return 'Required';
      if (label.startsWith('Flat') && s.length < 3) return 'Add a bit more detail';
      return null;
    } : null,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: VTokens.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VTokens.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VTokens.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: VTokens.green, width: 1.5)),
    ),
  );
}
