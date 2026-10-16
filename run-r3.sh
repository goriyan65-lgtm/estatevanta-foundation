#!/usr/bin/env bash
# EstateVanta Phase 3.3A r3: ONE command for Codespaces:   bash run-r3.sh
# Put this file and estatevanta-foundation-3.3A-verify-r3.tar.gz in the SAME folder (the Codespaces file explorer
# "Upload..." does this, no commit needed). The script then: checks the archive SHA-256, checks the archive paths are
# safe, unpacks into a NEW folder (nothing existing is overwritten), and runs the real install, TypeScript checks,
# npm test and production build, each reported separately. It does NOT touch Supabase, Firebase or the website, create
# users, commit, push or deploy. Result: r3-result.txt next to this script (open it in the file explorer).
set -u
ARCHIVE="estatevanta-foundation-3.3A-verify-r3.tar.gz"
EXPECTED_SHA256="d93b8a576982cbddf762d1c7aa424516048aebc003a6e8f86dce9f447682366f"
EXPECTED_ENTRIES=124
cd "$(dirname "$0")" || exit 2
OUT="$PWD/r3-result.txt"; rm -f "$OUT"
say() { echo "$*" | tee -a "$OUT"; }
stop() { say "OVERALL: STOPPED BEFORE VERIFICATION - $*"; exit 1; }

[ -f "$ARCHIVE" ] || stop "$ARCHIVE is not in this folder ($PWD). Upload it next to run-r3.sh."
GOT="$(sha256sum "$ARCHIVE" | cut -d' ' -f1)"
[ "$GOT" = "$EXPECTED_SHA256" ] || stop "archive SHA-256 does not match (expected ${EXPECTED_SHA256:0:12}..., got ${GOT:0:12}...). Re-upload the archive."
say "archive SHA-256: MATCH (${GOT:0:12}...)"
if tar tzf "$ARCHIVE" | grep -Eq '^/|(^|/)\.\.(/|$)'; then stop "unsafe path inside the archive"; fi
N="$(tar tzf "$ARCHIVE" | grep -vc '/$')"
[ "$N" = "$EXPECTED_ENTRIES" ] || stop "archive has $N files, expected $EXPECTED_ENTRIES"
say "archive paths: safe; files: $N"

DEST="r3-run-$(date +%Y%m%d-%H%M%S)"
mkdir "$DEST" || stop "could not create $DEST"
tar xzf "$ARCHIVE" -C "$DEST" || stop "extract failed"
PROJECT="$PWD/$DEST/estatevanta-foundation"
[ -f "$PROJECT/package.json" ] || stop "package.json not found after extract"
say "unpacked into: $DEST/estatevanta-foundation"
say "running verification (install + build take a few minutes; please wait) ..."
bash "$PROJECT/verify/run-verify-r3.sh" >"$PWD/$DEST/verify-console.txt" 2>&1
RC=$?
{ echo; echo "---- step results ----"; cat "$PROJECT/verify-result-r3.txt" 2>/dev/null || echo "(no result file was written)"; } >>"$OUT"
cat "$PROJECT/verify-result-r3.txt" 2>/dev/null
echo
if [ $RC -eq 0 ]; then echo "FINAL: ALL STEPS PASSED"; else echo "FINAL: SOME STEPS FAILED (see r3-result.txt)"; fi
echo "Result file: $OUT   Full logs: $DEST/estatevanta-foundation/verify-logs/"
echo "Do not commit $DEST (it holds node_modules)."
exit $RC
