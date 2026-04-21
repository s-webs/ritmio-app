import 'dart:io';

import '../../../core/network/api_client.dart';
import 'ai_result_model.dart';

class VoiceRepository {
  VoiceRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AiResultModel> parseVoice(File audioFile) async {
    final json = await _apiClient.postMultipart(
      '/ai/parse-voice',
      file: audioFile,
      field: 'audio',
    );
    return AiResultModel.fromJson(json as Map<String, dynamic>);
  }
}
