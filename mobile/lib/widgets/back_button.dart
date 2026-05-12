import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class VBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool floating;
  const VBackButton({super.key, this.onTap, this.floating = false});

  @override
  Widget build(BuildContext context) {
    final bg = floating ? Colors.white.withOpacity(.92) : VTokens.surface;
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: floating ? Colors.transparent : VTokens.line),
          boxShadow: floating ? VTokens.shadow1 : null,
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: VTokens.ink),
      ),
    );
  }
}
