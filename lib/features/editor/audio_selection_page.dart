import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:ringtone_set_plus/ringtone_set_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ringtone_maker_music_cutter/features/editor/file_loaded_page.dart';

class AudioSelectionPage extends StatefulWidget {
  const AudioSelectionPage({super.key});

  @override
  State<AudioSelectionPage> createState() => _AudioSelectionPageState();
}

class _AudioSelectionPageState extends State<AudioSelectionPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  String _searchQuery = '';
  late Future<List<SongModel>> _songsFuture;


  final Color primaryColor = const Color(0xFF4A00E0);
  final Color backgroundColor = const Color(0xFFF4F7FC);

  @override
  void initState() {
    super.initState();
    _fetchSongs(); 
  }


  void _fetchSongs() {
    _songsFuture = _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'All Available Music',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
                hintText: 'Search music...',
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
            child: FutureBuilder<List<SongModel>>(
              future: _songsFuture, 
              builder: (context, item) {
                if (item.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                if (item.data == null || item.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No music found on this device",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                List<SongModel> songs = item.data!.where((song) {
                  return song.title.toLowerCase().contains(_searchQuery) ||
                      (song.artist?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
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
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.music_note, color: primaryColor),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142), 
                          ),
                        ),
                        subtitle: Text(
                          song.artist ?? "Unknown Artist",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onPressed: () => _showOptionsDialog(context, song),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FileLoadedPage(filePath: song.data),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  void _showOptionsDialog(BuildContext context, SongModel song) {
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
                    '"${song.title}"\n${song.artist ?? 'Unknown Artist'}',
                    style: const TextStyle(
                      color: Color(0xFF2D3142),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                Divider(color: Colors.grey.shade300),

                _buildDialogOption('Edit', () {
                  Navigator.pop(dialogContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileLoadedPage(filePath: song.data),
                    ),
                  );
                }),

                _buildDialogOption('Set as Default Alarm', () async {
                  Navigator.pop(dialogContext);
                  try {
                    await RingtoneSet.setAlarmFromFile(File(song.data));
                    if (!mounted) return;
                    _showFeedback(context, "Alarm set successfully");
                  } catch (e) {
                    debugPrint("🚨 ALARM ERROR: $e");
                    if (!mounted) return;
                    _showFeedback(context, "Failed to set Alarm");
                  }
                }),

                _buildDialogOption('Set as Default Notification', () async {
                  Navigator.pop(dialogContext);
                  try {
                    await RingtoneSet.setNotificationFromFile(File(song.data));
                    if (!mounted) return;
                    _showFeedback(context, "Notification set successfully");
                  } catch (e) {
                    debugPrint("🚨 NOTIFICATION ERROR: $e");
                    if (!mounted) return;
                    _showFeedback(context, "Failed to set Notification");
                  }
                }),

                _buildDialogOption('Set as Default Ringtone', () async {
                  Navigator.pop(dialogContext);
                  try {
                    await RingtoneSet.setRingtoneFromFile(File(song.data));
                    if (!mounted) return;
                    _showFeedback(context, "Ringtone set successfully");
                  } catch (e) {
                    debugPrint("🚨 RINGTONE ERROR: $e");
                    if (!mounted) return;
                    _showFeedback(context, "Failed to set Ringtone");
                  }
                }),

                _buildDialogOption('Share File...', () async {
                  Navigator.pop(dialogContext);
                  try {
                    final xFile = XFile(song.data, mimeType: 'audio/mpeg');
                    await Share.shareXFiles([
                      xFile,
                    ], text: 'Listen to this track!');
                  } catch (e) {
                    debugPrint("🚨 SHARE ERROR: $e");
                    if (!mounted) return;
                    _showFeedback(context, "Failed to share file");
                  }
                }),

                _buildDialogOption('Delete', () {
                  Navigator.pop(dialogContext);
                  _showDeleteConfirmation(context, song);
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



  void _showDeleteConfirmation(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (BuildContext confirmContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete File?',
            style: TextStyle(color: Color(0xFF2D3142)),
          ),
          content: Text(
            'Are you sure you want to permanently delete "${song.title}"?',
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
                  final file = File(song.data);
                  if (await file.exists()) {
                    await file.delete();


                    if (!mounted) return;

                    setState(() {
                      _fetchSongs();
                    });

                    _showFeedback(context, "File deleted successfully");
                  }
                } catch (e) {
                  if (!mounted) return;
                  _showFeedback(
                    context,
                    "Permission denied: Android OS restricts deleting system media files.",
                  );
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
