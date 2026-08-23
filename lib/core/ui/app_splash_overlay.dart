import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_icon_glyph.dart';

/// The app icon's easter egg: a full-screen title card. The app fades to
/// pure black, then the icon, the name and the codename's meaning settle
/// in one at a time. A tap anywhere (or the back gesture) plays it back
/// out and returns to exactly where it was.
///
/// Built to hold frame rate on a mid-range phone, which rules out the
/// obvious way to write it. Every step is driven off one
/// [AnimationController] through one [AnimatedBuilder], and every
/// animated property is one that costs nothing to change per frame:
///
/// - the backdrop is a plain filled rect whose color alpha changes, not
///   an [Opacity] over a black box;
/// - text fades by animating the alpha of its own color, which never
///   allocates a compositing layer, rather than by [Opacity] or
///   [FadeTransition], which allocate one each;
/// - movement is [Transform.translate] and [Transform.scale], which are
///   paint-time offsets rather than relayouts, so nothing above them is
///   ever laid out again mid-animation;
/// - the divider grows by an x-scale on a fixed-size box, not by
///   animating its width (which would relayout the column every frame);
/// - the icon's fade is handed to its painter, folding into a `saveLayer`
///   it already had to make anyway.
///
/// The net effect is a whole title card that allocates one compositing
/// layer total, and that one was already there before this screen existed.
class AppSplashOverlay extends StatefulWidget {
  const AppSplashOverlay({super.key});

  /// Pushes the title card over whatever is currently on screen. The route
  /// itself is transparent and has no transition of its own; the widget
  /// runs the entire entrance and exit, so it stays in control of the
  /// timing in both directions.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder:
            (BuildContext _, Animation<double> _, Animation<double> _) =>
                const AppSplashOverlay(),
      ),
    );
  }

  @override
  State<AppSplashOverlay> createState() => _AppSplashOverlayState();
}

class _AppSplashOverlayState extends State<AppSplashOverlay>
    with SingleTickerProviderStateMixin {
  // Slower on the way in than on the way out: arriving is the part meant
  // to be watched, leaving is the part meant to get out of the way.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
    reverseDuration: const Duration(milliseconds: 560),
  );

  bool _leaving = false;
  bool _startedEntrance = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedEntrance) {
      return;
    }
    _startedEntrance = true;
    // Honors the system's "remove animations" accessibility setting by
    // presenting the finished card outright instead of a faster version
    // of the same motion.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_leaving) {
      return;
    }
    _leaving = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _controller.reverse();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The back gesture plays the exit rather than cutting to it, the
      // same as a tap does. `_dismiss` is what actually pops.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          _dismiss();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _dismiss,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) =>
                _SplashCard(t: _controller.value),
          ),
        ),
      ),
    );
  }
}

/// Wraps an app icon glyph so tapping it opens [AppSplashOverlay]. A
/// [GestureDetector] rather than an [InkWell], matching how `AphanesTitle`
/// handles its own tap easter egg: a ripple on an odd-shaped glyph reads
/// as a stray rectangle, and neither of these is a control the user is
/// meant to hunt for in the first place.
class SplashTapTarget extends StatelessWidget {
  const SplashTapTarget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'About webOS Dev Mode Manager',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => AppSplashOverlay.show(context),
        child: child,
      ),
    );
  }
}

/// One frame of the title card, laid out from a single 0-1 progress value.
/// Stateless and rebuilt per frame on purpose: at this size, rebuilding
/// this handful of widgets is cheaper than the compositing layers the
/// usual transition widgets would each allocate to avoid it.
class _SplashCard extends StatelessWidget {
  const _SplashCard({required this.t});

  final double t;

  // Where each element starts and finishes, as a fraction of the whole.
  // Overlapping rather than sequential, so the card assembles as one
  // continuous movement instead of a queue of separate ones.
  static const _Step _backdrop = _Step(0, 0.26);
  static const _Step _icon = _Step(0.20, 0.50);
  static const _Step _name = _Step(0.38, 0.62);
  static const _Step _shippedName = _Step(0.46, 0.68);
  static const _Step _rule = _Step(0.58, 0.76);
  static const _Step _greek = _Step(0.66, 0.84);
  static const _Step _meaning = _Step(0.72, 0.90);
  static const _Step _hint = _Step(0.90, 1);

