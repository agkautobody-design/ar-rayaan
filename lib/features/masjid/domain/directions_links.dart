/// Map apps a place can be opened in for directions.
enum DirectionsApp { googleMaps, waze, appleMaps }

String directionsAppName(DirectionsApp a) {
  switch (a) {
    case DirectionsApp.googleMaps:
      return 'Google Maps';
    case DirectionsApp.waze:
      return 'Waze';
    case DirectionsApp.appleMaps:
      return 'Apple Maps';
  }
}

/// A universal https link, so a phone with the app installed opens the app
/// and any other device (or the web) opens the site. Coordinates only: no
/// name, no home address, nothing about the person.
Uri directionsUri(DirectionsApp app, double lat, double lon) {
  switch (app) {
    case DirectionsApp.googleMaps:
      return Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    case DirectionsApp.waze:
      return Uri.parse('https://waze.com/ul?ll=$lat,$lon&navigate=yes');
    case DirectionsApp.appleMaps:
      return Uri.parse('https://maps.apple.com/?daddr=$lat,$lon&dirflg=d');
  }
}
