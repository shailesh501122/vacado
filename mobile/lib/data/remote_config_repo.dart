import '../models/remote_config.dart';
import 'api_client.dart';

class RemoteConfigRepository {
  RemoteConfigRepository(this._api);
  final ApiClient _api;

  Future<RemoteConfig> fetch() async {
    final res = await _api.get('/config/public');
    return RemoteConfig.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
