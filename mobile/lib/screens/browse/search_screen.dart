import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/back_button.dart';
import '../../widgets/fruit_tile.dart';
import '../../widgets/primitives.dart';
import '../product/product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<Product> _results = [];
  List<String> _trending = const [];
  final List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    // Fetch trending from the backend on open so the chips reflect real data.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final r = await context.read<CatalogProvider>().search('a');
        if (!mounted) return;
        setState(() => _trending = (r['trending'] as List<String>));
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().isEmpty) {
        if (mounted) setState(() => _results = []);
        return;
      }
      final r = await context.read<CatalogProvider>().search(q.trim());
      if (!mounted) return;
      setState(() {
        _results = (r['products'] as List<Product>);
        _trending = (r['trending'] as List<String>);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 64),
                children: [
                  if (_results.isNotEmpty) _suggestions(_results) else _emptyState(),
                  const SizedBox(height: 20),
                  _trendingChips(),
                  const SizedBox(height: 20),
                  _recentList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Row(children: [
      VBackButton(onTap: () => Navigator.maybePop(context)),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: VTokens.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VTokens.line),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 16, color: VTokens.ink3),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'Search Vacado…',
                  hintStyle: TextStyle(color: VTokens.ink3, fontSize: 14),
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VTokens.ink),
              ),
            ),
            if (_ctrl.text.isNotEmpty)
              GestureDetector(
                onTap: () { _ctrl.clear(); _onChanged(''); },
                child: Container(
                  width: 22, height: 22, alignment: Alignment.center,
                  decoration: const BoxDecoration(color: VTokens.green25, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 14, color: VTokens.green700),
                ),
              ),
            const SizedBox(width: 10),
            Container(width: 1, height: 18, color: VTokens.line),
            const SizedBox(width: 8),
            const Icon(Icons.mic_none_rounded, size: 18, color: VTokens.green700),
          ]),
        ),
      ),
    ]),
  );

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: VTokens.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: VTokens.line2)),
      child: const Row(children: [
        Icon(Icons.tune_rounded, color: VTokens.ink2),
        SizedBox(width: 10),
        Expanded(child: Text('Try "Alphonso mango", "organic", or "under 99"', style: TextStyle(fontSize: 13, color: VTokens.ink2))),
      ]),
    ),
  );

  Widget _suggestions(List<Product> list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('SUGGESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
          ),
          ...List.generate(list.length > 6 ? 6 : list.length, (i) {
            final p = list[i];
            return InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(slug: p.slug))),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: VTokens.line2, width: i == list.length - 1 ? 0 : 1))),
                child: Row(children: [
                  FruitTile(kind: p.fruitKind, size: 36, radius: 10, blobScale: .7),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: VTokens.ink)),
                        const SizedBox(height: 2),
                        Text('${p.weightLabel} · ₹${p.priceRupees}', style: const TextStyle(fontSize: 11, color: VTokens.ink3)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: VTokens.ink3, size: 18),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _trendingChips() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TRENDING NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _trending.map((t) => VChip(label: t)).toList()),
      ],
    ),
  );

  Widget _recentList() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('RECENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
            Text('Clear all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.green700)),
          ],
        ),
        ..._recent.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: VTokens.line2, shape: BoxShape.circle),
              child: const Icon(Icons.schedule_rounded, size: 14, color: VTokens.ink3),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(r, style: const TextStyle(fontSize: 13.5, color: VTokens.ink2, fontWeight: FontWeight.w500))),
            const Icon(Icons.north_west_rounded, size: 16, color: VTokens.ink3),
          ]),
        )),
      ],
    ),
  );
}
