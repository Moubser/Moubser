import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'base_viewmodel.dart';
import '../../data/repositories/navigation_repository.dart';
import '../../di/locator.dart';
import '../../services/gps_service.dart';
import '../../services/tts_service.dart';

enum AppNavigationMode {
  none,
  safeAssistant,
  buildingSelection,
  buildingNavigation,
}

class NavigationViewModel extends BaseViewModel {
  final NavigationRepository _repo = NavigationRepository();
  final TtsService _tts = locator<TtsService>();
  final GpsService _gpsService = locator<GpsService>();

  AppNavigationMode _mode = AppNavigationMode.none;
  AppNavigationMode get mode => _mode;

  // ── Selection state ──
  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> get buildings => _buildings;

  Map<String, dynamic>? _targetBuilding;

  // ── Navigation state ──
  String _currentInstruction = '';
  String get currentInstruction => _currentInstruction;

  double _distanceToTarget = 0;
  double get distanceToTarget => _distanceToTarget;

  // ── Compass state ──
  double _deviceHeading = 0;
  double get deviceHeading => _deviceHeading;

  double _targetBearing = 0;
  double get targetBearing => _targetBearing;

  /// Relative arrow rotation for the UI overlay (radians).
  double get arrowRotation {
    double diff = (_targetBearing - _deviceHeading) * pi / 180;
    return diff;
  }

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _positionStream;

  // ── Lifecycle ──

  Future<void> init() async {
    await _tts.init();
    await loadBuildings();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _positionStream?.cancel();
    _tts.dispose();
    super.dispose();
  }

  // ── Data loading ──

  Future<void> loadBuildings() async {
    setState(ViewState.busy);
    try {
      _buildings = await _repo.fetchBuildings();
      setState(ViewState.idle);
    } catch (e) {
      setError('خطأ في تحميل المباني: $e');
    }
  }

  // ── Modes ──

  void startSafeNavigation() {
    _mode = AppNavigationMode.safeAssistant;
    _currentInstruction = 'المساعد العام قيد التشغيل';
    _tts.speak('تم تشغيل المساعد العام للتنقل الآمن. بنبهك على اللي حولك.');
    notifyListeners();
  }

  void startBuildingSelection() {
    _mode = AppNavigationMode.buildingSelection;
    notifyListeners();
  }

  Future<void> navigateToBuilding(Map<String, dynamic> building) async {
    setState(ViewState.busy);
    _targetBuilding = building;

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double lat = (building['latitude'] ?? building['lat'] ?? 0.0).toDouble();
      double lng = (building['longitude'] ?? building['lng'] ?? 0.0).toDouble();

      if (lat == 0.0 || lng == 0.0) {
        _tts.speak('إحداثيات المبنى غير متوفرة');
        setError('إحداثيات المبنى غير متوفرة');
        return;
      }

      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, lat, lng);

      if (distance > 2000) {
        // Outside campus scope
        await _tts.speak('أنت برا نطاق الجامعة، بوجهك عبر خرائط قوقل');
        final url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        setState(ViewState.idle);
      } else {
        // Inside campus scope
        _mode = AppNavigationMode.buildingNavigation;
        _distanceToTarget = distance;
        _startCompass();
        _startPositionTracking();
        _updateInstruction();
        setState(ViewState.idle);
        await _tts.speak('بدء التوجيه نحو ${building['building_name']}');
      }
    } catch (e) {
      _tts.speak('فشل تحديد الموقع');
      setError('فشل تحديد الموقع: $e');
    }
  }

  void stopNavigation() {
    _mode = AppNavigationMode.none;
    _targetBuilding = null;
    _currentInstruction = '';
    _distanceToTarget = 0;
    _compassSub?.cancel();
    _compassSub = null;
    _positionStream?.cancel();
    _positionStream = null;
    _tts.stop();
    notifyListeners();
  }

  void stopCurrentMode() {
    stopNavigation();
  }

  // ── Real-time position tracking ──

  void _startPositionTracking() {
    _positionStream?.cancel();
    _positionStream = _gpsService.getPositionStream().listen((position) {
      if (_mode != AppNavigationMode.buildingNavigation || _targetBuilding == null) {
        return;
      }
      _updateRouteProgress(position);
    });
  }

  void _updateRouteProgress(Position position) {
    if (_targetBuilding == null) return;

    double lat = (_targetBuilding!['latitude'] ?? _targetBuilding!['lat']).toDouble();
    double lng = (_targetBuilding!['longitude'] ?? _targetBuilding!['lng']).toDouble();

    _distanceToTarget = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );

    // Bearing to target
    _targetBearing = Geolocator.bearingBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );

    _updateInstruction();
    notifyListeners();

    if (_distanceToTarget < 5.0) {
      _tts.speak('وصلت إلى ${_targetBuilding!['building_name']}');
      stopNavigation();
    }
  }

  // ── Compass ──

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        _deviceHeading = event.heading!;
        notifyListeners();
      }
    });
  }

  // ── Instruction generation ──

  void _updateInstruction() {
    if (_targetBuilding == null) return;

    final String distanceText = _distanceToTarget < 1
        ? 'أقل من متر'
        : '${_distanceToTarget.round()} متر';

    // Calculate relative turn
    double turn = (_targetBearing - _deviceHeading + 360) % 360;
    String direction;

    if (turn < 30 || turn > 330) {
      direction = 'امش قدام';
    } else if (turn >= 30 && turn < 150) {
      direction = 'يمينك';
    } else if (turn >= 150 && turn < 210) {
      direction = 'وراك';
    } else {
      direction = 'يسارك';
    }

    _currentInstruction =
        '$direction $distanceText نحو ${_targetBuilding!['building_name']}';
  }
}
