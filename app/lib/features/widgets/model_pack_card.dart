import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/ai/model_manager.dart';
import '../../core/data/models.dart';
import 'ca_widgets.dart';

/// Human-readable size.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  const int mb = 1024 * 1024;
  if (bytes >= 1024 * mb) {
    return '${(bytes / (1024 * mb)).toStringAsFixed(1)} GB';
  }
  return '${(bytes / mb).round()} MB';
}

/// One optional model pack, with install, progress and removal.
class ModelPackCard extends StatelessWidget {
  /// Create a card.
  const ModelPackCard({
    super.key,
    required this.services,
    required this.packId,
    this.showDescription = true,
  });

  /// Application services.
  final AppServices services;

  /// Pack id, e.g. `moondream`.
  final String packId;

  /// Whether to show the pack's explanation.
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: services.models,
      builder: (BuildContext context, Widget? _) {
        final pack = ModelManager.packs.firstWhere(
          (ModelPack value) => value.id == packId,
          orElse: () => ModelManager.packs.first,
        );
        final status = services.models.status[packId] ??
            ModelStatus(state: ModelInstallState.missing);
        final theme = Theme.of(context);
        final supported = !pack.requiresDesktop ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux;

        if (status.state == ModelInstallState.installing) {
          return CaSection(
            title: pack.title,
            trailing: CaPill(
              label: '${(status.progress * 100).round()}%',
              icon: Icons.downloading_rounded,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LinearProgressIndicator(value: status.progress),
                const SizedBox(height: 10),
                Text(
                  status.currentFile == null
                      ? 'Preparing files'
                      : 'Downloading ${status.currentFile}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatBytes(status.receivedBytes)} of '
                  '${formatBytes(status.totalBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (status.state == ModelInstallState.ready) {
          return CaSection(
            title: pack.title,
            trailing: const CaPill(
              label: 'Installed',
              icon: Icons.check_circle_rounded,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showDescription)
                  Text(
                    pack.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${formatBytes(pack.totalBytes)} on disk',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmRemove(context, pack),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return CaSection(
          title: pack.title,
          trailing: status.state == ModelInstallState.failed
              ? const CaPill(
                  label: 'Failed',
                  icon: Icons.error_outline_rounded,
                )
              : CaPill(label: formatBytes(pack.totalBytes)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showDescription)
                Text(
                  pack.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (status.error != null) ...<Widget>[
                const SizedBox(height: 10),
                CaBanner(
                  message: status.error!,
                  level: AwarenessLevel.warning,
                  icon: Icons.error_outline_rounded,
                ),
              ],
              if (!supported) ...<Widget>[
                const SizedBox(height: 10),
                const CaBanner(
                  message: 'This pack runs on Windows and Linux only. '
                      'Android uses the bundled object, sound and face models.',
                ),
              ] else ...<Widget>[
                const SizedBox(height: 14),
                CaActionButton(
                  icon: Icons.download_rounded,
                  label: 'Install ${formatBytes(pack.totalBytes)}',
                  onPressed: () => services.models.install(pack.id),
                ),
                const SizedBox(height: 8),
                Text(
                  'Downloads come directly from Hugging Face and the '
                  'llama.cpp project over HTTPS. Nothing else is downloaded.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context, ModelPack pack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Remove ${pack.title}?'),
        content: const Text(
          'The files are deleted from this device. You can install them again '
          'at any time.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await services.models.remove(pack.id);
    }
  }
}
