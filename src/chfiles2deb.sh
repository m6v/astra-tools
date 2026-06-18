#!/bin/bash

usage() {
    echo "Использование: $0 [путь_для_поиска] <имя_пакета.deb> <флаги_времени_find>"
    echo "   или: $0 -h | --help"
    echo "Находит новые и измененные файлы и собирает из них готовый DEB-пакет."
    echo ""
    echo "Обязательные параметры:"
    echo "  флаги_времени_find  Любые временные флаги утилиты find (например: -mmin -5, -mtime -1)"
    echo "  <имя_пакета.deb>    Имя DEB-пакета"
    echo ""
    echo "Необязательные параметры:"
    echo "  [путь_для_поиска]     Каталог для сканирования (по умолчанию текущий каталог) "
    echo ""
    echo "Примеры вызова:"
    echo "  $0 -mmin -10 foo.deb"
    echo "  $0 /usr/local foo.deb -mtime -1"
    exit 1
}

SRC_DIR=""
DEB_FILE=""
TIME_PARAMS=()
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -mmin|-mtime|-amin|-atime|-cmin|-ctime|-newer*)
            TIME_PARAMS+=("$1" "$2")
            shift 2
            ;;
        -*) echo "Ошибка: Неизвестный флаг $1"; usage ;;
        *) POSITIONAL_ARGS+=("$1"); shift 1 ;;
    esac
done

if [ ${#TIME_PARAMS[@]} -eq 0 ] || [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
    echo "Ошибка: Не указаны обязательные параметры"
    usage
fi

if [ ${#POSITIONAL_ARGS[@]} -eq 1 ]; then
    DEB_FILE="${POSITIONAL_ARGS}"
    SRC_DIR="."
else
    SRC_DIR="${POSITIONAL_ARGS}"
    DEB_FILE="${POSITIONAL_ARGS}"
fi

SRC_DIR=$(realpath "$SRC_DIR")
DEB_FILE=$(realpath "$DEB_FILE")
SCRIPT_PATH=$(realpath "$0")

# Получение имени пакета без пути и расширения .deb
PKG_NAME=$(basename "$DEB_FILE" .deb)

# Создание структуры подкаталогов во временном каталоге
BUILD_DIR="/tmp/deb_build_$$"
mkdir -p "$BUILD_DIR"

EXCLUDES=(
    -path "/temp"
    -o -path "/proc"
    -o -path "/sys"
    -o -path "/dev"
    -o -path "/run"
    -o -path "$DEB_FILE"
    -o -path "$SCRIPT_PATH"
    -o -path "$BUILD_DIR"
)

# Поиск и копирование измененных файлов во временный каталог с сохранением структуры путей
find "$SRC_DIR" \( "${EXCLUDES[@]}" \) -prune -o -type f "${TIME_PARAMS[@]}" -print0 | \
    tar --null -T - -cf - | tar -xf - -C "$BUILD_DIR"

# Проверка наличия файлов
if [ -z "$(ls -A "$BUILD_DIR")" ]; then
    echo "Предупреждение: Измененных файлов не найдено. Сборка $DEB_FILE отменена"
    rm -rf "$BUILD_DIR"
    exit 0
fi

# Создание обязательных метаданные пакета (DEBIAN/control)
mkdir -p "$BUILD_DIR/DEBIAN"
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: 1.0.$(date +%Y%m%d%H%M)
Architecture: all
Maintainer: BackupScript <admin@localhost>
Description: Автоматический пакет обновлений измененных файлов
EOF

# Сборка DEB-пакета
echo "Сборка пакета $DEB_FILE..."
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

# Очистка временных файлов
rm -rf "$BUILD_DIR"
echo "$DEB_FILE успешно создан"
