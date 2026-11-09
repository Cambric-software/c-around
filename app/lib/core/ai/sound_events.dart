import '../data/models.dart';

/// A sound the app recognised, with the sentence it should say.
class SoundAlert {
  /// Create an alert.
  const SoundAlert({
    required this.kind,
    required this.message,
    required this.level,
  });

  /// Machine name used for cooldown.
  final String kind;

  /// Sentence shown and spoken.
  final String message;

  /// Severity.
  final AwarenessLevel level;
}

/// Map an AudioSet class name to an alert, or null when the class is not one
/// the product claims to detect.
///
/// Only classes that were measured to work are mapped. Adding every AudioSet
/// label would produce confident-sounding nonsense, which is worse than
/// silence for someone relying on the alert.
SoundAlert? soundAlertFor(String displayName, double score) {
  // YAMNet scores are per-class probabilities averaged over the clip. Below
  // this the label is noise; announcing it would train the user to ignore the
  // alerts that matter.
  if (score < 0.18) return null;
  final name = displayName.toLowerCase();

  bool has(List<String> needles) =>
      needles.any((String needle) => name.contains(needle));

  if (has(<String>['smoke detector', 'smoke alarm', 'fire alarm'])) {
    return const SoundAlert(
      kind: 'fire_alarm',
      message: 'Fire alarm detected.',
      level: AwarenessLevel.danger,
    );
  }
  if (has(<String>['siren'])) {
    return const SoundAlert(
      kind: 'siren',
      message: 'Siren nearby.',
      level: AwarenessLevel.danger,
    );
  }
  if (has(<String>['glass', 'shatter'])) {
    return const SoundAlert(
      kind: 'glass',
      message: 'Glass breaking detected.',
      level: AwarenessLevel.danger,
    );
  }
  if (has(<String>['gunshot', 'gunfire'])) {
    return const SoundAlert(
      kind: 'gunshot',
      message: 'Possible gunshot detected.',
      level: AwarenessLevel.danger,
    );
  }
  if (has(<String>['car horn', 'honking', 'vehicle horn'])) {
    return const SoundAlert(
      kind: 'horn',
      message: 'Car horn nearby.',
      level: AwarenessLevel.warning,
    );
  }
  if (has(<String>['baby cry', 'infant cry'])) {
    return const SoundAlert(
      kind: 'baby',
      message: 'Baby crying nearby.',
      level: AwarenessLevel.warning,
    );
  }
  if (has(<String>['bark', 'dog'])) {
    return const SoundAlert(
      kind: 'dog',
      message: 'Dog barking nearby.',
      level: AwarenessLevel.warning,
    );
  }
  if (has(<String>['screaming', 'shout', 'yell'])) {
    return const SoundAlert(
      kind: 'shout',
      message: 'Someone is shouting nearby.',
      level: AwarenessLevel.warning,
    );
  }
  if (has(<String>['alarm clock'])) {
    return const SoundAlert(
      kind: 'alarm_clock',
      message: 'Alarm clock ringing.',
      level: AwarenessLevel.warning,
    );
  }
  if (has(<String>['thunder'])) {
    return const SoundAlert(
      kind: 'thunder',
      message: 'Thunder nearby.',
      level: AwarenessLevel.info,
    );
  }
  if (has(<String>['doorbell', 'ding-dong'])) {
    return const SoundAlert(
      kind: 'doorbell',
      message: 'Doorbell.',
      level: AwarenessLevel.info,
    );
  }
  if (has(<String>['knock'])) {
    return const SoundAlert(
      kind: 'knock',
      message: 'Knocking.',
      level: AwarenessLevel.info,
    );
  }
  return null;
}
