import 'package:flutter/material.dart';
import '../core/offline/brick_image_provider.dart';
import '../theme/app_theme.dart';

/// Branded primitive widgets — the **LEGO "Build Together" clone** kit (Redesign
/// V1). Two surface treatments carry the whole look:
///
/// - [BrickSurface] — a raised "brick plate" that clicks down when pressed. Used
///   for every button / action tile / FAB (the yellow hero CTAs, the squircle
///   action buttons). This is the LEGO 3D-button motif.
/// - [SoftCard] (and [AppCard]) — a crisp white card floating on a soft blue
///   shadow. Used for list rows, info panels, settings groups.
///
/// Colours resolve through `BrickColors.of(context)` so everything renders
/// correctly in light **and** dark with no per-call-site branching.

// ── BrickSurface (the raised plate) ──────────────────────────────────────────

/// A raised brick plate: a rounded face sitting [depth] points above a darker
/// [edge] lip. When [pressed], the face travels down onto its lip while overall
/// height stays constant so layout never shifts.
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
  final Color? stroke;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
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

/// Scale-on-press wrapper (thumbnails, icon taps). No-op when [onTap] is null.
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

/// A brick-plate button that clicks down when pressed. `ghost` skips the plate.
class _BrickButton extends StatefulWidget {
  const _BrickButton({
    required this.child,
    required this.fill,
    required this.edge,
    this.radius = AppRadius.button,
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

/// primary = bright-blue confirm, hero = the yellow "go" CTA (Start Building /
/// Join party), secondary = white, ghost = flat text.
enum AppButtonVariant { primary, hero, secondary, ghost }

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
    final (fill, edge, fg, stroke, depth) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.primaryEdge, c.onPrimary, null, AppDepth.cta),
      AppButtonVariant.hero => (c.accent, c.accentEdge, c.onAccent, null, AppDepth.cta),
      AppButtonVariant.secondary => (c.card, c.cardEdge, c.ink, c.line, AppDepth.tile),
      AppButtonVariant.ghost => (c.card, c.cardEdge, c.ink, null, AppDepth.tile),
    };
    final isGhost = variant == AppButtonVariant.ghost;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20, vertical: AppSpacing.s16),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.title.copyWith(color: fg, fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );

    return _BrickButton(
      fill: fill,
      edge: edge,
      radius: AppRadius.lg,
      depth: depth,
      stroke: stroke,
      ghost: isGhost,
      onTap: loading ? null : onPressed,
      child: content,
    );
  }
}

/// A rounded-square (squircle-ish) action button — the reference's top-corner
/// controls (back / filter / owned-check) and the search FAB. A raised brick
/// tile that clicks down. Pass [child] to override the centred [icon].
class SquircleButton extends StatelessWidget {
  const SquircleButton({
    super.key,
    this.icon,
    this.child,
    required this.onTap,
    this.fill,
    this.edge,
    this.fg,
    this.stroke,
    this.size = 56,
    this.iconSize = 24,
    this.semanticLabel,
  });

  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final Color? fill;
  final Color? edge;
  final Color? fg;
  final Color? stroke;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: _BrickButton(
        fill: fill ?? c.card,
        edge: edge ?? c.cardEdge,
        radius: AppRadius.button,
        depth: AppDepth.tile,
        stroke: stroke,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: child ?? Icon(icon, size: iconSize, color: fg ?? c.ink),
          ),
        ),
      ),
    );
  }
}

// ── Soft card (white, floating on a soft blue shadow) ────────────────────────

/// The crisp white card that floats over the pale-blue page — the reference's
/// list rows, info panels, settings groups. `onTap` adds a scale-press.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.radius = AppRadius.card,
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, child: box);
  }
}

/// Kept name for existing call sites — now a soft white card.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
      onTap: onTap,
      child: child,
    );
  }
}

/// A pill badge. `filled` paints a solid colour with white text (the reference's
/// RETIRED chip); the default is a soft tinted chip.
class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key, this.color, this.filled = false});
  final String text;
  final Color? color;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final c = color ?? BrickColors.of(context).inkSoft;
    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(
          text,
          style: AppText.label.copyWith(color: Colors.white, letterSpacing: 0.6),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(color: c, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// A centered bold section title — the reference's "Account" / "Language" /
/// "Legal" dividers.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.align = TextAlign.center});
  final String text;
  final TextAlign align;
  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Text(text, style: AppText.h2.copyWith(color: c.ink), textAlign: align);
  }
}

