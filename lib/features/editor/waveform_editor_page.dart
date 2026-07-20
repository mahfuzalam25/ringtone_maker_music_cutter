// ignore_for_file: deprecated_member_use, depend_on_referenced_packages
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ringtone_maker_music_cutter/features/editor/saved_success_page.dart';

class WaveformEditorPage extends StatefulWidget {
  final String filePath;

  const WaveformEditorPage({super.key, required this.filePath});

  @override
  State<WaveformEditorPage> createState() => _WaveformEditorPageState();
}

class _WaveformEditorPageState extends State<WaveformEditorPage> {
  final AudioPlayer _player = AudioPlayer();
  Waveform? _waveform;
  bool _isExtracting = true;
  bool _isSaving = false;
  double _extractionProgress = 0.0;

  double _startValue = 0.0;
  double _endValue = 1.0;
  Duration _totalDuration = Duration.zero;

  String _selectedSaveType = 'Ringtone';
  final TextEditingController _fileNameController = TextEditingController();

  // AdMob Interstitial Variable
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      // adUnitId:'ca-app-pub-3993160111071835/8767566240', // Real Interstitial ID
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test Interstitial ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> _initAudio() async {
    try {
      final duration = await _player.setFilePath(widget.filePath);
      if (!mounted) return;
      if (duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }

    _player.positionStream.listen((position) {
      final endTime = _totalDuration * _endValue;
      if (_player.playing && position >= endTime) {
        _player.pause();
        _player.seek(_totalDuration * _startValue);
      }
    });

    final audioFile = File(widget.filePath);
    final tempDir = await getTemporaryDirectory();
    final waveFile = File(p.join(tempDir.path, 'waveform.wave'));

    JustWaveform.extract(
      audioInFile: audioFile,
      waveOutFile: waveFile,
      zoom: const WaveformZoom.pixelsPerSecond(50),
    ).listen(
      (progress) {
        if (!mounted) return;
        setState(() {
          _extractionProgress = progress.progress;
        });
      },
      onDone: () async {
        final waveform = await JustWaveform.parse(waveFile);
        if (!mounted) return;
        setState(() {
          _waveform = waveform;
          _isExtracting = false;
        });
      },
      onError: (e) {
        debugPrint("Waveform Extraction Error: $e");
        if (!mounted) return;
        setState(() {
          _isExtracting = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _fileNameController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDarkBlue = Color(0xFF0D3B66);
    const Color waveColor = Color(0xFF3B8EBB);
    const Color headerColor = Color(0xFF1E88E5);

    final startTime = _totalDuration * _startValue;
    final endTime = _totalDuration * _endValue;

    return Scaffold(
      backgroundColor: bgDarkBlue,
      appBar: AppBar(
        backgroundColor: headerColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          p.basename(widget.filePath),
          style: const TextStyle(fontSize: 16, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, size: 28),
            onPressed: _isExtracting ? null : () => _showSaveDialog(context),
          ),
        ],
      ),
      body: _isExtracting || _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _isSaving
                        ? "Trimming Audio File..."
                        : "Analyzing Audio... ${(_extractionProgress * 100).toInt()}%",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (_waveform != null)
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: CustomPaint(
                            painter: WaveformPainter(
                              waveform: _waveform!,
                              waveColor: waveColor,
                              startPercent: _startValue,
                              endPercent: _endValue,
                            ),
                          ),
                        ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 0,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: Colors.grey.shade300,
                          overlayColor: Colors.white.withOpacity(0.1),
                          rangeThumbShape: const RoundRangeSliderThumbShape(
                            enabledThumbRadius: 15,
                          ),
                        ),
                        child: RangeSlider(
                          min: 0.0,
                          max: 1.0,
                          values: RangeValues(_startValue, _endValue),
                          onChanged: (values) {
                            setState(() {
                              _startValue = values.start;
                              _endValue = values.end;
                            });
                            _player.seek(_totalDuration * _startValue);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.black.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "MP3, 44100 Hz, 128 kbps, ${_totalDuration.inSeconds} seconds",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: () {
                              _player.seek(_totalDuration * _startValue);
                            },
                          ),
                          const SizedBox(width: 20),
                          StreamBuilder<PlayerState>(
                            stream: _player.playerStateStream,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? false;
                              return IconButton(
                                icon: Icon(
                                  playing
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                onPressed: () {
                                  if (playing) {
                                    _player.pause();
                                  } else {
                                    _player.seek(_totalDuration * _startValue);
                                    _player.play();
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: () {
                              _player.seek(_totalDuration * _endValue);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Start: ${(startTime.inMilliseconds / 1000).toStringAsFixed(1)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "End: ${(endTime.inMilliseconds / 1000).toStringAsFixed(1)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    _fileNameController.text =
        "Trimmed_${p.basenameWithoutExtension(widget.filePath)}";
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF4F7FC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "Save As:",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Name:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  TextField(
                    controller: _fileNameController,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Type:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  DropdownButton<String>(
                    value: _selectedSaveType,
                    isExpanded: true,
                    items: ['Music', 'Alarm', 'Notification', 'Ringtone']
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => _selectedSaveType = value);
                      }
                    },
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _executeTrimming();
                  },
                  child: const Text(
                    "SAVE",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeTrimming() async {
    setState(() => _isSaving = true);
    _player.pause();

    try {
      final startSeconds =
          (_totalDuration * _startValue).inMilliseconds / 1000.0;
      final endSeconds = (_totalDuration * _endValue).inMilliseconds / 1000.0;
      final directory = await getApplicationDocumentsDirectory();
      final originalExtension = p.extension(widget.filePath);

      String safeName = _fileNameController.text.replaceAll(' ', '_');

      if (!safeName.endsWith(originalExtension)) {
        safeName += originalExtension;
      }

      final outputPath = p.join(directory.path, safeName);

      if (await File(outputPath).exists()) {
        await File(outputPath).delete();
      }

      final arguments = [
        '-y',
        '-i',
        widget.filePath,
        '-ss',
        startSeconds.toString(),
        '-to',
        endSeconds.toString(),
        '-c',
        'copy',
        outputPath,
      ];

      await FFmpegKit.executeWithArguments(arguments).then((session) async {
        final returnCode = await session.getReturnCode();
        if (!mounted) return;
        setState(() => _isSaving = false);

        if (ReturnCode.isSuccess(returnCode)) {
          if (mounted) {
            // ==========================================
            // ADMOB INTERSTITIAL LOGIC
            // ==========================================
            if (_interstitialAd != null) {
              _interstitialAd!.fullScreenContentCallback =
                  FullScreenContentCallback(
                    onAdDismissedFullScreenContent: (ad) {
                      ad.dispose();
                      // Navigate after ad is closed
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedSuccessPage(
                            savedFilePath: outputPath,
                            saveType: _selectedSaveType,
                          ),
                        ),
                      );
                    },
                    onAdFailedToShowFullScreenContent: (ad, error) {
                      ad.dispose();
                      // Navigate immediately if ad fails to show
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedSuccessPage(
                            savedFilePath: outputPath,
                            saveType: _selectedSaveType,
                          ),
                        ),
                      );
                    },
                  );
              _interstitialAd!.show();
            } else {
              // Navigate immediately if ad never loaded
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedSuccessPage(
                    savedFilePath: outputPath,
                    saveType: _selectedSaveType,
                  ),
                ),
              );
            }
          }
        } else {
          final errorLogs = await session.getLogsAsString();
          debugPrint("🚨 FFMPEG CRASH REPORT 🚨\n$errorLogs");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Failed to trim. Check console logs.'),
              ),
            );
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      debugPrint("System Catch Error: $e");
    }
  }
}

class WaveformPainter extends CustomPainter {
  final Waveform waveform;
  final Color waveColor;
  final double startPercent;
  final double endPercent;

  WaveformPainter({
    required this.waveform,
    required this.waveColor,
    required this.startPercent,
    required this.endPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final disabledPaint = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    final disabledPath = Path();

    final width = size.width;
    final height = size.height;
    final halfHeight = height / 2;
    final samples = waveform.data;
    final step = samples.length / width;
    final startX = width * startPercent;
    final endX = width * endPercent;

    for (var i = 0; i < width; i++) {
      final sampleIndex = (i * step).toInt();
      if (sampleIndex < samples.length) {
        final sample = samples[sampleIndex].abs() / 32768.0;
        final y = sample * halfHeight;
        final targetPath = (i >= startX && i <= endX) ? path : disabledPath;
        targetPath.moveTo(i.toDouble(), halfHeight - y);
        targetPath.lineTo(i.toDouble(), halfHeight + y);
      }
    }
    canvas.drawPath(disabledPath, disabledPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.startPercent != startPercent ||
        oldDelegate.endPercent != endPercent ||
        oldDelegate.waveform != waveform;
  }
}
