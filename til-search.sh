#!/usr/bin/env bash

# Konfigurationsordner und Dateien
CONFIG_DIR="$HOME/.config/til"
CONFIG_FILE="$CONFIG_DIR/config"

# Standardwerte
TIL_DIR="$HOME/Notizen/TIL"

# Prüfen, ob fzf installiert ist
if ! command -v fzf &> /dev/null; then
    echo "Fehler: fzf ist nicht installiert. Bitte installiere es zuerst."
    exit 1
fi

# Prüfen, ob bat oder cat installiert ist (für die Vorschau)
PREVIEW_CMD="cat"
if command -v bat &> /dev/null; then
    PREVIEW_CMD="bat --style=numbers --color=always"
fi

# Konfigurationsdatei einlesen, wenn vorhanden
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Warnung: Konfigurationsdatei nicht gefunden unter $CONFIG_FILE"
    echo "Verwende Standardpfad: $TIL_DIR"
fi

# Prüfen, ob der TIL-Ordner existiert
if [ ! -d "$TIL_DIR" ]; then
    echo "Fehler: TIL-Ordner nicht gefunden: $TIL_DIR"
    exit 1
fi

# Anzahl der TIL-Notizen zählen
TIL_COUNT=$(find "$TIL_DIR" -type f -name "*.md" | wc -l)

if [ "$TIL_COUNT" -eq 0 ]; then
    echo "Keine TIL-Notizen gefunden in $TIL_DIR"
    exit 0
fi

echo "Durchsuche $TIL_COUNT TIL-Notizen..."

# Optionen verarbeiten
OPEN_WITH="vim"
PRINT_PATH=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --print|-p)
            PRINT_PATH=1
            shift
            ;;
        --editor|-e)
            if [[ -n "$2" && "$2" != -* ]]; then
                OPEN_WITH="$2"
                shift 2
            else
                echo "Fehler: --editor benötigt ein Argument"
                exit 1
            fi
            ;;
        *)
            # Alle anderen Argumente als Suchbegriffe behandeln
            SEARCH_TERMS="$*"
            break
            ;;
    esac
done

# Wenn Suchbegriffe angegeben wurden, führe eine Volltextsuche durch
if [ -n "$SEARCH_TERMS" ]; then
    # Suche in Dateien mit grep und zeige die Ergebnisse mit fzf an
    SELECTED=$(grep -l -i "$SEARCH_TERMS" "$TIL_DIR"/*.md | fzf --preview "$PREVIEW_CMD {}" \
                --preview-window=right:60% \
                --keep-right \
                --header "Suche nach: $SEARCH_TERMS" \
                --prompt "TIL > ")
else
    # Ansonsten zeige alle TIL-Notizen mit fzf an
    SELECTED=$(find "$TIL_DIR" -type f -name "*.md" | sort -r | fzf \
                --preview "$PREVIEW_CMD {}" \
                --preview-window=right:60% \
                --keep-right \
                --header "TIL-Notizen (${TIL_COUNT})" \
                --prompt "TIL > " \
                --bind "ctrl-f:change-preview-window(right:80%|down:50%|hidden|)" \
                --bind "ctrl-r:reload(find '$TIL_DIR' -type f -name '*.md' | sort -r)" \
                --bind "ctrl-d:execute(rm {})+reload(find '$TIL_DIR' -type f -name '*.md' | sort -r)")
fi

# Wenn eine Datei ausgewählt wurde
if [ -n "$SELECTED" ]; then
    if [ "$PRINT_PATH" -eq 1 ]; then
        # Nur den Pfad ausgeben
        echo "$SELECTED"
    else
        # Datei mit dem konfigurierten Editor öffnen
        $OPEN_WITH "$SELECTED"
    fi
fi
