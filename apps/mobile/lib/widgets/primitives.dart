import 'package:flutter/material.dart';
import '../core/offline/brick_image_provider.dart';
import '../theme/app_theme.dart';

/// Branded primitive widgets (F2) — a Flutter port of the Swift oracle
/// `apps/ios/BrickBack/DesignSystem/Primitives/Primitives.swift`. Token-driven,
/// no Material chrome. The public API is unchanged from the wireframe versions —
/// this pass swaps their internals for the LEGO-toy identity: every interactive
/// surface is a **brick plate** ([BrickSurface]) that sits raised on a darker
/// bottom lip and clicks down when pressed.
///
/// Colors resolve through `BrickColors.of(context)` so the primitives render
/// correctly in light **and** dark with no per-call-site branching.

// ── BrickSurface (the signature) ────────────────────────────────────────────

/// A raised "brick plate": a rounded face sitting [depth] points above a darker
/// [edge] lip — the app's core surface treatment. When [pressed], the face
/// travels down onto its lip (the satisfying "click into place"), while the
/// overall height stays constant so layout never shifts.
class BrickSurface extends StatelessWidget {
  const BrickSurface({
    super.key,
    required this.child,
    required this.fill,
    required this.edge,
    this.radius = AppRadius.lg,
    this.depth = AppDepth.brick,
    this.pressed = false,
    this.stroke,
  });

  final Widget child;
  final Color fill;
  final Color edge;
  final double radius;
  final double depth;
  final bool pressed;
  final Color? stroke; // optional hairline around the face

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      // The lip: full height, stays put.
      decoration: BoxDecoration(color: edge, borderRadius: shape),
      child: Padding(
        padding: EdgeInsets.only(bottom: depth),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: pressed ? depth : 0),
          duration: Motion.gate(context, Motion.pressDuration),
          curve: Motion.pressCurve,
          builder: (context, dy, face) =>
              Transform.translate(offset: Offset(0, dy), child: face),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: shape,
              border: stroke == null ? null : Border.all(color: stroke!),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Scale-on-press wrapper (kept for content that isn't a brick — thumbnails,
/// icon taps). No-op (plain child) when [onTap] is null.
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
        duration: Motion.pressDuration,
        child: widget.child,
      ),
    );
  }
}

/// A brick-plate button that clicks down when pressed. `ghost` skips the plate
/// and just dims. Drives the press state for its [BrickSurface].
class _BrickButton extends StatefulWidget {
  const _BrickButton({
    required this.child,
    required this.fill,
    required this.edge,
    this.radius = AppRadius.md,
    this.depth = AppDepth.tile,
    this.stroke,
    this.ghost = false,
    this.onTap,
  });
  final Widget child;
  final Color fill;
  final Color edge;
  final double radius;
  final double depth;
  final Color? stroke;
  final bool ghost;
  final VoidCallback? onTap;

  @override
  State<_BrickButton> createState() => _BrickButtonState();
}

