import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _kBrowserIdKey = 'chatpress_browser_id';
const _kSessionIdPrefix = 'chatpress_session_id_';
const _uuid = Uuid();

/// Manages persistent session state for the Chatpress SDK.
///
/// - **browser-id**: A stable UUID that identifies this device/install.
///   Auto-generated on first use and persisted forever unless [resetBrowserId]
///   is called.
/// - **session-id**: The last known conversation session for a given chatbot.
///   Used to resume conversations across app restarts.
class SessionService {
  final SharedPreferences _prefs;
  final String _chatbotId;

  SessionService._(this._prefs, this._chatbotId);

  /// Creates a [SessionService] scoped to [chatbotId].
  static Future<SessionService> create(String chatbotId) async {
    final prefs = await SharedPreferences.getInstance();
    return SessionService._(prefs, chatbotId);
  }

  // ── browser-id ────────────────────────────────────────────────────────────

  /// Returns the stable, device-unique browser identifier.
  ///
  /// Generates and persists a new UUID v4 the first time this is called.
  String get browserId {
    final existing = _prefs.getString(_kBrowserIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _uuid.v4();
    _prefs.setString(_kBrowserIdKey, generated);
    return generated;
  }

  /// Generates a new browser ID, replacing the existing one.
  ///
  /// ⚠️ This effectively creates a new visitor identity.
  Future<void> resetBrowserId() async {
    await _prefs.remove(_kBrowserIdKey);
  }

  // ── session-id ────────────────────────────────────────────────────────────

  /// The last known session ID for this chatbot, or `null` if none is stored.
  String? get sessionId =>
      _prefs.getString('$_kSessionIdPrefix$_chatbotId');

  /// Persists [sessionId] so it can be resumed on the next app launch.
  Future<void> saveSessionId(String sessionId) async {
    await _prefs.setString('$_kSessionIdPrefix$_chatbotId', sessionId);
  }

  /// Removes the stored session ID, forcing a fresh session on next connect.
  Future<void> clearSession() async {
    await _prefs.remove('$_kSessionIdPrefix$_chatbotId');
  }
}
