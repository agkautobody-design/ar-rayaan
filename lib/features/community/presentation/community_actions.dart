import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/router.dart';
import '../application/community_state.dart';

/// Before a person writes anything (a thread, a reply, a meet-up, a sign-up)
/// they must be able to: not muted, shown in the community, and have accepted
/// the current rules. This walks them through whatever is missing and returns
/// true only when writing can go ahead. The server checks all of it again.
Future<bool> ensureCanWrite(
  BuildContext context,
  WidgetRef ref,
  MeResponse me,
) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  CommunityRulesStatus s;
  try {
    s = await ref.refresh(communityRulesProvider.future);
  } on BackendException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
  if (s.mutedUntil != null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('You cannot post right now. See your notices.'),
      ),
    );
    return false;
  }
  if (!context.mounted) return false;
  if (!s.communityVisible) {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        semanticLabel: 'Show your name?',
        title: const Text('Show your name?'),
        content: const Text(
          'To write in the community, your display name is shown on your '
          'posts and meet-ups. Do you want to be visible in the community?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Yes, show my name'),
          ),
        ],
      ),
    );
    if (yes != true) return false;
    final BackendProfile? p = me.profile;
    if (p == null) return false;
    try {
      await ref
          .read(communityApiProvider)
          .saveProfile(
            displayName: p.displayName,
            handle: p.handle,
            bio: p.bio,
            visibility: ProfileVisibility.community,
          );
    } on BackendException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    }
    ref.invalidate(communityMeProvider);
  }
  if (!context.mounted) return false;
  if (!s.accepted) {
    final bool? ok = await context.push<bool>(AppRoutes.communityRules);
    ref.invalidate(communityRulesProvider);
    return ok == true;
  }
  return true;
}
