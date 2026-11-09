import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/data/models.dart';
import '../screens/emergency/emergency_screen.dart';

/// Visual treatment for an awareness level.
class LevelStyle {
  const LevelStyle({
    required this.color,
    required this.container,
    required this.icon,
    required this.label,
  });

  /// Foreground colour.
  final Color color;

  /// Background container colour.
  final Color container;

  /// Icon that always accompanies the colour.
  final IconData icon;

  /// Word that always accompanies the colour.
  final String label;

  /// Resolve a level against the current theme.
  factory LevelStyle.of(BuildContext context, AwarenessLevel level) {
    final scheme = Theme.of(context).colorScheme;
    switch (level) {
      case AwarenessLevel.danger:
        return LevelStyle(
          color: scheme.error,
          container: scheme.errorContainer,
          icon: Icons.warning_amber_rounded,
          label: 'Danger',
        );
      case AwarenessLevel.warning:
        return LevelStyle(
          color: scheme.onSecondaryContainer,
          container: scheme.secondaryContainer,
          icon: Icons.error_outline_rounded,
          label: 'Warning',
        );
      case AwarenessLevel.info:
        return LevelStyle(
          color: scheme.onPrimaryContainer,
          container: scheme.primaryContainer,
          icon: Icons.info_outline_rounded,
          label: 'Notice',
        );
    }
  }
}

/// The product mark, loaded from the generated branding asset.
class CaLogo extends StatelessWidget {
  /// Create a logo.
  const CaLogo({super.key, this.size = 40, this.showWordmark = false});

  /// Square edge length.
  final double size;

  /// Whether to draw "C Around" beside the tile.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset(
        'assets/branding/icon-512.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'C Around',
      ),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        mark,
        const SizedBox(width: 10),
        Text(
          'C Around',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
        ),
      ],
    );
  }
}

/// A screen scaffold with a consistent title, SOS action and readable width.
class CaPage extends StatelessWidget {
  /// Create a page.
  const CaPage({
    super.key,
    required this.services,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.scrollable = true,
    this.showSosAction = true,
    this.leading,
  });

  /// Application services.
  final AppServices services;

  /// Page heading, also used as the app bar title.
  final String title;

  /// One-line explanation under the heading.
  final String? subtitle;

  /// Extra app bar actions, placed before the SOS button.
  final List<Widget> actions;

  /// Page content.
  final Widget child;

  /// Whether to wrap [child] in a scroll view.
  final bool scrollable;

  /// Whether to show the red SOS button in the app bar.
  final bool showSosAction;

  /// Optional widget shown before the title, usually a back button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = <Widget>[
      if (subtitle != null) ...<Widget>[
        Text(
          subtitle!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
      ],
      child,
      const SizedBox(height: 28),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Text(title),
        actions: <Widget>[
          ...actions,
          if (showSosAction)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () => openEmergency(context, services),
                icon: const Icon(Icons.sos_rounded),
                label: const Text('SOS'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
        ],
      ),
      body: scrollable
          ? ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: content,
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Open the emergency screen.
Future<void> openEmergency(BuildContext context, AppServices services) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => EmergencyScreen(services: services),
    ),
  );
}

/// A titled card that groups related controls.
class CaSection extends StatelessWidget {
  /// Create a section.
  const CaSection({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.child,
    this.padding = const EdgeInsets.all(18),
  });

  /// Section heading.
  final String title;

  /// Optional explanation.
  final String? description;

  /// Optional widget on the heading row.
  final Widget? trailing;

  /// Section body.
  final Widget? child;

  /// Inner padding.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (description != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (child != null) ...<Widget>[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A large, tappable row with an icon, title and optional subtitle.
class CaTile extends StatelessWidget {
  /// Create a tile.
  const CaTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  /// Leading icon.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Secondary label.
  final String? subtitle;

  /// Tap handler. When null the tile is not interactive.
  final VoidCallback? onTap;

  /// Widget shown at the end of the row.
  final Widget? trailing;

  /// Override the icon colour.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor ?? scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              (onTap == null
                  ? const SizedBox.shrink()
                  : Icon(Icons.chevron_right_rounded, color: scheme.outline)),
        ],
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}

/// A banner that carries status, an error or a safety message.
class CaBanner extends StatelessWidget {
  /// Create a banner.
  const CaBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.level = AwarenessLevel.info,
    this.action,
  });

  /// Text to show.
  final String message;

  /// Leading icon.
  final IconData icon;

  /// Severity, which picks the colours.
  final AwarenessLevel level;

  /// Optional action button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final style = LevelStyle.of(context, level);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.container,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: style.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: style.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (action != null) ...<Widget>[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// Small rounded label used for levels and counts.
class CaPill extends StatelessWidget {
  /// Create a pill.
  const CaPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.background,
  });

  /// Text inside the pill.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Foreground colour.
  final Color? color;

  /// Background colour.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Centred message for an empty list or an unavailable feature.
class CaEmptyState extends StatelessWidget {
  /// Create an empty state.
  const CaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  /// Large icon.
  final IconData icon;

  /// Short heading.
  final String title;

  /// Explanation.
  final String message;

  /// Optional action.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 42, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

/// A button that fills the width and keeps a 56 px touch target.
class CaActionButton extends StatelessWidget {
  /// Create a button.
  const CaActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.busy = false,
  });

  /// Leading icon.
  final IconData icon;

  /// Button label.
  final String label;

  /// Tap handler.
  final VoidCallback? onPressed;

  /// Whether to use the filled style.
  final bool filled;

  /// Show a progress indicator instead of the icon.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (busy)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon),
        const SizedBox(width: 10),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    const style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(Size.fromHeight(56)),
    );
    if (filled) {
      return FilledButton(
        onPressed: busy ? null : onPressed,
        style: style,
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: style,
      child: child,
    );
  }
}
