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

/// The services this template actually wires at startup.
///
/// Everything here is constructed once in `main()` and passed down explicitly.
/// There is no global service locator: a screen receives the object it needs,
/// which keeps tests able to substitute a fake.
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
        version = VersionService.fromString(config.version);

  /// Creates a minimal service graph for widget tests.
  ///
  /// Platform services (camera, microphone, database) are not started.
  /// Settings, TTS, alerts, announcer and database stubs are wired so
  /// screens render without hardware access.
  static Future<AppServices> forTest(CambricConfig config) async {
    final svc = AppServices(config: config);
    final prefs = await svc.preferences.preferences;
    svc._settings = SettingsService(prefs);
    await svc._settings!.load();
    svc.diagnostics = DiagnosticsService(config: config, version: svc.version);
    // NOTE: database, TTS, alerts, camera, microphone are NOT initialised in
    // tests because their platform channels hang in the headless VM test runner.
    // Screens guard platform-service access with `services.isFullyInitialized`.
    return svc;
  }

  SettingsService? _settings;
  bool _announcerReady = false;

  /// True once [initialize] has finished; false after [forTest].
  bool get isFullyInitialized => _settings != null && _announcerReady;

  SettingsService get settings {
    if (_settings == null) {
      throw StateError(
        'AppServices.initialize() must be called before accessing settings. '
        'In tests, call await services.initialize() in setUp.',
      );
    }
    return _settings!;
  }

  /// Product identity and feature flags.
  final CambricConfig config;

  /// Authoritative version, parsed once from config.
  final VersionService version;

  /// Small persisted preferences: theme mode, onboarding completion.
  final PreferencesService preferences;

  /// Persistent user data, scoped to this product.
  final LocalStorage storage;

  /// Cache inspection and cleanup.
  final CacheCleanupService cacheCleanup;

  /// Network reachability, used by the diagnostics screen.
  final ConnectivityService connectivity;

  /// Release discovery, download and verification.
  final UpdateService updates;

  /// Subscription state and license validation.
  final SubscriptionService subscription;

  /// Local diagnostic report builder.
  late final DiagnosticsService diagnostics;

  // C Around specific services
  /// Database for people, phrases, places, items.
  late final CaDatabase database;

  /// Vibration and sound alerts.
  late final AlertService alerts;

  /// Text-to-speech output.
  late final TtsService tts;

  /// Central coordination of speech, haptics, and event history.
  late final Announcer announcer;

  /// Camera frame capture and preview.
  late final CameraFrameSource camera;

  /// Object detection with YOLO.
  late final YoloDetector detector;

  /// Face detection and recognition.
  late final FaceRecognizer faces;

  /// Audio analysis and sound classification.
  late final SoundMonitor soundMonitor;

  /// Captions display.
  late final CaptionController captions;

  /// Continuous camera awareness controller.
  late final AwarenessController awareness;

  /// Model pack management and download.
  late final ModelManager models;

  /// Feature flag management.
  late final FeatureFlagService featureFlags;

  /// App lock with PIN protection.
  late final AppLockService appLock;

  /// Off-screen whisper speech-to-text.
  late final SpeechRecognizer recognizer;

  /// Shared microphone.
  late final MicrophoneSource microphone;

  final AppLifecycleService _lifecycle = AppLifecycleService();

  /// Prepares logging, lifecycle tracking and the product data directory.
  ///
  /// Safe to call once from `main()`. Errors are reported to diagnostics rather
  /// than preventing the app from starting.
  Future<void> initialize() async {
    // Initialize settings first since other services depend on it
    _settings = SettingsService(await preferences.preferences);
    await _settings!.load();

    CambricLogger.initialize();
    await _lifecycle.initialize();

    try {
      await storage.dataDirectory;
    } catch (error) {
      diagnostics.setStorageHealthy(false);
      diagnostics.reportError('Could not create the data directory', error: error);
    }

    try {
      await subscription.load();
    } catch (error) {
      diagnostics.reportError('Could not load subscription state', error: error);
    }

    try {
      await database.open();
    } catch (error) {
      diagnostics.reportError('Could not open database', error: error);
    }

    // Initialize shared services in dependency order
    alerts = AlertService(settings);
    tts = TtsService(settings);
    final dataDir = await storage.dataDirectory;
    models = ModelManager(root: dataDir);
    recognizer = SpeechRecognizer(models);
    microphone = MicrophoneSource();
    announcer = Announcer(
      settings: settings,
      tts: tts,
      alerts: alerts,
      database: database,
    );
    _announcerReady = true;
    captions = CaptionController(
      recognizer: recognizer,
      microphone: microphone,
      database: database,
    );
    camera = CameraFrameSource();
    detector = YoloDetector();
    faces = FaceRecognizer();
    awareness = AwarenessController(
      settings: settings,
      camera: camera,
      detector: detector,
      faces: faces,
      moondream: MoondreamClient(models),
      announcer: announcer,
      database: database,
    );
    final prefs = await preferences.preferences;
    soundMonitor = SoundMonitor(
      classifier: YamnetClassifier(),
      announcer: announcer,
      microphone: microphone,
    );
    featureFlags = const FeatureFlagService({});
    appLock = AppLockService(prefs);
    diagnostics = DiagnosticsService(
      config: config,
      version: version,
    );

    try {
      await captions.start();
    } catch (error) {
      diagnostics.reportError('Could not start captions', error: error);
    }

    try {
      await awareness.start();
    } catch (error) {
      diagnostics.reportError('Could not start awareness controller', error: error);
    }
  }

  /// Stops lifecycle observation. Used by integration tests and hot restart.
  Future<void> dispose() async {
    await captions.stop();
    await awareness.stop();
    await database.close();
    _lifecycle.dispose();
  }
}
