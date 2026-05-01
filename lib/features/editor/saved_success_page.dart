import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ringtone_set_plus/ringtone_set_plus.dart';

class SavedSuccessPage extends StatelessWidget {
  final String savedFilePath;
  final String saveType;

  const SavedSuccessPage({
    super.key,
    required this.savedFilePath,
    required this.saveType,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgDarkBlue = Color(0xFF0D3B66);
    const Color headerColor = Color(0xFF1E88E5);
    const Color buttonColor = Color(0xFF3B8EBB);

    return Scaffold(
      backgroundColor: bgDarkBlue,
      appBar: AppBar(
        backgroundColor: headerColor,
        automaticallyImplyLeading: false, 
        title: const Text(
          'Saved!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              'Saved! Make this your default ${saveType.toLowerCase()}?',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            _buildActionMenuButton('SHARE FILE ...', () async {
              try {
                final xFile = XFile(savedFilePath, mimeType: 'audio/mpeg');
                await Share.shareXFiles([
                  xFile,
                ], text: 'Listen to my new $saveType!');
              } catch (e) {
                debugPrint(
                  "Share error: $e",
                ); 
              }
            }, buttonColor),

            const SizedBox(height: 12),

            _buildActionMenuButton('MAKE DEFAULT', () async {
              try {
                final file = File(savedFilePath);
                if (saveType == 'Alarm') {
                  await RingtoneSet.setAlarmFromFile(file);
                } else if (saveType == 'Notification') {
                  await RingtoneSet.setNotificationFromFile(file);
                } else {
                  await RingtoneSet.setRingtoneFromFile(file);
                }


                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$saveType set successfully!")),
                );
              } catch (e) {

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to set default.")),
                );
              }
            }, buttonColor),

            const SizedBox(height: 12),

            _buildActionMenuButton('CONTINUE EDITING', () {

              Navigator.pop(context);
            }, buttonColor),

            const SizedBox(height: 12),

            _buildActionMenuButton('CLOSE', () {

              Navigator.of(context).popUntil((route) => route.isFirst);
            }, buttonColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenuButton(
    String title,
    VoidCallback onPressed,
    Color color,
  ) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
