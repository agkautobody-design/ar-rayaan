/// The one thing the Masajid / Halal Food screen should show below the map.
///
/// Before this existed the screen could say "Live search failed" and "No
/// masajid found" together. Exactly one phase applies at a time.
enum MasjidPhase {
  /// No place yet: ask for a location or a city.
  needsPlace,

  /// A search is running.
  loading,

  /// The map service could not be reached and there is nothing to show.
  failed,

  /// The search worked and returned nothing.
  empty,

  /// Results to show (possibly with a failed refresh noted above them).
  results,
}

/// Pure mapping from the screen's facts to the phase it shows.
///
/// [failed] means the last network call failed. A failure never counts as
/// "none found": that wording is only for a search that really returned zero.
MasjidPhase masjidPhaseFor({
  required bool hasPlace,
  required bool loading,
  required bool failed,
  required int resultCount,
}) {
  if (!hasPlace) return MasjidPhase.needsPlace;
  if (loading) return MasjidPhase.loading;
  if (resultCount > 0) return MasjidPhase.results;
  if (failed) return MasjidPhase.failed;
  return MasjidPhase.empty;
}

/// Plain-words status for a [MasjidPhase], or null when the list itself is
/// the answer. [food] switches the noun.
String? masjidStatusText(MasjidPhase phase, {required bool food}) {
  final String noun = food ? 'halal places' : 'masajid';
  switch (phase) {
    case MasjidPhase.needsPlace:
      return null;
    case MasjidPhase.loading:
      return 'Searching for $noun nearby…';
    case MasjidPhase.failed:
      return 'Could not reach the map service, so we cannot tell what is '
          'nearby yet. Check your connection and try again.';
    case MasjidPhase.empty:
      return food
          ? 'No halal places found in this area’s open map data. Try a '
              'nearby city search.'
          : 'No masajid found in this area’s open map data. Try a '
              'nearby city search, or contribute the mosque to '
              'OpenStreetMap so the whole ummah finds it.';
    case MasjidPhase.results:
      return null;
  }
}

/// A web map search for the same thing, for when live search is down. Opens
/// in the browser or the maps app, so the person is never left with nothing.
Uri masjidFallbackMapUri({
  required double lat,
  required double lon,
  required bool food,
}) {
  final String q = food ? 'halal restaurant' : 'mosque';
  return Uri.parse(
    'https://www.google.com/maps/search/${Uri.encodeComponent(q)}/@$lat,$lon,14z',
  );
}
