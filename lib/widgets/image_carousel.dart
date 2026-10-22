import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// A horizontally-scrolling image carousel used on the dashboard.
/// Each item is a tall card with a real photo, a gradient overlay,
/// a title, and an optional subtitle. Tap invokes [onTap] with the index.
class ImageCarousel extends StatelessWidget {
  final List<String> imagePaths;
  final String sectionTitle;
  final String? sectionSubtitle;
  final List<String>? captions;
  final List<String>? subCaptions;
  final double height;
  final double cardWidth;
  final VoidCallback? onViewAll;
  final void Function(int index)? onTap;

  const ImageCarousel({
    super.key,
    required this.imagePaths,
    required this.sectionTitle,
    this.sectionSubtitle,
    this.captions,
    this.subCaptions,
    this.height = 200,
    this.cardWidth = 240,
    this.onViewAll,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            children: [
              Container(width: 3, height: 14, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    if (sectionSubtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          sectionSubtitle!,
                          style: const TextStyle(
                            fontFamily: 'PT Serif',
                            fontSize: 11,
                            color: AppTheme.slate,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    textStyle: const TextStyle(
                      fontFamily: 'PT Serif',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View all'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: imagePaths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final path = imagePaths[i];
              final caption = captions != null && i < captions!.length
                  ? captions![i]
                  : null;
              final sub = subCaptions != null && i < subCaptions!.length
                  ? subCaptions![i]
                  : null;
              return _CarouselCard(
                imagePath: path,
                title: caption,
                subtitle: sub,
                width: cardWidth,
                height: height,
                onTap: onTap != null ? () => onTap!(i) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final String imagePath;
  final String? title;
  final String? subtitle;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _CarouselCard({
    required this.imagePath,
    required this.width,
    required this.height,
    this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.primary,
                    child: const Icon(Icons.menu_book_rounded,
                        color: AppTheme.accent, size: 32),
                  ),
                ),
                // Top gradient for legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          AppTheme.primaryDark.withOpacity(0.55),
                          AppTheme.primaryDark.withOpacity(0.92),
                        ],
                        stops: const [0.0, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top-right gold corner accent
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome,
                            size: 11, color: AppTheme.primaryDark),
                        SizedBox(width: 3),
                        Text(
                          'IULMS',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontFamily: 'Playfair Display',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom caption block
                if (title != null || subtitle != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Playfair Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontFamily: 'PT Serif',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
