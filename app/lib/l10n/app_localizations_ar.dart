// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'C Around';

  @override
  String get navAround => 'الحول';

  @override
  String get navTalk => 'تحدّث';

  @override
  String get navPeople => 'الأشخاص';

  @override
  String get navNavigate => 'التنقل';

  @override
  String get navEmergency => 'الطوارئ';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get aroundTitle => 'C Around';

  @override
  String get aroundStart => 'بدء';

  @override
  String get aroundStop => 'إيقاف';

  @override
  String get aroundDescribeScene => 'وصف المشهد';

  @override
  String get aroundReadText => 'قراءة النص';

  @override
  String get aroundAsk => 'اطرح سؤالاً';

  @override
  String get aroundSoundMonitor => 'مراقبة الصوت';

  @override
  String get aroundNoCamera => 'الكاميرا غير متاحة';

  @override
  String get aroundScanningHint => 'جارٍ البحث عن المخاطر…';

  @override
  String get aroundHazardsNone => 'لم يتم اكتشاف أي مخاطر';

  @override
  String get talkTitle => 'تحدّث';

  @override
  String get talkQuickPhrases => 'عبارات سريعة';

  @override
  String get talkAllPhrases => 'جميع العبارات';

  @override
  String get talkAddPhrase => 'إضافة عبارة';

  @override
  String get talkSpeak => 'نطق';

  @override
  String get talkTypeHere => 'اكتب شيئاً…';

  @override
  String get talkCaptionsTitle => 'ترجمة مباشرة';

  @override
  String get talkCaptionsEmpty => 'لم يتم النسخ بعد. اضغط ابدأ للبدء.';

  @override
  String get talkCaptionsStart => 'بدء الترجمة';

  @override
  String get talkCaptionsStop => 'إيقاف الترجمة';

  @override
  String get talkCaptionsClear => 'مسح السجل';

  @override
  String get peopleTitle => 'الأشخاص';

  @override
  String get peopleAdd => 'تسجيل شخص';

  @override
  String get peopleEmpty => 'لا يوجد أشخاص مسجلون بعد.\nاضغط + لإضافة شخص.';

  @override
  String get peopleName => 'الاسم';

  @override
  String get peopleRelationship => 'العلاقة';

  @override
  String get peopleDelete => 'حذف';

  @override
  String get peopleTakePhoto => 'التقاط صورة';

  @override
  String get peoplePhotoRequired => 'صورة وجه مطلوبة';

  @override
  String get navigateTitle => 'التنقل';

  @override
  String get navigatePlaces => 'الأماكن المحفوظة';

  @override
  String get navigateItems => 'العناصر المتتبَّعة';

  @override
  String get navigateAddPlace => 'إضافة مكان';

  @override
  String get navigateAddItem => 'إضافة عنصر';

  @override
  String get navigatePlacesEmpty => 'لا توجد أماكن محفوظة بعد.';

  @override
  String get navigateItemsEmpty => 'لا توجد عناصر متتبَّعة بعد.';

  @override
  String get emergencyTitle => 'الطوارئ';

  @override
  String get emergencyMedicalCard => 'البطاقة الطبية';

  @override
  String get emergencyContact => 'جهة الاتصال في حالات الطوارئ';

  @override
  String emergencyCallContact(String name) {
    return 'الاتصال بـ $name';
  }

  @override
  String get emergencyShareCard => 'مشاركة البطاقة';

  @override
  String get emergencyNoCard =>
      'لم يتم إعداد بطاقة طبية. اذهب إلى الإعدادات لإضافة معلوماتك.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAccessibility => 'احتياجات إمكانية الوصول';

  @override
  String get settingsSpeech => 'الكلام';

  @override
  String get settingsSpeechEnabled => 'الإخراج الصوتي';

  @override
  String get settingsSpeechRate => 'سرعة الكلام';

  @override
  String get settingsSpeechPitch => 'نبرة الكلام';

  @override
  String get settingsSpeechLanguage => 'لغة الصوت';

  @override
  String get settingsHaptics => 'تنبيهات الاهتزاز';

  @override
  String get settingsFlash => 'تنبيهات وميض الشاشة';

  @override
  String get settingsSoundAlerts => 'تنبيهات صوتية';

  @override
  String get settingsHighContrast => 'تباين عالٍ';

  @override
  String get settingsTextScale => 'حجم النص';

  @override
  String get settingsConfidence => 'دقة الكشف';

  @override
  String get settingsCooldown => 'تأخير الإعلانات (ثوانٍ)';

  @override
  String get settingsAnnounceInfo => 'نطق الأوصاف منخفضة الأولوية';

  @override
  String get settingsSpeakCards => 'نطق البطاقات عند النقر';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsAppLock => 'قفل التطبيق';

  @override
  String get settingsAppLockEnabled => 'طلب رمز PIN عند التشغيل';

  @override
  String get settingsChangePIN => 'تغيير رمز PIN';

  @override
  String get settingsAutoUpdate => 'التحقق التلقائي من التحديثات';

  @override
  String get settingsDiagnostics => 'التشخيصات';

  @override
  String get settingsDiagnosticsView => 'عرض تقرير التشخيص';

  @override
  String get settingsClearDiagnostics => 'مسح التشخيصات';

  @override
  String get settingsReplayOnboarding => 'إعادة الترحيب';

  @override
  String get settingsMedicalCard => 'البطاقة الطبية';

  @override
  String get settingsMedicalName => 'الاسم';

  @override
  String get settingsMedicalConditions => 'الحالات الصحية';

  @override
  String get settingsMedicalAllergies => 'الحساسية';

  @override
  String get settingsMedicalMedications => 'الأدوية';

  @override
  String get settingsMedicalBloodType => 'فصيلة الدم';

  @override
  String get settingsContactName => 'اسم جهة اتصال الطوارئ';

  @override
  String get settingsContactPhone => 'هاتف جهة اتصال الطوارئ';

  @override
  String get onboardingWelcomeTitle => 'العالم، موضَّحاً.';

  @override
  String get onboardingWelcomeBody =>
      'يصف C Around ما أمامك، ويُسمّي الأشخاص الذين تعرفهم، ويقرأ اللافتات بصوت عالٍ، ويراقب الأصوات — كل ذلك دون اتصال بالإنترنت.';

  @override
  String get onboardingNeedsTitle => 'ما الذي تحتاجه؟';

  @override
  String get onboardingNeedsBody =>
      'اختر احتياجاتك من إمكانية الوصول. يضبط C Around الإعدادات الافتراضية. يمكنك تغيير كل شيء لاحقاً في الإعدادات.';

  @override
  String get onboardingReadyTitle => 'جاهز للاستخدام.';

  @override
  String get onboardingReadyBody =>
      'C Around جاهز للاستخدام. نماذج الكشف عن الأجسام وتصنيف الصوت مضمّنة مسبقاً.';

  @override
  String get onboardingSkip => 'تخطّي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingFinish => 'ابدأ';

  @override
  String get needBlind => 'كفيف';

  @override
  String get needLowVision => 'ضعف بصر';

  @override
  String get needDeaf => 'أصمّ';

  @override
  String get needHardOfHearing => 'ضعف سمع';

  @override
  String get needNonVerbal => 'غير لفظي';

  @override
  String get lockTitle => 'أدخل رمز PIN';

  @override
  String get lockHint => 'أدخل رمز PIN المكوّن من 6 أرقام';

  @override
  String get lockError => 'رمز PIN غير صحيح';

  @override
  String lockLockedOut(int minutes) {
    return 'محاولات كثيرة. حاول مرة أخرى خلال $minutes دقيقة.';
  }

  @override
  String get lockForgot => 'نسيت رمز PIN؟ أعد تعيينه في الإعدادات.';

  @override
  String get modelPacksTitle => 'حزم النماذج';

  @override
  String get modelPacksInstalled => 'مثبّت';

  @override
  String get modelPacksNotInstalled => 'غير مثبّت';

  @override
  String get modelPacksDownload => 'تنزيل';

  @override
  String get modelPacksRemove => 'إزالة';

  @override
  String get modelPacksDesktopOnly => 'لسطح المكتب فقط';

  @override
  String get errorGeneric => 'حدث خطأ ما.';

  @override
  String get errorNoCamera => 'الكاميرا غير متاحة على هذا الجهاز.';

  @override
  String get errorNoMicrophone => 'تم رفض إذن الميكروفون.';

  @override
  String get errorNoLocation => 'تم رفض إذن الموقع.';

  @override
  String get ok => 'حسناً';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get close => 'إغلاق';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get permissionRequired => 'الإذن مطلوب';

  @override
  String get permissionDenied => 'تم رفض الإذن';
}
