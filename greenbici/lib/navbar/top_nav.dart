import 'package:flutter/material.dart';

import '../theme/app_style.dart';

/// GreenBici's shared wordmark, screen context, and top-level search action.
/// The parent supplies horizontal padding so this fits page-specific layouts.
class TopNav extends StatelessWidget {
  const TopNav({
    super.key,
    this.displayName,
    this.title,
    this.subtitle,
    this.subtitleIcon = Icons.location_on_rounded,
    this.statusColor,
    this.onSearch,
  });

  final String? displayName;
  final String? title;
  final String? subtitle;
  final IconData subtitleIcon;
  final Color? statusColor;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 420 ||
          MediaQuery.textScalerOf(context).scale(14) > 21;
      final wordmarkWidth = (constraints.maxWidth - 64)
          .clamp(0, 126)
          .toDouble();
      final heading = title == null
          ? Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Good morning, '),
                  TextSpan(
                    text: displayName ?? 'Alex',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 17, height: 1.4),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(subtitleIcon, size: 20, color: AppStyle.darkGreen),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppStyle.muted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (statusColor != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.circle, size: 7, color: statusColor),
                      ],
                    ],
                  ),
                ],
              ],
            );
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: wordmarkWidth, child: const _Wordmark()),
                if (!compact) ...[
                  const SizedBox(width: 26),
                  Expanded(flex: 2, child: heading),
                ] else
                  const Spacer(),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Search stations',
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded, size: 31),
                ),
              ],
            ),
            if (compact) ...[const SizedBox(height: 6), heading],
          ],
        ),
      );
    },
  );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'GreenBici',
    image: true,
    child: ExcludeSemantics(
      child: Image.asset(
        'assets/branding/greenbici_logo.png',
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    ),
  );
}
