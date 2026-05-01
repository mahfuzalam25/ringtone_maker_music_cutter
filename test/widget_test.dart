import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Import all your pages
import 'package:ringtone_maker_music_cutter/features/home/home_page.dart';
import 'package:ringtone_maker_music_cutter/features/home/recordings_page.dart';
import 'package:ringtone_maker_music_cutter/features/home/saved_tones_page.dart';
import 'package:ringtone_maker_music_cutter/features/editor/audio_selection_page.dart';
import 'package:ringtone_maker_music_cutter/features/editor/file_loaded_page.dart';
import 'package:ringtone_maker_music_cutter/features/editor/waveform_editor_page.dart';
import 'package:ringtone_maker_music_cutter/features/editor/saved_success_page.dart';
import 'package:ringtone_maker_music_cutter/features/editor/record_audio_page.dart';

void main() {
  // --- TEST SETUP & HARDWARE MOCKING ---
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    final testDir = Directory.systemTemp.createTempSync('ringtone_test_dir');

    // 1. Mock Path Provider (Storage)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getApplicationDocumentsDirectory' ||
                methodCall.method == 'getTemporaryDirectory') {
              return testDir.path;
            }
            return null;
          },
        );

    // 2. Mock OnAudioQuery (Music Library scanning)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.lucasjosino.on_audio_query'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'querySongs') {
              return [];
            }
            return null;
          },
        );

    // 3. Mock Just Audio (Audio Player)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.just_audio.methods'),
          (MethodCall methodCall) async {
            return {};
          },
        );
  });

  group('Ringtone Maker UI Smoke Tests', () {
    // --- HOME SECTION ---

    testWidgets('HomePage renders all grid items and headers', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Studio'), findsOneWidget);
      expect(find.text('Mp3 Cutter & Ringtone Maker'), findsOneWidget);
      expect(find.text('Cut Audio'), findsOneWidget);
      expect(find.text('Record'), findsOneWidget);
      expect(find.text('Saved Tones'), findsOneWidget);
      expect(find.text('Recordings'), findsOneWidget);
    });

    testWidgets('RecordingsPage renders empty state successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RecordingsPage()));

      // FIX: Loop the pump to clear the multiple async 'await' gaps in this specific page
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('My Recordings'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('No voice recordings yet.'), findsOneWidget);
    });

    testWidgets('SavedTonesPage renders empty state successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SavedTonesPage()));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('My Creations'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('No saved ringtones yet.'), findsOneWidget);
    });

    // --- EDITOR SECTION ---

    testWidgets('AudioSelectionPage renders empty list state successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AudioSelectionPage()));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('All Available Music'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('No music found on this device'), findsOneWidget);
    });

    testWidgets('FileLoadedPage renders success icons and buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: FileLoadedPage(filePath: 'dummy_audio.mp3')),
      );

      expect(find.text('File Loaded Successfully'), findsOneWidget);
      expect(find.text('CONTINUE TO EDIT'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('WaveformEditorPage renders header and default UI', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: WaveformEditorPage(filePath: 'test_song.mp3')),
      );
      await tester.pump();

      expect(find.text('test_song.mp3'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('SavedSuccessPage renders dynamic action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SavedSuccessPage(
            savedFilePath: 'new_ringtone.mp3',
            saveType: 'Ringtone',
          ),
        ),
      );

      expect(find.text('Saved!'), findsOneWidget);
      expect(
        find.text('Saved! Make this your default ringtone?'),
        findsOneWidget,
      );
      expect(find.text('SHARE FILE ...'), findsOneWidget);
      expect(find.text('MAKE DEFAULT'), findsOneWidget);
      expect(find.text('CONTINUE EDITING'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
    });

    testWidgets('RecordAudioPage renders timer and controls', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RecordAudioPage()));

      expect(find.text('MP3 Cutter and Ringtone Maker'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Audio quality:'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Tap the button to start recording'), findsOneWidget);
    });
  });
}
