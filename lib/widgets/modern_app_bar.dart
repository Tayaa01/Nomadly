import 'package:flutter/material.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool isDarkMode;
  final VoidCallback? onToggleTheme;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final double elevation;
  final bool centerTitle;
  final Color? backgroundColor;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    required this.isDarkMode,
    this.onToggleTheme,
    this.showBackButton = false,
    this.onBackPressed,
    this.leading,
    this.elevation = 0,
    this.centerTitle = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    // Remove default theme toggle actions
    final List<Widget> defaultActions = [];

    // Choose background color based on isDarkMode if none provided
    final bgColor =
        backgroundColor ?? (isDarkMode ? Colors.black : Colors.white);

    return AppBar(
      backgroundColor: bgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                  size: 20,
                ),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
              : null),
      actions: actions ?? defaultActions,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );
  }
}