class _BrickButtonState extends State<_BrickButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: widget.ghost
          ? AnimatedOpacity(
              opacity: _pressed ? 0.55 : 1,
              duration: Motion.pressDuration,
              child: widget.child,
            )
          : BrickSurface(
              fill: widget.fill,
              edge: widget.edge,
              radius: widget.radius,
              depth: widget.depth,
              stroke: widget.stroke,
              pressed: _pressed,
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
    final c = BrickColors.of(context);
    final isPrimary = variant == AppButtonVariant.primary;
    final isGhost = variant == AppButtonVariant.ghost;
    final fill = isPrimary ? c.primary : c.card;
    final edge = isPrimary ? c.primaryEdge : c.cardEdge;
    final stroke = (isPrimary || isGhost) ? null : c.line;
    final fg = isPrimary ? c.onPrimary : c.ink;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20, vertical: AppSpacing.s12),
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
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.label.copyWith(color: fg)),
          ],
        ],
      ),
    );

    return _BrickButton(
      fill: fill,
      edge: edge,
      radius: AppRadius.md,
      stroke: stroke,
      ghost: isGhost,
      onTap: loading ? null : onPressed,
      child: content,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final body = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
      child: child,
    );
    if (onTap == null) {
      return BrickSurface(
        fill: c.card,
        edge: c.cardEdge,
        radius: AppRadius.lg,
        depth: AppDepth.brick,
        stroke: c.line,
        child: body,
      );
    }
    return _BrickButton(
      fill: c.card,
      edge: c.cardEdge,
      radius: AppRadius.lg,
      depth: AppDepth.brick,
      stroke: c.line,
      onTap: onTap,
      child: body,
    );
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? BrickColors.of(context).inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
            color: c, fontSize: 11, fontWeight: FontWeight.w700),
      ),
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
    final c = BrickColors.of(context);
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
                child: Icon(Icons.arrow_back, color: c.ink),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h1.copyWith(color: c.ink)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: AppText.caption.copyWith(color: c.inkSoft)),
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
    final c = BrickColors.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon on a soft brand-tinted round plate — the empty state's one
              // spot of colour.
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: c.brandDeep),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(title,
                  style: AppText.h2.copyWith(color: c.ink),
                  textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(message!,
                    style: AppText.body.copyWith(color: c.inkSoft),
                    textAlign: TextAlign.center),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.s24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Linear progress bar — warm track, blue-in-motion fill, green when complete.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.track,
    this.tint,
  });
  final double value; // 0..1
  final double height;

  /// The unfilled track. Defaults to the warm skeleton fill.
  final Color? track;

  /// The filled portion. `null` auto-picks green when complete, else blue-in-motion.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final v = value.clamp(0.0, 1.0);
    final fill = tint ?? (v >= 1.0 ? c.success : c.info);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track ?? c.faint)),
            // Sweep the fill as the count changes (instant under Reduce Motion).
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: v),
              duration: Motion.gate(context, Motion.progressDuration),
              curve: Motion.progressCurve,
              builder: (context, t, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: t <= 0 ? 0.0 : t,
                  child: ColoredBox(color: fill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress ring with a centered percent label.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 44,
    this.stroke = 5,
    this.track,
    this.tint,
    this.textColor,
  });
  final double value; // 0..1
  final double size;
  final double stroke;
  final Color? track;
  final Color? tint;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final v = value.clamp(0.0, 1.0);
    final arc = tint ?? (v >= 1.0 ? c.success : c.info); // colour from target
    final trackColor = track ?? c.faint;
    final label = textColor ?? c.ink;
    return SizedBox(
      width: size,
      height: size,
      // Sweep the arc + roll the label as progress changes (instant under Reduce Motion).
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: v),
        duration: Motion.gate(context, Motion.progressDuration),
        curve: Motion.progressCurve,
        builder: (context, t, _) => CustomPaint(
          painter: _RingPainter(t, stroke, trackColor, arc),
          child: Center(
            child: Text(
              '${(t * 100).round()}%',
              style: AppText.label.copyWith(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w700,
                color: label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.trackColor, this.fillColor);
  final double value;
  final double stroke;
  final Color trackColor;
  final Color fillColor;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fill = Paint()
      ..color = fillColor
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
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.stroke != stroke ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor;
}

/// Square catalog thumbnail. Renders the real image when [imageUrl] is set,
/// falling back to a branded placeholder box on null or load failure.
///
/// **F4:** the byte-loading path routes through [BrickImageProvider] — a
/// disk-first provider backed by the durable offline store (store, then
/// network with write-through). Once a set's images are prefetched they render
/// with no network. Only the fetch seam changed here; the F2 chrome (radius,
/// stroke, placeholder, hairline) is untouched.
class SetThumb extends StatelessWidget {
  const SetThumb(
      {super.key, this.imageUrl, this.size = 56, this.label, this.radius = AppRadius.md});
  final String? imageUrl;
  final double size;
  final String? label;
  final double radius;

  Widget _placeholder(BrickColors c) => Container(
        width: size,
        height: size,
        color: c.faint,
        alignment: Alignment.center,
        child: Icon(Icons.widgets_outlined, size: size * 0.34, color: c.muted),
      );

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final shape = BorderRadius.circular(radius);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: shape,
          child: SizedBox(
            width: size,
            height: size,
            child: imageUrl == null
                ? _placeholder(c)
                : ColoredBox(
                    color: c.card,
                    child: Image(
                      image: BrickImageProvider(imageUrl!),
                      fit: BoxFit.contain,
                      // Fade nothing in on a synchronous disk hit; still smooth
                      // for a network load. Placeholder on decode/network error.
                      errorBuilder: (_, _, _) => _placeholder(c),
                    ),
                  ),
          ),
        ),
        // Hairline that defines the plate on cream.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: shape,
                border: Border.all(color: c.line),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Branded search field — a brick plate with a magnifier + clearable field.
class SearchField extends StatelessWidget {
  const SearchField(
      {super.key,
      this.hint = 'Search…',
      this.controller,
      this.onChanged,
      this.autofocus = false});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return BrickSurface(
      fill: c.card,
      edge: c.cardEdge,
      radius: AppRadius.md,
      depth: AppDepth.tile,
      stroke: c.line,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: c.muted),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: autofocus,
                style: AppText.body.copyWith(color: c.ink),
                cursorColor: c.primary,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.body.copyWith(color: c.muted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app wordmark — chunky white lettering (only the two B's capitalised),
/// sized to sit on the brand-blue header.
class BrickBackWordmark extends StatelessWidget {
  const BrickBackWordmark({super.key, this.size = 30});
  final double size;
  @override
  Widget build(BuildContext context) {
    return Text(
      'BrickBack',
      maxLines: 1,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.5,
        height: 1.0,
      ),
    );
  }
}
