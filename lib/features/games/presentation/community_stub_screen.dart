import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_typography.dart';
import '../ui/games_theme.dart';

/// /games/community - friends, invitations, a waiting room, "your turn" and
/// who is online. These need accounts and a community service that the app
/// does not have yet, so this page only says so. Nothing links here while
/// `kGamesCommunityEnabled` is false.
class CommunityGamesStubScreen extends StatelessWidget {
  const CommunityGamesStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          const ArchHeader(
            title: 'Games with community',
            tagline: 'Coming with community',
            band: true,
          ),
          GamePanel(
            ornate: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Coming with community',
                  style: AppText.titleMedium.copyWith(
                    color: GamesTheme.champagne,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inviting friends and family, a waiting room, "your turn" '
                  'alerts and seeing who is online need accounts and an '
                  'online community service. The app does not have that '
                  'yet, so none of it is switched on.',
                  style: AppText.body.copyWith(height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'What works today: pass and play on one device, and '
                  'one-to-one tables in Ludo and Shatranj with a six-letter '
                  'code. There is no chat, ever, for children.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(
        children: <Widget>[
          PlayButton(
            label: 'All games',
            onPressed: () => context.go(AppRoutes.games),
          ),
        ],
      ),
    );
  }
}
