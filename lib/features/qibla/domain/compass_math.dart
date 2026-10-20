import 'dart:math' as math;

/// Pure compass maths for the live Qibla dial.
abstract final class CompassMath {
  /// Compass heading (degrees clockwise from MAGNETIC north, 0-360) of the
  /// direction the phone faces, from the W3C DeviceOrientation angles
  /// (alpha = rotation about z, counter-clockwise from north; beta = about
  /// x; gamma = about y; all degrees).
  ///
  /// Held roughly flat (|beta| up to 50 degrees, how a Qibla compass is
  /// used) it is the direction of the TOP edge: the device's y axis in world
  /// coordinates is (-sin a cos b, cos a cos b, sin b), so the heading is
  /// atan2(-sin a, cos a), unaffected by tilt or roll. Held upright (for
  /// example when the phone is raised) the top edge points at the sky, so
  /// the heading of the back of the phone is used instead (the W3C
  /// tilt-compensated formula).
  static double headingFromOrientation({
    required double alpha,
    required double beta,
    required double gamma,
  }) {
    final double a = alpha * math.pi / 180;
    final double sA = math.sin(a);
    final double cA = math.cos(a);
    if (beta.abs() <= 50) {
      return normalize(math.atan2(-sA, cA) * 180 / math.pi);
    }
    final double b = beta * math.pi / 180;
    final double g = gamma * math.pi / 180;
    final double sB = math.sin(b);
    final double cG = math.cos(g);
    final double sG = math.sin(g);
    final double vx = -cA * sG - sA * sB * cG;
    final double vy = -sA * sG + cA * sB * cG;
    return normalize(math.atan2(vx, vy) * 180 / math.pi);
  }

  /// [degrees] folded into 0 ≤ x < 360.
  static double normalize(double degrees) {
    final double d = degrees % 360;
    return d < 0 ? d + 360 : d;
  }

  /// Smallest signed difference [to] − [from] in degrees, in (−180, 180].
  static double shortestDelta(double from, double to) {
    double d = (to - from) % 360;
    if (d > 180) d -= 360;
    if (d <= -180) d += 360;
    return d;
  }

  /// Low-pass filter for jittery sensor headings, correct across the
  /// 359° → 0° wrap. [factor] in (0, 1]; 1 = no smoothing.
  static double smooth(double previous, double next, {double factor = 0.25}) {
    return normalize(previous + shortestDelta(previous, next) * factor);
  }

  /// TRUE heading from a MAGNETIC heading and the local magnetic
  /// declination (degrees, east positive, west negative).
  static double trueHeading(double magneticHeading, double declination) =>
      normalize(magneticHeading + declination);

  /// Angle (degrees clockwise, −180…180) from the direction the phone's top
  /// faces to the Qibla: 0 means the top of the phone points at the Kaaba.
  static double offsetToQibla({
    required double qiblaBearing,
    required double trueHeading,
  }) => shortestDelta(trueHeading, qiblaBearing);

  /// True when recent magnetic [headings] (oldest first) jump back and forth
  /// instead of moving steadily, which is what a phone near metal, a magnet
  /// or an uncalibrated sensor looks like. Turning on the spot gives a
  /// one-way run of changes and is not flagged.
  ///
  /// Method: take the changes between consecutive readings, keep those larger
  /// than [minStep] degrees, and flag the window when at least
  /// [minSteps] such changes exist and [reversalShare] of neighbouring pairs
  /// change direction.
  static bool isErratic(
    List<double> headings, {
    double minStep = 4,
    int minSteps = 6,
    double reversalShare = 0.6,
  }) {
    final List<double> steps = <double>[];
    for (int i = 1; i < headings.length; i++) {
      final double d = shortestDelta(headings[i - 1], headings[i]);
      if (d.abs() > minStep) steps.add(d);
    }
    if (steps.length < minSteps) return false;
    int reversals = 0;
    for (int i = 1; i < steps.length; i++) {
      if ((steps[i] > 0) != (steps[i - 1] > 0)) reversals++;
    }
    return reversals / (steps.length - 1) >= reversalShare;
  }
}
