#!/usr/bin/env bash

# Konfigurationsordner und Dateien
CONFIG_DIR="$HOME/.config/til"
CONFIG_FILE="$CONFIG_DIR/config"
DEFAULT_TEMPLATE="$CONFIG_DIR/template.md"

# Standardwerte
TIL_DIR="$HOME/Notizen/TIL"

# Konfigurationsordner erstellen, falls nicht vorhanden
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "Konfigurationsordner wurde erstellt: $CONFIG_DIR"

    # Standard-Template erstellen
    cat > "$DEFAULT_TEMPLATE" << EOF
# {{date}} - TIL

## Was ich heute gelernt habe

-

## Quellen

-
EOF
    echo "Standard-Template wurde erstellt: $DEFAULT_TEMPLATE"

    # Konfigurationsdatei erstellen
    cat > "$CONFIG_FILE" << EOF
# Konfiguration für til.sh
TEMPLATE_PATH="$DEFAULT_TEMPLATE"
TIL_DIR="$TIL_DIR"
EOF
    echo "Standardkonfiguration wurde erstellt: $CONFIG_FILE"
fi

# Konfigurationsdatei einlesen, wenn vorhanden
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Fehler: Konfigurationsdatei nicht gefunden unter $CONFIG_FILE"
    exit 1
fi

# Aktuelles Datum im Format YYYY-mm-dd
DATE=$(date +"%Y-%m-%d")

# Überprüfen, ob Parameter übergeben wurden
if [ $# -eq 0 ]; then
    echo "Fehler: Bitte gib eine Beschreibung an."
    echo "Verwendung: $0 beschreibung des TIL-Eintrags"
    exit 1
fi

# Beschreibung aus allen Parametern zusammensetzen
DESCRIPTION="$*"

# Neuen Dateinamen erstellen
NEW_FILENAME="$DATE $DESCRIPTION.md"
NEW_FILE_PATH="$TIL_DIR/$NEW_FILENAME"

# Überprüfen, ob der TIL-Ordner existiert, wenn nicht, erstellen
if [ ! -d "$TIL_DIR" ]; then
    mkdir -p "$TIL_DIR"
    echo "TIL-Ordner wurde erstellt: $TIL_DIR"
fi

# Überprüfen, ob die Template-Datei existiert
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Fehler: Template-Datei nicht gefunden: $TEMPLATE_PATH"
    echo "Bitte überprüfe den Pfad in $CONFIG_FILE"
    exit 1
fi

# Temporäre Datei für das generierte Template erstellen
TEMP_TEMPLATE=$(mktemp --suffix=.md)

# Template in die temporäre Datei kopieren und {{date}} durch das aktuelle Datum ersetzen
sed "s/{{date}}/$DATE/g" "$TEMPLATE_PATH" > "$TEMP_TEMPLATE"

# Anzahl der nicht-leeren Zeilen im generierten Template zählen
TEMPLATE_NON_EMPTY_LINES=$(grep -v "^\s*$" "$TEMP_TEMPLATE" | wc -l)

# Temporäre Datei für die Bearbeitung erstellen
TEMP_FILE=$(mktemp --suffix=.md)
cp "$TEMP_TEMPLATE" "$TEMP_FILE"

# Datei in vim öffnen
vim "$TEMP_FILE"

# Prüfen, ob Änderungen vorgenommen wurden
if cmp -s "$TEMP_TEMPLATE" "$TEMP_FILE"; then
    echo "Keine Änderungen vorgenommen. Die Notiz wird nicht gespeichert."
    rm "$TEMP_TEMPLATE" "$TEMP_FILE"
    exit 0
fi

# Anzahl der nicht-leeren Zeilen in der bearbeiteten Datei zählen
EDITED_NON_EMPTY_LINES=$(grep -v "^\s*$" "$TEMP_FILE" | wc -l)

# Prüfen, ob tatsächlich Inhalte hinzugefügt wurden
if [ "$EDITED_NON_EMPTY_LINES" -le "$TEMPLATE_NON_EMPTY_LINES" ]; then
    echo "Es wurden keine Inhalte hinzugefügt. Möchtest du die Notiz trotzdem speichern? (j/N)"
    read -r ANTWORT
    if [[ ! "$ANTWORT" =~ ^[jJ] ]]; then
        echo "Abgebrochen. Die Notiz wird nicht gespeichert."
        rm "$TEMP_TEMPLATE" "$TEMP_FILE"
        exit 0
    fi
fi

# Temporäre Datei an den endgültigen Ort verschieben
mv "$TEMP_FILE" "$NEW_FILE_PATH"
rm "$TEMP_TEMPLATE"

# Bestätigung ausgeben
echo "Neue TIL-Notiz erstellt: $NEW_FILE_PATH"
