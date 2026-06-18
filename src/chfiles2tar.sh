#!/bin/bash

usage() {
    echo "Использование: $0 [путь_для_поиска] <имя_архива.tar.gz> <флаги_времени_find>"
    echo "   или: $0 -h | --help"
    echo "Находит новые и измененные файлы и упаковывает их в архив с сохранением структуры каталогов."
    echo ""
    echo "Обязательные параметры:"
    echo "  флаги_времени_find   Любые временные флаги утилиты find (например: -mmin -5, -mtime -1)"
    echo "  <имя_архива.tar.gz>  Имя архива для упаковки измененных файлов"
    echo ""
    echo "Необязательные параметры:"
    echo "  [путь_для_поиска]      Каталог для сканирования (по умолчанию текущий каталог) "
    echo ""
    echo "Примеры вызова:"
    echo "  $0 -mmin -10 backup.tar.gz"
    echo "  $0 /var/www /tmp/web_site.tar.gz -mtime -1"
    exit 1
}

SRC_DIR=""
ARCHIVE=""
TIME_PARAMS=()        # Массив для хранения флагов с временными ограничениями
POSITIONAL_ARGS=() # Массив для пути поиска и архива с измененными файлами

# Цикл разбора аргументов командной строки
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -mmin|-mtime|-amin|-atime|-cmin|-ctime|-newer*)
            # Аргумент временных ограничений
            TIME_PARAMS+=("$1" "$2") 
            shift 2
            ;;
        -*)
            echo "Ошибка: Неизвестный флаг $1"
            usage
            ;;
        *)
             # Аргумент(ы) пути поиска и/или архива с измененными файлами
            POSITIONAL_ARGS+=("$1")
            shift 1
            ;;
    esac
done

if [ ${#TIME_PARAMS[@]} -eq 0 ]; then
    echo "Ошибка: Не указан параметр времени"
    usage
fi

if [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
    echo "Ошибка: Не указано имя архива"
    usage
elif [ ${#POSITIONAL_ARGS[@]} -eq 1 ]; then
    ARCHIVE="${POSITIONAL_ARGS}"
    SRC_DIR="."
else
    SRC_DIR="${POSITIONAL_ARGS}"
    ARCHIVE="${POSITIONAL_ARGS}"
fi

SRC_DIR=$(realpath "$SRC_DIR")
ARCHIVE=$(realpath "$ARCHIVE")
SCRIPT_PATH=$(realpath "$0")

EXCLUDES=(
    -path "/temp"
    -o -path "/proc"
    -o -path "/sys"
    -o -path "/dev"
    -o -path "/run"
    -o -path "$ARCHIVE"
    -o -path "$SCRIPT_PATH"
)

find "$SRC_DIR" \( "${EXCLUDES[@]}" \) -prune -o -type f "${TIME_PARAMS[@]}" -print0 | tar -czvf "$ARCHIVE" --null -T -
