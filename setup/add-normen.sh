#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  add-normen.sh
#  Legt gängige Feuerwehr-PSA-Normen in NocoDB an.
#  Duplikaterkennung: Bezeichnung + Kategorie
#  Verwendung: bash add-normen.sh
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

TOKEN="${XC_TOKEN:-}"
BASE_URL="${NOCODB_URL:-http://localhost:8181}"

if [ -z "$TOKEN" ]; then
  echo "❌ Fehler: XC_TOKEN nicht gesetzt (setup/.env fehlt)."
  exit 1
fi

IDS_FILE="$SCRIPT_DIR/.nocodb_table_ids"
if [ ! -f "$IDS_FILE" ]; then
  echo "❌ .nocodb_table_ids nicht gefunden."
  exit 1
fi

BASE_ID=$(grep "^BASE_ID=" "$IDS_FILE" | cut -d= -f2)
TABLE_ID=$(grep "^Normen=" "$IDS_FILE" | cut -d= -f2)

if [ -z "$BASE_ID" ] || [ -z "$TABLE_ID" ]; then
  echo "❌ BASE_ID oder Normen-ID fehlen in .nocodb_table_ids."
  exit 1
fi

API="$BASE_URL/api/v1/db/data/noco/$BASE_ID/$TABLE_ID"

