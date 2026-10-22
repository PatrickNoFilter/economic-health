#!/bin/bash
# Economic Health APK builder — manual aapt2 pipeline (no Gradle).
# Usage: ./build.sh   (run from ~/workspace/economic-health)
# Output: out/EconomicHealth-v1.apk
set -euo pipefail

APP="$HOME/workspace/economic-health"
SRC="$APP/android"
SDK="$HOME/workspace/android-sdk"
export PATH="$HOME/workspace/jdk/jdk-17.0.20.1+1/bin:$PATH"
BT="$SDK/build-tools/34.0.0"
PLATFORM="$SDK/platforms/android-34/android.jar"
KS="$APP/keystore/eh.keystore"
KSPASS="eh-local-debug-01"   # personal debug key for this app only; lives in this file
ALIAS="eh"
# Version convention: 3 digits MAJOR.MINOR.PATCH (patch = bug fixes only).
# Version comes from $1 or the VERSION file. versionCode is derived as
# MAJOR*10000 + MINOR*100 + PATCH so it always increases.
VER_NAME="${1:-$(cat "$APP/VERSION")}"
if [[ ! "$VER_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: version must be MAJOR.MINOR.PATCH, got '$VER_NAME'" >&2
  exit 1
fi
IFS=. read -r VM vm vp <<< "$VER_NAME"
VER_CODE=$((10#$VM*10000 + 10#$vm*100 + 10#$vp))
APK_NAME="EconomicHealth-v$VER_NAME.apk"
echo "$VER_NAME" > "$APP/VERSION"
echo "\$ version $VER_NAME (code $VER_CODE)"
OUT="$APP/out"

echo "\$ keystore check"
mkdir -p "$APP/keystore" "$OUT"
if [ ! -f "$KS" ]; then
  keytool -genkeypair -keystore "$KS" -alias "$ALIAS" -keyalg RSA -keysize 2048 \
    -validity 10950 -storepass "$KSPASS" -keypass "$KSPASS" \
    -dname "CN=PatrickNoFilter, OU=EconomicHealth" 2>/dev/null
  echo "  generated new keystore (keep it — same cert needed for updates)"
else
  echo "  reusing existing keystore"
fi

echo "\$ sync web assets"
rm -rf "$SRC/assets/www"
mkdir -p "$SRC/assets/www"
cp "$APP/www/index.html" "$SRC/assets/www/index.html"

echo "\$ aapt2 compile"
rm -rf "$SRC/compiled.zip" "$SRC/gen" "$OUT/classes" "$OUT/dex"
mkdir -p "$SRC/gen" "$OUT/classes" "$OUT/dex"
"$BT/aapt2" compile --dir "$SRC/res" -o "$SRC/compiled.zip"

echo "\$ aapt2 link"
"$BT/aapt2" link -o "$OUT/app-unsigned.apk" \
  --manifest "$SRC/AndroidManifest.xml" \
  -I "$PLATFORM" -A "$SRC/assets" --java "$SRC/gen" \
  --min-sdk-version 26 --target-sdk-version 34 \
  --version-code "$VER_CODE" --version-name "$VER_NAME" \
  "$SRC/compiled.zip"

echo "\$ javac"
javac -encoding UTF-8 --release 8 -cp "$PLATFORM" -d "$OUT/classes" $(find "$SRC/gen" "$SRC/src" -name "*.java")

echo "\$ d8"
"$BT/d8" --lib "$PLATFORM" --min-api 26 --output "$OUT/dex" $(find "$OUT/classes" -name "*.class")

echo "\$ add classes.dex"
python3 - "$OUT/app-unsigned.apk" "$OUT/dex/classes.dex" <<'EOF'
import sys, zipfile
apk, dex = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(apk, 'a', zipfile.ZIP_DEFLATED) as z:
    z.write(dex, 'classes.dex')
print("  classes.dex added")
EOF

echo "\$ zipalign"
"$BT/zipalign" -p -f 4 "$OUT/app-unsigned.apk" "$OUT/$APK_NAME"

echo "\$ apksigner sign"
KSPASS="$KSPASS" "$BT/apksigner" sign --ks "$KS" --ks-key-alias "$ALIAS" \
  --ks-pass env:KSPASS --key-pass env:KSPASS \
  "$OUT/$APK_NAME"

echo "\$ verify"
"$BT/apksigner" verify --print-certs "$OUT/$APK_NAME" | head -4
"$BT/aapt2" dump badging "$OUT/$APK_NAME" | head -3
echo "\$ md5 + size"
md5sum "$OUT/$APK_NAME"
ls -la "$OUT/$APK_NAME"
echo "DONE"
