import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:audioplayers/audioplayers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kitten TTS Nano 0.2 — 8 speakers
// 0=expr-voice-2-m  1=expr-voice-2-f  2=expr-voice-3-m  3=expr-voice-3-f
// 4=expr-voice-4-m  5=expr-voice-4-f  6=expr-voice-5-m  7=expr-voice-5-f
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, int> kCharacterSpeakerIds = {
  'narration': 2,
  'player': 0,
  'mayor': 4,
  'elder': 6,
  'merchant': 3,
  'guard': 4,
  'healer': 1,
  'child': 1,
  'villain': 6,
  'robot': 7,
};

const Map<String, double> kCharacterSpeechSpeed = {
  'narration': 1.0,
  'player': 1.05,
  'mayor': 0.90,
  'elder': 0.85,
  'villain': 0.95,
  'child': 1.10,
};

// ─── Isolate messages ─────────────────────────────────────────────────────────

/// Sent to the TTS isolate at startup to configure the model.
class _TtsIsolateInit {
  final String modelPath;
  final String tokensPath;
  final String voicesPath;
  final String espeakDir;
  final String tempDir;
  final SendPort mainPort;

  _TtsIsolateInit({
    required this.modelPath,
    required this.tokensPath,
    required this.voicesPath,
    required this.espeakDir,
    required this.tempDir,
    required this.mainPort,
  });
}

/// Sent from main isolate → TTS isolate to request synthesis.
class _TtsRequest {
  final String text;
  final int sid;
  final double speed;
  final String outputPath;
  final SendPort replyPort;

  _TtsRequest({
    required this.text,
    required this.sid,
    required this.speed,
    required this.outputPath,
    required this.replyPort,
  });
}

// ─── Isolate entry point (top-level) ─────────────────────────────────────────

/// Runs entirely in the background isolate — loads model once, then listens.
void _ttsIsolateEntry(_TtsIsolateInit init) {
  // Initialize Sherpa bindings in this isolate's context
  sherpa.initBindings();

  sherpa.OfflineTts? tts;
  try {
    final config = sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        kitten: sherpa.OfflineTtsKittenModelConfig(
          model: init.modelPath,
          voices: init.voicesPath,
          tokens: init.tokensPath,
          dataDir: init.espeakDir,
          lengthScale: 1.0,
        ),
        numThreads: 2,
        debug: false,
      ),
    );
    tts = sherpa.OfflineTts(config);
    init.mainPort.send('READY:${tts.numSpeakers}');
  } catch (e) {
    init.mainPort.send('ERROR:$e');
    return;
  }

  // Listen for synthesis requests
  final receivePort = ReceivePort();
  init.mainPort.send(receivePort.sendPort);

  receivePort.listen((msg) {
    if (msg is _TtsRequest) {
      try {
        final audio = tts!.generate(
          text: msg.text,
          sid: msg.sid,
          speed: msg.speed,
        );
        final bytes = _buildWavBytes(audio.samples, audio.sampleRate);
        File(msg.outputPath).writeAsBytesSync(bytes);
        msg.replyPort.send(msg.outputPath);
      } catch (e) {
        msg.replyPort.send('ERROR:$e');
      }
    }
  });
}

List<int> _buildWavBytes(List<double> samples, int sampleRate) {
  final pcm = <int>[];
  for (final s in samples) {
    final v = (s.clamp(-1.0, 1.0) * 32767).toInt();
    pcm.add(v & 0xFF);
    pcm.add((v >> 8) & 0xFF);
  }
  final dataSize = pcm.length;
  final fileSize = 36 + dataSize;
  final byteRate = sampleRate * 2;
  return [
    0x52,
    0x49,
    0x46,
    0x46,
    fileSize & 0xFF,
    (fileSize >> 8) & 0xFF,
    (fileSize >> 16) & 0xFF,
    (fileSize >> 24) & 0xFF,
    0x57,
    0x41,
    0x56,
    0x45,
    0x66,
    0x6D,
    0x74,
    0x20,
    16,
    0,
    0,
    0,
    1,
    0,
    1,
    0,
    sampleRate & 0xFF,
    (sampleRate >> 8) & 0xFF,
    (sampleRate >> 16) & 0xFF,
    (sampleRate >> 24) & 0xFF,
    byteRate & 0xFF,
    (byteRate >> 8) & 0xFF,
    (byteRate >> 16) & 0xFF,
    (byteRate >> 24) & 0xFF,
    2,
    0,
    16,
    0,
    0x64,
    0x61,
    0x74,
    0x61,
    dataSize & 0xFF,
    (dataSize >> 8) & 0xFF,
    (dataSize >> 16) & 0xFF,
    (dataSize >> 24) & 0xFF,
    ...pcm,
  ];
}

// ─── VoiceService ─────────────────────────────────────────────────────────────

class VoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _fallbackTts = FlutterTts();

  Isolate? _ttsIsolate;
  SendPort? _ttsSendPort;
  bool _modelReady = false;

  Completer<void>? _playbackCompleter;
  int _wavCounter = 0;
  String _tempDir = '';

  Future<void> initialize() async {
    await _initFallbackTts();

    try {
      final modelPath = await _copyAsset('assets/models/model.fp16.onnx');
      final tokensPath = await _copyAsset('assets/models/tokens.txt');
      final voicesPath = await _copyAsset('assets/models/voices.bin');

      if (modelPath == null || tokensPath == null || voicesPath == null) {
        debugPrint('[VoiceService] Model assets missing — using system TTS.');
        return;
      }

      final espeakDir = await _ensureEspeakNgData();
      final tempDirectory = await getTemporaryDirectory();
      _tempDir = tempDirectory.path;

      // Start the persistent background TTS isolate
      await _startTtsIsolate(
        modelPath: modelPath,
        tokensPath: tokensPath,
        voicesPath: voicesPath,
        espeakDir: espeakDir,
      );
    } catch (e) {
      debugPrint('[VoiceService] Init error: $e — using system TTS.');
    }
  }

  Future<void> _startTtsIsolate({
    required String modelPath,
    required String tokensPath,
    required String voicesPath,
    required String espeakDir,
  }) async {
    final readyCompleter = Completer<void>();
    final mainReceivePort = ReceivePort();
    bool gotSendPort = false;

    mainReceivePort.listen((msg) {
      if (msg is String && msg.startsWith('READY:')) {
        final speakers = msg.split(':')[1];
        debugPrint(
          '[VoiceService] KITTEN READY on isolate — $speakers speakers.',
        );
        _modelReady = true;
        if (!readyCompleter.isCompleted) readyCompleter.complete();
      } else if (msg is String && msg.startsWith('ERROR:')) {
        debugPrint('[VoiceService] Isolate error: $msg');
        if (!readyCompleter.isCompleted) readyCompleter.complete();
      } else if (!gotSendPort && msg is SendPort) {
        _ttsSendPort = msg;
        gotSendPort = true;
      }
    });

    _ttsIsolate = await Isolate.spawn(
      _ttsIsolateEntry,
      _TtsIsolateInit(
        modelPath: modelPath,
        tokensPath: tokensPath,
        voicesPath: voicesPath,
        espeakDir: espeakDir,
        tempDir: _tempDir,
        mainPort: mainReceivePort.sendPort,
      ),
    );

    // Wait up to 30s for model to load
    await readyCompleter.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => debugPrint('[VoiceService] Model load timed out.'),
    );
  }

  Future<void> speak(String text, {String characterKey = 'narration'}) async {
    await stopSpeaking();

    final sid = _getSpeakerId(characterKey);
    final speed = kCharacterSpeechSpeed[characterKey.toLowerCase()] ?? 1.0;

    if (_modelReady && _ttsSendPort != null) {
      try {
        _wavCounter++;
        final wavPath = '$_tempDir/dialogue_$_wavCounter.wav';

        // Send to background isolate — no UI blocking
        final replyPort = ReceivePort();
        _ttsSendPort!.send(
          _TtsRequest(
            text: text,
            sid: sid,
            speed: speed,
            outputPath: wavPath,
            replyPort: replyPort.sendPort,
          ),
        );

        final result = await replyPort.first;
        replyPort.close();

        if (result is String && !result.startsWith('ERROR:')) {
          _playbackCompleter = Completer<void>();
          _audioPlayer.onPlayerComplete.listen((_) {
            _playbackCompleter?.complete();
            _playbackCompleter = null;
          });
          await _audioPlayer.play(DeviceFileSource(result));
          return _playbackCompleter!.future;
        }
        debugPrint('[VoiceService] Synthesis error: $result');
      } catch (e) {
        debugPrint('[VoiceService] Speak error: $e — fallback.');
      }
    }

    // System TTS fallback
    _playbackCompleter = Completer<void>();
    await _fallbackTts.speak(text);
    return _playbackCompleter!.future;
  }

  Future<void> stopSpeaking() async {
    _playbackCompleter?.complete();
    _playbackCompleter = null;
    await _audioPlayer.stop();
    await _fallbackTts.stop();
  }

  void dispose() {
    _ttsIsolate?.kill(priority: Isolate.immediate);
    _ttsIsolate = null;
    _ttsSendPort = null;
    _modelReady = false;
    _audioPlayer.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int _getSpeakerId(String key) {
    if (kCharacterSpeakerIds.containsKey(key.toLowerCase())) {
      return kCharacterSpeakerIds[key.toLowerCase()]!;
    }
    return key.hashCode.abs() % 8;
  }

  Future<void> _initFallbackTts() async {
    await _fallbackTts.setLanguage('en-US');
    await _fallbackTts.setPitch(1.0);
    await _fallbackTts.setSpeechRate(0.5);
    await _fallbackTts.setVolume(1.0);
    _fallbackTts.setCompletionHandler(() {
      _playbackCompleter?.complete();
      _playbackCompleter = null;
    });
  }

  Future<String> _ensureEspeakNgData() async {
    final appDir = await getApplicationDocumentsDirectory();
    final espeakDir = Directory('${appDir.path}/espeak-ng-data');

    if (await espeakDir.exists()) return espeakDir.path;

    debugPrint('[VoiceService] Downloading espeak-ng-data...');
    const url =
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/espeak-ng-data.tar.bz2';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200)
      throw Exception('Download failed: ${response.statusCode}');

    final archive = TarDecoder().decodeBytes(
      BZip2Decoder().decodeBytes(response.bodyBytes),
    );
    for (final file in archive) {
      if (file.isFile) {
        final out = File('${appDir.path}/${file.name}');
        await out.create(recursive: true);
        await out.writeAsBytes(file.content as List<int>);
      }
    }
    return espeakDir.path;
  }

  Future<String?> _copyAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final dir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${dir.path}/$fileName');
      if (!await file.exists()) {
        await file.writeAsBytes(data.buffer.asUint8List());
        debugPrint('[VoiceService] Cached $fileName');
      }
      return file.path;
    } catch (e) {
      debugPrint('[VoiceService] Asset not found: $assetPath');
      return null;
    }
  }
}
