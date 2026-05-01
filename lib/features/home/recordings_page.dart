// ignore_for_file: deprecated_member_use, depend_on_referenced_packages, use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ringtone_set_plus/ringtone_set_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ringtone_maker_music_cutter/features/editor/file_loaded_page.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  final Color primaryColor = const Color(0xFF4A00E0);
  final Color backgroundColor = const Color(0xFFF4F7FC);
  final Color recordingAccentColor = const Color(0xFF1D976C);

  List<File> _recordedFiles = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordedFiles();
  }

  Future<void> _loadRecordedFiles() async {
    setState(() => _isLoading = true);
    try {
      final mainDirectory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(p.join(mainDirectory.path, 'Recordings'));

      if (!await recordingsDir.exists()) {
        await recordingsDir.create();
      }

      final mainFiles = mainDirectory.listSync().whereType<File>();
      for (var file in mainFiles) {
        if (p.basename(file.path).startsWith('DraftRecording_')) {
          await file.rename(p.join(recordingsDir.path, p.basename(file.path)));
        }
      }

      final List<FileSystemEntity> entities = recordingsDir.listSync();
      final files = entities
          .whereType<File>()
          .where(
            (file) => file.path.endsWith('.m4a') || file.path.endsWith('.aac'),
          )
          .toList();

      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      if (!mounted) return;
      setState(() {
        _recordedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading recorded files: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFiles = _recordedFiles.where((file) {
      final fileName = p.basenameWithoutExtension(file.path).toLowerCase();
      return fileName.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Recordings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search recordings...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : filteredFiles.isEmpty
                ? Center(
                    child: Text(
                      "No voice recordings yet.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredFiles.length,
                    itemBuilder: (context, index) {
                      final file = filteredFiles[index];
                      final fileName = p.basenameWithoutExtension(file.path);
                      final fileSize = (file.lengthSync() / (1024 * 1024))
                          .toStringAsFixed(2);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: recordingAccentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.mic, color: recordingAccentColor),
                          ),
                          title: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2D3142),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "$fileSize MB",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Voice Note",
                                style: TextStyle(
                                  color: recordingAccentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    _showOptionsDialog(context, file, fileName),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FileLoadedPage(filePath: file.path),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, File file, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: Color(0xFF2D3142),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Divider(color: Colors.grey.shade300),
                _buildDialogOption('Edit Recording', () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileLoadedPage(filePath: file.path),
                    ),
                  );
                }),
                _buildDialogOption('Set as Default Alarm', () async {
                  Navigator.pop(dialogContext);
                  try {
                    await RingtoneSet.setAlarmFromFile(file);
                    if (!mounted) return;
                    _showFeedback(context, "Alarm set successfully");
                  } catch (e) {
                    if (!mounted) return;
                    _showFeedback(context, "Failed to set Alarm");
                  }
                }),
                _buildDialogOption('Set as Default Notification', () async {
                  Navigator.pop(dialogContext);
                  try {
                    await RingtoneSet.setNotificationFromFile(file);
                    if (!mounted) return;
                    _showFeedback(context, "Notification set successfully");
                  } catch (e) {
                    if (!mounted) return;
                    _showFeedback(context, "Failed to set Notification");
                  }
                }),
                _buildDialogOption('Set as Default Ringtone', () async {
                  Navigator.pop(dialogContext);
                  try {
                    await RingtoneSet.setRingtoneFromFile(file);
                    if (!mounted) return;
                    _showFeedback(context, "Ringtone set successfully");
                  } catch (e) {
                    if (!mounted) return;
                    _showFeedback(context, "Failed to set Ringtone");
                  }
                }),
                _buildDialogOption('Share File...', () async {
                  Navigator.pop(dialogContext);
                  try {
                    final xFile = XFile(file.path, mimeType: 'audio/mpeg');
                    await Share.shareXFiles([
                      xFile,
                    ], text: 'Listen to my recording!');
                  } catch (e) {
                    if (!mounted) return;
                    _showFeedback(context, "Failed to share file");
                  }
                }),
                _buildDialogOption('Delete', () {
                  Navigator.pop(dialogContext);
                  _showDeleteConfirmation(context, file, fileName);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      splashColor: primaryColor.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    File file,
    String fileName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext confirmContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Recording?',
            style: TextStyle(color: Color(0xFF2D3142)),
          ),
          content: Text(
            'Are you sure you want to permanently delete "$fileName"?',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(confirmContext);
                try {
                  if (await file.exists()) {
                    await file.delete();
                    await _loadRecordedFiles();
                    if (!mounted) return;
                    _showFeedback(context, "Recording deleted successfully");
                  }
                } catch (e) {
                  if (!mounted) return;
                  _showFeedback(context, "Failed to delete recording.");
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
