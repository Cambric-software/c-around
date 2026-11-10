/// All spoken phrases in every supported language.
///
/// The language is selected from [SettingsService.speechLanguage] (a BCP-47
/// tag). Falls back to English for any tag that is not explicitly translated.
///
/// Every public method returns a ready-to-speak string. Keep each string short
/// and unambiguous — it will be read aloud by a TTS engine.
class SpeechStrings {
  const SpeechStrings(this.langCode);

  /// BCP-47 language code, e.g. 'ar', 'fr', 'de', 'en'.
  final String langCode;

  /// Extract language part only (ar-SA → ar).
  String get _lang => langCode.split('-').first.toLowerCase();

  bool get _isAr => _lang == 'ar';
  bool get _isFr => _lang == 'fr';
  bool get _isDe => _lang == 'de';

  // ── Directions ──────────────────────────────────────────────────────────

  String get ahead {
    if (_isAr) return 'أمامك';
    if (_isFr) return 'devant vous';
    if (_isDe) return 'vor Ihnen';
    return 'ahead';
  }

  String get onYourLeft {
    if (_isAr) return 'على يسارك';
    if (_isFr) return 'à votre gauche';
    if (_isDe) return 'links von Ihnen';
    return 'on your left';
  }

  String get onYourRight {
    if (_isAr) return 'على يمينك';
    if (_isFr) return 'à votre droite';
    if (_isDe) return 'rechts von Ihnen';
    return 'on your right';
  }

  String direction(double centerX) {
    if (centerX < 0.34) return onYourLeft;
    if (centerX > 0.66) return onYourRight;
    return ahead;
  }

  // ── Object labels ────────────────────────────────────────────────────────

  String translateLabel(String cocoLabel) {
    final label = cocoLabel.toLowerCase();
    if (_isAr) {
      return _arLabels[label] ?? cocoLabel;
    } else if (_isFr) {
      return _frLabels[label] ?? cocoLabel;
    } else if (_isDe) {
      return _deLabels[label] ?? cocoLabel;
    }
    return _enLabels[label] ?? cocoLabel;
  }

  static const Map<String, String> _enLabels = <String, String>{
    'person': 'Person', 'car': 'Car', 'truck': 'Truck', 'bus': 'Bus',
    'motorcycle': 'Motorcycle', 'train': 'Train', 'bicycle': 'Bicycle',
    'dog': 'Dog', 'cat': 'Cat', 'chair': 'Chair', 'couch': 'Couch',
    'dining table': 'Table', 'bed': 'Bed', 'toilet': 'Toilet',
    'potted plant': 'Plant', 'bench': 'Bench', 'stairs': 'Stairs',
    'door': 'Door', 'knife': 'Knife', 'scissors': 'Scissors',
    'bottle': 'Bottle', 'cup': 'Cup', 'laptop': 'Laptop',
    'cell phone': 'Phone', 'book': 'Book', 'backpack': 'Backpack',
    'umbrella': 'Umbrella', 'traffic light': 'Traffic light',
    'fire hydrant': 'Fire hydrant', 'stop sign': 'Stop sign',
  };

  static const Map<String, String> _arLabels = <String, String>{
    'person': 'شخص', 'car': 'سيارة', 'truck': 'شاحنة', 'bus': 'حافلة',
    'motorcycle': 'دراجة نارية', 'train': 'قطار', 'bicycle': 'دراجة هوائية',
    'dog': 'كلب', 'cat': 'قطة', 'chair': 'كرسي', 'couch': 'أريكة',
    'dining table': 'طاولة', 'bed': 'سرير', 'toilet': 'مرحاض',
    'potted plant': 'نبتة', 'bench': 'مقعد', 'stairs': 'سلّم',
    'door': 'باب', 'knife': 'سكين', 'scissors': 'مقص',
    'bottle': 'زجاجة', 'cup': 'كوب', 'laptop': 'حاسوب محمول',
    'cell phone': 'هاتف', 'book': 'كتاب', 'backpack': 'حقيبة ظهر',
    'umbrella': 'مظلة', 'traffic light': 'إشارة مرور',
    'fire hydrant': 'صنبور إطفاء', 'stop sign': 'إشارة توقف',
  };

  static const Map<String, String> _frLabels = <String, String>{
    'person': 'Personne', 'car': 'Voiture', 'truck': 'Camion', 'bus': 'Bus',
    'motorcycle': 'Moto', 'train': 'Train', 'bicycle': 'Vélo',
    'dog': 'Chien', 'cat': 'Chat', 'chair': 'Chaise', 'couch': 'Canapé',
    'dining table': 'Table', 'bed': 'Lit', 'toilet': 'Toilettes',
    'potted plant': 'Plante', 'bench': 'Banc', 'stairs': 'Escaliers',
    'door': 'Porte', 'knife': 'Couteau', 'scissors': 'Ciseaux',
    'bottle': 'Bouteille', 'cup': 'Tasse', 'laptop': 'Ordinateur portable',
    'cell phone': 'Téléphone', 'book': 'Livre', 'backpack': 'Sac à dos',
    'umbrella': 'Parapluie', 'traffic light': 'Feu de circulation',
    'fire hydrant': 'Bouche d\'incendie', 'stop sign': 'Panneau stop',
  };

