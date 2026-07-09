import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wireframe primitive widgets. Token-driven, no Material chrome. Re-skinned to
/// the brand in Phase 9 without changing their public API.

/// Scale-on-press wrapper (replaces InkWell; no splash).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AppButtonVariant.primary;
    final isGhost = variant == AppButtonVariant.ghost;
    final bg = isPrimary
        ? AppColors.primary
        : isGhost
            ? Colors.transparent
            : AppColors.card;
    final fg = isPrimary ? AppColors.onPrimary : AppColors.ink;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20, vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isGhost ? null : Border.all(color: isPrimary ? AppColors.primary : AppColors.line),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else ...[
            if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
            Text(label, style: AppText.label.copyWith(color: fg)),
          ],
        ],
      ),
    );
    return Pressable(onTap: loading ? null : onPressed, child: child);
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: AppText.caption.copyWith(color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader(this.title, {super.key, this.subtitle, this.trailing, this.onBack});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: Pressable(
                onTap: onBack,
                child: const Icon(Icons.arrow_back, color: AppColors.ink),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h1),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: AppText.caption),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.muted),
            const SizedBox(height: AppSpacing.s16),
            Text(title, style: AppText.title, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(message!, style: AppText.caption, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: AppSpacing.s20), action!],
          ],
        ),
      ),
    );
  }
}

/// Linear progress bar (wireframe: hairline track + ink fill).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.height = 8});
  final double value; // 0..1
  final double height;
  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: height,
        color: AppColors.faint,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v == 0 ? 0.0001 : v,
            child: Container(color: v >= 1.0 ? AppColors.success : AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Circular progress ring with a centered percent label (CustomPaint).
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 44, this.stroke = 5});
  final double value; // 0..1
  final double size;
  final double stroke;
  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(v, stroke),
        child: Center(
          child: Text('${(v * 100).round()}%',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke);
  final double value;
  final double stroke;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = AppColors.faint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fill = Paint()
      ..color = value >= 1.0 ? AppColors.success : AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * value,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.stroke != stroke;
}

/// Square catalog thumbnail. Renders the real image (cached) when [imageUrl] is
/// set, falling back to a wireframe placeholder box on null or load failure.
class SetThumb extends StatelessWidget {
  const SetThumb({super.key, this.imageUrl, this.size = 56, this.label, this.radius = AppRadius.md});
  final String? imageUrl;
  final double size;
  final String? label;
  final double radius;

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: AppColors.faint,
        alignment: Alignment.center,
        child: Text(label ?? '[img]', style: AppText.caption.copyWith(color: AppColors.muted)),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null
            ? _placeholder()
            : ColoredBox(
                color: AppColors.card,
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => _placeholder(),
                ),
              ),
      ),
    );
  }
}

/// Minimal wireframe search field.
class SearchField extends StatelessWidget {
  const SearchField({super.key, this.hint = 'Search…', this.controller, this.onChanged, this.autofocus = false});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              style: AppText.body,
              cursorColor: AppColors.ink,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.body.copyWith(color: AppColors.muted),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