/// An icon → label → value cell for the set-detail stats row (Pieces / Year / …).
class StatCell extends StatelessWidget {
  const StatCell({super.key, required this.icon, required this.label, required this.value, this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return Semantics(
      container: true,
      label: '$label $value',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color ?? c.ink),
            const SizedBox(height: AppSpacing.s8),
            Text(label, style: AppText.caption.copyWith(color: c.inkSoft)),
            const SizedBox(height: 2),
            Text(value, style: AppText.title.copyWith(color: c.ink, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// A LEGO-stud toggle — a rounded track with a chunky yellow stud thumb when on.
class BrickToggle extends StatelessWidget {
  const BrickToggle({super.key, required this.value, required this.onChanged, this.semanticLabel});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    const w = 58.0, h = 34.0, thumb = 26.0;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: Motion.gate(context, Motion.pressDuration),
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: value ? c.accent.withValues(alpha: 0.30) : c.faint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: value ? c.accentEdge : c.line),
          ),
          child: AnimatedAlign(
            duration: Motion.gate(context, Motion.pressDuration),
            curve: Motion.pressCurve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: thumb,
                height: thumb,
                decoration: BoxDecoration(
                  color: value ? c.accent : c.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: value ? c.accentEdge : c.line, width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (value ? c.accentEdge : c.muted).withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Collapsing header (profile + set details) ────────────────────────────────

/// A `SliverPersistentHeaderDelegate` that hands its [builder] the collapse
/// progress `t` (0 = fully expanded, 1 = collapsed) so a screen can crossfade /
/// shrink its own header content as the list scrolls under it. Pinned.
class CollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  CollapsingHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.builder,
  });

  @override
  final double minExtent;
  @override
  final double maxExtent;

  /// `(context, t)` where t ∈ [0,1]; 0 expanded, 1 collapsed.
  final Widget Function(BuildContext context, double t) builder;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = (maxExtent - minExtent);
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    return SizedBox.expand(child: builder(context, t));
  }

  @override
  bool shouldRebuild(CollapsingHeaderDelegate old) =>
      old.minExtent != minExtent || old.maxExtent != maxExtent || old.builder != builder;
}

// ── Legacy simple header (secondary screens) ─────────────────────────────────

/// A plain page header used by the deeper screens (parts, minifigs, rebuild,
/// review, paywall, invite). A white squircle back button + a heavy title.
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
              padding: const EdgeInsets.only(right: AppSpacing.s12),
              child: SquircleButton(
                icon: Icons.arrow_back_rounded,
                size: 44,
                iconSize: 22,
                onTap: onBack,
                semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
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
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.brand.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: c.brand),
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

/// Linear progress bar — blue-in-motion fill, green when complete.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.track,
    this.tint,
  });
  final double value; // 0..1
  final double height;
  final Color? track;
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
    final arc = tint ?? (v >= 1.0 ? c.success : c.info);
    final trackColor = track ?? c.faint;
    final label = textColor ?? c.ink;
    return SizedBox(
      width: size,
      height: size,
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
                fontWeight: FontWeight.w800,
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
/// falling back to a branded placeholder box. The byte path routes through
/// [BrickImageProvider] (disk-first offline store).
class SetThumb extends StatelessWidget {
  const SetThumb(
      {super.key, this.imageUrl, this.size = 56, this.label, this.radius = AppRadius.md, this.background});
  final String? imageUrl;
  final double size;
  final String? label;
  final double radius;
  final Color? background;

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
    return ClipRRect(
      borderRadius: shape,
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null
            ? _placeholder(c)
            : ColoredBox(
                color: background ?? c.card,
                child: Image(
                  image: BrickImageProvider(imageUrl!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _placeholder(c),
                ),
              ),
      ),
    );
  }
}

/// Branded search field — a soft white rounded field. The magnifier is the
/// separate FAB in the reference, so the leading icon is off by default.
class SearchField extends StatelessWidget {
  const SearchField(
      {super.key,
      this.hint = 'Search…',
      this.controller,
      this.onChanged,
      this.autofocus = false,
      this.showLeadingIcon = false});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool showLeadingIcon;
  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: c.shadow.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Row(
          children: [
            if (showLeadingIcon) ...[
              Icon(Icons.search, size: 20, color: c.muted),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: autofocus,
                style: AppText.title.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                cursorColor: c.primary,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.title.copyWith(color: c.muted, fontWeight: FontWeight.w600),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app wordmark — chunky white lettering on the brand-blue header.
class BrickBackWordmark extends StatelessWidget {
  const BrickBackWordmark({super.key, this.size = 30, this.color = Colors.white});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Text(
      'BrickBack',
      maxLines: 1,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 0.5,
        height: 1.0,
      ),
    );
  }
}
