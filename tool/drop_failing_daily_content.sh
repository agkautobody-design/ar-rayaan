#!/usr/bin/env bash
# Deploy-time guard for the daily content bots.
#
# The bots push stories straight to main and (see docs/OWNER_ACTIONS.md item 16)
# do not always run the content check first. When the check fails, this drops
# the bad bot content instead of blocking every deploy: it walks back through
# the commits that touched the story packs and takes the newest state that
# passes tool/check_daily_content.py. The checker itself is never changed.
#
# Exit 0: content passes (as found, or after the fallback). Exit 1: nothing
# in the last 30 content commits passes, so a person must look.
# Set NO_PUSH=1 to skip the commit/push (used for local testing).
set -u
PATHS="assets/stories assets/content_version.json"

if python3 tool/check_daily_content.py; then exit 0; fi
echo "::warning::Daily content check failed; looking for the newest content that passes."

# CI checks out one commit; the walk-back needs the recent history.
git fetch --quiet --depth=60 origin main 2>/dev/null || true

found=""
for c in $(git log --format=%H -n 30 -- $PATHS); do
  git checkout "$c" -- $PATHS 2>/dev/null || continue
  python3 tool/gen_content_manifest.py >/dev/null 2>&1
  python3 tool/sync_app_toc.py >/dev/null 2>&1
  if python3 tool/check_daily_content.py >/dev/null 2>&1; then found="$c"; break; fi
done

if [ -z "$found" ]; then
  echo "::error::No recent content state passes the check; a person must fix it."
  exit 1
fi
echo "Using story content as of $found. The failing bot entry was dropped."
python3 tool/check_daily_content.py || exit 1

if [ "${NO_PUSH:-0}" = "1" ]; then exit 0; fi
git config user.name "Ar-Rayaan Builder"
git config user.email "builder@ar-rayaan.app"
git add $PATHS assets/content_manifest.json assets/share/app_toc.json
git commit -m "Drop daily story that failed the content check (restored content as of ${found:0:7})" || exit 0
git push origin HEAD:main || echo "::warning::Could not push the removal to main; the deploy still uses the clean content."
exit 0
