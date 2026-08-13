import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/last_fm_service.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<String?> {
  final _storage = const FlutterSecureStorage();
  
  @override
  Future<String?> build() async {
    return await _storage.read(key: 'lastfm_session_key');
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final lastFm = ref.read(lastFmServiceProvider);
      final sessionKey = await lastFm.authenticate(username, password);
      
      if (sessionKey != null) {
        await _storage.write(key: 'lastfm_session_key', value: sessionKey);
      } else {
        throw Exception("Invalid credentials");
      }
      
      return sessionKey;
    });
  }
  
  Future<void> logout() async {
    await _storage.delete(key: 'lastfm_session_key');
    state = const AsyncValue.data(null);
  }
}