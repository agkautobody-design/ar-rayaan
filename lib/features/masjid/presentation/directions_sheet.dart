import 'package:flutter/material.dart' hide Text;
import 'package:flutter/widgets.dart' as w show Text;

import '../../../app/core/open_link.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../domain/directions_links.dart';

/// "Directions" for a place: asks which map app, then opens it.
Future<void> showDirectionsSheet(
  BuildContext context, {
  required double lat,
  required double lon,
  required String name,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.navy,
    builder: (BuildContext ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Directions',
                style: AppText.body.copyWith(color: AppColors.goldLight)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: w.Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
          ),
        ),
        for (final DirectionsApp a in DirectionsApp.values)
          ListTile(
            key: Key('directions-${a.name}'),
            leading: const Icon(Icons.directions, color: AppColors.gold),
            title: w.Text(directionsAppName(a),
                style: AppText.body.copyWith(fontSize: 14)),
            onTap: () {
              Navigator.of(ctx).pop();
              openLinkWithFeedback(context, directionsUri(a, lat, lon));
            },
          ),
      ]),
    ),
  );
}
