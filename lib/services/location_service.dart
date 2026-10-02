import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/rules.dart';

class LocationFailure implements Exception {
  final String message;
  final bool appSettings;
  final bool locationSettings;
  const LocationFailure(
    this.message, {
    this.appSettings = false,
    this.locationSettings = false,
  });
}

class CapturedLocation {
  final double latitude, longitude, accuracy;
  final int timestamp;
  const CapturedLocation(
    this.latitude,
    this.longitude,
    this.accuracy,
    this.timestamp,
  );
}

class LocationService {
  Future<CapturedLocation> capture() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationFailure(
          'Location services are disabled.',
          locationSettings: true,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(
          'Location permission is permanently denied. Enable it in settings.',
          appSettings: true,
        );
      }
      if (permission == LocationPermission.denied && !kIsWeb) {
        throw const LocationFailure(
          'Location permission was denied. Retry or continue without location.',
        );
      }
      // Some browsers do not expose the Permissions API. getCurrentPosition
      // still triggers the browser prompt after this explicit user action.
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      ).timeout(const Duration(seconds: 25));
      final time = p.timestamp.toUtc().millisecondsSinceEpoch;
      Rules.validateLocation(p.latitude, p.longitude, time);
      return CapturedLocation(p.latitude, p.longitude, p.accuracy, time);
    } on LocationFailure {
      rethrow;
    } on TimeoutException {
      throw const LocationFailure(
        'Location timed out. Retry outdoors or continue without location.',
      );
    } catch (_) {
      throw const LocationFailure(
        'Position unavailable. Check device or browser permissions, then retry or continue without location.',
      );
    }
  }

  Future<bool> openSettings({required bool app}) async {
    if (kIsWeb) return false;
    try {
      return app
          ? await Geolocator.openAppSettings()
          : await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }
}
