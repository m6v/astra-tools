#!/bin/bash

# Функция вывода справки
usage() {
    echo "НАЗНАЧЕНИЕ:"
    echo "  Скрипт находит новые и измененные файлы с помощью утилиты find"
    echo "  и собирает из них готовый DEB-пакет с сохранением структуры каталогов."
    echo ""
    echo "Использование: $0 [путь_для_поиска] <имя_пакета.deb> <флаги_времени_find> [-k | --keep]"
    echo "   или: $0 -h | --help"
    echo ""
    echo "Обязательные параметры:"
    echo "  флаги_времени_find  Любые временные флаги утилиты find (например: -mmin -5, -mtime -1)"
    echo "  <имя_пакета.deb>    Имя DEB-пакета"
    echo ""
    echo "Необязательные параметры:"
    echo "  [путь_для_поиска]     Каталог для сканирования (по умолчанию текущий каталог '.')"
    echo "  -k, --keep          Не удалять временный каталог с файлами после сборки"
    echo ""
    echo "Примеры вызова:"
    echo "  $0 -mmin -10 foo.deb"
    echo "  $0 /var/www /tmp/web_site.deb -mtime -1 --keep"
    echo "  $0 /usr/local foo.deb -newermt \"2026-06-19 09:15:00\""
    exit 1
}

SRC_DIR=""
DEB_FILE=""
TIME_PARAMS=()
POSITIONAL_ARGS=()
KEEP_BUILD_DIR=false 

# Цикл разбора аргументов командной строки
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -k|--keep)
            KEEP_BUILD_DIR=true
            shift 1
            ;;
        -mmin|-mtime|-amin|-atime|-cmin|-ctime|-newer*)
            TIME_PARAMS+=("$1" "$2") 
            shift 2
            ;;
        -*)
            echo "Ошибка: Неизвестный флаг $1"
            usage
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift 1
            ;;
    esac
done

if [ ${#TIME_PARAMS[@]} -eq 0 ] || [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
    echo "Ошибка: Не указаны обязательные параметры"
    usage
fi

# Логика распределения путей (архив и каталог)
if [ ${#POSITIONAL_ARGS[@]} -eq 1 ]; then
    DEB_FILE="${POSITIONAL_ARGS[0]}"
    SRC_DIR="."
else
    SRC_DIR="${POSITIONAL_ARGS[0]}"
    DEB_FILE="${POSITIONAL_ARGS[1]}"
fi

SRC_DIR=$(realpath "$SRC_DIR")
DEB_FILE=$(realpath "$DEB_FILE")
SCRIPT_PATH=$(realpath "$0")

PKG_NAME=$(basename "$DEB_FILE" .deb)

# Создание уникальной временной директории со случайным именем
BUILD_DIR=$(mktemp -d -t deb_build_XXXXXX)

# Функция автоматической очистки при выходе или сбое
cleanup() {
    if [ -d "$BUILD_DIR" ]; then
        if [ "$KEEP_BUILD_DIR" = false ]; then
            rm -rf "$BUILD_DIR"
        else
            if [ -d "$BUILD_DIR/DEBIAN" ]; then
                echo "Временный каталог сохранен: $BUILD_DIR"
                echo "Для сборки пакета выполните команду: dpkg-deb --build \"$BUILD_DIR\" \"$DEB_FILE\""
            fi
        fi
    fi
}
trap cleanup EXIT SIGINT SIGTERM

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

# Поиск и копирование измененных файлов и символических ссылок
find "$SRC_DIR" \( "${EXCLUDES[@]}" \) -prune -o \( -type f -o -type l \) "${TIME_PARAMS[@]}" -print0 | tar --null -T - -cf - | tar -xf - -C "$BUILD_DIR"

# Проверка наличия файлов
if [ -z "$(ls -A "$BUILD_DIR")" ]; then
    echo "Предупреждение: Измененных файлов не найдено. Сборка $DEB_FILE отменена"
    exit 0
fi

# ПРОВЕРКА СИМВОЛИЧЕСКИХ ССЫЛОК
echo "Проверка целостности символических ссылок внутри сборки..."
while read -r -d '' link_path; do
    target=$(readlink "$link_path")
    
    if [[ "$target" = /* ]]; then
        full_target_path="$BUILD_DIR$target"
    else
        link_dir=$(dirname "$link_path")
        full_target_path=$(realpath -m "$link_dir/$target")
    fi

    if [ ! -e "$full_target_path" ]; then
        display_link="${link_path#$BUILD_DIR}"
        echo "Предупреждение: Ссылка [$display_link] ведет на отсутствующий в пакете объект [$target]"
        KEEP_BUILD_DIR=true
    fi
done < <(find "$BUILD_DIR" -type l -print0)

# Создание обязательных метаданных пакета (DEBIAN/control)
mkdir -p "$BUILD_DIR/DEBIAN"
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: 1.0.$(date +%Y%m%d%H%M)
Architecture: all
Maintainer: Sergey Maksimov <m6v@mail.ru>
Description: Автоматический пакет обновлений измененных файлов
EOF

# Сборка DEB-пакета
echo "Сборка пакета $DEB_FILE..."
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

echo "$DEB_FILE успешно создан"
