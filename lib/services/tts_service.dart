import 'package:flutter_tts/flutter_tts.dart';

import '../repositories/settings_repository.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

/// Text-to-Speech service backed by `flutter_tts`. Initializes the platform
/// TTS engine, exposes a `speak()` helper, and reads the persisted
/// `voice_navigation_enabled` setting so the toggle survives restarts.
///
/// Voice navigation flow: every sidebar/drawer item, when tapped, calls
/// `TtsProvider.speakNav(...)` which (when enabled) reads the destination's
/// name back to the user — making the app usable without looking at the
/// screen for users with low vision or while driving/walking.
class TtsService {
  final SettingsRepository _settings;
  FlutterTts? _tts;
  bool _enabled = true;
  String _language = 'en-US';

  TtsService(this._settings);

  /// Lazy-loads the platform TTS engine and applies persisted settings.
  Future<void> init() async {
    if (_tts != null) return;
    _tts = FlutterTts();
    _enabled = await _settings.getBool(AppConstants.keyTtsEnabled, defaultValue: true);
    _language = (await _settings.get(AppConstants.keyTtsLanguage)) ?? 'en-US';
    try {
      await _tts!.setLanguage(_language);
      await _tts!.setSpeechRate(0.95);
      await _tts!.setPitch(1.0);
      await _tts!.setVolume(1.0);
      // Don't await TTS completion for navigation prompts — keep snappy.
      await _tts!.awaitSpeakCompletion(false);
    } catch (e) {
      // TTS engine may not be available on this device; fail silently so the
      // app still runs.
      if (kDebugMode) {
        debugPrint('TtsService init failed: $e');
      }
    }
  }

  bool get isEnabled => _enabled;

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    await _settings.set(AppConstants.keyTtsEnabled, v ? 'true' : 'false');
    if (!v) {
      await stop();
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _settings.set(AppConstants.keyTtsLanguage, lang);
    try {
      await _tts?.setLanguage(lang);
    } catch (_) {}
  }

  /// Speaks a single phrase, interrupting anything currently playing.
  Future<void> speak(String text) async {
    if (!_enabled) return;
    await init();
    try {
      await _tts?.stop();
      await _tts?.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  /// Convenience: announces a navigation event in a natural phrasing.
  /// e.g. `speakNav('Dashboard')` → "Opening Dashboard."
  Future<void> speakNav(String destinationName) async {
    await speak('Opening $destinationName.');
  }

  /// Convenience: announces a successful CRUD action.
  /// e.g. `speakCrud('added', 'book', 'Introduction to Algorithms')`
  Future<void> speakCrud(String verb, String entity, String title) async {
    await speak('$verb $entity: $title.');
  }
}

/// Wraps TtsService in a ChangeNotifier so UI widgets can rebuild when
/// the voice toggle flips. Reads the initial enabled state from settings
/// and exposes a simple flip toggle.
class TtsProvider extends ChangeNotifier {
  final TtsService _service;
  TtsProvider(this._service);

  bool _enabled = true;
  bool get isEnabled => _enabled;

  Future<void> bootstrap() async {
    await _service.init();
    _enabled = _service.isEnabled;
    notifyListeners();
  }

  Future<void> toggle() async {
    final next = !_enabled;
    _enabled = next;
    notifyListeners();
    await _service.setEnabled(next);
    // Announce the change so the user gets audible confirmation.
    if (next) {
      await _service.speak('Voice navigation enabled.');
    } else {
      await _service.stop();
    }
  }

  Future<void> speakNav(String destinationName) =>
      _service.speakNav(destinationName);

  Future<void> speak(String text) => _service.speak(text);

  Future<void> speakCrud(String verb, String entity, String title) =>
      _service.speakCrud(verb, entity, title);

  Future<void> stop() => _service.stop();
}