# Vorhandene Normen als "Bezeichnung|Kategorie"-Schlüssel laden
EXISTING=$(curl -s -H "xc-token: $TOKEN" "$API?limit=500" | \
  python3 -c "
import sys, json
d = json.load(sys.stdin)
for r in d.get('list', []):
    print(r.get('Bezeichnung','') + '|' + r.get('Ausruestungstyp_Kategorie',''))
" 2>/dev/null)

ok=0; skip=0; fail=0

add_norm() {
  local bezeichnung="$1"
  local kategorie="$2"
  local intervall="$3"
  local lebensdauer="$4"
  local max_waeschen="$5"
  local beschreibung="$6"
  local key="${bezeichnung}|${kategorie}"

  if echo "$EXISTING" | grep -qxF "$key"; then
    echo "  ⏭  $bezeichnung ($kategorie) – bereits vorhanden"
    skip=$((skip+1))
    return
  fi

  JSON=$(python3 -c "
import json, sys
d = {
  'Bezeichnung': sys.argv[1],
  'Ausruestungstyp_Kategorie': sys.argv[2],
  'Beschreibung': sys.argv[6]
}
if sys.argv[3]: d['Pruefintervall_Monate'] = int(sys.argv[3])
if sys.argv[4]: d['Max_Lebensdauer_Jahre'] = int(sys.argv[4])
if sys.argv[5]: d['Max_Waeschen'] = int(sys.argv[5])
print(json.dumps(d))
" "$bezeichnung" "$kategorie" "$intervall" "$lebensdauer" "$max_waeschen" "$beschreibung")

  HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API" \
    -H "xc-token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON")

  if [ "$HTTP" = "200" ] || [ "$HTTP" = "201" ]; then
    echo "  ✅ $bezeichnung ($kategorie)"
    ok=$((ok+1))
  else
    echo "  ❌ $bezeichnung ($kategorie) – HTTP $HTTP"
    fail=$((fail+1))
  fi
}

echo "📋 Füge Feuerwehr-PSA-Normen ein..."
echo ""

# ── Schutzjacke ───────────────────────────────────────────────────────────────
echo "▸ Schutzjacke"
add_norm "EN 469:2020" "Jacke" "12" "10" "20" \
  "Schutzkleidung für die Feuerwehr – Leistungsanforderungen zur Brandbekämpfung (Jacke). Prüfklassen: XF1/XF2 (Flamme), XR1/XR2 (Strahlungswärme), XB1/XB2 (Konvektionswärme), Y1/Y2 (Flüssigkeitsdichtheit), Z (Dampf). Entspricht EN 469:2005+A1:2006 (Vorgänger)."
add_norm "EN ISO 11612:2015" "Jacke" "" "10" "" \
  "Schutzkleidung gegen Hitze und Flammen. Ergänzende Norm zur EN 469 für Hitzearbeitsplätze. Klassen A–F je nach Schutzart."

# ── Schutzhose ────────────────────────────────────────────────────────────────
echo "▸ Schutzhose"
add_norm "EN 469:2020" "Hose" "12" "10" "20" \
  "Schutzkleidung für die Feuerwehr – Leistungsanforderungen zur Brandbekämpfung (Hose). Gleiche Prüfklassen wie Jacke; muss als System mit EN-469-Jacke getragen werden."
add_norm "EN ISO 11612:2015" "Hose" "" "10" "" \
  "Schutzkleidung gegen Hitze und Flammen – Ergänzende Norm (Hose). Klassen A1/A2 (begrenzte Flammenausbreitung), B (Konvektion), C (Strahlung), D/E/F (Schmelzspritzer, Kontakthitze)."

# ── Stiefel ───────────────────────────────────────────────────────────────────
echo "▸ Stiefel"
add_norm "EN 15090:2012" "Stiefel" "12" "10" "" \
  "Schuhe für die Feuerwehr. Typen: F1 (Gebäudebrandbekämpfung), F2 (Außenbrandbekämpfung), F3 (technische Rettung). Anforderungen: Hitzeschutz, Rutschfestigkeit (SRC), Chemikalienbeständigkeit, Antistatik, Durchtrittsicherheit."

# ── Handschuhe ────────────────────────────────────────────────────────────────
echo "▸ Handschuhe"
add_norm "EN 659:2003+A1:2008" "Handschuh" "12" "10" "" \
  "Schutzhandschuhe für Feuerwehrmänner. Anforderungen: Flammen- und Hitzeschutz (Konvektion, Strahlung, Kontakt), Wasserdurchdringung, mechanische Schutzwirkung. Typische Lebensdauer nach Herstellerangabe (meist 10 J.)."
add_norm "EN 388:2016+A1:2018" "Handschuh" "" "" "" \
  "Schutzhandschuhe gegen mechanische Risiken. Piktogramm-Kennwerte: Abrieb, Schnitt (Coupe), Weiterreißen, Durchstechen, Schnitt (TDM), Schlagschutz. Ergänzung zu EN 659 für mechanischen Schutz."

# ── Helme ─────────────────────────────────────────────────────────────────────
echo "▸ Helme"
add_norm "EN 443:2008" "Helm" "12" "10" "" \
  "Helme für die Brandbekämpfung in Gebäuden und Bauwerken. Anforderungen: Stoßdämpfung, Durchdringungswiderstand, Flammenschutz, elektrische Isolation (440 V), Beständigkeit gegen heiße Flüssigkeiten, Sichtfeld. Visor-Optionen: Innenkinnriemen, Nackenschutz."
add_norm "EN 16471:2014" "Helm" "12" "10" "" \
  "Helme für die Waldbrandbekämpfung. Leichter als EN 443; integrierter Gehörschutz und erweiterbarer Nackenschutz für Außeneinsatz. Kein Vollvisier erforderlich."
add_norm "EN 16473:2014" "Helm" "12" "10" "" \
  "Helme für die technische Rettung (TR). Einsatz bei Verkehrsunfällen, Technischer Hilfe, CBRN-Einsätzen. Stoßdämpfung und Durchdringungsschutz nach EN 397 (Industrieschutzhelm) als Basis."

# ── Atemschutz ────────────────────────────────────────────────────────────────
echo "▸ Atemschutz"
add_norm "EN 136:1998" "Atemschutz" "12" "" "" \
  "Vollmasken für Atemschutzgeräte. Anforderungen: Dichtheit (Gesichtsdichtrahmen), optische Sichtscheibe, Anschlussgewinde (DIN 40), Ausatemventil, Sprecheinrichtung. Trägerpflicht nach FwDV 7."
add_norm "EN 137:2006" "Atemschutz" "12" "15" "" \
  "Druckluftatemschutzgeräte mit offenem Kreislauf (Pressluftatmer, PA). Anforderungen: Druckbehälter (Stahl/CFK), Druckminderer, Lungenautomatik, Überdruckprinzip. Flasche: TÜV-Prüfung alle 5/10 J. (ADR); Gerät: jährliche Sachkundigenprüfung nach FwDV 7."
add_norm "EN 14387:2004+A1:2008" "Atemschutz" "" "" "" \
  "Gasfilter und Kombinationsfilter. Typen: A (org. Gase), B (anorg. Gase/Dämpfe), E (SO₂), K (Ammoniak), P (Partikel). Klassen 1/2/3. Für Fluchtgeräte und Halbmasken im leichten Atemschutz."

# ── Flammschutzhaube ─────────────────────────────────────────────────────────
echo "▸ Flammschutzhaube"
add_norm "EN 13911:2017" "Haube" "12" "10" "20" \
  "Schutzkleidung für die Feuerwehr – Anforderungen und Prüfverfahren für Flammschutzhauben. Schützt Hals, Kinn und Ohren unter dem Feuerwehrhelm. Prüfanforderungen: begrenzte Flammenausbreitung, Wärmedurchgangswiderstand, Zugfestigkeit, Dehnung. Wird als Ergänzung zu EN 469 und EN 443 getragen."

# ── Hemd / Unterziehbekleidung ────────────────────────────────────────────────
echo "▸ Hemd / Unterziehbekleidung"
add_norm "EN ISO 14116:2015" "Hemd" "" "" "50" \
  "Schutzkleidung mit begrenzter Flammenausbreitung. Indizes 1–3 (3 = kein Nachglühen, kein Nachbrennen, keine Lochabstand ≥ 150 mm). Typisch für Unterziehwäsche und Hemden, die unter EN-469-Kleidung getragen werden. Max. Waschzyklen nach Herstellerangabe (i. d. R. 50)."
add_norm "EN ISO 11612:2015" "Hemd" "" "" "25" \
  "Schutzkleidung gegen Hitze und Flammen. Ergänzende Norm für Hemden/Shirts bei Hitzeeinsätzen. Klassen A–F; Kombinationsanforderungen je nach Einsatz."

# ── Poloshirt ─────────────────────────────────────────────────────────────────
echo "▸ Poloshirt"
add_norm "EN ISO 14116:2015" "Poloshirt" "" "" "50" \
  "Schutzkleidung mit begrenzter Flammenausbreitung. Für Poloshirts, die als Unterkleidung oder im Bereich ohne direkten Brandkontakt getragen werden. Index 1–3."

# ── Fleece / Softshell ────────────────────────────────────────────────────────
echo "▸ Fleece / Softshell"
add_norm "EN ISO 14116:2015" "Fleece/Softshell" "" "" "50" \
  "Schutzkleidung mit begrenzter Flammenausbreitung. Gilt für Fleece- und Softshell-Jacken als Zwischenschicht unter EN-469-Oberbekleidung. Index 1 mindestens erforderlich."

# ── Warnschutz ────────────────────────────────────────────────────────────────
echo "▸ Warnschutz"
add_norm "EN ISO 20471:2013+A1:2016" "Sonstige" "12" "3" "25" \
  "Hochsichtbare Warnschutzkleidung. Klassen 1–3 nach retroreflektierender und fluoreszierender Mindestfläche. Klasse 3 = Weste + Hose oder Kombination. Pflicht bei Einsätzen an Straßen und Schienen (§ 35 StVO / UVV)."

# ── Absturzsicherung ──────────────────────────────────────────────────────────
echo "▸ Absturzsicherung"
add_norm "EN 361:2002" "Absturzsicherung" "12" "10" "" \
  "Auffanggurte (Vollkörpergurt). Mindestbruchlast 15 kN. Fangpunkt im Rücken (D-Ring). Jährliche Sichtprüfung durch Benutzer, periodische Prüfung durch Sachkundigen. Aussonderung nach Sturzbelastung oder nach Herstellervorgabe."
add_norm "EN 362:2004" "Absturzsicherung" "12" "10" "" \
  "Verbindungsmittel (Karabiner, Deltakarabiner). Dreifachsicherung, Mindestbruchlast 20 kN axial. Sichtprüfung vor jeder Benutzung."
add_norm "EN 363:2008" "Absturzsicherung" "12" "10" "" \
  "Systeme zur Absturzsicherung – Gesamtsystem bestehend aus Auffanggurt (EN 361), Verbindungsmittel (EN 362) und Anschlagpunkt. Anforderungen an das Zusammenwirken der Komponenten."
add_norm "EN 1891:1998" "Absturzsicherung" "12" "10" "" \
  "Kernmantelseile mit geringer Dehnung (Halbstatikseile, Typ A ≥ 11 mm). Einsatz bei Höhenrettung, Abseilarbeiten und Seilrettung der Feuerwehr. Jährliche Sachkundigenprüfung; Aussonderung nach Belastung, mechanischer Beschädigung oder spätestens nach 10 Jahren."

# ── Sonstiges ─────────────────────────────────────────────────────────────────
echo "▸ Sonstiges"
add_norm "DIN 14920" "Sonstige" "12" "5" "" \
  "Feuerwehrleine – Sicherheitsleine nach FwDV. Mindestbruchlast 15 kN, Länge 30 m, Durchmesser 8 mm. Jährliche Prüfung durch Sachkundigen; Aussonderung spätestens nach 5 Jahren oder nach Belastung mit mehr als 100 kg Fallhöhe > 1 m."
add_norm "DIN 14800-18" "Sonstige" "12" "" "" \
  "Haltegurt für Feuerwehrleute (Positionierungsgurt). Dient der Positionierung an Leitern – kein Auffanggurt! Anforderungen nach FwDV; jährliche Sichtprüfung und Funktionskontrolle."

echo ""
echo "──────────────────────────────────────────────────────────"
echo "✅ Erfolgreich angelegt: $ok"
echo "⏭  Bereits vorhanden:   $skip"
echo "❌ Fehler:               $fail"
echo ""
if [ "$ok" -gt 0 ]; then
  echo "Normen sind sofort in der App sichtbar (kein Neustart nötig)."
fi
