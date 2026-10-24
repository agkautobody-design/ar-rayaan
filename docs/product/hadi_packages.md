# Hadi packages and hosted AI

Status: capability built, switched off. No billing, no prices, no real AI
endpoint. This file lists what the owner must still decide.

## What exists in the app

| Piece | Where | Notes |
| --- | --- | --- |
| Package enum and the one limits table | `lib/app/core/packages/hadi_package.dart` | `free`, `plus`, `family` mirror the tier ids in `assets/system/subscription.json`. Names and every number are placeholders (`TODO-OWNER`). |
| UsageMeter | `lib/app/core/packages/usage_meter.dart` | Per-day and per-month counters in shared_preferences, local calendar. Hosted messages only. |
| HostedAi interface | `lib/features/hadi/data/hosted_ai.dart` | Abstract backend. Default is `UnavailableHostedAi`, so nothing changes until the owner supplies one. |
| "X of Y left today" | `hadi_usage_line.dart` | Shown only when a backend exists. |
| Entitlement | `lib/app/core/subscription/` (already existed) | `hadiPackageProvider` reads it. Expired or inactive means `free`. |

The older managed-key quota (`SubscriptionService.consumeQuestion`, used by
Hadi and Wasia when a per-user key is active) is untouched. Once the proxy
exists, that path should be retired in favour of this one (one meter, one
table). Wasia is not on the new meter yet.

## How a question is answered

1. Safety first, as before: crisis, child-safety, grief, personal rulings.
   None of these ever reaches a hosted model or the meter.
2. The built-in checked library answers first. It is free, unmetered, and
   never paywalled (core religious answers, du'as, guides).
3. Only if the library has no answer (it would refuse) and the question is
   not ruling-shaped or medical, and no own API key is set, Hadi may use the
   hosted tier, if the package allowance has room.
4. A hosted reply goes through the same reference verifier and ruling filter
   as any live reply, is shortened to the package's max length, and always
   ends with: "AI-generated, may be wrong. Check with a scholar."
5. At the cap, Hadi says the allowance is used up, says when it returns, and
   shows the library's own reply. A failed call is refunded.

A person who supplies their own AI key keeps the existing path (no meter).

## Security: the real cap lives on a server

A cap kept on the phone can be reset by clearing storage or patching the app.
The local meter is a courtesy display. The real backend must be a server
proxy that:

- holds the provider key (the app ships no secret and never will);
- authenticates the user and checks the entitlement itself (the `package`
  field the app sends is a hint, not proof);
- enforces the per-user day and month cap, and answers with a cap-reached
  response, which the app maps to `HostedAiCapReached`;
- applies the guardrail prompt on its side as well (the app sends
  `kHadiSystemPrompt` plus scope rules, but the server must not rely on that);
- logs counts, not conversation text, and states its retention in the privacy
  page before launch.

## Owner decisions still needed

1. Package names (placeholders: Free, Plus, Family).
2. Prices and currencies, and whether there is a free hosted allowance at
   all. (None invented here. The free row is a placeholder of 3 a day.)
3. Limits per package: messages per day and per month, max reply length,
   any feature flags. Placeholders: free 3/30, plus 30/600, family 100/2000.
   Plus and family daily figures come from `subscription.json`.
4. The server proxy: who builds and hosts it, the sign-in it uses, and where
   the cap is stored.
5. The AI provider and model, and its data-use terms (no training on user
   questions is the intent to confirm).
6. The privacy and sources wording for hosted answers (a scholar should
   review the label and cap wording).
7. Whether Wasia and the Family Wing should share the same meter.
8. Billing: still closed (`SandboxBillingGateway` refuses in release builds).
   Opening it is a separate decision.
