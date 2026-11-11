import '../core/cache/cache_cleanup_service.dart';
import '../core/config/cambric_config.dart';
import '../core/data/ca_database.dart';
import '../core/diagnostics/diagnostics_service.dart';
import '../core/lifecycle/app_lifecycle_service.dart';
import '../core/lifecycle/feature_flag_service.dart';
import '../core/lifecycle/version_service.dart';
import '../core/logging/logging_service.dart';
import '../core/network/connectivity_service.dart';
import '../core/output/alert_service.dart';
import '../core/output/announcer.dart';
import '../core/output/tts_service.dart';
import '../core/security/app_lock_service.dart';
import '../core/security/security_service.dart';
import '../core/services/preferences_service.dart';
import '../core/settings/settings_service.dart';
import '../core/storage/local_storage.dart';
import '../core/subscription/subscription_service.dart';
import '../core/updates/update_service.dart';
import '../core/ai/model_manager.dart';
import '../core/ai/face_recognizer.dart';
import '../core/ai/yolo_detector.dart';
import '../core/ai/sound_classifier.dart';
import '../core/ai/moondream_client.dart';
import '../core/awareness/awareness_controller.dart';
import '../core/awareness/caption_controller.dart';
import '../core/awareness/microphone_source.dart';
import '../core/awareness/sound_monitor.dart';
import '../core/ai/speech_recognizer.dart';
import '../core/vision/camera_frame_source.dart';

class AppServices {
  AppServices({
    required this.config,
    PreferencesService? preferences,
    LocalStorage? storage,
    CacheCleanupService? cacheCleanup,
    ConnectivityService? connectivity,
    UpdateService? updates,
    SubscriptionService? subscription,
  })  : preferences = preferences ?? PreferencesService.instance,
        storage = storage ?? LocalStorage(productId: config.productId),
        cacheCleanup = cacheCleanup ?? CacheCleanupService(),
        connectivity = connectivity ?? ConnectivityService(),
        updates = updates ?? UpdateService(),
        subscription = subscription ??
            SubscriptionService(
              config: config,
              security: const SecurityService(),
            ),
        version = VersionService.fromString(config.version),
        // diagnostics is created immediately — never late
        diagnostics = DiagnosticsService(
          config: config,
          version: VersionService.fromString(config.version),
        );

  // ── Test factory ──────────────────────────────────────────────────────────

  static Future<AppServices> forTest(CambricConfig config) async {
    final svc = AppServices(config: config);
    final prefs = await svc.preferences.preferences;
    svc._settings = SettingsService(prefs);
    await svc._settings!.load();
    return svc;
  }

  // ── State ─────────────────────────────────────────────────────────────────

  SettingsService? _settings;
  bool _announcerReady = false;

  bool get isFullyInitialized => _settings != null && _announcerReady;

  SettingsService get settings {
    final s = _settings;
    if (s == null) throw StateError('call initialize() before accessing settings');
    return s;
  }

  // ── Core services (always available) ─────────────────────────────────────

  final CambricConfig config;
  final VersionService version;
  final PreferencesService preferences;
  final LocalStorage storage;
  final CacheCleanupService cacheCleanup;
  final ConnectivityService connectivity;
  final UpdateService updates;
  final SubscriptionService subscription;
  final DiagnosticsService diagnostics;   // ← eager, not late

  // ── C Around services (set in initialize()) ───────────────────────────────

  late final CaDatabase database;
  late final AlertService alerts;
  late final TtsService tts;
  late final Announcer announcer;
  late final CameraFrameSource camera;
  late final YoloDetector detector;
  late final FaceRecognizer faces;
  late final SoundMonitor soundMonitor;
  late final CaptionController captions;
  late final AwarenessController awareness;
  late final ModelManager models;
  late final FeatureFlagService featureFlags;
  late final AppLockService appLock;
  late final SpeechRecognizer recognizer;
  late final MicrophoneSource microphone;

  final AppLifecycleService _lifecycle = AppLifecycleService();

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Settings — everything else depends on this
    _settings = SettingsService(await preferences.preferences);
    await _settings!.load();

    CambricLogger.initialize();

    // 2. Lifecycle
    try {
      await _lifecycle.initialize();
    } catch (_) {}

    // 3. Storage
    try {
      await storage.dataDirectory;
    } catch (error) {
      diagnostics.setStorageHealthy(false);
      diagnostics.reportError('Storage unavailable', error: error);
    }

    // 4. Subscription
    try {
      await subscription.load();
    } catch (error) {
      diagnostics.reportError('Subscription load failed', error: error);
    }

    // 5. Database
    database = CaDatabase.instance;
    try {
      await database.open();
    } catch (error) {
      diagnostics.reportError('Database open failed', error: error);
    }

    // 6. Output services
    alerts = AlertService(settings);
    tts = TtsService(settings);

    // 7. Models root
    models = ModelManager(root: await storage.dataDirectory);

    // 8. Microphone + speech recognizer
    recognizer = SpeechRecognizer(models);
    microphone = MicrophoneSource();

    // 9. Announcer
    announcer = Announcer(
      settings: settings,
      tts: tts,
      alerts: alerts,
      database: database,
    );
    _announcerReady = true;

    // 10. Camera + detectors
    camera = CameraFrameSource();
    detector = YoloDetector();
    faces = FaceRecognizer();

    // 11. Captions (Whisper — will gracefully say "not installed" if pack missing)
    captions = CaptionController(
      recognizer: recognizer,
      microphone: microphone,
      database: database,
    );

    // 12. Awareness controller
    awareness = AwarenessController(
      settings: settings,
      camera: camera,
      detector: detector,
      faces: faces,
      moondream: MoondreamClient(models),
      announcer: announcer,
      database: database,
    );

    // 13. Sound monitor
    soundMonitor = SoundMonitor(
      classifier: YamnetClassifier(),
      announcer: announcer,
      microphone: microphone,
      settings: settings,
    );

    // 14. Misc
    featureFlags = const FeatureFlagService({});
    appLock = AppLockService(await preferences.preferences);

    // 15. All hardware services are started ON DEMAND from the screens,
    //     not here. Starting camera/microphone before runApp() causes crashes
    //     on Android because platform channels are not fully ready.
    //     The Around screen starts awareness when the user opens it.
    //     The Sound Monitor starts when the user enables it.
    //     This means the app always opens successfully, even without permissions.
  }

  Future<void> dispose() async {
    if (_announcerReady) {
      try { await captions.stop(); } catch (_) {}
      try { await awareness.stop(); } catch (_) {}
    }
    try { await database.close(); } catch (_) {}
    try { _lifecycle.dispose(); } catch (_) {}
  }
}
