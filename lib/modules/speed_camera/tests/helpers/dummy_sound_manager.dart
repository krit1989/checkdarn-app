/// Dummy implementation of SoundManager for testing
/// Provides all the same methods but without actual sound playback
class DummySoundManager {
  bool _isSoundEnabled = true;

  // Track method calls for testing verification
  List<String> calledMethods = [];
  List<String> playedSounds = [];

  // Mock the SoundManager API
  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> initialize() async {
    calledMethods.add('initialize');
  }

  Future<void> setSoundEnabled(bool enabled) async {
    calledMethods.add('setSoundEnabled:$enabled');
    _isSoundEnabled = enabled;
  }

  Future<void> playAlert(String message) async {
    calledMethods.add('playAlert:$message');
    playedSounds.add(message);
  }

  Future<void> playBeep() async {
    calledMethods.add('playBeep');
    playedSounds.add('beep');
  }

  Future<void> testSound() async {
    calledMethods.add('testSound');
    playedSounds.add('test');
  }

  void dispose() {
    calledMethods.add('dispose');
  }

  // Helper methods for testing
  void reset() {
    calledMethods.clear();
    playedSounds.clear();
    _isSoundEnabled = true;
  }

  bool wasMethodCalled(String method) {
    return calledMethods.contains(method);
  }

  bool wasSoundPlayed(String sound) {
    return playedSounds.contains(sound);
  }

  int getMethodCallCount(String method) {
    return calledMethods.where((call) => call == method).length;
  }
}