  // The icon's own gradient start, reused so the one accent on the card
  // is visibly the same color the icon is drawn in.
  static const Color _accent = Color(0xFFFB7185);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double backdrop = _backdrop.of(t);

    final Widget card = ColoredBox(
      color: Color.fromRGBO(0, 0, 0, backdrop),
      child: SafeArea(
        child: Stack(
          children: [
            // Well above dead center, not Center: with a footer anchored
            // at the bottom, a perfectly centered block reads as sitting
            // low, and the icon is the thing meant to hold the eye.
            Align(
              alignment: const Alignment(0, -0.66),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Rise(
                    progress: _icon.of(t),
                    // Settles in from slightly small and slightly low, so
                    // it reads as coming to rest rather than appearing
                    // already placed.
                    distance: 10,
                    scaleFrom: 0.86,
                    child: AppIconGlyph(size: 176, opacity: _icon.of(t)),
                  ),
                  const SizedBox(height: 30),
                  _Rise(
                    progress: _name.of(t),
                    child: Text(
                      'Aphanes',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: _fade(Colors.white, _name.of(t)),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Rise(
                    progress: _shippedName.of(t),
                    child: Text(
                      'a webOS Dev Mode Manager',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _fade(Colors.white70, _shippedName.of(t)),
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _GrowingRule(progress: _rule.of(t)),
                  const SizedBox(height: 26),
                  _Rise(
                    progress: _greek.of(t),
                    child: Text(
                      // The codename's own source word. The long-press
                      // easter egg on the app bar title tells this story
                      // in full; this is the short version of it.
                      'ἀφανής',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _fade(_accent, _greek.of(t)),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Rise(
                    progress: _meaning.of(t),
                    child: Text(
                      'unseen · not manifest',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _fade(Colors.white, _meaning.of(t) * 0.55),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                // Last in, and last on the page: the card settles first,
                // then quietly says how to leave it.
                child: Text(
                  'Tap anywhere to return',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _fade(Colors.white, _hint.of(t) * 0.3),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Light system bar icons only once there is enough black behind them
    // to read against. Flipping them at the first frame would put white
    // glyphs on a still-bright app for the length of the fade.
    if (backdrop < 0.6) {
      return card;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: card,
    );
  }

  static Color _fade(Color base, double amount) =>
      base.withValues(alpha: base.a * amount.clamp(0, 1));
}

/// One element's slice of the overall timeline, mapped back onto its own
/// eased 0-1 progress.
class _Step {
  const _Step(this.begin, this.end);

  final double begin;
  final double end;

  double of(double t) {
    final double raw = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }
}

/// Fades a child in by lifting it into place, using only paint-time
/// transforms. The fade itself belongs to the child (its own color alpha,
/// or its painter), so nothing here allocates a compositing layer.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.progress,
    required this.child,
    this.distance = 14,
    this.scaleFrom,
  });

  final double progress;
  final Widget child;
  final double distance;
  final double? scaleFrom;

  @override
  Widget build(BuildContext context) {
    final Widget lifted = Transform.translate(
      offset: Offset(0, distance * (1 - progress)),
      child: child,
    );
    final double? from = scaleFrom;
    if (from == null) {
      return lifted;
    }
    return Transform.scale(scale: from + (1 - from) * progress, child: lifted);
  }
}

/// The hairline between the name and the meaning below it, drawn at full
/// width and scaled in from the center rather than laid out at a changing
/// width, so the column above and below it never moves.
class _GrowingRule extends StatelessWidget {
  const _GrowingRule({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: progress,
      child: const SizedBox(
        width: 64,
        height: 1,
        child: ColoredBox(color: Color.fromRGBO(255, 255, 255, 0.22)),
      ),
    );
  }
}
