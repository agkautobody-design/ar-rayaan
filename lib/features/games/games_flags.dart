/// Switches for parts of the Games section that must stay hidden until the
/// service behind them exists.
library;

/// Friends, invitations, a waiting room, "your turn" and who-is-online need
/// accounts and a community service that the app does not have yet. The
/// screen exists and says so, but nothing links to it while this is false.
/// Change it only when that service ships, and update
/// `docs/product/games_plan.md` phase 3 in the same change.
const bool kGamesCommunityEnabled = false;
