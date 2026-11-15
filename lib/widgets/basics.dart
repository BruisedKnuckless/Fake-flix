import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../state/profile_store.dart';
import '../theme.dart';

/// Makes its child press in slightly while a finger is on it.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (mounted && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}

/// A TMDB image that fills its box, grey while loading or missing.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.alignment = Alignment.center, this.fit = BoxFit.cover});
  final String url;
  final Alignment alignment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const blank = ColoredBox(color: AppColors.surface2);
    if (url.isEmpty) return blank;
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => blank,
      errorWidget: (_, _, _) => blank,
    );
  }
}

/// Profile avatar: a coloured tile with a face, or the F logo for guests
/// ([colorIndex] null).
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.colorIndex, this.size = 30, this.radius});

  Avatar.of(Profile? profile, {super.key, this.size = 30, this.radius}) : colorIndex = profile?.avatar;

  final int? colorIndex;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final index = colorIndex;
    final corner = BorderRadius.circular(radius ?? size * 0.2);
    if (index == null) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: corner),
        child: Image.asset('assets/fakeflix-icon.png', fit: BoxFit.contain),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: avatarColors[index.abs() % avatarColors.length], borderRadius: corner),
      child: CustomPaint(painter: _FacePainter()),
    );
  }
}

class _FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final fill = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(s * 0.33, s * 0.39), s * 0.066, fill);
    canvas.drawCircle(Offset(s * 0.67, s * 0.39), s * 0.066, fill);

    final smile = Path()
      ..moveTo(s * 0.27, s * 0.61)
      ..quadraticBezierTo(s * 0.50, s * 0.82, s * 0.73, s * 0.61);
    canvas.drawPath(
      smile,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// White filled button (Play) or outlined grey button.
class WideButton extends StatelessWidget {
  const WideButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.radius = 6,
    this.height = 44,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool filled;
  final double radius;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.black : Colors.white;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Colors.white : const Color(0x6B787878),
          borderRadius: BorderRadius.circular(radius),
          border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: color, size: 26), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Outlined button used on the profile screens and empty states.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onTap, this.solid = false, this.danger = false});
  final String label;
  final VoidCallback onTap;
  final bool solid;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = solid ? Colors.black : (danger ? AppColors.red : AppColors.muted);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: solid ? Colors.white : null,
          border: Border.all(color: solid ? Colors.white : (danger ? AppColors.red : AppColors.dim)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 14, letterSpacing: 0.8, fontWeight: solid ? FontWeight.w700 : FontWeight.w400),
        ),
      ),
    );
  }
}
