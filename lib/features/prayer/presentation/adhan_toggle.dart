import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// The user-owned switch for the autonomous adhan.
class AdhanToggle extends StatefulWidget {
  const AdhanToggle({super.key});

  @override
  State<AdhanToggle> createState() => _AdhanToggleState();
}

class _AdhanToggleState extends State<AdhanToggle> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _on = p.getBool('ar.adhan.autoplay') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(children: [
        const Icon(Icons.notifications_active_outlined,
            size: 16, color: AppColors.goldLight),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Adhan at prayer times',
                style: AppText.body.copyWith(fontSize: 12.5)),
            Text('plays by itself after your first tap (browser rule)',
                style: AppText.bodyMuted.copyWith(fontSize: 9.5)),
          ]),
        ),
        Switch(
          value: _on,
          activeColor: AppColors.gold,
          onChanged: (v) async {
            final p = await SharedPreferences.getInstance();
            await p.setBool('ar.adhan.autoplay', v);
            if (mounted) setState(() => _on = v);
          },
        ),
      ]),
    );
  }
}
