# Data sources and their terms (Zakat live prices)

Last checked: 28 Oct 2026. Covers every outside service the Zakat calculator's
"Use live prices" button talks to. Nothing is contacted on opening the screen:
only when the person taps the button, and then a handful of small requests
(normally two to gold-api.com and one to the daily feed; up to eight if the first addresses fail). No key, no secret, no
account, and nothing about the person's balances is sent.

## How the terms were checked, and the limit of that

The build environment's network proxy refuses `gold-api.com`, `cdn.jsdelivr.net`
and `github.com` page loads (HTTP 403), so the pages were read through the
web-fetch tool, which returns a short machine summary of a page, not the raw
text. The summaries below are paraphrases of those summaries. The owner should
open the three pages once in a browser (links below) and confirm them. This
is in `docs/OWNER_ACTIONS.md`, section 21.

## 1. gold-api.com: gold and silver spot price (US dollars per ounce)

- Used for: `GET https://api.gold-api.com/price/XAU` and `/price/XAG`.
- Terms page: https://gold-api.com/terms (read 28 Oct 2026).
  - Section 3: use for lawful purposes only.
  - Section 9: commercial use is allowed, "including use in web applications,
    mobile apps" and sites built for clients.
  - Section 4: no spamming or abusing the API; several requests a second can
    get an address banned, and the operator may ban without notice.
  - Sections 5 and 6: provided "as is"; no guarantee of accuracy; the user is
    solely responsible for checking the data before relying on it.
  - Not addressed: attribution, redistribution, caching.
- Home page and docs: the real-time price endpoint is free, "no restrictions
  on how many requests", no credit card; the Get Price endpoint is marked
  FREE and needs no authentication; CORS is enabled (so the web build can
  call it). Paid plans exist only for history.
- Verdict: free use in an app is permitted, no key is needed, no attribution
  is required. We credit it anyway on the Our Sources screen.
- How the app stays inside the terms: user-initiated only (a button tap),
  two requests per tap, never on a timer, never on page load.
- Not documented, so not verified: the docs we could read do not state the
  currency of `price`. The app has treated it as US dollars since PR #146 and
  refuses any gold price outside 200 to 100,000 dollars an ounce (silver 2 to
  5,000, silver below gold), which would reject a price in a currency worth
  far less than a dollar.
- Re-check if the service ever asks for a key (the app would then show "price
  services are not answering" and fall back to the daily feed).

## 2. currency-api (fawazahmed0): exchange rates, and daily gold and silver

- Used for: `usd.json` (how many units of each currency one US dollar buys,
  the rate used to convert the gold-api.com price), and `xau.json` / `xag.json`
  (an ounce of gold or silver in every currency, used only if gold-api.com
  fails).
- Project: https://github.com/fawazahmed0/exchange-api. The older repository
  name `currency-api` is marked as moved there; the package name
  `@fawazahmed0/currency-api` in the CDN address is unchanged.
- Address format (project docs): `https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{date}/v1/currencies/{code}.json`,
  with the fallback `https://{date}.currency-api.pages.dev/v1/currencies/{code}.json`.
  The app uses `{date}` = `latest` and tries jsDelivr first, then Cloudflare
  Pages. Both are in the web build's connection list (`web/index.html`).
- Data: updated once a day, "no rate limits", "over 200 currencies, including
  cryptocurrencies and metals". Each file carries a `date`; the app shows it.
- Licence: listed as CC0-1.0 (public domain) in the repository metadata we could
  read; one third-party article says MIT. Either allows free use without
  attribution. The LICENSE file itself was not read. The app does not copy or
  republish the dataset; it reads three small files per tap.
- Not confirmed from this environment: that `xau` and `xag` appear in the live
  feed. The project docs say "metals" without naming them; only a third-party
  article lists XAU and XAG. The first, normal path (gold-api.com plus
  `usd.json`) does not need them. If they were missing, the fallback would
  report "no exchange rate" in plain words and the person would type the
  prices. The owner can confirm in ten seconds (section 21 of OWNER_ACTIONS).
- These are reference rates, not what a bank, a bureau or a jeweller charges.
  The Zakat screen says so.

## 3. jsDelivr and Cloudflare Pages: delivery of the daily feed

- jsDelivr terms (https://github.com/jsdelivr/jsdelivr/blob/master/Terms%20of%20Use.md,
  read 28 Oct 2026): "free for both personal and commercial use", no limits on
  bandwidth or number of requests, no attribution requirement; prohibited uses
  (malware, general file hosting, scraping rarely used content, bypassing
  limits) do not apply; no guarantee of availability. That is why a second
  address exists.
- Cloudflare Pages (`*.currency-api.pages.dev`): the project's own fallback
  address. Cloudflare's terms were not read; it is a static file host serving
  a public dataset, and the app is a reader of public pages.
- Both see the person's IP address when the button is tapped. The privacy
  policy says so (section "Location and other services").

## What the person sees

- Zakat screen, after a fetch: the price per gram in their currency, the
  source and time, and (when converted) "Converted from USD at 1 USD = x
  CUR (rate for DATE, currency-api daily reference rate, via jsDelivr)".
- Our Sources screen: both services, in "Also in Ar-Rayaan".
- Errors are never silent: offline, timeout, service down, unreadable answer,
  no rate for the currency, and "dollar price arrived but the exchange rate
  did not" each have their own message, and typing the prices always works.

## Currencies

56 currencies are offered (`lib/features/zakat/domain/zakat_currencies.dart`).
Left out on purpose because the published rate differs sharply from the rate
people actually trade at: Iranian rial, Lebanese pound, Syrian pound, Yemeni
rial, Sudanese pound, Venezuelan bolivar. People there type the prices
themselves. A currency not in the list can still be typed in the box as a
label and used with typed prices.

## Region detection (on the device, never sent)

1. A currency the person picked here before (kept on the device).
2. The country of the saved prayer-times city (`ar.location.country`).
3. The region of the phone's language list.
4. Otherwise nothing is guessed and the screen says so.
The note under the currency box always says which of these set it.
