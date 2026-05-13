import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/tokens.dart';

/// Light-weight current-location picker — OpenStreetMap tiles, a draggable
/// center marker, "use my location" GPS button. Returns the picked
/// coordinates via [Navigator.pop].
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  LatLng _center = const LatLng(12.9716, 77.5946); // Bangalore default
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _center = widget.initial!;
    // Try to grab the device GPS on first open so the dot drops on the user.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation(silent: true));
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() { _locating = true; _error = null; });
    try {
      final svcOk = await Geolocator.isLocationServiceEnabled();
      if (!svcOk) throw 'Turn on Location services';

      final status = await Permission.location.request();
      if (!status.isGranted) throw 'Location permission denied';

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      final pt = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = pt);
      _mapController.move(pt, 16);
    } catch (e) {
      if (!silent) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VTokens.bg,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 19,
              onPositionChanged: (camera, _) => _center = camera.center,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vacado.app',
              ),
            ],
          ),
          // Center pin
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: VTokens.ink, borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 8, offset: const Offset(0, 4))]),
                    child: const Text('Move map to set location',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Container(width: 2, height: 12, color: VTokens.ink),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: VTokens.green, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: VTokens.green.withOpacity(.5), blurRadius: 16, spreadRadius: -2, offset: const Offset(0, 6))],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Row(children: [
                  _circleBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.maybePop(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: VTokens.shadow1),
                      child: const Row(children: [
                        Icon(Icons.search_rounded, size: 18, color: VTokens.ink3),
                        SizedBox(width: 10),
                        Expanded(child: Text('Search a location (coming soon)', style: TextStyle(color: VTokens.ink3, fontSize: 13))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // Bottom action card
          Positioned(
            left: 14, right: 14, bottom: 24,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: const TextStyle(color: VTokens.rose700, fontSize: 12)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(children: [
                      Container(
                        width: 38, height: 38, alignment: Alignment.center,
                        decoration: BoxDecoration(color: VTokens.green25, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.my_location_rounded, size: 18, color: VTokens.green700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selected location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: VTokens.ink3, letterSpacing: .5)),
                          Text('${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      )),
                      TextButton.icon(
                        onPressed: _locating ? null : () => _useMyLocation(),
                        icon: _locating ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.gps_fixed_rounded, size: 16),
                        label: const Text('Locate me'),
                        style: TextButton.styleFrom(foregroundColor: VTokens.green700),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_center),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VTokens.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        child: const Text('Confirm location & add details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42, alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: VTokens.shadow1),
      child: Icon(icon, size: 18, color: VTokens.ink),
    ),
  );
}
