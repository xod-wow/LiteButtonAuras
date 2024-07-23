#!/bin/sh

DASHES=--------------------------------------------------------------------------------

header () {
    _LINE="-- $1 "
    _LEN=$(( 1 + 80 - $(echo "$_LINE" | wc -c) ))
    printf "%s%.*s\n" "$_LINE" $_LEN $DASHES
    echo
}

fetch () {
    curl -s -H "X-Api-Token: $APIKEY" "https://wow.curseforge.com/api/projects/526431/localization/export?export-type=TableAdditions&lang=$1&unlocalized=Ignore" | awk -F' = ' '{ printf("    %-21s = %s\n", $1, $2) }'
}

for locale in "deDE" "esES" "frFR" "itIT" "koKR" "ptBR" "ruRU" "zhCN" "zhTW"; do

    # As far as I can tell everyone treats esES and esMX as identical
    case $locale in
    esES)
        header "esES / esMX"
        echo 'if locale == "esES" or locale == "esMX" then'
        ;;
    *)
        header $locale
        echo "if locale == \"$locale\" then"
        ;;
    esac

    fetch $locale

    echo "end"
    if [ "$locale" != "zhTW" ]; then
        echo
    fi
done
