import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Renders either a real product image (cached) or, when no image is
/// available, an abstract fruit-color tile that mirrors the design system.
class FruitTile extends StatelessWidget {
  final String kind;
  final double? size;
  final double radius;
  final double blobScale;
  final bool showCaption;
  final String? captionOverride;
  final String? imageUrl;
  final BoxFit fit;

  const FruitTile({
    super.key,
    required this.kind,
    this.size,
    this.radius = 14,
    this.blobScale = .6,
    this.showCaption = false,
    this.captionOverride,
    this.imageUrl,
    this.fit = BoxFit.cover,
  });

  bool get _hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 220),
          placeholder: (_, __) => _AbstractTile(kind: kind, radius: radius, blobScale: blobScale, showCaption: false),
          errorWidget: (_, __, ___) => _AbstractTile(kind: kind, radius: radius, blobScale: blobScale, showCaption: false),
        ),
      );
      if (size != null) return SizedBox(width: size, height: size, child: image);
      return image;
    }

    final tile = _AbstractTile(
      kind: kind, radius: radius, blobScale: blobScale, showCaption: showCaption, captionOverride: captionOverride,
    );
    if (size != null) return SizedBox(width: size, height: size, child: tile);
    return tile;
  }
}

class _AbstractTile extends StatelessWidget {
  final String kind;
  final double radius;
  final double blobScale;
  final bool showCaption;
  final String? captionOverride;
  const _AbstractTile({
    required this.kind, required this.radius, required this.blobScale,
    this.showCaption = false, this.captionOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = fruitFor(kind);
    return LayoutBuilder(
      builder: (ctx, c) {
        final double w = c.maxWidth.isFinite ? c.maxWidth : 64;
        final double blob = w * blobScale;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            color: p.tile,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.5, -0.7),
                        radius: 0.95,
                        colors: [Colors.white.withOpacity(.55), Colors.white.withOpacity(0)],
                        stops: const [0, 0.55],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: blob, height: blob,
                    decoration: BoxDecoration(
                      color: p.blob,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.white.withOpacity(.35), blurRadius: 10, offset: const Offset(2, 3), spreadRadius: -2),
                        BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 14, offset: const Offset(-3, -3), spreadRadius: -2),
                      ],
                    ),
                  ),
                ),
                if (showCaption)
                  Positioned(
                    left: 8, bottom: 6,
                    child: Text(
                      (captionOverride ?? p.caption).toUpperCase(),
                      style: AppTheme.mono(size: 9),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
