#!/bin/bash

usage() {
    echo "Использование: $0 [путь] <пакет.deb> <фильтр_времени> [-k | --keep] [-l | --follow]"
    echo "Находит новые и измененные файлы и собирает из них DEB-пакет с сохранением структуры каталогов"
    echo ""
    echo "Обязательные параметры:"
    echo "  фильтр_времени  Любые флаги фильтрации по времени, используемые в утилите find, например, -mmin -5, -mtime -1"
    echo "  <пакет.deb>     Имя создаваемого DEB-пакета"
    echo ""
    echo "Необязательные параметры:"
    echo "  [путь]          Каталог для сканирования (по умолчанию текущий каталог '.')"
    echo "  -k, --keep      Не удалять временный каталог с файлами после сборки"
    echo "  -l, --follow    Автоматически добавлять в пакет файлы, на которые указывают битые ссылки"
    echo ""
    echo "Примеры вызова:"
    echo "  $0 -mmin -10 foo.deb"
    echo "  $0 /usr/local foo.deb -mtime -1 -l"
    echo "  $0 /usr/local foo.deb -newermt '09:15:00' --keep --follow"
    exit 1
}

SRC_DIR=""
DEB_FILE=""
TIME_PARAMS=()
POSITIONAL_ARGS=()
KEEP_BUILD_DIR=false 
FOLLOW_LINKS=false    

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -k|--keep)
            KEEP_BUILD_DIR=true
            shift 1
            ;;
        -l|--follow)
            FOLLOW_LINKS=true
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

if [ ${#POSITIONAL_ARGS[@]} -eq 1 ]; then
    # Если аргумент один - это имя DEB-пакета, ищем измененные файлы в текущем каталоге
    DEB_FILE="${POSITIONAL_ARGS[0]}"
    SRC_DIR="."
else
    # Если аргументов два - первый это путь (индекс 0), второй имя DEB-пакета (индекс 1)
    SRC_DIR="${POSITIONAL_ARGS[0]}"
    DEB_FILE="${POSITIONAL_ARGS[1]}"
fi

SRC_DIR=$(realpath "$SRC_DIR")
DEB_FILE=$(realpath "$DEB_FILE")
SCRIPT_PATH=$(realpath "$0")

PKG_NAME=$(basename "$DEB_FILE" .deb)
BUILD_DIR=$(mktemp -d -t deb_build_XXXXXX)

# Функция автоматической очистки
cleanup() {
    # Если каталога нет, сразу выходим
    [ -d "$BUILD_DIR" ] || return

    if [ "$KEEP_BUILD_DIR" = false ]; then
        rm -rf "$BUILD_DIR"
    elif [ -d "$BUILD_DIR/DEBIAN" ]; then
        echo "Временный каталог сохранен: $BUILD_DIR"
        echo "Для сборки пакета выполните команду: dpkg-deb --build \"$BUILD_DIR\" \"$DEB_FILE\""
    fi
}
trap cleanup EXIT SIGINT SIGTERM

EXCLUDES=(
    -path "/tmp"
    -o -path "/proc"
    -o -path "/sys"
    -o -path "/dev"
    -o -path "/run"
    -o -path "$DEB_FILE"
    -o -path "$SCRIPT_PATH"
    -o -path "$BUILD_DIR"
)

# Поиск и копирование измененных файлов и ссылок
find "$SRC_DIR" \( "${EXCLUDES[@]}" \) -prune -o \( -type f -o -type l \) "${TIME_PARAMS[@]}" -print0 | tar --null -T - -cf - | tar -xf - -C "$BUILD_DIR"

# Проверка наличия файлов
if [ -z "$(ls -A "$BUILD_DIR")" ]; then
    echo "Предупреждение: Измененных файлов не найдено. Сборка $DEB_FILE отменена"
    exit 0
fi

echo "Проверка целостности символических ссылок внутри сборки..."
while read -r -d '' link_path; do
    target=$(readlink "$link_path")
    
    if [[ "$target" = /* ]]; then
        real_system_target="$target"
    else
        link_dir_real=$(dirname "${link_path#$BUILD_DIR}")
        real_system_target=$(realpath -m "$SRC_DIR/$link_dir_real/$target")
    fi

    full_target_path="$BUILD_DIR$real_system_target"

    if [ ! -e "$full_target_path" ]; then
        display_link="${link_path#$BUILD_DIR}"
        
        if [ "$FOLLOW_LINKS" = true ] && [ -e "$real_system_target" ]; then
            echo "Автодобавление: Ссылка [$display_link] требует файл [$real_system_target]. Копируем..."
            (cd / && cp -a --parents ".${real_system_target}" "$BUILD_DIR/")
            KEEP_BUILD_DIR=true
        else
            echo "Предупреждение: Ссылка [$display_link] ведет на отсутствующий в пакете объект [$target]"
            KEEP_BUILD_DIR=true
        fi
    fi
done < <(find "$BUILD_DIR" -type l -print0)

# Создание обязательной структуры папки DEBIAN
mkdir -p "$BUILD_DIR/DEBIAN"

echo "Генерация контрольных сумм md5sums..."
(
    cd "$BUILD_DIR" || exit 1
    find . -type f ! -path "./DEBIAN/*" -print0 | xargs -0 md5sum > DEBIAN/md5sums
)

# Создание обязательных метаданных пакета (DEBIAN/control)
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: 1.0.$(date +%Y%m%d%H%M)
Architecture: all
Maintainer: Sergey Maksimov <m6v@mail.ru>
Description: Пакет постинсталляционных изменений файловой системы
EOF

# Сборка DEB-пакета
echo "Сборка пакета $DEB_FILE..."
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

echo "$DEB_FILE успешно создан"
