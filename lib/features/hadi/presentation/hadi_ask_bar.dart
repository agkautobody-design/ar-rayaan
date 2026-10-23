import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// The "Ask Hādi anything" bar on Home. It is a real text field: what is
/// typed travels with the person to Hādi's chat (`/hadi?q=…`) and is sent
/// there, instead of being lost when the chat opens.
class HadiAskBar extends StatefulWidget {
  const HadiAskBar({super.key});

  @override
  State<HadiAskBar> createState() => _HadiAskBarState();
}

class _HadiAskBarState extends State<HadiAskBar> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _go() {
    final String q = _text.text.trim();
    _text.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    context.go(q.isEmpty ? AppRoutes.hadi : AppRoutes.hadiAsk(q));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 16, right: 2),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          // Not a magnifier: Home's header has the real Search button next
          // to this bar, and two search icons read as a mistake.
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: AppColors.gold.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _text,
              onSubmitted: (String _) => _go(),
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(500),
              ],
              style: AppText.body,
              decoration: InputDecoration(
                hintText: 'Ask Hādi anything..',
                hintStyle: AppText.bodyMuted.copyWith(
                  color: AppColors.sand.withValues(alpha: 0.85),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Send to Hādi',
            onPressed: _go,
            iconSize: 18,
            color: AppColors.gold,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