  static const Map<String, String> _deLabels = <String, String>{
    'person': 'Person', 'car': 'Auto', 'truck': 'LKW', 'bus': 'Bus',
    'motorcycle': 'Motorrad', 'train': 'Zug', 'bicycle': 'Fahrrad',
    'dog': 'Hund', 'cat': 'Katze', 'chair': 'Stuhl', 'couch': 'Sofa',
    'dining table': 'Tisch', 'bed': 'Bett', 'toilet': 'Toilette',
    'potted plant': 'Pflanze', 'bench': 'Bank', 'stairs': 'Treppe',
    'door': 'Tür', 'knife': 'Messer', 'scissors': 'Schere',
    'bottle': 'Flasche', 'cup': 'Tasse', 'laptop': 'Laptop',
    'cell phone': 'Telefon', 'book': 'Buch', 'backpack': 'Rucksack',
    'umbrella': 'Regenschirm', 'traffic light': 'Ampel',
    'fire hydrant': 'Hydrant', 'stop sign': 'Stoppschild',
  };

  // ── Hazard messages ──────────────────────────────────────────────────────

  String personClose(String dir) {
    if (_isAr) return 'شخص قريب جداً، $dir.';
    if (_isFr) return 'Personne très proche, $dir.';
    if (_isDe) return 'Person sehr nah, $dir.';
    return 'Person very close, $dir.';
  }

  String person(String dir) {
    if (_isAr) return 'شخص $dir.';
    if (_isFr) return 'Personne $dir.';
    if (_isDe) return 'Person $dir.';
    return 'Person $dir.';
  }

  String vehicle(String label, String dir) {
    final l = translateLabel(label);
    if (_isAr) return '$l $dir.';
    if (_isFr) return '$l $dir.';
    if (_isDe) return '$l $dir.';
    return '$l $dir.';
  }

  String dog(String dir) {
    if (_isAr) return 'كلب $dir.';
    if (_isFr) return 'Chien $dir.';
    if (_isDe) return 'Hund $dir.';
    return 'Dog $dir.';
  }

  String sharpObject(String dir) {
    if (_isAr) return 'جسم حاد $dir.';
    if (_isFr) return 'Objet tranchant $dir.';
    if (_isDe) return 'Scharfer Gegenstand $dir.';
    return 'Sharp object $dir.';
  }

  String obstacle(String dir) {
    if (_isAr) return 'عائق $dir.';
    if (_isFr) return 'Obstacle $dir.';
    if (_isDe) return 'Hindernis $dir.';
    return 'Obstacle $dir.';
  }

  // ── Scene description ────────────────────────────────────────────────────

  String nothingDetected() {
    if (_isAr) return 'لا يوجد شيء محدد أمامك الآن.';
    if (_isFr) return 'Rien de spécifique détecté devant vous maintenant.';
    if (_isDe) return 'Nichts Bestimmtes gerade vor Ihnen erkannt.';
    return 'Nothing specific detected in front of you right now.';
  }

  String modelNotLoaded() {
    if (_isAr) return 'الكاميرا ترى شيئاً لكن النموذج لم يُحمَّل بعد.';
    if (_isFr) return 'La caméra voit quelque chose mais le modèle n\'est pas encore chargé.';
    if (_isDe) return 'Die Kamera sieht etwas, aber das Modell ist noch nicht geladen.';
    return 'The camera sees something but the vision model is not loaded yet.';
  }

  String cannotAnalyse() {
    if (_isAr) return 'لا يمكن تحليل المشهد الآن.';
    if (_isFr) return 'Impossible d\'analyser la scène maintenant.';
    if (_isDe) return 'Die Szene kann gerade nicht analysiert werden.';
    return 'Could not analyse the scene right now.';
  }

  String iCanSeeOne(String item) {
    if (_isAr) return 'أرى $item.';
    if (_isFr) return 'Je vois $item.';
    if (_isDe) return 'Ich sehe $item.';
    return 'I can see $item.';
  }

  String iCanSeeMultiple(List<String> items) {
    if (items.length == 1) return iCanSeeOne(items.first);
    final last = items.last;
    final rest = items.sublist(0, items.length - 1);
    if (_isAr) return 'أرى ${rest.join('، ')} و$last.';
    if (_isFr) return 'Je vois ${rest.join(', ')} et $last.';
    if (_isDe) return 'Ich sehe ${rest.join(', ')} und $last.';
    return 'I can see ${rest.join(', ')}, and $last.';
  }

  // ── Face recognition ─────────────────────────────────────────────────────

  String faceRecognised(String name, String dir) {
    if (_isAr) return '$name $dir.';
    if (_isFr) return '$name est $dir.';
    if (_isDe) return '$name ist $dir.';
    return '$name is $dir.';
  }

  // ── Sound alerts ─────────────────────────────────────────────────────────

  String soundAlert(String soundName) {
    if (_isAr) return 'تنبيه: $soundName.';
    if (_isFr) return 'Alerte: $soundName.';
    if (_isDe) return 'Alarm: $soundName.';
    return 'Alert: $soundName.';
  }

  // ── Onboarding / System ───────────────────────────────────────────────────

  String welcome() {
    if (_isAr) return 'مرحباً بك في C Around. العالم، موضَّحاً. هذا التطبيق يعمل بدون إنترنت.';
    if (_isFr) return 'Bienvenue dans C Around. Le monde, expliqué. Cette application fonctionne sans internet.';
    if (_isDe) return 'Willkommen bei C Around. Die Welt, erklärt. Diese App funktioniert ohne Internet.';
    return 'Welcome to C Around. The world, explained. This app works without the internet.';
  }

  String setupDone() {
    if (_isAr) return 'الإعداد اكتمل. يمكن تغيير كل شيء في الإعدادات.';
    if (_isFr) return 'Configuration terminée. Tout peut être modifié dans les paramètres.';
    if (_isDe) return 'Einrichtung abgeschlossen. Alles kann in den Einstellungen geändert werden.';
    return 'Setup is done. Everything can be changed in Settings.';
  }
}
