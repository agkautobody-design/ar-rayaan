import 'package:ar_rayaan/features/masjid/domain/masjid_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _p(String n, double la, double lo) =>
    <String, dynamic>{'display_name': n, 'lat': '$la', 'lon': '$lo'};

void main() {
  final List<dynamic> milton = <dynamic>[
    _p('Milton, Norfolk County, Massachusetts, United States', 42.2495, -71.0662),
    _p('Milton, Halton Region, Ontario, Canada', 43.5183, -79.8774),
    _p('Milton Township, Massachusetts, United States', 42.25, -71.07),
  ];

  test('same-town duplicates collapse, far-apart places stay', () {
    final List<PlaceChoice> c = placeChoicesFrom(milton);
    expect(c.length, 2);
    expect(c.first.label, contains('Massachusetts'));
    expect(c.last.label, contains('Ontario'));
  });

  test('a saved place near Ontario puts Ontario first', () {
    final List<PlaceChoice> c =
        placeChoicesFrom(milton, nearLat: 43.5, nearLon: -79.9);
    expect(c.first.label, contains('Ontario'));
  });

  test('one match, junk entries and empty answers', () {
    expect(placeChoicesFrom(<dynamic>[_p('Only Town', 1, 2)]).length, 1);
    expect(placeChoicesFrom(<dynamic>[<String, dynamic>{'lat': 'x', 'lon': '1'}, 'junk']), isEmpty);
    expect(placeChoicesFrom(<dynamic>[]), isEmpty);
  });

  test('never more than five', () {
    final List<dynamic> many = <dynamic>[
      for (int i = 0; i < 9; i++) _p('Town $i', i * 5.0, i * 5.0),
    ];
    expect(placeChoicesFrom(many).length, 5);
  });
}
