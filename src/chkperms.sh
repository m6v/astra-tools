#!/usr/bin/env bash

VERSION=1.03

# Используемые escape-последовательности
NC='\033[0m' # Нет цвета
Red='\033[0;31m' # Красный
Green='\033[0;32m' # Зеленый
EraseLine='\033[K' # Стереть от курсора до конца строки

checks=0
errors=0

usage(){
  echo "Использование: $(basename $0) [-h|-v|-p|--version] ФАЙЛ..."
  echo "Проверяет соответствие прав доступа к файлам и каталогам матрице доступа"
  echo
  echo "  -h, --help     показать эту справку и выйти"
  echo "  -v, --verbose  показывать успешные проверки"
  echo "  -p, --progress показать индикатор програсса выполнения"
  echo "  --version      показать информацию о версии и выйти"
  echo "  ФАЙЛ           файл с матрицей даступа"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      exit
      ;;
    -v|--verbose)
      verbose=true
      ;; 
    -p|--progress)
      show_progress=true
      ;;     
    --version)
      echo $(basename $0) $VERSION
      exit
      ;;
    *)
      file=$1
      ;;
  esac
  shift
done

if [ ! -f "$file" ]; then
  echo "Ошибка: файл с матрицей доступа не задан или не найден" >&2
  exit
fi

total=$(cat $file | wc -l)
# Число колонок в окне терминала 
wterm=$(tput cols)

# Присвоить переменной NAME имя дистрибутива
eval $(grep ^NAME /etc/os-release)
if [ "$NAME" == "Astra" ]; then
  # Исправить, чтобы в Астре это работало правилиьно, кол-во полей точно отличается!
  template="pdp-ls -daM --time-style=+ %s | cut -d' ' -f1,3,4,7-"
else
  template="ls -dal --time-style=+ %s | cut -d' ' -f1,3,4,7-"
fi

echo "Проверка прав доступа..."
while read -r line; do
    if [ -n "$show_progress" ]; then
      # Процент выполнения проверок (сначала умножаем, потом делим, т.к. деление целочисленное)
      percent=$((${checks}*100/${total}))
      # Количество знаков индикатора прогресса с учетом ширины терминала
      sharpcount=$((${checks}*${wterm}/${total}))
      # escape-последовательность для повторения символа перед ней несколько раз (REP) \e[n;b
      # см.: https://invisible-island.net/xterm/ctlseqs/ctlseqs.pdf (стр. 12)
      printf [%d%%]"#\e[%d;b\r" $percent $sharpcount
    fi

    ((checks++))
    fname=$(echo $line  | cut -d' ' -f4-)
    if [ ! -e "${fname}" ]; then
      echo -e "${fname}...${Red}нет такого файла или каталога${NC}"
      continue
    fi

    # Имя файла обрамляем одинарными кавычками на случай наличия в нем пробелов
    # perms=$(eval "ls -dal --time-style=+ '${fname}' | cut -d' ' -f1,3,4,7-")
    perms=$(eval $(printf "$template" "'$fname'"))

    if [ "$line" != "$perms" ]; then
      ((errors++))
      echo -e "${fname}...${Red}ошибка${NC}${EraseLine}"
      continue  
    fi
    if [ -n "$verbose" ]; then
      # Вывести сообщение и затереть индикатор прогресса
      echo -e "${fname}...${Green}успешно${NC}${EraseLine}"
    fi
done <$file

echo "Проверено объектов "$checks", ошибок "$errors
