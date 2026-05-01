import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:ringtone_maker_music_cutter/features/editor/waveform_editor_page.dart';

class RecordAudioPage extends StatefulWidget {
  const RecordAudioPage({super.key});

  @override
  State<RecordAudioPage> createState() => _RecordAudioPageState();
}

class _RecordAudioPageState extends State<RecordAudioPage> {

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isHighQuality = true;


  int _recordDuration = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel(); 
        return;
      }
      setState(() => _recordDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();

        final tempPath = p.join(tempDir.path, 'temp_recording.m4a');


        final config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: _isHighQuality ? 128000 : 64000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: tempPath);

        if (!mounted) return; 

        setState(() => _isRecording = true);
        _startTimer();
      }
    } catch (e) {
      debugPrint("Recording failed to start: $e"); 
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      if (!mounted) return; 

      _timer?.cancel();
      setState(() => _isRecording = false);

      if (path != null) {
        _showSaveDialog(path);
      }
    } catch (e) {
      debugPrint("Recording failed to stop: $e"); 
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDarkBlue = Color(0xFF0D3B66);
    const Color headerColor = Color(0xFF1E88E5);

    return Scaffold(
      backgroundColor: bgDarkBlue,
      appBar: AppBar(
        backgroundColor: bgDarkBlue, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'MP3 Cutter and Ringtone Maker',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),


          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: Center(
              child: Text(
                _formatDuration(_recordDuration),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          const Spacer(flex: 3),


          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Audio quality:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(width: 10),
              Switch(
                value: _isHighQuality,
                activeColor: const Color(0xFF00BFA5), 
                onChanged: _isRecording
                    ? null
                    : (value) {
                        setState(() => _isHighQuality = value);
                      },
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            _isRecording
                ? 'Recording in progress...'
                : 'Tap the button to start recording',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 40),


          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }


  void _showSaveDialog(String tempPath) {
    final TextEditingController nameController = TextEditingController(
      text: "DraftRecording_${DateTime.now().millisecondsSinceEpoch}.m4a",
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Row(
            children: const [
              Icon(Icons.save, color: Colors.white70),
              SizedBox(width: 10),
              Text(
                "Save Recording",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Name:",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00BFA5)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                File(tempPath).delete().catchError(
                  (e) => debugPrint(e.toString()),
                ); 
                setState(() => _recordDuration = 0); 
              },
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Color(0xFF00BFA5)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _saveAndShowEditPrompt(tempPath, nameController.text);
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Color(0xFF00BFA5)),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveAndShowEditPrompt(String tempPath, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();


      final recordingsDir = Directory(p.join(directory.path, 'Recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create();
      }

      if (!fileName.endsWith('.m4a')) fileName += '.m4a';


      final savedPath = p.join(recordingsDir.path, fileName);
      await File(tempPath).copy(savedPath);
      await File(tempPath).delete();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: const Text(
              "Edit Recording",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: const Text(
              "Recording has been saved successfully!.\nWould you like to edit it?",
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() => _recordDuration = 0);
                },
                child: const Text(
                  "CANCEL",
                  style: TextStyle(color: Color(0xFF00BFA5)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WaveformEditorPage(filePath: savedPath),
                    ),
                  );
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Color(0xFF00BFA5)),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint("Error saving file: $e"); 
    }
  }
}
