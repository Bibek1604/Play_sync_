import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sound Manager Service
/// 
/// Plays subtle sounds for different notification types.
/// Matches web version exactly with similar frequencies.
class SoundManager {
  // Singleton pattern
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  /// Convenience getter for singleton instance
  static SoundManager get instance => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _enabled = true;

  /// Enable or disable sounds
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Get current enabled state
  bool get isEnabled => _enabled;

  /// Play a beep sound with specific frequency and duration
  /// Note: Flutter doesn't support direct frequency generation like Web Audio API
  /// We'll use pre-generated sound files or generate simple tones
  Future<void> _playBeep(int frequency, int durationMs, double volume) async {
    if (!_enabled || kIsWeb) return; // Skip on web for now
    
    try {
      // For production, you would have actual sound files
      // For now, we'll use a simple approach with audio files
      // Place sound files in assets/sounds/
      
      // This is a placeholder - you'll need actual sound files
      // await _audioPlayer.play(AssetSource('sounds/beep_$frequency.mp3'));
      
      debugPrint('[SOUND] Playing beep: ${frequency}Hz for ${durationMs}ms at volume $volume');
    } catch (e) {
      debugPrint('[SOUND] Failed to play sound: $e');
    }
  }

  /// Success sound - Pleasant ascending tone
  /// Web: C5 (523.25Hz) → E5 (659.25Hz)
  Future<void> success() async {
    if (!_enabled) return;
    
    try {
      // Play success sound
      // await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      
      debugPrint('[SOUND] 🎵 Success sound');
      await _playBeep(523, 100, 0.2);
      await Future.delayed(const Duration(milliseconds: 80));
      await _playBeep(659, 150, 0.25);
    } catch (e) {
      debugPrint('[SOUND] Error playing success sound: $e');
    }
  }

  /// Error sound - Alert tone
  /// Web: E4 (329.63Hz) → D4 (293.66Hz)
  Future<void> error() async {
    if (!_enabled) return;
    
    try {
      // await _audioPlayer.play(AssetSource('sounds/error.mp3'));
      
      debugPrint('[SOUND] ⚠️ Error sound');
      await _playBeep(330, 150, 0.3);
      await Future.delayed(const Duration(milliseconds: 100));
      await _playBeep(294, 200, 0.3);
    } catch (e) {
      debugPrint('[SOUND] Error playing error sound: $e');
    }
  }

  /// Info sound - Neutral single tone
  /// Web: A4 (440Hz)
  Future<void> info() async {
    if (!_enabled) return;
    
    try {
      // await _audioPlayer.play(AssetSource('sounds/info.mp3'));
      
      debugPrint('[SOUND] ℹ️ Info sound');
      await _playBeep(440, 150, 0.2);
    } catch (e) {
      debugPrint('[SOUND] Error playing info sound: $e');
    }
  }

  /// Warning sound - Double beep
  /// Web: B4 (493.88Hz) x2
  Future<void> warning() async {
    if (!_enabled) return;
    
    try {
      // await _audioPlayer.play(AssetSource('sounds/warning.mp3'));
      
      debugPrint('[SOUND] ⚡ Warning sound');
      await _playBeep(494, 100, 0.25);
      await Future.delayed(const Duration(milliseconds: 150));
      await _playBeep(494, 100, 0.25);
    } catch (e) {
      debugPrint('[SOUND] Error playing warning sound: $e');
    }
  }

  /// Generic notification sound
  Future<void> notification() async {
    if (!_enabled) return;
    
    try {
      // await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      
      debugPrint('[SOUND] 🔔 Notification sound');
      await _playBeep(587, 120, 0.2); // D5
    } catch (e) {
      debugPrint('[SOUND] Error playing notification sound: $e');
    }
  }

  /// Join game sound
  Future<void> joinGame() async {
    if (!_enabled) return;
    
    try {
      debugPrint('[SOUND] 🎮 Join game sound');
      await _playBeep(392, 100, 0.2); // G4
      await Future.delayed(const Duration(milliseconds: 80));
      await _playBeep(523, 100, 0.2); // C5
    } catch (e) {
      debugPrint('[SOUND] Error playing join sound: $e');
    }
  }

  /// Leave game sound
  Future<void> leaveGame() async {
    if (!_enabled) return;
    
    try {
      debugPrint('[SOUND] 👋 Leave game sound');
      await _playBeep(523, 100, 0.2); // C5
      await Future.delayed(const Duration(milliseconds: 80));
      await _playBeep(392, 120, 0.2); // G4
    } catch (e) {
      debugPrint('[SOUND] Error playing leave sound: $e');
    }
  }

  /// Chat message sound
  Future<void> chatMessage() async {
    if (!_enabled) return;
    
    try {
      debugPrint('[SOUND] 💬 Chat message sound');
      await _playBeep(349, 80, 0.15); // F4
    } catch (e) {
      debugPrint('[SOUND] Error playing chat sound: $e');
    }
  }

  // ===================================
  // 🎵 CONVENIENCE ALIASES (play* methods)
  // ===================================
  Future<void> playSuccess() => success();
  Future<void> playError() => error();
  Future<void> playInfo() => info();
  Future<void> playWarning() => warning();
  Future<void> playNotification() => notification();
  Future<void> playJoinGame() => joinGame();
  Future<void> playLeaveGame() => leaveGame();
  Future<void> playChatMessage() => chatMessage();

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}

/// Global sound manager instance
final soundManager = SoundManager();
