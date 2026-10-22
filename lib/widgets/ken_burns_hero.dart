import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Auto-rotating hero banner with a Ken Burns moving animation on each
/// panoramic image. The image slowly zooms and pans while it is visible,
/// then cross-fades to the next image in the list. Captions fade in/out
/// in sync with the image.
///
/// Each image asset is expected to depict MULTIPLE library aspects
/// (interior + students + books + librarian), so the user sees the whole
/// library ecosystem in motion across the top of the dashboard.
class KenBurnsHero extends StatefulWidget {
  /// List of panoramic image asset paths to cycle through.
  final List<String> imagePaths;

  /// Title line shown over each image (paired 1:1 with [imagePaths]).
  final List<String>? titles;

  /// Subtitle line shown over each image (paired 1:1 with [imagePaths]).
  final List<String>? subtitles;

  /// How long each image stays before cross-fading (default 7s).
  final Duration perImage;

  /// Cross-fade duration (default 1.2s).
  final Duration fadeDuration;

  /// Hero height in logical pixels.
  final double height;

  /// Optional tap handler.
  final VoidCallback? onTap;

  const KenBurnsHero({
    super.key,
    required this.imagePaths,
    this.titles,
    this.subtitles,
    this.perImage = const Duration(seconds: 7),
    this.fadeDuration = const Duration(milliseconds: 1200),
    this.height = 260,
    this.onTap,
  });

  @override
  State<KenBurnsHero> createState() => _KenBurnsHeroState();
}

class _KenBurnsHeroState extends State<KenBurnsHero>
    with TickerProviderStateMixin {
  late final AnimationController _kenBurns;
  late final AnimationController _crossfade;
  late final AnimationController _captionFade;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(
      vsync: this,
      duration: widget.perImage,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advance();
        }
      });

    _crossfade = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
      value: 1.0, // current image fully visible
    );

    _captionFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0,
    );

    // Kick off the animation loop after the first frame so layout is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _kenBurns.forward();
    });
  }

  void _advance() {
    if (!mounted) return;
    final next = (_currentIndex + 1) % widget.imagePaths.length;
    // Fade out the current image + caption
    _crossfade.reverse();
    _captionFade.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentIndex = next);
      // Reset and restart Ken Burns for the new image
      _kenBurns
        ..reset()
        ..forward();
      // Fade the new image in, then bring the caption back
      _crossfade.forward();
      _captionFade.forward();
    });
  }

  @override
  void dispose() {
    _kenBurns.dispose();
    _crossfade.dispose();
    _captionFade.dispose();
    super.dispose();
  }

  // Tween sequence for the Ken Burns effect — slow zoom + slow pan.
  // The image scales from 1.0 → 1.18 (gentle zoom) while also translating
  // along a diagonal so it appears to glide. Different directions per index
  // so consecutive images don't pan in the same direction.
  Tween<double> _scaleForIndex(int i) {
    // Alternate between starting smaller / larger for variety.
    return i.isEven
        ? Tween(begin: 1.05, end: 1.22)
        : Tween(begin: 1.22, end: 1.05);
  }

  Tween<Offset> _panForIndex(int i) {
    // Different diagonal per index — 4 different directions cycle.
    switch (i % 4) {
      case 0:
        return Tween(
          begin: const Offset(-12, -8),
          end: const Offset(12, 8),
        );
      case 1:
        return Tween(
          begin: const Offset(12, -8),
          end: const Offset(-12, 8),
        );
      case 2:
        return Tween(
          begin: const Offset(-12, 8),
          end: const Offset(12, -8),
        );
      default:
        return Tween(
          begin: const Offset(12, 8),
          end: const Offset(-12, -8),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) {
      return SizedBox(height: widget.height);
    }

    final path = widget.imagePaths[_currentIndex];
    final scaleAnim = _scaleForIndex(_currentIndex).animate(
      CurvedAnimation(parent: _kenBurns, curve: Curves.easeInOut),
    );
    final panAnim = _panForIndex(_currentIndex).animate(
      CurvedAnimation(parent: _kenBurns, curve: Curves.easeInOut),
    );
    final fadeAnim = CurvedAnimation(parent: _crossfade, curve: Curves.easeOut);
    final captionAnim =
        CurvedAnimation(parent: _captionFade, curve: Curves.easeOut);

    final hasTitle = widget.titles != null &&
        _currentIndex < widget.titles!.length;
    final hasSub = widget.subtitles != null &&
        _currentIndex < widget.subtitles!.length;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          color: AppTheme.primaryDark,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Animated image (Ken Burns: zoom + pan)
              AnimatedBuilder(
                animation: Listenable.merge([_kenBurns, _crossfade]),
                builder: (context, child) {
                  return Opacity(
                    opacity: fadeAnim.value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: panAnim.value,
                      child: Transform.scale(
                        scale: scaleAnim.value,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: widget.height,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.primary,
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppTheme.accent, size: 60),
                  ),
                ),
              ),

              // Top gradient — for legibility of brand strip
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryDark.withOpacity(0.35),
                        Colors.transparent,
                        AppTheme.primaryDark.withOpacity(0.45),
                        AppTheme.primaryDark.withOpacity(0.92),
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // Brand strip top-left (gold accent line + small label)
              Positioned(
                top: 14,
                left: 16,
                child: FadeTransition(
                  opacity: captionAnim,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 1.6,
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'INJIBARA UNIVERSITY · LIBRARY',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontFamily: 'PT Serif',
                          fontSize: 9.5,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top-right page indicator dots
              Positioned(
                top: 12,
                right: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.imagePaths.length, (i) {
                    final active = i == _currentIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.accent
                            : Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

              // Caption block bottom-left
              if (hasTitle || hasSub)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 20,
                  child: FadeTransition(
                    opacity: captionAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasTitle)
                          Text(
                            widget.titles![_currentIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Playfair Display',
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        if (hasSub) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitles![_currentIndex],
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontFamily: 'PT Serif',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // CTA chip bottom-right
              Positioned(
                right: 16,
                bottom: 18,
                child: FadeTransition(
                  opacity: captionAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.menu_book_rounded,
                            size: 13, color: AppTheme.primaryDark),
                        SizedBox(width: 4),
                        Text(
                          'Browse Catalog',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontFamily: 'Playfair Display',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
