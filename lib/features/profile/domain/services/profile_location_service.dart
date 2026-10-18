import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationFailure implements Exception {
  const LocationFailure(this.message, {this.settings = false});
  final String message;
  final bool settings;
}

/// Only returns a city/country label. Coordinates never enter the profile payload.
class ProfileLocationService {
  ProfileLocationService({
    Future<bool> Function()? enabled,
    Future<LocationPermission> Function()? check,
    Future<LocationPermission> Function()? request,
    Future<String> Function()? resolve,
  }) : _native = resolve == null,
       _enabled = enabled ?? Geolocator.isLocationServiceEnabled,
       _check = check ?? Geolocator.checkPermission,
       _request = request ?? Geolocator.requestPermission,
       _resolve = resolve ?? _resolveNative;
  final bool _native;
  final Future<bool> Function() _enabled;
  final Future<LocationPermission> Function() _check, _request;
  final Future<String> Function() _resolve;
  Future<String> locateCity() async {
    if (_native &&
        (kIsWeb ||
            ![
              TargetPlatform.android,
              TargetPlatform.iOS,
            ].contains(defaultTargetPlatform))) {
      throw const LocationFailure(
        'Bu cihazda şehir tespiti desteklenmiyor. Şehrini elle yazabilirsin.',
      );
    }
    if (!await _enabled()) {
      throw const LocationFailure(
        'Konum servisi kapalı. Açabilir veya şehrini elle yazabilirsin.',
      );
    }
    var permission = await _check();
    if (permission == LocationPermission.denied) permission = await _request();
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Konum izni kapalı. Ayarlardan açabilir veya şehrini elle yazabilirsin.',
        settings: true,
      );
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const LocationFailure(
        'Konum izni verilmedi. Şehrini elle yazabilir veya boş bırakabilirsin.',
      );
    }
    return _resolve().timeout(const Duration(seconds: 20));
  }

  static Future<String> _resolveNative() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      throw const LocationFailure(
        'Bu cihazda şehir tespiti desteklenmiyor. Şehrini elle yazabilirsin.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final places = await Geocoding().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
      locale: const Locale('tr', 'TR'),
    );
    for (final place in places) {
      final city =
          (place.administrativeArea?.trim().isNotEmpty == true
                  ? place.administrativeArea
                  : place.locality)
              ?.trim() ??
          '';
      if (city.isNotEmpty) {
        return [
          city,
          if (place.country?.isNotEmpty == true) place.country!,
        ].join(', ');
      }
    }
    throw const LocationFailure(
      'Şehir bulunamadı. Şehrini elle yazabilir veya boş bırakabilirsin.',
    );
  }
}
