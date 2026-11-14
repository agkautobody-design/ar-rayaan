import 'package:ar_rayaan/features/masjid/domain/directions_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each app gets a universal https link with the coordinates only', () {
    final Uri g = directionsUri(DirectionsApp.googleMaps, 43.5, -79.9);
    final Uri w = directionsUri(DirectionsApp.waze, 43.5, -79.9);
    final Uri a = directionsUri(DirectionsApp.appleMaps, 43.5, -79.9);
    expect(g.host, 'www.google.com');
    expect(g.queryParameters['destination'], '43.5,-79.9');
    expect(w.host, 'waze.com');
    expect(w.queryParameters['ll'], '43.5,-79.9');
    expect(w.queryParameters['navigate'], 'yes');
    expect(a.host, 'maps.apple.com');
    expect(a.queryParameters['daddr'], '43.5,-79.9');
    for (final Uri u in <Uri>[g, w, a]) {
      expect(u.scheme, 'https');
    }
  });

  test('names for the chooser', () {
    expect(directionsAppName(DirectionsApp.waze), 'Waze');
    expect(DirectionsApp.values.length, 3);
  });
}
