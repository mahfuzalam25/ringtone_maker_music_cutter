// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ringtone_maker_music_cutter/core/utils/permissions_handler.dart';
import 'package:ringtone_maker_music_cutter/core/widgets/info_popup_widget.dart';
import 'package:ringtone_maker_music_cutter/features/editor/audio_selection_page.dart';
import 'package:ringtone_maker_music_cutter/features/editor/record_audio_page.dart';
import 'package:ringtone_maker_music_cutter/features/home/recordings_page.dart';
import 'package:ringtone_maker_music_cutter/features/home/saved_tones_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Professional color palette
  final Color primaryColor = const Color(0xFF4A00E0);
  final Color secondaryColor = const Color(0xFF8E2DE2);
  final Color backgroundColor = const Color(0xFFF4F7FC);

  // AdMob Banner Variables
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      // adUnitId: 'ca-app-pub-3993160111071835/9450092528', // Real Banner ID
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x404A00E0),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Studio',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mp3 Cutter & Ringtone Maker',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.95,
              children: [
                _buildPremiumCard(
                  title: 'Cut Audio',
                  subtitle: 'Trim songs & music',
                  icon: Icons.content_cut_rounded,
                  gradientColors: [
                    const Color(0xFF00C6FF),
                    const Color(0xFF0072FF),
                  ],
                  onTap: () async {
                    bool hasPermission =
                        await PermissionsHandler.requestStoragePermission(
                          context,
                        );
                    if (!mounted) return;
                    if (hasPermission) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AudioSelectionPage(),
                        ),
                      );
                    } else {
                      _showError('Storage permission is required.');
                    }
                  },
                ),
                _buildPremiumCard(
                  title: 'Record',
                  subtitle: 'Capture & edit voice',
                  icon: Icons.mic_rounded,
                  gradientColors: [
                    const Color(0xFFFF512F),
                    const Color(0xFFDD2476),
                  ],
                  onTap: () async {
                    bool hasMicPermission =
                        await PermissionsHandler.requestMicrophonePermission(
                          context,
                        );
                    if (!mounted) return;
                    if (hasMicPermission) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordAudioPage(),
                        ),
                      );
                    } else {
                      _showError('Microphone permission is required.');
                    }
                  },
                ),
                _buildPremiumCard(
                  title: 'Saved Tones',
                  subtitle: 'My ringtone library',
                  icon: Icons.library_music_rounded,
                  gradientColors: [
                    const Color(0xFFF5AF19),
                    const Color(0xFFF12711),
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedTonesPage(),
                      ),
                    );
                  },
                ),
                _buildPremiumCard(
                  title: 'Recordings',
                  subtitle: 'Saved voice notes',
                  icon: Icons.folder_special_rounded,
                  gradientColors: [
                    const Color(0xFF1D976C),
                    const Color(0xFF93F9B9),
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecordingsPage(),
                      ),
                    );
                  },
                ),
                _buildPremiumCard(
                  title: 'About',
                  subtitle: 'App information',
                  icon: Icons.info_outline_rounded,
                  gradientColors: [
                    const Color(0xFF4568DC),
                    const Color(0xFFB06AB3),
                  ],
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const InfoPopupWidget(
                        title: 'About App',
                        description:
                            'MP3 Cutter & Ringtone Maker is a premium audio utility designed to provide precise trimming and studio-quality recording directly on your device.',
                        buttonText: 'CLOSE',
                      ),
                    );
                  },
                ),
                _buildPremiumCard(
                  title: 'More Apps',
                  subtitle: 'Discover tools',
                  icon: Icons.apps_rounded,
                  gradientColors: [
                    const Color(0xFF3A1C71),
                    const Color(0xFFD76D77),
                  ],
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const InfoPopupWidget(
                        title: 'More from NexaCore',
                        description:
                            'Explore our full suite of professional software tools, productivity apps, and premium utilities available on the Play Store.',
                        buttonText: 'DISCOVER',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ==========================================
          // ADMOB BANNER PLACEMENT
          // ==========================================
          if (_isBannerAdReady && _bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              margin: const EdgeInsets.only(bottom: 16),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            // Fallback empty space if ad fails to load
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: gradientColors.first.withOpacity(0.1),
          highlightColor: gradientColors.first.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
