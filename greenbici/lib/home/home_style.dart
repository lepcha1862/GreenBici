import 'package:flutter/material.dart';

abstract final class HomeStyle {
  static const ink = Color(0xFF202820);
  static const muted = Color(0xFF868D84);
  static const green = Color(0xFF72AD43);
  static const darkGreen = Color(0xFF347C3D);
  static const paleGreen = Color(0xFFF1F7EE);
  static const blue = Color(0xFF249EBD);
  static const border = Color(0xFFEEF1EB);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Arial',
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: ink,
      primary: darkGreen,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.3),
      bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.3),
      titleMedium: TextStyle(
        color: ink,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: const IconThemeData(color: ink),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkGreen),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
    ),
  );
}

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x090E2E0A),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HomeStyle.border, width: .6),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(left: 4),
                minimumSize: const Size(64, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'View all',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
