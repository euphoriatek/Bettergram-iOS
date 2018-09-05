find . -type f -name "*.editable.strings" | sed s/.editable.strings$// | xargs -I@ bash -c "sed s/TELEGRAM_APP_NAME/${TELEGRAM_APP_NAME}/g @.editable.strings > @.strings"
