#!/bin/bash
# Zwischenspeicher für fertig eingerichtete Simulatoren. Der erste Start eines frischen Simulators
# richtet iOS-Daten ein und dauert minutenlang; mit dem gespeicherten Stand bootet er in Sekunden.
#
#   device-cache.sh key      Schlüssel für den Cache (Xcode, iOS-Version, Modelle) ausgeben
#   device-cache.sh restore  gespeicherten Stand in die frisch angelegten Simulatoren kopieren
#   device-cache.sh save     Simulatoren anhalten, Stand nach $SIM_DIR/devcache kopieren, neu starten
#
# Gespeichert wird nur das frisch eingerichtete iOS – vor der Installation der App und vor dem
# Einspielen von Profil-Daten. (Der Cache eines öffentlichen Repos ist nicht privat.)
set -euo pipefail
SIM_DIR=${SIM_DIR:-/tmp/sim}
CACHE="$SIM_DIR/devcache"
DEVICES_ROOT="$HOME/Library/Developer/CoreSimulator/Devices"

devices() {
  python3 -c "import json;[print(d['role'], d['udid']) for d in json.load(open('$SIM_DIR/devices.json'))]"
}

case "${1:-}" in
  key)
    XC=$(xcodebuild -version | tail -1 | awk '{print $NF}')
    SUM=$(python3 -c "
import json, hashlib
d = json.load(open('$SIM_DIR/devices.json'))
print(hashlib.sha1('|'.join(f\"{x['role']}:{x['model']}:{x['runtime']}\" for x in d).encode()).hexdigest()[:16])")
    echo "simdata-v1-$XC-$SUM"
    ;;

  restore)
    devices | while read -r role udid; do
      if [ ! -d "$CACHE/$role/data" ]; then echo "$role: kein gespeicherter Stand"; continue; fi
      xcrun simctl shutdown "$udid" 2>/dev/null || true
      rm -rf "$DEVICES_ROOT/$udid/data"
      ditto "$CACHE/$role/data" "$DEVICES_ROOT/$udid/data"
      # Sprache und Region wieder setzen (gehören zur Sitzung, nicht zum Cache)
      python3 - "$DEVICES_ROOT/$udid/data/Library/Preferences/.GlobalPreferences.plist" <<'PY'
import os, plistlib, sys
path = sys.argv[1]
os.makedirs(os.path.dirname(path), exist_ok=True)
try:
    prefs = plistlib.load(open(path, "rb"))
except Exception:
    prefs = {}
prefs["AppleLanguages"] = [os.environ.get("LANGUAGE") or "de-DE"]
prefs["AppleLocale"] = os.environ.get("LOCALE") or "de_DE"
plistlib.dump(prefs, open(path, "wb"))
PY
      echo "$role: eingerichteter Stand übernommen ($(du -sh "$CACHE/$role/data" | cut -f1))"
    done
    ;;

  save)
    rm -rf "$CACHE" && mkdir -p "$CACHE"
    devices | while read -r role udid; do
      xcrun simctl shutdown "$udid" 2>/dev/null || true
    done
    devices | while read -r role udid; do
      mkdir -p "$CACHE/$role"
      ditto "$DEVICES_ROOT/$udid/data" "$CACHE/$role/data"
      # Protokolle und Zwischenspeicher von iOS braucht der nächste Start nicht
      rm -rf "$CACHE/$role/data/Library/Logs" "$CACHE/$role/data/Library/Caches"/* 2>/dev/null || true
      echo "$role: gespeichert ($(du -sh "$CACHE/$role/data" | cut -f1))"
    done
    devices | while read -r role udid; do
      xcrun simctl boot "$udid" 2>/dev/null || true
    done
    devices | while read -r role udid; do
      xcrun simctl bootstatus "$udid" -b > /dev/null
    done
    ;;

  *)
    echo "Aufruf: device-cache.sh key|restore|save" >&2
    exit 2
    ;;
esac
