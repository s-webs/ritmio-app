import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../data/ai_result_model.dart';
import '../data/voice_repository.dart';

enum VoiceState { idle, recording, processing, success, error }

class VoiceController extends ChangeNotifier {
  VoiceController(this._repository);

  final VoiceRepository _repository;
  final AudioRecorder _recorder = AudioRecorder();

  VoiceState _state = VoiceState.idle;
  AiResultModel? _result;
  String? _errorMessage;
  String? _recordingPath;

  VoiceState get state => _state;
  AiResultModel? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _state == VoiceState.recording;
  bool get isProcessing => _state == VoiceState.processing;

  Future<void> toggleRecording() async {
    if (_state == VoiceState.recording) {
      await _stopAndProcess();
    } else if (_state == VoiceState.idle ||
        _state == VoiceState.success ||
        _state == VoiceState.error) {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _errorMessage = 'Нет разрешения на использование микрофона';
      _state = VoiceState.error;
      notifyListeners();
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _recordingPath!,
    );

    _state = VoiceState.recording;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _stopAndProcess() async {
    final path = await _recorder.stop();
    if (path == null) {
      _errorMessage = 'Не удалось записать аудио';
      _state = VoiceState.error;
      notifyListeners();
      return;
    }

    _state = VoiceState.processing;
    notifyListeners();

    try {
      final file = File(path);
      _result = await _repository.parseVoice(file);
      _state = VoiceState.success;
    } catch (e) {
      _errorMessage = 'Ошибка обработки: ${e.toString()}';
      _state = VoiceState.error;
    } finally {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      notifyListeners();
    }
  }

  void reset() {
    _state = VoiceState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> cancelIfActive() async {
    if (_state == VoiceState.recording) {
      await _recorder.stop();
    }
    if (_recordingPath != null) {
      try {
        final f = File(_recordingPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _state = VoiceState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
