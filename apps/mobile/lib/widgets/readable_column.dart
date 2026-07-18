import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The single source of truth for the phone/tablet layout split (F3). ~640 logical
/// px is the natural tablet threshold and mirrors the Swift `.regular`/`.compact`
/// intent: an iPhone (portrait-locked) never reaches it, an iPad full-screen (820 in
/// portrait, 1180 in landscape) always clears it, and an iPad squeezed into a narrow
/// Split View correctly falls back to the compact width. Used by the readable-column
/// clamp and the counting grid (bigger tiles on wide widths).
const double kWideLayoutBreakpoint = 640;

extension AdaptiveLayout on BuildContext {
  /// True at tablet / regular widths. Drives the raised counting-grid tile floor.
  /// Read off `MediaQuery` so it tracks orientation and iPad multitasking live.
  bool get isWideLayout =>
      MediaQuery.sizeOf(this).width >= kWideLayoutBreakpoint;
}

/// Caps a stretchy content column at [AppLayout.readableWidth] (620) and centres
/// it — the Flutter port of the Swift `.readableColumn()`. The fix for "labels
/// stranded 800pt from their values" on a wide iPad.
///
/// **A true no-op below the cap.** On the phone the incoming width is < 620, so the
/// child is returned verbatim with no wrapper inserted — the compact shell stays
/// pixel-identical to F2. On a wide detail pane the child is given a *tight* 620pt
/// width and centred, which behaves correctly for a `Column(stretch)`, a `ListView`
/// or a `CustomScrollView` alike (a loose `ConstrainedBox` would let a stretch
/// column shrink-wrap instead of filling the readable width).
class ReadableColumn extends StatelessWidget {
  const ReadableColumn({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.readableWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return Center(
          child: SizedBox(width: maxWidth, child: child),
        );
      },
    );
  }
}
