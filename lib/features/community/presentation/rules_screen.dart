import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/backend/backend_config.dart';
import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../application/community_state.dart';
import '../domain/community_rules_text.dart';
import 'community_widgets.dart';

/// The community rules and code of conduct. Shown before a person's first
/// post, thread, reply or meet-up, and always reachable from the community
/// home. Accepting records the version on the server.
class CommunityRulesScreen extends ConsumerStatefulWidget {
  const CommunityRulesScreen({super.key});

  @override
  ConsumerState<CommunityRulesScreen> createState() =>
      _CommunityRulesScreenState();
}

class _CommunityRulesScreenState extends ConsumerState<CommunityRulesScreen> {
  bool _agree = false;
  bool _busy = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(communityApiProvider)
          .acceptCommunityRules(kCommunityRulesVersion);
      ref.invalidate(communityRulesProvider);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(AppRoutes.communityHub);
      }
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityGate(
      title: 'Community Rules',
      builder: (BuildContext c, MeResponse me) {
        final bool accepted =
            ref.watch(communityRulesProvider).asData?.value.accepted ?? false;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            if (kCommunityRulesAreDraft)
              GlassCard(
                strong: true,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.edit_note,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DRAFT. These rules are waiting for review by the '
                        'owner and by a scholar. They may change.',
                        style: AppText.body.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text('Our code of conduct', style: AppText.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Please read this before you write anything.',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: 12),
            for (final RulesSection s in kCommunityRules)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          s.title,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final String p in s.points)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 6, right: 8),
                                child: Icon(
                                  Icons.circle,
                                  size: 5,
                                  color: AppColors.sand,
                                ),
                              ),
                              Expanded(child: Text(p, style: AppText.body)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            if (accepted)
              Text(
                'You have accepted these rules.',
                style: AppText.bodyMuted,
                textAlign: TextAlign.center,
              )
            else ...<Widget>[
              CheckboxListTile(
                value: _agree,
                onChanged: (bool? v) => setState(() => _agree = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I have read these rules and I agree to follow them.',
                  style: AppText.body,
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.destructive),
                  ),
                ),
              GoldButton(
                label: 'I agree',
                onPressed: _agree && !_busy ? _accept : null,
              ),
            ],
          ],
        );
      },
    );
  }
}
