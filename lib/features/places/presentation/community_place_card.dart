import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/core/open_link.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../auth/application/auth_providers.dart';
import '../../masjid/domain/masjid_search_service.dart';
import '../application/places_providers.dart';
import '../data/community_places_service.dart';
import '../domain/community_place.dart';
import 'report_place_sheet.dart';

/// A community-submitted place, shown above the open-map results with its
/// honest label and the two taps that keep the map trustworthy.
class CommunityPlaceCard extends ConsumerWidget {
  const CommunityPlaceCard({
    super.key,
    required this.place,
    required this.fromLat,
    required this.fromLon,
  });

  final CommunityPlace place;
  final double fromLat;
  final double fromLon;

  Future<void> _vote(BuildContext context, WidgetRef ref, String kind) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (ref.read(authStateProvider).value == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Sign in with an account to confirm places.')));
      return;
    }
    try {
      final CommunityPlacesService? svc =
          ref.read(communityPlacesServiceProvider);
      if (svc == null) return;
      await svc.vote(placeId: place.id, kind: kind);
      messenger.showSnackBar(SnackBar(
          content: Text(kind == 'confirm'
              ? 'Thank you — marked as still correct.'
              : 'Thank you — flagged for the community.')));
    } on PlacesRejected catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not save that. Check your connection.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double d =
        masjidDistanceMeters(fromLat, fromLon, place.lat, place.lon);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(place.name,
                  style: AppText.body.copyWith(
                      fontWeight: FontWeight.w700, fontSize: 14.5)),
            ),
            Text('${(d / 1000).toStringAsFixed(1)} km',
                style: AppText.body
                    .copyWith(color: AppColors.goldLight, fontSize: 12.5)),
          ]),
          if (place.address != null)
            Text(place.address!,
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
          if (place.note != null)
            Text(place.note!,
                style: AppText.bodyMuted.copyWith(fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _chip(place.type == CommunityPlaceType.halalFood
                ? 'halal food'
                : 'masjid'),
            _chip('added by the community — unverified'),
            if (place.confirms > 0)
              _chip('confirmed by ${place.confirms}'),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 4, children: [
            TextButton.icon(
              key: Key('confirm-${place.id}'),
              onPressed: () => _vote(context, ref, 'confirm'),
              icon: const Icon(Icons.thumb_up_alt_outlined,
                  size: 14, color: AppColors.goldLight),
              label: const Text('Still correct',
                  style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
            ),
            TextButton.icon(
              key: Key('flag-${place.id}'),
              onPressed: () => _vote(context, ref, 'flag'),
              icon: const Icon(Icons.thumb_down_alt_outlined,
                  size: 14, color: AppColors.goldLight),
              label: const Text('Problem',
                  style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
            ),
            TextButton(
              onPressed: () => showReportPlaceSheet(
                context,
                targetType: 'place',
                targetId: place.id,
                name: place.name,
              ),
              child: const Text('Report or correct',
                  style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Text(t, style: TextStyle(fontSize: 12, color: AppColors.sand)),
      );
}

/// A community event in the list: title, where, when, and directions.
class CommunityEventCard extends ConsumerWidget {
  const CommunityEventCard({
    super.key,
    required this.event,
    this.fromLat,
    this.fromLon,
  });

  final CommunityEvent event;
  final double? fromLat;
  final double? fromLon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double? d = (fromLat != null && fromLon != null)
        ? masjidDistanceMeters(fromLat!, fromLon!, event.lat, event.lon)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(event.title,
                  style: AppText.body.copyWith(
                      fontWeight: FontWeight.w700, fontSize: 14.5)),
            ),
            if (d != null)
              Text('${(d / 1000).toStringAsFixed(1)} km',
                  style: AppText.body
                      .copyWith(color: AppColors.goldLight, fontSize: 12.5)),
          ]),
          Text(event.where, style: AppText.bodyMuted.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEEE d MMMM, HH:mm').format(event.startsAt),
            style: AppText.body
                .copyWith(color: AppColors.goldLight, fontSize: 12.5),
          ),
          if (event.details != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(event.details!,
                  style: AppText.bodyMuted.copyWith(fontSize: 12)),
            ),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text('added by the community',
                  style: TextStyle(fontSize: 12, color: AppColors.sand)),
            ),
          ]),
          Row(children: [
            TextButton(
              onPressed: () => _directions(context, event),
              child: const Text('Directions',
                  style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => showReportPlaceSheet(
                context,
                targetType: 'event',
                targetId: event.id,
                name: event.title,
              ),
              child: const Text('Report',
                  style: TextStyle(color: AppColors.goldLight, fontSize: 12)),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Same pattern as the masjid cards: straight to the person's map app,
/// and a word for them when nothing opens.
Future<bool> _directions(BuildContext context, CommunityEvent e) {
  return openLinkWithFeedback(
    context,
    Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${e.lat},${e.lon}'),
  );
}
