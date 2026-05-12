import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final Color? color;

  const PrimaryBtn({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = false,
    this.height = 52,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: color ?? VTokens.green,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: (color ?? VTokens.green).withOpacity(.55), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -8),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -.1)),
            ],
          ),
        ),
      ),
    );
    if (fullWidth) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}

class GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  const GhostBtn({super.key, required this.label, this.onPressed, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: VTokens.line, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        foregroundColor: VTokens.ink,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
    if (fullWidth) return SizedBox(width: double.infinity, child: btn);
    return btn;
  }
}

class VChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? dot;
  final IconData? icon;
  final VoidCallback? onTap;

  const VChip({super.key, required this.label, this.active = false, this.dot, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? VTokens.ink : VTokens.surface,
          border: Border.all(color: active ? VTokens.ink : VTokens.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: active ? Colors.white : VTokens.ink2), const SizedBox(width: 4)],
            if (dot != null) ...[Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? Colors.white : VTokens.ink2)),
          ],
        ),
      ),
    );
  }
}

class VBadge extends StatelessWidget {
  final String label;
  final String tone;
  final EdgeInsetsGeometry? padding;
  const VBadge({super.key, required this.label, this.tone = 'green', this.padding});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (tone) {
      case 'orange': bg = VTokens.orange50; fg = const Color(0xFFB65419); break;
      case 'dark':   bg = VTokens.ink; fg = Colors.white; break;
      case 'white':  bg = Colors.white; fg = VTokens.ink; break;
      default:       bg = VTokens.green50; fg = VTokens.green700;
    }
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .3),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool large;
  const QtyStepper({super.key, required this.qty, this.onDecrement, this.onIncrement, this.large = false});

  @override
  Widget build(BuildContext context) {
    final h = large ? 36.0 : 28.0;
    final fs = large ? 14.0 : 12.0;
    return Container(
      height: h,
      decoration: BoxDecoration(color: VTokens.green, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onDecrement, h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('$qty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: fs)),
          ),
          _btn(Icons.add, onIncrement, h),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? on, double h) => InkWell(
    onTap: on,
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(width: h - 4, height: h - 4, child: Icon(icon, size: 14, color: Colors.white)),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? link;
  final VoidCallback? onTap;
  const SectionHeader({super.key, required this.title, this.subtitle, this.link, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  fontFamily: 'serif', fontStyle: FontStyle.italic,
                  fontSize: 22, letterSpacing: -.3, height: 1, color: VTokens.ink,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(subtitle!, style: const TextStyle(fontSize: 11.5, color: VTokens.ink3, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
        if (link != null)
          GestureDetector(
            onTap: onTap,
            child: Text(link!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: VTokens.green700)),
          ),
      ],
    );
  }
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Color? bg;
  final VoidCallback? onTap;
  const IconBox({super.key, required this.icon, this.size = 38, this.color, this.bg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: bg ?? VTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VTokens.line),
        ),
        child: Icon(icon, color: color ?? VTokens.ink, size: 18),
      ),
    );
  }
}
