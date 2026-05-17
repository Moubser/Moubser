import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../core/theme/app_colors.dart';
import '../../di/locator.dart';
import '../../services/ai_service.dart';
import '../../services/tts_service.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/base_viewmodel.dart';
import '../widgets/arrow_painter.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationViewModel()..init(),
      child: const _NavigationBody(),
    );
  }
}

class _NavigationBody extends StatelessWidget {
  const _NavigationBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NavigationViewModel>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: Text(
            'الملاحة الذكية',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.white,
          elevation: 0,
          leading: vm.mode != AppNavigationMode.none
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: vm.stopNavigation,
                  tooltip: 'العودة للقائمة الرئيسية',
                )
              : null,
          actions: vm.mode == AppNavigationMode.safeAssistant ||
                  vm.mode == AppNavigationMode.buildingNavigation
              ? [
                  IconButton(
                    onPressed: vm.stopNavigation,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'إيقاف',
                  ),
                ]
              : null,
        ),
        body: Builder(builder: (context) {
          switch (vm.mode) {
            case AppNavigationMode.none:
              return _MainMenuScreen(vm: vm);
            case AppNavigationMode.buildingSelection:
              return _SelectionScreen(vm: vm);
            case AppNavigationMode.safeAssistant:
              return _ArNavigationScreen(vm: vm, isSafeAssistant: true);
            case AppNavigationMode.buildingNavigation:
              return _ArNavigationScreen(vm: vm, isSafeAssistant: false);
          }
        }),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Main Menu Mode – Choose navigation type
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _MainMenuScreen extends StatelessWidget {
  final NavigationViewModel vm;
  const _MainMenuScreen({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'زر: مسار الوصول. للتوجيه الجغرافي نحو مباني الجامعة.',
            button: true,
            child: _MenuButton(
              title: 'مسار الوصول',
              subtitle: 'التوجيه نحو مباني الجامعة',
              icon: Icons.map_rounded,
              color: AppColors.primary,
              onTap: vm.startBuildingSelection,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            label:
                'زر: المساعد العام للتنقل الآمن. لتشغيل الكاميرا وتحليل المحيط صوتياً.',
            button: true,
            child: _MenuButton(
              title: 'المساعد العام للتنقل الآمن',
              subtitle: 'تحليل البيئة المحيطة بالكاميرا',
              icon: Icons.remove_red_eye_rounded,
              color: AppColors.accent,
              onTap: vm.startSafeNavigation,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Selection Mode – choose building
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SelectionScreen extends StatelessWidget {
  final NavigationViewModel vm;
  const _SelectionScreen({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المباني المتاحة',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          if (vm.state == ViewState.busy && vm.buildings.isEmpty)
            const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          if (vm.buildings.isEmpty && vm.state != ViewState.busy)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.location_city_rounded,
                        size: 64, color: AppColors.grey.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد مباني مسجلة حالياً',
                      style: GoogleFonts.cairo(
                          color: AppColors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ...vm.buildings.map((b) => _BuildingCard(building: b, vm: vm)),
        ],
      ),
    );
  }
}

class _BuildingCard extends StatelessWidget {
  final Map<String, dynamic> building;
  final NavigationViewModel vm;
  const _BuildingCard({required this.building, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'مبنى ${building['building_name']}. اضغط للذهاب إليه.',
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              vm.navigateToBuilding(building);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mintBg, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.mintBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      building['building_name'] ?? 'مبنى',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AR Navigation Mode – Camera + Arrow Overlay
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ArNavigationScreen extends StatefulWidget {
  final NavigationViewModel vm;
  final bool isSafeAssistant;
  const _ArNavigationScreen({
    required this.vm,
    required this.isSafeAssistant,
  });

  @override
  State<_ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends State<_ArNavigationScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  String? _cameraError;
  Timer? _visionTimer;
  bool _isAnalyzing = false;
  final _aiService = locator<AiService>();
  final _ttsService = locator<TtsService>();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'لا توجد كاميرا متاحة');
        return;
      }
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraReady = true);
        _startVisionLoop();
      }
    } catch (e) {
      setState(() => _cameraError = 'فشل تشغيل الكاميرا');
    }
  }

  void _startVisionLoop() {
    _visionTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isAnalyzing) return;
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _cameraController!.value.isTakingPicture) {
        return;
      }
      _isAnalyzing = true;
      try {
        final image = await _cameraController!.takePicture();
        if (!mounted) return;
        final bytes = await image.readAsBytes();
        final result = await _aiService.analyzeScene(bytes);
        if (mounted) {
          await _ttsService.speak(result);
        }
      } catch (e) {
        debugPrint('Vision loop error: $e');
      } finally {
        if (mounted) {
          _isAnalyzing = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _visionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Semantics(
      label: widget.isSafeAssistant
          ? 'المساعد العام للتنقل الآمن يعمل.'
          : 'شاشة الملاحة. ${vm.currentInstruction}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Camera preview ──
          if (_cameraReady && _cameraController != null)
            CameraPreview(_cameraController!)
          else if (_cameraError != null)
            Container(
              color: AppColors.primaryDark,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded,
                        color: AppColors.accent, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      _cameraError!,
                      style: GoogleFonts.cairo(
                          color: AppColors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              color: AppColors.primaryDark,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),

          // ── Layer 2: AR Arrow overlay (only for Building Navigation) ──
          if (!widget.isSafeAssistant)
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: ArrowPainter(
                    rotation: vm.arrowRotation,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),

          // ── Layer 3: Instruction panel (bottom) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primaryDark.withOpacity(0.95),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Instruction text
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          widget.isSafeAssistant
                              ? 'يقوم النظام بتحليل البيئة من حولك وتنبيهك بالعوائق...'
                              : vm.currentInstruction,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stop button
                      SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          label: 'إيقاف النظام',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: vm.stopNavigation,
                            icon: const Icon(Icons.stop_rounded),
                            label: Text('إيقاف',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
