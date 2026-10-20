/// Magnetic declination (the angle between true north and magnetic north)
/// from the World Magnetic Model 2025, computed fully offline.
///
/// A phone compass reads MAGNETIC north; the Qibla bearing is measured from
/// TRUE north. The difference is the declination, which depends on where you
/// are and drifts every year, so the model carries yearly change terms.
///
/// The method is the standard spherical-harmonic synthesis of the WMM
/// technical report (Chulliat et al., "The US/UK World Magnetic Model for
/// 2025-2030", NOAA NCEI, doi:10.25923/9rvb-y322): Schmidt semi-normalised
/// Legendre functions, geodetic to geocentric conversion on the WGS-84
/// ellipsoid, geocentric field rotated back to geodetic north/east/down.
/// The coefficients are in `wmm2025_coefficients.dart`; this implementation
/// reproduces all twelve of NOAA's published WMM2025 test values (see
/// `test/magnetic_declination_test.dart`).
///
/// Accuracy: the model's own stated error is about 0.5 degrees in declination
/// at the surface away from the poles, and it is not meaningful near the
/// magnetic poles. It does not include local magnetic anomalies such as steel
/// in a building or a car, which a phone sensor will pick up regardless.
library;

import 'dart:math' as math;

import 'wmm2025_coefficients.dart';

/// Result of a declination lookup.
class MagneticDeclination {
  const MagneticDeclination({
    required this.degrees,
    required this.withinValidity,
    required this.decimalYear,
  });

  /// Degrees, east positive, west negative (true = magnetic + declination).
  final double degrees;

  /// False when [decimalYear] is outside the 2025.0 to 2030.0 span the
  /// model was issued for; the number is then an extrapolation.
  final bool withinValidity;

  final double decimalYear;
}

abstract final class MagneticModel {
  /// Semi-major axis of the WGS-84 ellipsoid, km.
  static const double _a = 6378.137;

  /// First eccentricity squared of WGS-84.
  static const double _e2 = 0.00669437999014;

  /// WMM geomagnetic reference radius, km.
  static const double _refRadius = 6371.2;

  static const int _nMax = 12;

  /// Decimal year of [date] (for example 2026-07-01 is about 2026.5).
  static double decimalYear(DateTime date) {
    final DateTime start = DateTime.utc(date.year);
    final DateTime end = DateTime.utc(date.year + 1);
    final DateTime utc = date.toUtc();
    final double fraction =
        utc.difference(start).inMilliseconds /
        end.difference(start).inMilliseconds;
    return date.year + fraction;
  }

  /// Declination at [latitude] / [longitude] (degrees) and [heightKm] above
  /// the ellipsoid for [date].
  static MagneticDeclination declination({
    required double latitude,
    required double longitude,
    required DateTime date,
    double heightKm = 0,
  }) {
    final double year = decimalYear(date);
    final (double x, double y, double _) = fieldComponents(
      latitude: latitude,
      longitude: longitude,
      decimalYear: year,
      heightKm: heightKm,
    );
    return MagneticDeclination(
      degrees: math.atan2(y, x) * 180 / math.pi,
      withinValidity: year >= kWmmValidFrom && year < kWmmValidTo,
      decimalYear: year,
    );
  }

  /// Declination in degrees from north (x) and east (y) field components.
  static double declinationFromComponents(double x, double y) =>
      math.atan2(y, x) * 180 / math.pi;

  /// North (x), east (y) and down (z) field components in nT at the
  /// geodetic position, for a decimal year.
  static (double, double, double) fieldComponents({
    required double latitude,
    required double longitude,
    required double decimalYear,
    double heightKm = 0,
  }) {
    final double dt = decimalYear - kWmmEpoch;
    // Keep clear of the poles, where east is undefined.
    final double latClamped = latitude.clamp(-89.999, 89.999).toDouble();
    final double phi = latClamped * math.pi / 180;
    final double lambda = longitude * math.pi / 180;
    final double sinPhi = math.sin(phi);
    final double cosPhi = math.cos(phi);

    // Geodetic to geocentric spherical coordinates.
    final double rc = _a / math.sqrt(1 - _e2 * sinPhi * sinPhi);
    final double p = (rc + heightKm) * cosPhi;
    final double z = (rc * (1 - _e2) + heightKm) * sinPhi;
    final double r = math.sqrt(p * p + z * z);
    final double phiGeocentric = math.asin(z / r);
    final double theta = math.pi / 2 - phiGeocentric; // colatitude
    final double st = math.sin(theta);
    final double ct = math.cos(theta);

    // Schmidt semi-normalised associated Legendre functions and their
    // derivatives with respect to colatitude.
    final List<List<double>> pnm = List<List<double>>.generate(
      _nMax + 1,
      (_) => List<double>.filled(_nMax + 1, 0),
    );
    final List<List<double>> dpnm = List<List<double>>.generate(
      _nMax + 1,
      (_) => List<double>.filled(_nMax + 1, 0),
    );
    pnm[0][0] = 1;
    for (int n = 1; n <= _nMax; n++) {
      for (int m = 0; m <= n; m++) {
        if (n == m) {
          final double k = n == 1 ? 1.0 : math.sqrt(1.0 - 1.0 / (2 * n));
          pnm[n][n] = st * k * pnm[n - 1][n - 1];
          dpnm[n][n] = k * (st * dpnm[n - 1][n - 1] + ct * pnm[n - 1][n - 1]);
        } else {
          final double d = math.sqrt((n * n - m * m).toDouble());
          final double p2 = n >= 2 ? pnm[n - 2][m] : 0;
          final double dp2 = n >= 2 ? dpnm[n - 2][m] : 0;
          final double k2 = n >= 2
              ? math.sqrt(((n - 1) * (n - 1) - m * m).toDouble())
              : 0;
          pnm[n][m] = ((2 * n - 1) * ct * pnm[n - 1][m] - k2 * p2) / d;
          dpnm[n][m] =
              ((2 * n - 1) * (ct * dpnm[n - 1][m] - st * pnm[n - 1][m]) -
                  k2 * dp2) /
              d;
        }
      }
    }

    // Synthesis of the geocentric field.
    double br = 0;
    double bt = 0;
    double bl = 0;
    final double ratio = _refRadius / r;
    for (final WmmRow row in kWmm2025) {
      final int n = row.$1;
      final int m = row.$2;
      final double g = row.$3 + dt * row.$5;
      final double h = row.$4 + dt * row.$6;
      final double f = math.pow(ratio, n + 2).toDouble();
      final double c = math.cos(m * lambda);
      final double s = math.sin(m * lambda);
      br += f * (n + 1) * (g * c + h * s) * pnm[n][m];
      bt -= f * (g * c + h * s) * dpnm[n][m];
      bl += f * m * (g * s - h * c) * pnm[n][m] / st;
    }

    // Geocentric (north, east, down) to geodetic.
    final double xp = -bt;
    final double yp = bl;
    final double zp = -br;
    final double psi = phiGeocentric - phi;
    final double x = xp * math.cos(psi) - zp * math.sin(psi);
    final double zz = xp * math.sin(psi) + zp * math.cos(psi);
    return (x, yp, zz);
  }
}
