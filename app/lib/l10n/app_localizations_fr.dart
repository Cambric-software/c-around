// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'C Around';

  @override
  String get navAround => 'Autour';

  @override
  String get navTalk => 'Parler';

  @override
  String get navPeople => 'Personnes';

  @override
  String get navNavigate => 'Navigation';

  @override
  String get navEmergency => 'Urgence';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get aroundTitle => 'C Around';

  @override
  String get aroundStart => 'Démarrer';

  @override
  String get aroundStop => 'Arrêter';

  @override
  String get aroundDescribeScene => 'Décrire la scène';

  @override
  String get aroundReadText => 'Lire le texte';

  @override
  String get aroundAsk => 'Poser une question';

  @override
  String get aroundSoundMonitor => 'Moniteur sonore';

  @override
  String get aroundNoCamera => 'Caméra non disponible';

  @override
  String get aroundScanningHint => 'Recherche de dangers…';

  @override
  String get aroundHazardsNone => 'Aucun danger détecté';

  @override
  String get talkTitle => 'Parler';

  @override
  String get talkQuickPhrases => 'Phrases rapides';

  @override
  String get talkAllPhrases => 'Toutes les phrases';

  @override
  String get talkAddPhrase => 'Ajouter une phrase';

  @override
  String get talkSpeak => 'Parler';

  @override
  String get talkTypeHere => 'Tapez quelque chose…';

  @override
  String get talkCaptionsTitle => 'Sous-titres en direct';

  @override
  String get talkCaptionsEmpty =>
      'Rien de transcrit pour l\'instant. Appuyez sur Démarrer.';

  @override
  String get talkCaptionsStart => 'Démarrer les sous-titres';

  @override
  String get talkCaptionsStop => 'Arrêter les sous-titres';

  @override
  String get talkCaptionsClear => 'Effacer l\'historique';

  @override
  String get peopleTitle => 'Personnes';

  @override
  String get peopleAdd => 'Inscrire une personne';

  @override
  String get peopleEmpty =>
      'Aucune personne inscrite.\nAppuyez sur + pour en ajouter une.';

  @override
  String get peopleName => 'Nom';

  @override
  String get peopleRelationship => 'Relation';

  @override
  String get peopleDelete => 'Supprimer';

  @override
  String get peopleTakePhoto => 'Prendre une photo';

  @override
  String get peoplePhotoRequired => 'Une photo du visage est requise';

  @override
  String get navigateTitle => 'Navigation';

  @override
  String get navigatePlaces => 'Lieux sauvegardés';

  @override
  String get navigateItems => 'Objets suivis';

  @override
  String get navigateAddPlace => 'Ajouter un lieu';

  @override
  String get navigateAddItem => 'Ajouter un objet';

  @override
  String get navigatePlacesEmpty => 'Aucun lieu sauvegardé pour l\'instant.';

  @override
  String get navigateItemsEmpty => 'Aucun objet suivi pour l\'instant.';

  @override
  String get emergencyTitle => 'Urgence';

  @override
  String get emergencyMedicalCard => 'Carte médicale';

  @override
  String get emergencyContact => 'Contact d\'urgence';

  @override
  String emergencyCallContact(String name) {
    return 'Appeler $name';
  }

  @override
  String get emergencyShareCard => 'Partager la carte';

  @override
  String get emergencyNoCard =>
      'Aucune carte médicale configurée. Allez dans Paramètres pour ajouter vos informations.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAccessibility => 'Besoins en accessibilité';

  @override
  String get settingsSpeech => 'Parole';

  @override
  String get settingsSpeechEnabled => 'Sortie vocale';

  @override
  String get settingsSpeechRate => 'Vitesse de parole';

  @override
  String get settingsSpeechPitch => 'Hauteur de la voix';

  @override
  String get settingsSpeechLanguage => 'Langue de la voix';

  @override
  String get settingsHaptics => 'Alertes par vibration';

  @override
  String get settingsFlash => 'Alertes par flash d\'écran';

  @override
  String get settingsSoundAlerts => 'Alertes sonores';

  @override
  String get settingsHighContrast => 'Contraste élevé';

  @override
  String get settingsTextScale => 'Taille du texte';

  @override
  String get settingsConfidence => 'Seuil de détection';

  @override
  String get settingsCooldown => 'Délai d\'annonce (secondes)';

  @override
  String get settingsAnnounceInfo =>
      'Prononcer les descriptions basse priorité';

  @override
  String get settingsSpeakCards => 'Prononcer les cartes au toucher';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsAppLock => 'Verrouillage de l\'application';

  @override
  String get settingsAppLockEnabled => 'Exiger un code PIN au démarrage';

  @override
  String get settingsChangePIN => 'Changer le code PIN';

  @override
  String get settingsAutoUpdate => 'Vérification automatique des mises à jour';

  @override
  String get settingsDiagnostics => 'Diagnostics';

  @override
  String get settingsDiagnosticsView => 'Voir le rapport de diagnostic';

  @override
  String get settingsClearDiagnostics => 'Effacer les diagnostics';

  @override
  String get settingsReplayOnboarding => 'Revoir l\'accueil';

  @override
  String get settingsMedicalCard => 'Carte médicale';

  @override
  String get settingsMedicalName => 'Nom';

  @override
  String get settingsMedicalConditions => 'Conditions médicales';

  @override
  String get settingsMedicalAllergies => 'Allergies';

  @override
  String get settingsMedicalMedications => 'Médicaments';

  @override
  String get settingsMedicalBloodType => 'Groupe sanguin';

  @override
  String get settingsContactName => 'Nom du contact d\'urgence';

  @override
  String get settingsContactPhone => 'Téléphone du contact d\'urgence';

  @override
  String get onboardingWelcomeTitle => 'Le monde, expliqué.';

  @override
  String get onboardingWelcomeBody =>
      'C Around décrit ce qui est devant vous, nomme les personnes que vous connaissez, lit les panneaux à voix haute et surveille les sons — tout hors ligne.';

  @override
  String get onboardingNeedsTitle => 'De quoi avez-vous besoin ?';

  @override
  String get onboardingNeedsBody =>
      'Choisissez vos besoins en accessibilité. C Around ajuste ses paramètres par défaut. Vous pouvez tout modifier ultérieurement dans les Paramètres.';

  @override
  String get onboardingReadyTitle => 'Prêt à utiliser.';

  @override
  String get onboardingReadyBody =>
      'C Around est prêt. Les modèles de détection d\'objets et de classification sonore sont déjà inclus.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingFinish => 'Commencer';

  @override
  String get needBlind => 'Aveugle';

  @override
  String get needLowVision => 'Malvoyant';

  @override
  String get needDeaf => 'Sourd';

  @override
  String get needHardOfHearing => 'Malentendant';

  @override
  String get needNonVerbal => 'Non verbal';

  @override
  String get lockTitle => 'Entrez le code PIN';

  @override
  String get lockHint => 'Entrez votre code PIN à 6 chiffres';

  @override
  String get lockError => 'Code PIN incorrect';

  @override
  String lockLockedOut(int minutes) {
    return 'Trop de tentatives. Réessayez dans $minutes minutes.';
  }

  @override
  String get lockForgot =>
      'Code PIN oublié ? Réinitialisez-le dans les Paramètres.';

  @override
  String get modelPacksTitle => 'Packs de modèles';

  @override
  String get modelPacksInstalled => 'Installé';

  @override
  String get modelPacksNotInstalled => 'Non installé';

  @override
  String get modelPacksDownload => 'Télécharger';

  @override
  String get modelPacksRemove => 'Supprimer';

  @override
  String get modelPacksDesktopOnly => 'Bureau uniquement';

  @override
  String get errorGeneric => 'Quelque chose s\'est mal passé.';

  @override
  String get errorNoCamera =>
      'La caméra n\'est pas disponible sur cet appareil.';

  @override
  String get errorNoMicrophone => 'Permission microphone refusée.';

  @override
  String get errorNoLocation => 'Permission de localisation refusée.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get close => 'Fermer';

  @override
  String get retry => 'Réessayer';

  @override
  String get loading => 'Chargement…';

  @override
  String get permissionRequired => 'Permission requise';

  @override
  String get permissionDenied => 'Permission refusée';
}
